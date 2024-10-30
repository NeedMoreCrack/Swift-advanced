print("輸入一個正整數：")
if let num = readLine(), var numInt = Int(num) {
    let ten = 10
    var numArr: [Int] = []
    while numInt > 0 { // 當 numInt > 0 時，繼續迴圈
        numArr.append(numInt % ten)
        numInt /= 10    // 移除最後一位數
    }
    print("numArr : \(numArr)")
    var oddValue = 0
    var evenValue = 0
    // 使用 enumerated 來遍歷陣列，並取得索引和元素
    for (index, value) in numArr.enumerated() {
        if (index % 2 == 0) { // 索引是偶數 -> 位置是奇數
            print("奇數位置 : \(value)")
            oddValue += value
        } else {              // 索引是奇數 -> 位置是偶數
            print("偶數位置 : \(value)")
            evenValue += value
        }
    }
    print("=======================")
    print("奇數的和 : \(oddValue)")
    print("偶數的和 : \(evenValue)")
    print("秘密差 : \(abs(oddValue - evenValue))")
    
    print("=======================")
} else {
    print("輸入的不是有效的整數")
}