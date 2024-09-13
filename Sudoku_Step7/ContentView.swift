import SwiftUI
import Foundation

struct SudokuData {
    var id: String = UUID().uuidString
    var name: String
    var content: String
}

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
    @State private var data_hints: [[String]] = Array(repeating: Array(repeating: "", count: 9), count: 9)
    @State private var answers = false
    @State private var nextChoices: [[Int]] = []
    @State private var sudoku_data = [SudokuData]()
    @State private var listn = 0
    @State private var isEdit = false

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
            if answers {
                SudokuAnswerButtons()
            } else {
                SudokuLists()
            }
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
                                                    .foregroundColor(getCellFontColor(row: row, col: col))
                                                    .background(getCellColor(row: row, col: col))
                                                    .font(getCellFontSize(row: row, col: col))
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

    @ViewBuilder
    func SudokuLists() -> some View{
        HStack {
            Button(action: {
                append_data()  // データをリストに追加
                writefile()    // ファイルに書き込み
            }) {
                Text("append")
            }
            .opacity(isEdit ? 0 : 1)  // リスト編集モードの時は追加ボタンを隠す
            Spacer()
            Button(action: {
                isEdit.toggle()  // editボタン
            }) {
                Text(isEdit ? "close" : "edit")
                .opacity(listn == 0 ? 1 : 0)  // 個別のリスト編集中は閉じられないようにボタンを隠す
            }
        }
        .padding(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
        List {
            if !isEdit {   // リスト編集モードでないとき
                ForEach(0..<sudoku_data.count, id: \.self) { index in
                    Button(action: {
                        set_sudoku_data(index: index)  // 選択の内容をsudokuに設定
                    }, label: {
                        Text(sudoku_data[index].name)  // nameを表示
                    })
                }
            } else {  // リスト編集モードの場合、編集（ペンマーク）、削除（ゴミ箱）を表示
                ForEach(0..<sudoku_data.count, id: \.self) { index in
                    HStack {
                        if listn != index + 1 { // 個別編集モードで無いとき
                            Text(sudoku_data[index].name)  // name テキスト表示
                        } else {  // 個別編集モードのときは
                            TextField("", text: $sudoku_data[index].name)  // TextFieldにして編集可
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        Spacer()

                        Button(action: {
                            if listn != index + 1 {
                                listn = index + 1  // 個別編集モードに設定
                            } else {
                                listn = 0     // 個別編集モードを解除
                                writefile()   // ファイルに書き込み
                            }
                        }, label: {
                            Image(systemName: "pencil")  // 編集ボタンイメージ
                        })
                        .frame(width: 30, alignment: .center)
                        .buttonStyle(BorderlessButtonStyle())
                        .opacity(listn == 0 || listn == index + 1 ? 1 : 0)  // 個別編集になったら該当以外の編集ボタンを隠す

                        Button(action: {
                            let newArray = sudoku_data.filter { $0.id != sudoku_data[index].id }  // 該当するデータを削除
                            sudoku_data = newArray  // 削除後のデータを問題リストとする
                            writefile() //  ファイル書き込み
                        }, label: {
                            Image(systemName: "trash")  // 削除ボタンイメージ
                        })
                        .frame(width: 30, alignment: .center)
                        .buttonStyle(BorderlessButtonStyle())
                        .opacity(listn == 0 ? 1 : 0)  // 個別編集中は削除ボタンを隠す
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .onAppear {
            readfile()
        }
    }

    private func readfile() {
        // アプリ固有のドキュメント領域から問題リストを読み込み
        let fileName = "sudoku.txt"
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            do {
                let text = try String(contentsOf: fileURL, encoding: .utf8)
                let components = text.components(separatedBy: "\n")  // 改行で分割
                sudoku_data = []
                for row in components {
                    let col = row.components(separatedBy: ",")  // カンマで分割
                    if col.count == 3 {
                        let cnvname = col[1].replacingOccurrences(of: "<<<comma>>>", with: ",")  // 別の形のカンマを復元
                        sudoku_data.append(SudokuData(name: cnvname, content: col[2]))
                    }
                }
                print("File was successfully read: \(fileURL)")
            } catch {
                print("Error reading file: \(error)")  // 新しくプロジェクトを作成するとファイルがないので必ずエラーになる
                init_data()  // 初期値データを設定
                writefile()  // ファイル保存
            }
        }
    }

    private func writefile() {
        // アプリ固有のドキュメント領域に問題リストを保存
        var csvData: String = ""
        for row in sudoku_data {
            let cnvname = row.name.replacingOccurrences(of: ",", with: "<<<comma>>>")  // nameにカンマがある場合は別の形に変換
            csvData += row.id
            csvData += ","
            csvData += cnvname
            csvData += ","
            csvData += row.content
            csvData += "\n"
        }
        let fileName = "sudoku.txt"
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            do {
                try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
                print("Successfully wrote to file: \(fileURL)")
            } catch {
                print("Error writing to file: \(error)")
            }
        }
    }

    private func init_data() {
        // 乱数で問題を作成して解けるものだけ残す方法で自動生成したオリジナル問題集
        sudoku_data = []
        sudoku_data.append(SudokuData(name: "Test21-001", content: "000900800002000001700504030900000740013000006000000000004000070000060009369000000"))
        sudoku_data.append(SudokuData(name: "Test21-002", content: "407000050000095010000080006000004027085003000000000000720900000000000700000260005"))
        sudoku_data.append(SudokuData(name: "Test21-003", content: "000900800002000001700504030900000740013000006000000000004000070000060009369000000"))
        sudoku_data.append(SudokuData(name: "Test21-004", content: "000200004039000000007000610000005700400600005092000000800000000050007030000034002"))
        sudoku_data.append(SudokuData(name: "Test21-005", content: "000000490002001000003046050018000000000009006000270000400030207090000001000005000"))
        sudoku_data.append(SudokuData(name: "Test21-006", content: "000907000000080000050000210700020060408005000000010003000000000012009085006001000"))
        sudoku_data.append(SudokuData(name: "Test21-007", content: "407000050000095010000080006000004027085003000000000000720900000000000700000260005"))
        sudoku_data.append(SudokuData(name: "Test21-008", content: "000000000008050006000708100000000004030009000409102000900040000000560003270000010"))
        sudoku_data.append(SudokuData(name: "Test21-009", content: "000000070000200106005001000100000800060740000409000000000018005000060040007530000"))
        sudoku_data.append(SudokuData(name: "Test21-010", content: "006000902000000000002300001401009000300000007000020008800160000000790040050000600"))
        sudoku_data.append(SudokuData(name: "Test21-011", content: "000900010045700030000004000900000003000080402007000600080020000002501000300000070"))
        sudoku_data.append(SudokuData(name: "Test21-012", content: "500000800000260000000000009406001090900000005000005070000090604002000010700048000"))
        sudoku_data.append(SudokuData(name: "Test21-013", content: "080643100104900000063080040035000008040000001010038200001020000000000600320504907"))
        sudoku_data.append(SudokuData(name: "Test22-001", content: "070100000090004000000000000100900020003072800000008005000020347760003000080000090"))
        sudoku_data.append(SudokuData(name: "Test22-002", content: "800030000000900000790020001023000070005084000000000360004000000200070694000005000"))
        sudoku_data.append(SudokuData(name: "Test22-003", content: "089300000001006070007020000000008200010050040500000003600000000000001900020600308"))
        sudoku_data.append(SudokuData(name: "Test22-004", content: "009600052100000000000800000740006010006040000000500000000980000020000760005203008"))
        sudoku_data.append(SudokuData(name: "Test22-005", content: "097040000200790016300000000089006070001000000000000105500001000000970003000020000"))
        sudoku_data.append(SudokuData(name: "Test22-006", content: "000000000006000030050700480000206000802040100000008570200000003003001006000509000"))
        sudoku_data.append(SudokuData(name: "Test22-007", content: "002000047700000009908200000000100006006000080005023000000000000000078590003004100"))
        sudoku_data.append(SudokuData(name: "Test22-008", content: "000060180000000050920300700400980000007000015000002000001400300600200004070000000"))
        sudoku_data.append(SudokuData(name: "Test22-009", content: "200603000079000054000000000150070060400000000002300090065007000000900000000400308"))
        sudoku_data.append(SudokuData(name: "Test22-010", content: "000050090004070200017300000000020080500016003000007000020000100600900004000008500"))
    }

    private func append_data() {
        // 問題データをリストに追加
        let temp = data[0 ..< data.count].map{$0[0 ..< $0.count].map{String($0)}.joined()}.joined() // 問題保存データを１つの文字列に結合
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let formattedDate = dateFormatter.string(from: Date()) // データ判別用に日付時刻をname用に準備
        sudoku_data.append(SudokuData(name: formattedDate, content: temp)) // 問題リストに追加
    }

    private func set_sudoku_data(index: Int) {
        // 問題リストから指定位置を読みだして設定
        let dt = sudoku_data[index].content
        let dtarray = Array(dt)
        let str = dtarray.map{String($0)} // バイナリーを文字列に変換
        for i in 0..<str.count { 
            let row = Int(i / 9) 
            let col = Int(i % 9) 
            data[row][col] = Int(str[i])! // Intに変換してsudokuに設定
        }
        setMemory()   // 問題保存メモリーに保存
        loadMemory()  // 保存メモリーから呼び出し設定
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

    private func getCellFontColor(row: Int, col: Int) -> Color {
        if answers && data_hints[row][col] != "" {
            return Color.red
        }
        return Color.black
    }

    private func getCellFontSize(row: Int, col: Int) -> Font {
        var size: CGFloat = 35
        if answers && data_hints[row][col] != "" {
            size = 15
        }
        return .system(size: size)
    }

    private func getCellText(row: Int, col: Int) -> String {
        // Cellに表示する文字を返す
        // 0 の時はスペースを返す
        var answer = " "
        if data[row][col] != 0 {
            answer = String(data[row][col])
        } else if answers && data_hints[row][col] != "" {
            answer = data_hints[row][col]
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
                } else {
                    next()
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
        data_hints = Array(repeating: Array(repeating: "", count: 9), count: 9)
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
        data_hints = Array(repeating: Array(repeating: "", count: 9), count: 9)
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
        data_hints = Array(repeating: Array(repeating: "", count: 9), count: 9)
        var candidates = listCandidates(sudokuMatrix: data)
        var answer: [[Int]] = []

        answer = getAnswerNakedSingle(candicates_9x9: candidates)
        let newAnswer = getAnswerHiddenSingle(candicates_9x9: candidates)
        for ans in newAnswer {
            answer.append(ans)
        }

        if answer.count == 0 {
            var update = false
            repeat {
                update = updateLockedCandicates(candicates_9x9: &candidates)
            } while update
            answer = getAnswerNakedSingle(candicates_9x9: candidates)
            let newAnswer = getAnswerHiddenSingle(candicates_9x9: candidates)
            for ans in newAnswer {
                answer.append(ans)
            }
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

    private func updateLockedCandicates(candicates_9x9: inout [[[Int]]]) -> Bool  {
        var update: Bool = false
        var candicates_Row: [[[[Int]]]] = []
        var candicates_Column: [[[[Int]]]] = []
        var candicates_Block: [[[[Int]]]] = []
        for _ in 0..<9 {
            var temp_Row: [[[Int]]] = []
            var temp_Column: [[[Int]]] = []
            var temp_Block: [[[Int]]] = []
            for _ in 0..<9 {
                temp_Row.append([])
                temp_Column.append([])
                temp_Block.append([])
            }
            candicates_Row.append(temp_Row)
            candicates_Column.append(temp_Column)
            candicates_Block.append(temp_Block)
        }
        // Block Loop
        for block in 0..<9 {
            let baseRow = Int(block / 3) * 3
            let baseCol = Int(block % 3) * 3
            var numberLocations: [[[Int]]] = [[], [], [], [], [], [], [], [], []]
            for row in baseRow..<baseRow + 3 {
                for col in baseCol..<baseCol + 3 {
                    for n in 0..<numberLocations.count {
                        if candicates_9x9[row][col].contains(n + 1) {
                            numberLocations[n].append([row, col])
                        }
                    }
                }
            }
            for n in 0..<numberLocations.count {
                let times = numberLocations[n].count
                if times > 0 {
                    for location in numberLocations[n] {
                        candicates_Block[location[0]][location[1]].append([n + 1, times])
                    }
                }
            }
            // Locked Candidates (row within block)
            for row in baseRow..<baseRow + 3 {
                for times in 2..<3 + 1 {
                    var columnLocations: [[Int]] = [[], [], [], [], [], [], [], [], []]
                    for col in baseCol..<baseCol + 3 {
                        for i in 0..<candicates_Block[row][col].count {
                            if candicates_Block[row][col][i][1] == times {
                                columnLocations[candicates_Block[row][col][i][0] - 1].append(col)
                            }
                        }
                    }
                    for n in 0..<columnLocations.count {
                        if columnLocations[n].count == times {
                            for col in 0..<candicates_9x9[row].count {
                                if !columnLocations[n].contains(col) {
                                    let str = candicates_9x9[row][col].map { String(describing: $0) }
                                    candicates_9x9[row][col] = candicates_9x9[row][col].filter { $0 != n + 1 }
                                    if str != (candicates_9x9[row][col].map { String(describing: $0) }) {
                                        update = true
                                    }
                                }
                            }
                            if update {
                                for col in 0..<candicates_9x9[row].count {
                                    if columnLocations[n].contains(col) {
                                        if !data_hints[row][col].contains(String(n + 1)) {
                                            if data_hints[row][col].count > 0 {
                                                data_hints[row][col] += " "
                                            }
                                            data_hints[row][col] += String(n + 1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Locked Candidates (column within block)
            for col in baseCol..<baseCol + 3 {
                for times in 2..<3 + 1 {
                    var rowLocations: [[Int]] = [[], [], [], [], [], [], [], [], []];
                    for row in baseRow..<baseRow + 3 {
                        for i in 0..<candicates_Block[row][col].count {
                            if candicates_Block[row][col][i][1] == times {
                                rowLocations[candicates_Block[row][col][i][0] - 1].append(row)
                            }
                        }
                    }
                    for n in 0..<rowLocations.count {
                        if rowLocations[n].count == times {
                            for row in 0..<candicates_9x9.count {
                                if !rowLocations[n].contains(row) {
                                    let str = candicates_9x9[row][col].map { String(describing: $0) }
                                    candicates_9x9[row][col] = candicates_9x9[row][col].filter { $0 != n + 1 }
                                    if str != (candicates_9x9[row][col].map { String(describing: $0) }) {
                                        update = true
                                    }
                                }
                            }
                            if update {
                                for row in 0..<candicates_9x9.count {
                                    if rowLocations[n].contains(row) {
                                        if !data_hints[row][col].contains(String(n + 1)) {
                                            if data_hints[row][col].count > 0 {
                                                data_hints[row][col] += " "
                                            }
                                            data_hints[row][col] += String(n + 1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // Row Loop
        for row in 0..<candicates_9x9.count {
            var numberLocations: [[[Int]]] = [[], [], [], [], [], [], [], [], []]
            for col in 0..<candicates_9x9[row].count {
                for n in 0..<numberLocations.count {
                    if candicates_9x9[row][col].contains(n + 1) {
                        numberLocations[n].append([row, col])
                    }
                }
            }
            for n in 0..<numberLocations.count {
                let times = numberLocations[n].count
                if times > 0 {
                    for location in numberLocations[n] {
                        candicates_Row[location[0]][location[1]].append([n + 1, times])
                    }
                }
            }
            // Locked Candidates (block within row)
            for block in 0..<3 {
                let baseRow = Int(row / 3) * 3
                let baseCol = block * 3
                for times in 2..<3 + 1 {
                    var columnLocations: [[Int]] = [[], [], [], [], [], [], [], [], []];
                    for col in baseCol..<baseCol + 3 {
                        for i in 0..<candicates_Row[row][col].count {
                            if candicates_Row[row][col][i][1] == times {
                                columnLocations[candicates_Row[row][col][i][0] - 1].append(col)
                            }
                        }
                    }
                    for n in 0..<columnLocations.count {
                        if columnLocations[n].count == times {
                            for row2 in baseRow..<baseRow + 3 {
                                for col in baseCol..<baseCol + 3 {
                                    if row2 != row || !columnLocations[n].contains(col) {
                                        let str = candicates_9x9[row2][col].map { String(describing: $0) }
                                        candicates_9x9[row2][col] = candicates_9x9[row2][col].filter { $0 != n + 1 }
                                        if str != (candicates_9x9[row2][col].map { String(describing: $0) }) {
                                            update = true
                                        }
                                    }
                                }
                            }
                            if update {
                                for row2 in baseRow..<baseRow + 3 {
                                    for col in baseCol..<baseCol + 3 {
                                        if row2 == row && columnLocations[n].contains(col) {
                                            if !data_hints[row][col].contains(String(n + 1)) {
                                                if data_hints[row][col].count > 0 {
                                                    data_hints[row][col] += " "
                                                }
                                                data_hints[row][col] += String(n + 1)
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
        // Column Loop
        for col in 0..<candicates_9x9.count {
            var numberLocations: [[[Int]]] = [[], [], [], [], [], [], [], [], []]
            for row in 0..<candicates_9x9.count {
                for n in 0..<numberLocations.count {
                    if candicates_9x9[row][col].contains(n + 1) {
                        numberLocations[n].append([row, col])
                    }
                }
            }
            for n in 0..<numberLocations.count {
                let times = numberLocations[n].count
                if times > 0 {
                    for location in numberLocations[n] {
                        candicates_Row[location[0]][location[1]].append([n + 1, times])
                    }
                }
            }
            // Locked Candidates (block within Column)
            for block in 0..<3 {
                let baseRow = block * 3
                let baseCol = Int(col / 3) * 3
                for times in 2..<3 + 1 {
                    var rowLocations: [[Int]] = [[], [], [], [], [], [], [], [], []];
                    for row in baseRow..<baseRow + 3 {
                        for i in 0..<candicates_Block[row][col].count {
                            if candicates_Block[row][col][i][1] == times {
                                rowLocations[candicates_Block[row][col][i][0] - 1].append(row)
                            }
                        }
                    }
                    for n in 0..<rowLocations.count {
                        if rowLocations[n].count == times {
                            for row in baseRow..<baseRow + 3 {
                                for col2 in baseCol..<baseCol + 3 {
                                    if col2 != col || !rowLocations[n].contains(row) {
                                        let str = candicates_9x9[row][col2].map { String(describing: $0) }
                                        candicates_9x9[row][col2] = candicates_9x9[row][col2].filter { $0 != n + 1 }
                                        if str != (candicates_9x9[row][col2].map { String(describing: $0) }) {
                                            update = true
                                        }
                                    }
                                }
                            }
                            if update {
                                for row in baseRow..<baseRow + 3 {
                                    for col2 in baseCol..<baseCol + 3 {
                                        if col2 == col && rowLocations[n].contains(row) {
                                            if !data_hints[row][col].contains(String(n + 1)) {
                                                if data_hints[row][col].count > 0 {
                                                    data_hints[row][col] += " "
                                                }
                                                data_hints[row][col] += String(n + 1)
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
        return update
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