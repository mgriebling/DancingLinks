//
//  DancingLinks.swift
//  Dancing Links
//
//  Created by Mike Griebling on 4 Jun 2017.
//  Copyright © 2017 Computer Inspirations. All rights reserved.
//

import Foundation

/// Algorithm by Knuth from his *dance.w* program.

/** Given a matrix whose elements are 0 or 1, the problem is to
 find all subsets of its rows whose sum is at most 1 in all columns and
 *exactly* 1 in all *primary* columns. The matrix is specified
 in the standard input file as follows: Each column has a symbolic name,
 from one to seven characters long. The first line of input contains
 the names of all primary columns, followed by '|', followed by
 the names of all other columns.
 (If all columns are primary, the '|' may be omitted.)
 The remaining lines represent the rows, by listing the columns where 1 appears.
 
 The program prints the number of solutions and the total number of link
 updates. It also prints every *n*th solution, if the integer command
 line argument *n* is given. A second command-line argument causes the
 full search tree to be printed, and a third argument makes the output
 even more verbose.
 */

class DancingLinks {
    
    enum Limits {
        static let maxLevel  = 150
        static let maxDegree = 10_000
        static let maxCols   = 10_000
        static let maxNodes  = 1_000_000
//        static let bufSize   = 8*maxCols+3
    }

    var verbose : Int = 2       // > 0 to show solutions, > 1 to show partial ones too
    var count: Int = 0          // number of solutions found so far
    var updates : Double = 0    // number of times we deleted a list element
    var spacing : Int = 1       // if *verbose* we output solutions when count % spacing == 0
    
    /// tree nodes of given level and degree
    var profile = [[Double]](repeating:[Double](repeating:0, count:Limits.maxLevel), count: Limits.maxDegree)
    var updProf = [Double](repeating:0, count:Limits.maxLevel) // updates at a given level
    var maxb = 0                // maximum branching factor actually needed
    var maxl = 0                // maximum level actually reached
    
    /** 
    Each column of the input matrix is represented by a *column* struct,
    and each row is represented as a linked list of *node* structs. There's one
    node for each nonzero entry in the matrix.
    
    More precisely, the nodes are linked circularly within each row, in
    both directions. The nodes are also linked circularly within each column;
    the column lists each include a header node, but the row lists do not.
    Column header nodes are part of a  *column* struct, which
    contains further info about the column.
    
    Each node contains five fields. Four are the pointers of doubly linked lists,
    already mentioned; the fifth points to the column containing the node.
    */
    class Node {
        var left, right : Node?  // predecessor and successor in row
        var up, down : Node?     // predecessor and successor in column
        var col : Column?        // the column containing this node
    }
    
    /**
     Each *column* struct contains five fields:
     The |head| is a node that stands at the head of its list of nodes;
     the |len| tells the length of that list of nodes, not counting the header;
     the |name| is a user-specified identifier;
     |next| and |prev| point to adjacent columns, when this
     column is part of a doubly linked list.
     
     As backtracking proceeds, nodes
     will be deleted from column lists when their row has been blocked by
     other rows in the partial solution.
     But when backtracking is complete, the data structures will be
     restored to their original state.
    */
    class Column {
        var head = Node()           // the list header
        var len : Int = 0           // the number of non-header items currently in this column's list
        var name : String = ""      // the symbolic identification of the column for printing
        var next, prev : Column?    // neighbors of this column
    }
    
    /**
    One |column| struct is called the root. It serves as the head of the
    list of columns that need to be covered, and is identifiable by the fact
    that its |name| is empty.
    */
    var root : Column   /* gateway to the unsettled columns */
    
    var level : Int = 0 // number of choices in current partial solution
    var choice = [Node?](repeating: nil, count: Limits.maxLevel) // the row and column chosen on each level
    
    /// Place for the Column records
    var colArray = [Column](repeating: Column(), count: Limits.maxCols)
    
    /// Place for the  Node records
    var nodeArray = [Node](repeating: Node(), count: Limits.maxNodes)
//    var buf = [UInt8](repeating: 0, count: Limits.bufSize)
    
    /// Set up the root here since Swift won't let me do it at the definition
    init(_ s : InputStream) {
        root = colArray[0]
        initializeData(s)
        backtrack()
        print("Altogether \(count) solutions, after \(updates) updates.")
        if verbose > 0 {
            var tot,subtot : Double
            tot = 1 /* the root node doesn't show up in the profile */
            for level in 1...maxl+1 {
                subtot = 0
                for k in 0...maxb {
                    print(" \(profile[level][k])", terminator: "")
                    subtot += profile[level][k]
                }
                print(" \(subtot) nodes, \(updProf[level-1]) updates")
                tot += subtot
            }
            print("Total \(tot) nodes.")
        }
    }
    
