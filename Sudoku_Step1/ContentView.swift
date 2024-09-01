import SwiftUI

struct ContentView: View {
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

    private func selectCell(row: Int, col: Int) {
        // Cellを選択したときのコードを書く予定
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
        // Cellの色を返す　今後、色々な状態を色で区別する予定
        return Color.white
    }

}