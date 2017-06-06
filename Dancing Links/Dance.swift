//
//  Dance.swift
//  Dancing Links
//
//  Created by Mike Griebling on 6 Jun 2017.
//  Copyright © 2017 Computer Inspirations. All rights reserved.
//

import Foundation

class Dance {
    
    typealias RC = (r: Int, c: Int)
    
    var N : Int
    var R, C : Int
    var X = [[String : RC]]()
    
    private func buildX() {
        var x1 = [[String : RC]]()
        var x2 = [[String : RC]]()
        var x3 = [[String : RC]]()
        var x4 = [[String : RC]]()
        for i in 0..<N {
            for j in 0..<N {
                x1.append(["rc" : (i, j)])
            }
            for k in 1...N {
                x2.append(["rn" : (i, k)])
                x3.append(["cn" : (i, k)])
                x4.append(["bn" : (i, k)])
            }
        }
        X = x1 + x2 + x3 + x4
    }
    
    init (size : Int) {
        R = size; C = size
        N = R * C
        
    }
    
}
