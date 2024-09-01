import SwiftUI

struct ContentView: View {
    @State private var selected = false
    @State private var selRow = -1
    @State private var selCol = -1
    @State private var markNumber = -1
    @State private var data = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    @State private var data_save = Array(repeating: Array(repeating: 0, count: 9), count: 9)

    var body: some View {
        let cellSize = CGFloat(40)
        let blockLineSize = CGFloat(3)
        let lineColor = Color.black
        VStack(spacing: 0) {
            Text("Sudoku")
                .font(.system(size: 30))
                .fontWeight(.bold)
            SudokuCells(cellSize: cellSize, blockLineSize: blockLineSize, lineColor: lineColor)
        }
        Spacer().frame(height: 8)
        VStack(spacing:4) {
            SudokuNumberButtons()
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

    private func selectCell(row: Int, col: Int) {
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
        if selected {
            if data[selRow][selCol] == 0 { // 選択状態のセルが空白なら数値を設定する
                data[selRow][selCol] = n
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
        if selected {
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

}