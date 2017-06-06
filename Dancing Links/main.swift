//
//  main.swift
//  Dancing Links
//
//  Created by Mike Griebling on 4 Jun 2017.
//  Copyright © 2017 Computer Inspirations. All rights reserved.
//

import Foundation

var row = [[Int]](repeating: [Int](repeating: 0, count:10), count:9)
var col = [[Int]](repeating: [Int](repeating: 0, count:10), count:9)
var box = [[Int]](repeating: [Int](repeating: 0, count:10), count:9)
var board = [
             [0,0,0, 0,0,0, 0,1,0],
             [4,0,0, 0,0,0, 0,0,0],
             [0,2,0, 0,0,0, 0,0,0],
             [0,0,0, 0,5,0, 4,0,7],
             [0,0,8, 0,0,0, 3,0,0],
             [0,0,1, 0,9,0, 0,0,0],
             [3,0,0, 4,0,0, 2,0,0],
             [0,5,0, 1,0,0, 0,0,0],
             [0,0,0, 8,0,6, 0,0,0]
            ]

var file = ""

// populate the rows, cols, boxes
for k in 0..<9 {
    // input row k
    for j in 0..<9 {
        let d = board[k][j]
        if d > 0 {
            if row[k][d] > 0 { assertionFailure("Two identical digits in a row!") }
            row[k][d] = 1
            if col[j][d] > 0 { assertionFailure("Two identical digits in a column!") }
            col[j][d] = 1
            let x = (k/3)*3 + j/3
            if box[x][d] > 0 { assertionFailure("Two identical digits in a box!") }
            box[x][d] = 1
        }
    }
}

// output the column names for the Dance algorithm
for k in 0..<9 {
    for j in 0..<9 {
        if board[k][j] != 0 { print(" p\(k)\(j)", terminator: "", to: &file) }
    }
}
for k in 0..<9 {
    for d in 1...9 {
        if row[k][d] != 0 { print(" r\(k)\(d)", terminator: "", to: &file) }
        if col[k][d] != 0 { print(" c\(k)\(d)", terminator: "", to: &file) }
        if box[k][d] != 0 { print(" b\(k)\(d)", terminator: "", to: &file) }
    }
}
print("", to:&file)

// output the possibilities
for j in 0..<9 {
    for k in 0..<9 {
        if board[k][j] != 0 {
            let x = (k/3)*3 + j/3
            for d in 1...9 {
                if row[k][d] != 0 && col[j][d] != 0 && box[x][d] != 0 {
                    print("p\(k)\(j) r\(k)\(d) c\(j)\(d) b\(x)\(d)", to: &file)
                }
            }
        }
    }
}


// let home = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
// let file = home.appendingPathComponent("dancing").appendingPathExtension("txt")
if let data = file.data(using: .ascii) {
    let input = InputStream(data: data)
    input.open()
    let dancing = DancingLinks(input)
    input.close()
}


