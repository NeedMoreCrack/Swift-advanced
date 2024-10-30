import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/chuanchiawei/Desktop/Swift/Swift Advanced/113.10.30/TyphoonApp/TyphoonApp/ContentView.swift", line: 1)
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
            Text(__designTimeString("#5066_0", fallback: "颱風假查詢"))
                .font(.largeTitle)
                .padding()
            
            Picker(__designTimeString("#5066_1", fallback: "選擇縣市"), selection: $selectedCity) {
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
                    .foregroundColor(getHolidayStatus().contains(__designTimeString("#5066_2", fallback: "停止上班")) ? .green : .red)
            }
            
            Button(__designTimeString("#5066_3", fallback: "更新資料")) {
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
        isLoading = __designTimeBoolean("#5066_4", fallback: true)
        let service = DisasterNotificationService()
        do {
            workStopInfos = try await service.fetchWorkStopStatus()
            print("載入了 \(workStopInfos.count) 筆資料")
            if workStopInfos.isEmpty {
                print(__designTimeString("#5066_5", fallback: "沒有找到任何資料"))
            }
        } catch {
            print("錯誤：\(error.localizedDescription)")
        }
        isLoading = __designTimeBoolean("#5066_6", fallback: false)
    }
    
    func getHolidayStatus() -> String {
        guard let cityInfo = workStopInfos.first(where: { $0.region == selectedCity }) else {
            return __designTimeString("#5066_7", fallback: "資料載入中...")
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
        print(__designTimeString("#5066_8", fallback: "開始獲取資料..."))
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP 狀態碼: \(httpResponse.statusCode)")
        }
        
        guard let htmlString = String(data: data, encoding: .utf8) else {
            print(__designTimeString("#5066_9", fallback: "無法解析 HTML"))
            throw NSError(domain: __designTimeString("#5066_10", fallback: "解析錯誤"), code: __designTimeInteger("#5066_11", fallback: -1))
        }
        
        print("HTML 長度: \(htmlString.count)")
        
        // 修改正則表達式來匹配整個 tr 和 td 的內容
        let pattern = __designTimeString("#5066_12", fallback: "<tr[^>]*>\\s*<td[^>]*>\\s*<font[^>]*>([^<]+)</font>\\s*</td>\\s*<td[^>]*>((?:.|\\n)*?)</td>")
        
        let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        let matches = regex.matches(in: htmlString, options: [], range: NSRange(location: __designTimeInteger("#5066_13", fallback: 0), length: htmlString.count))
        
        print("找到 \(matches.count) 個匹配項")
        
        var results: [WorkStopInfo] = []
        
        for match in matches {
            guard let regionRange = Range(match.range(at: __designTimeInteger("#5066_14", fallback: 1)), in: htmlString),
                let statusRange = Range(match.range(at: __designTimeInteger("#5066_15", fallback: 2)), in: htmlString) else {
                continue
            }
            
            let region = String(htmlString[regionRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            var status = String(htmlString[statusRange])
            
            // 清理 HTML 標籤和特殊字符
            status = status.replacingOccurrences(of: __designTimeString("#5066_16", fallback: "<[^>]+>"), with: __designTimeString("#5066_17", fallback: ""), options: .regularExpression)
            status = status.replacingOccurrences(of: __designTimeString("#5066_18", fallback: "\\s+"), with: __designTimeString("#5066_19", fallback: " "), options: .regularExpression)
            status = status.replacingOccurrences(of: __designTimeString("#5066_20", fallback: " +"), with: __designTimeString("#5066_21", fallback: " "))
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
