import SwiftUI

struct ContentView: View {
    @State private var selected = false
    @State private var selRow = -1
    @State private var selCol = -1
    @State private var markNumber = -1
    @State private var sudokulog: [[Int]] = []
    @State private var undoCount = 0
    @State private var sudokuError = false
    @State private var data = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    @State private var data_save = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    @State private var answers = false
    @State private var nextChoices: [[Int]] = []

    var body: some View {
        let cellSize = CGFloat(40)
        let blockLineSize = CGFloat(3)
        let lineColor = Color.black
        VStack(spacing: 0) {
            ZStack {
                Text("Sudoku")
                    .font(.system(size: 30))
                    .fontWeight(.bold)
                HStack {
                    Text("answer")
                    Toggle(isOn: $answers) {}
                        .labelsHidden()
                }
                .offset(x: 130, y: 0)
            }
            SudokuCells(cellSize: cellSize, blockLineSize: blockLineSize, lineColor: lineColor)
        }
        Spacer().frame(height: 8)
        VStack(spacing:4) {
            SudokuNumberButtons()
            SudokuFunctionButtons()
            SudokuAnswerButtons()
        }
    }

    @ViewBuilder
    func SudokuCells(cellSize: CGFloat, blockLineSize: CGFloat, lineColor: Color) -> some View{
        ZStack {
            let backgroundSize = CGFloat(cellSize * 9 + blockLineSize * 5) // 背景の大きさを計算
            RoundedRectangle(cornerRadius: 0)
                .fill(lineColor)
                .frame(width: backgroundSize, height: backgroundSize)
            VStack(spacing: blockLineSize) {
                ForEach(0..<3, id: \.self) { brow in
                    HStack(spacing: blockLineSize) {
                        ForEach(0..<3, id: \.self){ bcol in
                            VStack(spacing:0) {
                                ForEach(0..<3, id: \.self) { crow in
                                    HStack(spacing:0) {
                                        ForEach(0..<3, id: \.self) { ccol in
                                            let row = brow * 3 + crow
                                            let col = bcol  * 3 + ccol
                                            Button(action: {
                                                selectCell(row: row, col: col)
                                            }) {
                                                Text(getCellText(row: row, col: col))
                                                    .frame(width: cellSize, height: cellSize, alignment: .center)
                                                    .border(lineColor)
                                                    .foregroundColor(.black)
                                                    .background(getCellColor(row: row, col: col))
                                                    .font(.system(size: 35))
                                                    .fontWeight(data_save[row][col] == 0 ? .regular : .semibold) // 問題は太字で表示
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func SudokuNumberButtons() -> some View{
        HStack(spacing:3) {
            ForEach(0..<9, id: \.self) { n in
                Button(action: {
                    setnumber(n: n + 1)
                }) {
                    Text(String(n + 1))
                        .frame(width: 38, height: 38, alignment: .center)
                        .foregroundColor(.black)
                        .background(.mint)
                        .cornerRadius(10)
                        .font(.system(size: 35))
                }
            }
        }
        HStack(spacing:3) {
            ForEach(0..<9, id: \.self) { n in
                Text(numberOfRemainingCases(n: n + 1, sudokuMatrix: data))
                    .frame(width: 38, height: 26, alignment: .center)
                    .foregroundColor(.black)
                    .background(.white)
                    .font(.system(size: 20))                        
            }
        }
    }

    @ViewBuilder
    func SudokuFunctionButtons() -> some View{
        HStack(spacing:4) {
            Button(action: {
                undo()
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundColor(Color.black)
                    .imageScale(.large)
                    .frame(width: 40, height: 40, alignment: .center)
                    .background(Color.mint)
                    .cornerRadius(10)
            }
            Button(action: {
                redo()
            }) {
                Image(systemName: "arrow.uturn.forward")
                    .foregroundColor(Color.black)
                    .imageScale(.large)
                    .frame(width: 40, height: 40, alignment: .center)
                    .background(Color.mint)
                    .cornerRadius(10)
            }
            Button(action: {
                setMemory()
            }) {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(Color.black)
                    .imageScale(.large)
                    .frame(width: 40, height: 40, alignment: .center)
                    .background(Color.mint)
                    .cornerRadius(10)
            }
            Button(action: {
                loadMemory()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Color.black)
                    .imageScale(.large)
                    .frame(width: 40, height: 40, alignment: .center)
                    .background(Color.mint)
                    .cornerRadius(10)
            }
            Button(action: {
                allClear()
            }) {
                Image(systemName: "eraser.fill")
                    .foregroundColor(Color.black)
                    .imageScale(.large)
                    .frame(width: 40, height: 40, alignment: .center)
                    .background(Color.mint)
                    .cornerRadius(10)
            }
        }
    }

    @ViewBuilder
    func SudokuAnswerButtons() -> some View{
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { krow in
                HStack(spacing: 4) { 
                    ForEach(0..<5, id: \.self){ kcol in
                        let k = krow * 5 + kcol                           
                        Button(action: {
                            if k < nextChoices.count {
                                selectCell(row: nextChoices[k][0], col: nextChoices[k][1])
                                setnumber(n: nextChoices[k][2])
                            }
                        }) {
                            Text(getTextNextChoices(n: k, dt: nextChoices))
                                .frame(width: 70, height: 40, alignment: .center)
                                .foregroundColor(.black)
                                .font(.system(size: 20))
                                .fontWeight(.regular)
                                .background(.mint)
                                .cornerRadius(10)
                        }
                        .opacity(answers && k < nextChoices.count ? 1 : 0)
                    }
                }
            }
        }
    }

    private func selectCell(row: Int, col: Int) {
        if sudokuError { return } // エラー状態では受け付けない
        if data[row][col] == 0 { // 空白の時には選択状態にする、マーク番号を未定義にする
            markNumber = -1
            selRow = row
            selCol = col
            selected = true
        } else {                  // 空白でないときはマーク番号を設定、非選択状態にする
            markNumber = data[row][col]
            selected = false
            selRow = -1
            selCol = -1
        }
    }

    private func setnumber(n: Int) {
        if sudokuError { return } // エラー状態では受け付けない
        if selected {
            if data[selRow][selCol] == 0 { // 選択状態のセルが空白なら数値を設定する
                while undoCount > 0 {
                    sudokulog.removeLast()
                    undoCount -= 1
                }
                sudokulog.append([selRow, selCol, n])
                data[selRow][selCol] = n
                if checkError(row: selRow, col: selCol, num: n, sudokuMatrix: data) { // エラーチェック
                    sudokuError = true
                } else {
                    sudokuError = false
                }
                return
            }
        }
        selectNumber(num: n)  // 非選択状態ならその数値をマークするように設定する
    }

    private func selectNumber(num: Int) {
        if num != 0 {  // 0で無ければその数値をマーク番号とする、非選択状態にする
            markNumber = num
            selected = false
            selRow = -1
            selCol = -1
        } else {  // 0は特別に非選択状態＆数値非マーク状態設定用に使用しています
            markNumber = -1
            selected = false
            selRow = -1
            selCol = -1
        }
    }

    private func getCellText(row: Int, col: Int) -> String {
        // Cellに表示する文字を返す
        // 0 の時はスペースを返す
        var answer = " "
        if data[row][col] != 0 {
            answer = String(data[row][col])
        }
        return answer
    }

    private func getCellColor(row: Int, col: Int) -> Color {
        if sudokuError { // エラー状態のとき
            if selRow == row && selCol == col { // 選択セルを赤
                return Color.red
            } else if selected {
                if data[row][col] == data[selRow][selCol] { // 同じ数値を黄色
                    return Color.yellow
                }
            }
        } else if selected {
            if selRow == row && selCol == col { // そのセルが選択されたセルならば
                if data[row][col] == 0 { // 空白の時はオレンジでマーク
                    return Color.orange
                } else {
                    return Color.blue   // 空白でなければブルーでマーク
                }
            }
        } else if data[row][col] == markNumber {  // 非選択状態でそのセルがマーク番号と一致した場合
            return Color.mint   // ミントでマーク
        }
        return Color.white   // デフォルトは白
    }

    private func numberOfRemainingCases(n: Int, sudokuMatrix: [[Int]]) -> String {
        // 各数字を設定する残り回数を戻す
        let count = 9 - sudokuMatrix.flatMap { $0 }.filter { $0 == n }.count
        return String(count)
    }

    private func displayLog(row: Int, col: Int) {
        // セル選択状態、数値設定あり --> ブルーマーク状態にする
        markNumber = -1
        selected = true
        selRow = row
        selCol = col
    }

    private func undo() {
        if sudokulog.count > 0 {
            if undoCount < sudokulog.count {
                undoCount = undoCount + 1
                var p = sudokulog.count - undoCount
                data[sudokulog[p][0]][sudokulog[p][1]] = 0 // 空白に戻す
                p -= 1
                if p >= 0 { // 履歴表示途中なら
                    displayLog(row: sudokulog[p][0], col: sudokulog[p][1]) // セルをブルーマーク状態にする
                    sudokuError = false
                    if checkError(row: sudokulog[p][0], col: sudokulog[p][1], num: sudokulog[p][2], sudokuMatrix: data) {
                        sudokuError = true
                    }
                    return
                }
            }
        }
        selectNumber(num: 0) // 非選択＆数字非マーク状態設定
    }

    private func redo() {
        if sudokuError { return } // エラー状態では受け付けない
        if sudokulog.count > 0 {
            if undoCount > 0 {
                let p = sudokulog.count - undoCount
                data[sudokulog[p][0]][sudokulog[p][1]] = sudokulog[p][2] // 履歴から戻して設定する
                displayLog(row: sudokulog[p][0], col: sudokulog[p][1]) // セルをブルーマーク状態にする
                sudokuError = false
                if checkError(row: sudokulog[p][0], col: sudokulog[p][1], num: sudokulog[p][2], sudokuMatrix: data) {
                    sudokuError = true
                }
                undoCount = undoCount - 1
                return
            }
        }
        selectNumber(num: 0) // 非選択＆数字非マーク状態設定
    }

    private func setMemory() {
        // 問題データとして保存する
        if sudokuError { return } // エラー状態では受け付けない
        data_save = data
        sudokulog = []
        undoCount = 0
        selectNumber(num: 0) // 非選択＆数字非マーク状態設定
    }

    private func loadMemory() {
        // 保存されている問題データを読み込む
        data = data_save
        sudokulog = []
        undoCount = 0
        selectNumber(num: 0) // 非選択＆数字非マーク状態設定
        sudokuError = false
        next()
    }

    private func allClear() {
        // Sudokuの作業状態をクリアする
        data = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        sudokulog = []
        undoCount = 0
        selectNumber(num: 0) // 非選択＆数字非マーク状態設定
        sudokuError = false
        nextChoices = []
    }

    private func checkError(row: Int, col: Int, num: Int, sudokuMatrix: [[Int]]) -> Bool {
        // セルに設定した数値がルールエラーだとtrueを返す
        for c in 0..<sudokuMatrix[row].count {
            if c != col && num == sudokuMatrix[row][c] {
                return true
            }
        }
        for r in 0..<sudokuMatrix.count {
            if r != row && num == sudokuMatrix[r][col] {
                return true
            }
        }
        let baseRow = Int(row / 3) * 3
        let baseCol = Int(col / 3) * 3
        for r in baseRow..<baseRow + 3 {
            for c in baseCol..<baseCol + 3 {
                if r != row && c != col && num == sudokuMatrix[r][c] {
                    return true
                }
            }
        }
        next()
        return false
    }

    private func getTextNextChoices(n: Int, dt: [[Int]]) -> String {
        var answer = " "
        if n < dt.count {
            answer = String(dt[n][0]) + "," + String(dt[n][1]) + ":" + String(dt[n][2])
        }
        return answer
    }

    private func next() {
        var candidates = listCandidates(sudokuMatrix: data)
        var answer: [[Int]] = []

        answer = getAnswerNakedSingle(candicates_9x9: candidates)
        let newAnswer = getAnswerHiddenSingle(candicates_9x9: candidates)
        for ans in newAnswer {
            answer.append(ans)
        }

        nextChoices = answer
    }

    private func getAnswerNakedSingle(candicates_9x9: [[[Int]]]) -> [[Int]]  {
        var answer: [[Int]] = []
        for row in 0..<candicates_9x9.count {
            for col in 0..<candicates_9x9[row].count {
                if candicates_9x9[row][col].count == 1 {
                    answer.append([row, col, candicates_9x9[row][col][0]])
                }
            }
        }
        return answer
    }

    private func getAnswerHiddenSingle(candicates_9x9: [[[Int]]]) -> [[Int]]  {
        var answer: [[Int]] = []
        let allLocations = getAllLocations(sudokuMatrix: data)
        for locations in allLocations {
            var numberLocations: [[[Int]]] = [[], [], [], [], [], [], [], [], []]
            for c in locations {
                for n in 0..<numberLocations.count {
                    let row = c[0]
                    let col = c[1]
                    if candicates_9x9[row][col].contains(n + 1) {
                        numberLocations[n].append([row, col])
                    }
                }
            }
            for n in 0..<numberLocations.count {
                if numberLocations[n].count == 1 {
                    let row = numberLocations[n][0][0]
                    let col = numberLocations[n][0][1]
                    let num = n + 1
                    if candicates_9x9[row][col].count > 1 {
                        let strAnswer = answer.map { String(describing: $0) }
                        if !strAnswer.contains(String(describing:[row, col, num])) {
                            answer.append([row, col, num])
                        }
                    }
                }
            }
        }
        return answer
    }

    private func listCandidates(sudokuMatrix: [[Int]]) -> [[[Int]]] {
        // 9x9の候補リスト（３次元配列）を返します
        var candicates_9x9: [[[Int]]] = []
        for r in 0..<sudokuMatrix.count {
            var candicates_1x9: [[Int]] = []
            for c in 0..<sudokuMatrix[r].count {
                let candicates_1x1 = getCcandicates(row: r, col: c, sudokuMatrix: sudokuMatrix)
                candicates_1x9.append(candicates_1x1) // 1セル分追加
            }
            candicates_9x9.append(candicates_1x9) // 1行分追加
        }
        return candicates_9x9
    }

    private func getCcandicates(row: Int, col: Int, sudokuMatrix: [[Int]]) -> [Int] {
        // 1x1 指定されたセルの候補リスト（１次元配列）を返します
        var candicates_1x1: [Int] = []
        if sudokuMatrix[row][col] == 0 {
            candicates_1x1 = [1, 2, 3, 4, 5, 6, 7, 8, 9]
            let baseRow = Int(row / 3) * 3
            let baseCol = Int(col / 3) * 3
            for r in baseRow..<baseRow + 3 {
                for c in baseCol..<baseCol + 3 {
                    candicates_1x1 = candicates_1x1.filter { $0 != sudokuMatrix[r][c] } // ブロックにある数値を取り除きます
                }
            }
            for r in 0..<sudokuMatrix.count {
                candicates_1x1 = candicates_1x1.filter { $0 != sudokuMatrix[r][col] } // 行にある数値を取り除きます
            }
            for c in 0..<sudokuMatrix[row].count {
                candicates_1x1 = candicates_1x1.filter { $0 != sudokuMatrix[row][c] } // 列にある数値を取り除きます
            }
        }
        return candicates_1x1
    } 

    private func getAllLocations(sudokuMatrix: [[Int]]) -> [[[Int]]] {
        // ブロック(3x3)、行(1x9)、列(9x1)の行と列の組み合わせパターン27組を返す
        var locations: [[[Int]]] = []
        for brow in 0..<3 {
            for bcol in 0..<3 {
                var locations_line: [[Int]] = []
                let baseRow = brow * 3
                let baseCol = bcol * 3
                for row in baseRow..<baseRow + 3 {
                    for col in baseCol..<baseCol + 3 {
                        locations_line.append([row, col])
                    }  
                }
                locations.append(locations_line)
            }
        }
        for row in 0..<sudokuMatrix.count {
            var locations_line: [[Int]] = []
            for col in 0..<sudokuMatrix[row].count {
                locations_line.append([row, col])
            }
            locations.append(locations_line)
        }
        for col in 0..<sudokuMatrix[0].count {
            var locations_line: [[Int]] = []
            for row in 0..<sudokuMatrix.count {
                locations_line.append([row, col])
            }
            locations.append(locations_line)
        }
        return locations
    }

}