    /**
     *Backtracking*
     Our strategy for generating all exact covers will be to repeatedly
     choose always the column that appears to be hardest to cover, namely the
     column with shortest list, from all columns that still need to be covered.
     And we explore all possibilities via depth-first search.
     
     The neat part of this algorithm is the way the lists are maintained.
     Depth-first search means last-in-first-out maintenance of data structures;
     and it turns out that we need no auxiliary tables to undelete elements from
     lists when backing up. The nodes removed from doubly linked lists remember
     their former neighbors, because we do no garbage collection.
     */

    private func backtrack() {
        var bestCol : Column? // column chosen for branching
        var pp : Node?        // traverses a row
        var curNode : Node?
        
        // Backtrack through all solutions
        level = 0
        forward: while true {
            // Set |bestCol| to the best column for branching
            bestCol = getBestColumn()
            cover(bestCol!)
            
            curNode = bestCol?.head.down
            choice[level] = curNode
            
            advance: while true {
                if curNode === bestCol?.head {
                    // goto backup
                    uncover(bestCol!)
                    if level == 0 {
                        // goto done
                        if verbose > 3 {
                            // Print column lengths, to make sure everything has been restored
                            print("Final column lengths", terminator: "")
                            var curCol = root.next
                            while curCol !== root {
                                print(" \(curCol!.name)(\(curCol!.len))", terminator: "")
                                curCol = curCol?.next
                            }
                            print()
                        }
                        return
                    }
                    level -= 1
                    curNode = choice[level]; bestCol = curNode?.col
                    
                    // Uncover all other columns of |cur_node|
                    recover(pp: &pp, curNode: &curNode)
                    continue advance
                }
                if verbose > 1 {
                    print("L\(level):", terminator: "")
                    printRow(curNode)
                }
                
                // Cover all other columns of |cur_node|
                pp = curNode?.right
                while pp !== curNode {
                    cover(pp!.col!)
                    pp = pp?.right
                }
                if root.next === root {
                    count += 1
                    if verbose != 0 {
                        profile[level+1][0] += 1
                        if count%spacing == 0 {
                            print("\(count):")
                            for k in 0...level { printRow(choice[k]) }
                        }
                    }
                    // goto recover;
                    recover(pp: &pp, curNode: &curNode)
                    continue advance
                }
                level += 1
            }
        } // goto forward;
    }
    
    private func recover(pp : inout Node?, curNode : inout Node?) {
        pp = curNode?.left
        while pp !== curNode {
            uncover(pp!.col!)
            pp = pp?.left
        }
        curNode = curNode?.down
        choice[level] = curNode
    }
    
    /**
     A row is identified not by name but by the names of the columns it contains.
     Here is a routine that prints a row, given a pointer to any of its
     columns. It also prints the position of the row in its column.
     */
    private func printRow(_ p : Node?) {
        guard p != nil else { return }
        var q = p
        var k : Int
        repeat {
            print(" \(q!.col!.name)", terminator: "")
            q = q?.right
        } while q !== p
        q = p?.col?.head.down; k = 1
        while q !== p {
            if q === p?.col?.head {
                print()
                return /* row not in its column! */
            } else {
                q = q?.down
            }
            k += 1
        }
        print(" (\(k) of \(p!.col!.len))")
    }
    
    public func printState(_ lev : Int) {
        for l in 0...lev { printRow(choice[l]) }
    }
    
    private func panic(_ message: String) {
        assertionFailure("\(message)!\n")
    }
    
    private func getBestColumn() -> Column {
        var minlen = Limits.maxNodes
        var bestCol : Column?
        
        if verbose > 2 { print("Level \(level):", terminator: "") }
        var curCol = root.next
        while curCol !== root {
            if (verbose>2) { print(" \(curCol!.name)(\(curCol!.len))", terminator: "") }
            if (curCol!.len < minlen) { bestCol = curCol; minlen = curCol!.len }
            curCol = curCol?.next
        }
        if verbose != 0 {
            if level > maxl {
                if level >= Limits.maxLevel { panic("Too many levels") }
                maxl = level
            }
            if minlen > maxb {
                if minlen >= Limits.maxDegree { panic("Too many branches") }
                maxb = minlen
            }
            profile[level][minlen] += 1
            if verbose > 2 { print(" branching on \(bestCol!.name)(\(minlen))") }
        }
        return bestCol!
    }
    
    /** The basic operation is *covering a column*. This means removing it
    from the list of columns needing to be covered, and *blocking* its
    rows: removing nodes from other lists whenever they belong to a row of
    a node in this column's list.
     */
    private func cover (_ c : Column) {
        var l, r : Column?
        var rr, nn, uu, dd : Node?
        var k = 1   // updates
        
        l = c.prev; r = c.next
        l?.next = r; r?.prev = l
        rr = c.head.down
        while rr !== c.head {
            nn = rr?.right
            while nn !== rr {
                uu = nn?.up; dd = nn?.down
                uu?.down = dd; dd?.up = uu
                k += 1
                nn?.col?.len -= 1
                nn = nn?.right
            }
            rr = rr?.right
        }
        updates += Double(k)
        updProf[level] += Double(k)
    }
    
