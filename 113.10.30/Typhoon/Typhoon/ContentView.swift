import SwiftUI

struct ContentView: View {
    @State private var selectedCity = "臺北市"
    @State private var workStopInfos: [DisasterNotificationService.WorkStopInfo] = []
    @State private var isLoading = false
    
    // 台灣縣市列表
    let cities = [
        "臺北市", "新北市", "基隆市", "桃園市", "新竹市", "新竹縣",
        "苗栗縣", "臺中市", "彰化縣", "南投縣", "雲林縣", "嘉義市",
        "嘉義縣", "臺南市", "高雄市", "屏東縣", "宜蘭縣", "花蓮縣",
        "臺東縣", "澎湖縣", "金門縣", "連江縣"
    ]
    
    var body: some View {
        VStack {
            Text("颱風假查詢")
                .font(.largeTitle)
                .padding()
            
            Picker("選擇縣市", selection: $selectedCity) {
                ForEach(cities, id: \.self) { city in
                    Text(city).tag(city)
                }
            }
            .pickerStyle(.wheel)
            
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                Text(getHolidayStatus())
                    .font(.title)
                    .padding()
                    .foregroundColor(getHolidayStatus().contains("停止上班") ? .green : .red)
            }
            
            Button("更新資料") {
                Task {
                    await loadData()
                }
            }
            .padding()
        }
        .task {
            await loadData()
        }
    }
    
    func loadData() async {
        isLoading = true
        let service = DisasterNotificationService()
        do {
            workStopInfos = try await service.fetchWorkStopStatus()
            print("載入了 \(workStopInfos.count) 筆資料")
            if workStopInfos.isEmpty {
                print("沒有找到任何資料")
            }
        } catch {
            print("錯誤：\(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func getHolidayStatus() -> String {
        guard let cityInfo = workStopInfos.first(where: { $0.region == selectedCity }) else {
            return "資料載入中..."
        }
        return cityInfo.status
    }
}

class DisasterNotificationService {
    let url = URL(string: "https://www.dgpa.gov.tw/typh/daily/nds.html")!
    
    struct WorkStopInfo {
        let region: String
        let status: String
    }
    
    func fetchWorkStopStatus() async throws -> [WorkStopInfo] {
        print("開始獲取資料...")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP 狀態碼: \(httpResponse.statusCode)")
        }
        
        guard let htmlString = String(data: data, encoding: .utf8) else {
            print("無法解析 HTML")
            throw NSError(domain: "解析錯誤", code: -1)
        }
        
        print("HTML 長度: \(htmlString.count)")
        
        // 修改正則表達式來匹配整個 tr 和 td 的內容
        let pattern = "<tr[^>]*>\\s*<td[^>]*>\\s*<font[^>]*>([^<]+)</font>\\s*</td>\\s*<td[^>]*>((?:.|\\n)*?)</td>"
        
        let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        let matches = regex.matches(in: htmlString, options: [], range: NSRange(location: 0, length: htmlString.count))
        
        print("找到 \(matches.count) 個匹配項")
        
        var results: [WorkStopInfo] = []
        
        for match in matches {
            guard let regionRange = Range(match.range(at: 1), in: htmlString),
                let statusRange = Range(match.range(at: 2), in: htmlString) else {
                continue
            }
            
            let region = String(htmlString[regionRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            var status = String(htmlString[statusRange])
            
            // 清理 HTML 標籤和特殊字符
            status = status.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            status = status.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            status = status.replacingOccurrences(of: " +", with: " ")
            status = status.replacingOccurrences(of: "\n+", with: "\n")
            status = status.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("解析到: \(region) - \(status)")
            
            if !region.isEmpty && !status.isEmpty {
                results.append(WorkStopInfo(region: region, status: status))
            }
        }
        
        print("總共解析到 \(results.count) 筆資料")
        return results
    }
}

#Preview {
    ContentView()
}