    /** Uncovering is done in precisely the reverse order. The pointers thereby
    execute an exquisitely choreographed dance which returns them almost
    magically to their former state.
     */
    private func uncover(_ c : Column) {
        var l, r : Column?
        var rr, nn, uu, dd : Node?
        rr = c.head.up
        while rr !== c.head {
            nn = rr?.left
            while nn !== rr {
                uu = nn?.up; dd = nn?.down
                uu?.down = nn
                dd?.up = nn
                nn?.col?.len += 1
                nn = nn?.left
            }
            rr = rr?.up
        }
        l = c.prev; r = c.next
        l?.next = c; r?.prev = c
    }
    
    private func initializeData (_ s : InputStream) {
        readColumnNames(s)
        readRows(s)
    }
    
    private func getLine (_ s : InputStream) -> [UInt8] {
        let eol = [UInt8]("\n".data(using: .ascii)!).first!
        var line : [UInt8] = []
        while s.hasBytesAvailable {
            var buf : [UInt8] = [0]
            let _ = s.read(&buf, maxLength: 1)
            if buf[0] == eol { return line }
            line.append(buf[0])
        }
        return line
    }
    
    private func readColumnNames(_ s : InputStream) {
        let divider = [UInt8]("|".data(using: .ascii)!).first!
        var cur_col : Column?
        var colIndex = 1
        var q : [UInt8]
        var primary : Int
        
        colArray[colIndex] = Column()   // create new column entry
        cur_col = colArray[colIndex]
        var buf = getLine(s)
        if buf.count == 0 { panic("No input") }
        primary = 1
        while buf.count > 0 {
            var p = buf.removeFirst()
            while isspace(Int32(p)) != 0 { p = buf.removeFirst() }
            if buf.count == 0 { break }
            if p == divider {
                primary = 0
                if colIndex == colArray.count { panic("No primary columns") }
                colArray[colIndex-1].next = root; root.prev = colArray[colIndex-1]
                continue
            }
            q = []
            while isspace(Int32(p)) == 0 {
                q.append(p)
                if buf.count == 0 { p = 0; break }
                else { p = buf.removeFirst() }
            }
            if colIndex >= Limits.maxCols { panic("Too many columns") }
            cur_col?.name = String(bytes: q, encoding: .ascii)!
            cur_col?.head.up = cur_col?.head
            cur_col?.head.down = cur_col?.head
            cur_col?.len = 0
            if primary != 0 {
                cur_col?.prev = colArray[colIndex-1]
                colArray[colIndex-1].next = cur_col
            } else {
                cur_col?.prev = cur_col
                cur_col?.next = cur_col
            }
            colIndex += 1; colArray[colIndex] = Column()   // create new column entry
            cur_col = colArray[colIndex]
        }
        if primary != 0 {
            if colIndex == colArray.count { panic("No primary columns") }
            colArray[colIndex-1].next = root; root.prev = colArray[colIndex-1]
        }
    }
    
    private func readRows (_ s : InputStream) {
        var cur_node = nodeArray[0]
        var nodeIndex = 0
        var buf = getLine(s)
        while buf.count > 0 {
            var row_start : Node?
            row_start = nil
            var p = buf.removeFirst()
            var q : [UInt8]
            while buf.count > 0 {
                while isspace(Int32(p)) != 0 { p = buf.removeFirst() }
                if buf.count == 0 { break }
                q = []
                while isspace(Int32(p)) == 0 {
                    q.append(p)
                    if buf.count == 0 { p = 0; break }
                    else { p = buf.removeFirst() }
                }
                let name = String(bytes: q, encoding: .ascii)!
                var ccol : Column?
                for col in colArray {
                    if col.name == name { ccol = col; break }
                }
                if ccol == nil { panic("Unknown column name") }
                if nodeIndex == Limits.maxNodes { panic("Too many nodes") }
                if row_start == nil { row_start = cur_node }
                else { cur_node.left = nodeArray[nodeIndex-1]; nodeArray[nodeIndex-1].right = cur_node }
                cur_node.col = ccol
                cur_node.up = ccol?.head.up; ccol?.head.up?.down = cur_node
                ccol?.head.up = cur_node; cur_node.down = ccol?.head
                ccol!.len += 1
                nodeIndex += 1; nodeArray[nodeIndex] = Node()  // create a new entry
                cur_node = nodeArray[nodeIndex]
            }
            if row_start == nil { panic("Empty row") }
            row_start?.left = nodeArray[nodeIndex-1]
            nodeArray[nodeIndex-1].right = row_start
            buf = getLine(s)
        }
    }
    
}
