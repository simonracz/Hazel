//
//  Board.swift
//  Hazel
//
//  Created by Simon Racz on 05/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import Foundation

// The M in MVC
final class Board: NSObject, NSCoding {
    let dimension: Int
    // Board has a 2 item thick border to simplify calculations later
    var board: [[Gem]]
    
    // MARK: Initializations
    
    init(dimension: Int) {
        assert(dimension > 3)
        self.dimension = dimension
        self.board = [[Gem]]()
        for var i=0; i<dimension + 4; ++i {
            var arr = [Gem]()
            for var j=0; j<dimension + 4; ++j {
                arr.append(Gem(type: GemType.None))
            }
            board.append(arr)
        }
    }

    init(copyFromBoard other: Board) {
        self.dimension = other.dimension
        self.board = [[Gem]]()
        for var i=0; i<dimension + 4; ++i {
            var arr = [Gem]()
            for var j=0; j<dimension + 4; ++j {
                arr.append(Gem(type: other.board[i][j].type))
            }
            board.append(arr)
        }
    }
    
    func clearBoard() {
        for i in 2..<(dimension + 2) {
            for j in 2..<(dimension + 2) {
                board[i][j].type = GemType.None
            }
        }
    }
    
    //Makes sure to not cause automatic gem explosion on start.
    func populateBoard() {
        let allowedGemTypes: Set = [GemType.Gem1, GemType.Gem2, GemType.Gem3, GemType.Gem4, GemType.Gem5]
        for i in 2..<(dimension + 2) {
            for j in 2..<(dimension + 2) {
                var currentGemTypes = allowedGemTypes
                // o o x
                if board[i-1][j].type == board[i-2][j].type {
                    currentGemTypes.remove(board[i-1][j].type)
                }
                // o
                // o
                // x
                if board[i][j-1].type == board[i][j-2].type {
                    currentGemTypes.remove(board[i][j-1].type)
                }
                // No need to check for other directions because of the direction of the traversal.
                board[i][j].type = randomType(fromSet: currentGemTypes)
            }
        }
    }
    
    // MARK: HelperMethods
    
    private func randomType(fromSet set: Set<GemType>) -> GemType {
        if set.count == 0 {
            return .None
        }
        let dice = Int(arc4random_uniform(UInt32(set.count)))
        for (count, item) in set.sort().enumerate() {
            if count == dice {
                return item
            }
        }
        return .None
    }
    
    private func clearGemAt(index: GemIndex) {
        board[index.x][index.y].type = .None
    }
    
    private func clearGemsInSet(set: Set<ExplodingGem>) {
        for index in set {
            clearGemAt(index.index)
        }
    }
    
    private func swapGems(gem1 gem1: GemIndex, gem2: GemIndex) {
        let gem1Type = board[gem1.x][gem1.y]
        board[gem1.x][gem1.y] = board[gem2.x][gem2.y]
        board[gem2.x][gem2.y] = gem1Type
    }
    
    private func randomGem() -> GemType {
        return randomGems(1).first!
    }
    
    private func randomGems(count: Int) -> [GemType] {
        let allowedGemTypes = [GemType.Gem1, GemType.Gem2, GemType.Gem3, GemType.Gem4, GemType.Gem5]
        var ret = [GemType]()
        for _ in 0..<count {
            ret.append(allowedGemTypes[Int(arc4random_uniform(UInt32(5)))])
        }
        return ret
    }
    
    // MARK: GamePlay

    // STEP 0 : Call hint() to get a hint.
    // STEP 1A : Call checkSwap() for swaps
    // STEP 1B : Call gatherSimpleCollisions after new gems fell in place
    // STEP 2 (repatedly) : Call calculateNextExplosion while there are new explosions
    // Board is updated automatically
    // Exploding gems are replaced with .None
    // New SuperGems might appear in place of exploding gems.
    // STEP 3 : Call fellOneStep() until no new nodes --> Go Back To STEP 1B
   
    /**
        Returns a hint.
    */
    func hint(inout index1 index1: GemIndex, inout index2: GemIndex) -> Bool {
        let superGems: Set = [GemType.SuperGemBomb, GemType.SuperGemColor, GemType.SuperGemLine]
        for var j = dimension + 1; j>1; --j {
            for var i = dimension + 1; i>1; --i {
                if superGems.contains(board[i][j].type) {
                    let first = GemIndex(x: i, y: j)
                    let second: GemIndex
                    if i>2 {
                        second = GemIndex(x: i - 1, y: j)
                    } else {
                        second = GemIndex(x: i + 1, y: j)
                    }
                    index1 = first
                    index2 = second
                    return true
                }
            }
        }
        
        let cBoard = Board(copyFromBoard: self)
        for var j = dimension + 1; j>1; --j {
            for var i = dimension + 1; i>1; --i {
                if i > 2 {
                    let first = GemIndex(x: i, y: j)
                    let second = GemIndex(x: i - 1, y: j)
                    if cBoard.checkSwap(forGemIndex: first, withGemIndex: second).count > 0 {
                        index1 = first
                        index2 = second
                        return true
                    }
                }
                if j > 2 {
                    let first = GemIndex(x: i, y: j)
                    let second = GemIndex(x: i, y: j - 1)
                    if cBoard.checkSwap(forGemIndex: first, withGemIndex: second).count > 0 {
                        index1 = first
                        index2 = second
                        return true
                    }
                }
            }
        }
        return false
    }
   
    /**
        Calculates the GemIndexes that fell
        Applies these changes to the board.
    
        - Returns: Tuple
            $0 : array of tuple (index, index) -  cells that should fell, and to where they should fell
            $1 : dictionary of [coloumn: [new gem]] ther order of new gem array matters. first element fell the lowest
    */
    func fellGems() -> ([(GemIndex, GemIndex)], [Int: [GemType]]) {
        var indexes = [(GemIndex, GemIndex)]()
        var newGems = [Int: [GemType]]()
        for i in 2..<(dimension + 2) {
            var shouldFall = 0
            for var j = dimension + 1; j>1; --j {
                if board[i][j].type == .None {
                    shouldFall+=1
                    continue
                }
                if shouldFall > 0 {
                    indexes.append((GemIndex(x: i, y: j), GemIndex(x: i, y: j + shouldFall)))
                    swapGems(gem1: GemIndex(x: i, y: j), gem2: GemIndex(x: i, y: j + shouldFall))
                }
            }
            if shouldFall > 0 {
                var gems = [GemType]()
                for var count = shouldFall; count > 0; --count {
                    let newGem = randomGem()
                    board[i][1 + count].type = newGem
                    gems.append(newGem)
                }
                newGems[i] = gems
            }
        }
        return (indexes, newGems)
    }
    
    func gatherSimpleCollisions() -> Set<ExplodingGem> {
        let b = Board(copyFromBoard: self)
        let normalGems: Set = [GemType.Gem1, GemType.Gem2, GemType.Gem3, GemType.Gem4, GemType.Gem5]
        var ret = Set<ExplodingGem>()
        for i in 2..<(dimension + 2) {
            var currentSet = Set<ExplodingGem>()
            var currentType: GemType = .None
            for j in 2..<(dimension + 2) {
                if board[i][j].type == currentType {
                    currentSet.nonUpdatingInsert(ExplodingGem(index: GemIndex(x: i, y: j), type:currentType, cause: .Normal))
                    continue
                }
                if currentSet.count > 2 {
                    ret.nonUpdatingUnionInPlace(currentSet)
                    b.clearGemsInSet(currentSet)
                }
                currentSet.removeAll(keepCapacity: true)
                currentType = board[i][j].type
                if normalGems.contains(currentType) {
                    currentSet.nonUpdatingInsert(ExplodingGem(index: GemIndex(x: i, y: j), type:currentType, cause: .Normal))
                } else {
                    currentType = .None
                }
            }
            if currentSet.count > 2 {
                ret.nonUpdatingUnionInPlace(currentSet)
                b.clearGemsInSet(currentSet)
            }
        }
        for j in 2..<(dimension + 2) {
            var currentSet = Set<ExplodingGem>()
            var currentType: GemType = .None
            for i in 2..<(dimension + 2) {
                if board[i][j].type == currentType {
                    currentSet.nonUpdatingInsert(ExplodingGem(index: GemIndex(x: i, y: j), type:currentType, cause: .Normal))
                    continue
                }
                if currentSet.count > 2 {
                    ret.nonUpdatingUnionInPlace(currentSet)
                    b.clearGemsInSet(currentSet)
                }
                currentSet.removeAll(keepCapacity: true)
                currentType = board[i][j].type
                if normalGems.contains(currentType) {
                    currentSet.nonUpdatingInsert(ExplodingGem(index: GemIndex(x: i, y: j), type:currentType, cause: .Normal))
                } else {
                    currentType = .None
                }
            }
            if currentSet.count > 2 {
                ret.nonUpdatingUnionInPlace(currentSet)
                b.clearGemsInSet(currentSet)
            }
        }
        self.board = b.board
        createSuperGemsFromSet(ret)
        return ret
    }
    
    private func createSuperGemsFromSet(var explosions: Set<ExplodingGem>) {
        while explosions.count > 0 {
            let explosion = explosions.first!
            
            let horizontalSet = horizontalExpansionFromSet(explosions, at: explosion)
            var verticalExpansions = Array<Set<ExplodingGem>>()
            for hExplosion in horizontalSet {
                verticalExpansions.append(verticalExpansionFromSet(explosions, at: hExplosion))
            }
            verticalExpansions.sortInPlace({$0.count > $1.count})
            
            let verticalSet = verticalExpansionFromSet(explosions, at: explosion)
            var horizontalExpansions = Array<Set<ExplodingGem>>()
            for vExplosion in verticalSet {
                horizontalExpansions.append(horizontalExpansionFromSet(explosions, at: vExplosion))
            }
            horizontalExpansions.sortInPlace({$0.count > $1.count})
            
            let bigH = max(horizontalSet.count, verticalExpansions.first!.count)
            let smallH = min(horizontalSet.count, verticalExpansions.first!.count)
            
            let bigV = max(verticalSet.count, horizontalExpansions.first!.count)
            let smallV = min(verticalSet.count, horizontalExpansions.first!.count)
            
            let ratio = 10 * (bigH - bigV) + (smallH - smallV)
            if ratio > 0 {
                let h = horizontalSet
                let v = verticalExpansions.first!
                createSuperGemsFromFormation(horizontalSet: h, verticalSet: v)
                explosions.subtractInPlace(h)
                explosions.subtractInPlace(v)
            } else {
                let h = horizontalExpansions.first!
                let v = verticalSet
                createSuperGemsFromFormation(horizontalSet: h, verticalSet: v)
                explosions.subtractInPlace(h)
                explosions.subtractInPlace(v)
            }
        }
    }
    
    private func createSuperGemsFromFormation(horizontalSet h: Set<ExplodingGem>, verticalSet v: Set<ExplodingGem>) {
        switch (h.count, v.count) {
        case (4, 1...2):
            fallthrough
        case (1...2, 4):
            let index = h.first!.index
            board[index.x][index.y].type = .SuperGemBomb
        case (5...8, 1...2):
            fallthrough
        case (1...2, 5...8):
            let index = h.first!.index
            board[index.x][index.y].type = .SuperGemColor
        case (3...4, 3...4):
            let index = h.first!.index
            board[index.x][index.y].type = .SuperGemLine
        case (3, 5...8):
            fallthrough
        case (5...8, 3):
            var gen = h.generate()
            var arr = [GemIndex]()
            arr.append(gen.next()!.index)
            arr.append(gen.next()!.index)
            arr.append(gen.next()!.index)
            arr.removeAtIndex(Int(arc4random_uniform(UInt32(3))))
            board[arr.first!.x][arr.first!.y].type = .SuperGemLine
            board[arr.last!.x][arr.last!.y].type = .SuperGemColor
        case (4, 4):
            var gen = h.generate()
            var arr = [GemIndex]()
            arr.append(gen.next()!.index)
            arr.append(gen.next()!.index)
            arr.append(gen.next()!.index)
            arr.append(gen.next()!.index)
            arr.removeAtIndex(Int(arc4random_uniform(UInt32(4))))
            arr.removeAtIndex(Int(arc4random_uniform(UInt32(3))))
            board[arr.first!.x][arr.first!.y].type = .SuperGemLine
            board[arr.last!.x][arr.last!.y].type = .SuperGemLine
        case (4, 5...8):
            fallthrough
        case (5...8, 4):
            var arr = Array(h)
            while (arr.count > 2) {
                arr.removeAtIndex(Int(arc4random_uniform(UInt32(arr.count))))
            }
            board[arr.first!.index.x][arr.first!.index.y].type = .SuperGemLine
            board[arr.last!.index.x][arr.last!.index.y].type = .SuperGemColor
        case (5...8, 5...8):
            fallthrough
        case (5...8, 5...8):
            var arr = Array(h)
            while (arr.count > 2) {
                arr.removeAtIndex(Int(arc4random_uniform(UInt32(arr.count))))
            }
            board[arr.first!.index.x][arr.first!.index.y].type = .SuperGemColor
            board[arr.last!.index.x][arr.last!.index.y].type = .SuperGemColor
        default:
            break
        }
    }
    
    private func horizontalExpansionFromSet(set: Set<ExplodingGem>, at: ExplodingGem) -> Set<ExplodingGem> {
        var horizontalSet = Set<ExplodingGem>()
        for i in 0..<dimension {
            if !addToSet(&horizontalSet, fromSet: set, ifItContains: GemIndex(x: at.index.x + i, y: at.index.y), withType: at.type) {
                break
            }
        }
        for i in 0..<dimension {
            if !addToSet(&horizontalSet, fromSet: set, ifItContains: GemIndex(x: at.index.x - i, y: at.index.y), withType: at.type) {
                break
            }
        }
        return horizontalSet
    }
    
    private func verticalExpansionFromSet(set: Set<ExplodingGem>, at: ExplodingGem) -> Set<ExplodingGem> {
        var verticalSet = Set<ExplodingGem>()
        for j in 0..<dimension {
            if !addToSet(&verticalSet, fromSet: set, ifItContains: GemIndex(x: at.index.x, y: at.index.y + j), withType: at.type) {
                break
            }
        }
        for j in 0..<dimension {
            if !addToSet(&verticalSet, fromSet: set, ifItContains: GemIndex(x: at.index.x, y: at.index.y - j), withType: at.type) {
                break
            }
        }
        return verticalSet
    }
    
    private func addToSet(inout set: Set<ExplodingGem>, var fromSet: Set<ExplodingGem>, ifItContains index: GemIndex, withType type: GemType) -> Bool {
        let helper = ExplodingGem(index: index, type: .None, cause: .Normal)
        if fromSet.contains(helper) {
            let explosion = fromSet.remove(helper)!
            if explosion.type != type {
                fromSet.insert(explosion)
                return false
            }
            set.nonUpdatingInsert(explosion)
            return true
        }
        return false
    }
    
    func checkSwap(forGemIndex forGemIndex: GemIndex, withGemIndex: GemIndex) -> Set<ExplodingGem> {
        swapGems(gem1: forGemIndex, gem2: withGemIndex)
        let gem1 = board[forGemIndex.x][forGemIndex.y]
        let gem2 = board[withGemIndex.x][withGemIndex.y]
        switch gem1.type {
        case .SuperGemBomb:
            return checkSwapFor(superGemBomb: forGemIndex, withGem: withGemIndex)
        case .SuperGemColor:
            return checkSwapFor(superGemColor: forGemIndex, withGem: withGemIndex)
        case .SuperGemLine:
            return checkSwapFor(superGemLine: forGemIndex, withGem: withGemIndex)
        default:
            break
        }
        // gem1 is normal
        
        switch gem2.type {
        case .SuperGemBomb:
            return checkSwapFor(superGemBomb: withGemIndex, withGem: forGemIndex)
        case .SuperGemColor:
            return checkSwapFor(superGemColor: withGemIndex, withGem: forGemIndex)
        case .SuperGemLine:
            return checkSwapFor(superGemLine: withGemIndex, withGem: forGemIndex)
        default:
            break
        }
        // gem2 is also normal
        
        let ret = gatherSimpleCollisions()
        if ret.count == 0 {
            // Nothing happened, swap back
            swapGems(gem1: forGemIndex, gem2: withGemIndex)
        }
        return ret
    }

    private func checkSwapFor(superGemBomb superGem: GemIndex, withGem: GemIndex) -> Set<ExplodingGem> {
        let otherType = board[withGem.x][withGem.y].type
        switch otherType {
        case .SuperGemBomb:
            return explosionsForSwap(bomb1: superGem, bomb2: withGem)
        case .SuperGemColor:
            return explosionsForSwap(bomb: superGem, color: withGem)
        case .SuperGemLine:
            return explosionsForSwap(bomb: superGem, line: withGem)
        default:
            break
        }

        var ret = gatherSimpleCollisions()
        ret.nonUpdatingInsert(ExplodingGem(index: superGem, type: .SuperGemBomb, cause: .SuperGemBomb(index: superGem), processed: true))
        clearGemAt(superGem)
        let iMin = max(2, superGem.x - 1)
        let iMax = min(dimension + 1, superGem.x + 1)
        for i in iMin...iMax {
            let jMin = max(2, superGem.y - 1)
            let jMax = min(dimension + 1, superGem.y + 1)
            for j in jMin...jMax {
                let currentIndex = GemIndex(x: i, y: j)
                ret.nonUpdatingInsert(ExplodingGem(index: currentIndex, type: board[currentIndex.x][currentIndex.y].type, cause: .SuperGemBomb(index: superGem)))
                clearGemAt(currentIndex)
            }
        }
        return ret
    }
    
    private func checkSwapFor(superGemColor superGem: GemIndex, withGem: GemIndex) -> Set<ExplodingGem> {
        let otherType = board[withGem.x][withGem.y].type
        switch otherType {
        case .SuperGemBomb:
            return explosionsForSwap(bomb: withGem, color: superGem)
        case .SuperGemColor:
            return explosionsForSwap(color1: superGem, color2: withGem)
        case .SuperGemLine:
            return explosionsForSwap(color: superGem, line: withGem)
        default:
            break
        }
        
        var ret = gatherSimpleCollisions()
        ret.nonUpdatingInsert(ExplodingGem(index: superGem, type: .SuperGemColor, cause: .SuperGemColor(index: superGem), processed: true))
        clearGemAt(superGem)
        let indexes = collectGemIndexes(ofType: otherType)
        for index in indexes {
            ret.nonUpdatingInsert(ExplodingGem(index: index, type: board[index.x][index.y].type, cause: .SuperGemColor(index: superGem)))
            clearGemAt(index)
        }
        return ret
    }
    
    private func checkSwapFor(superGemLine superGem: GemIndex, withGem: GemIndex) -> Set<ExplodingGem> {
        let otherType = board[withGem.x][withGem.y].type
        switch otherType {
        case .SuperGemBomb:
            return explosionsForSwap(bomb: withGem, line: superGem)
        case .SuperGemColor:
            return explosionsForSwap(color: withGem, line: superGem)
        case .SuperGemLine:
            return explosionsForSwap(line1: superGem, line2: withGem)
        default:
            break
        }
        
        var ret = gatherSimpleCollisions()
        ret.nonUpdatingInsert(ExplodingGem(index: superGem, type: .SuperGemLine, cause: .SuperGemLine(index: superGem), processed: true))
        clearGemAt(superGem)
        // horizontal sweep
        for i in 2..<(dimension + 2) {
            let index = GemIndex(x: i, y:superGem.y)
            ret.nonUpdatingInsert(ExplodingGem(index: index, type: board[i][superGem.y].type, cause: .SuperGemLine(index: superGem)))
            clearGemAt(index)
        }
        // vertical sweep
        for j in 2..<(dimension + 2) {
            let index = GemIndex(x: superGem.x, y:j)
            ret.nonUpdatingInsert(ExplodingGem(index: index, type: board[superGem.x][j].type, cause: .SuperGemLine(index: superGem)))
            clearGemAt(index)
        }
        return ret
    }
    
    private func explosionsForSwap(bomb1 bomb1: GemIndex, bomb2: GemIndex) -> Set<ExplodingGem> {
        var ret = Set<ExplodingGem>()
        ret.insert(ExplodingGem(index: GemIndex(x: bomb1.x, y: bomb1.y), type: .SuperGemBomb, cause: .SuperGemBomb(index: bomb2), processed: true))
        ret.insert(ExplodingGem(index: GemIndex(x: bomb2.x, y: bomb2.y), type: .SuperGemBomb, cause: .SuperGemBomb(index: bomb1), processed: true))
        clearGemAt(bomb1)
        clearGemAt(bomb2)
        let iMin = max(2, min(bomb1.x - 3, bomb2.x - 3))
        let iMax = min(dimension + 1, max(bomb1.x + 3, bomb2.x + 3))
        for i in iMin...iMax {
            let jMin = max(2, min(bomb1.y - 3, bomb2.y - 3))
            let jMax = min(dimension + 1, max(bomb1.y + 3, bomb2.y + 3))
            for j in jMin...jMax {
                let currentIndex = GemIndex(x: i, y: j)
                ret.nonUpdatingInsert(ExplodingGem(index: currentIndex, type: board[i][j].type, cause: .SuperGemBomb(index: bomb2)))
                clearGemAt(currentIndex)
            }
        }
        return ret
    }
    
    private func explosionsForSwap(bomb bomb: GemIndex, color: GemIndex) -> Set<ExplodingGem> {
        var ret = Set<ExplodingGem>()
        ret.nonUpdatingInsert(ExplodingGem(index: bomb, type: .SuperGemBomb, cause: .SuperGemColor(index: color), processed: true))
        ret.nonUpdatingInsert(ExplodingGem(index: color, type: .SuperGemColor, cause: .SuperGemBomb(index: bomb), processed: true))
        clearGemAt(bomb)
        clearGemAt(color)
        let type = randomType(fromSet: normalGemTypesOnBoard(excludedIndexes: Set<GemIndex>()))
        let indexes = collectGemIndexes(ofType: type)
        for index in indexes {
            ret.nonUpdatingInsert(ExplodingGem(index: index, type: .SuperGemBomb, cause: .SuperGemColor(index: color)))
            clearGemAt(index)
        }
        return ret
    }
    
    private func explosionsForSwap(bomb bomb: GemIndex, line: GemIndex) -> Set<ExplodingGem> {
        var ret = Set<ExplodingGem>()
        ret.nonUpdatingInsert(ExplodingGem(index: bomb, type: .SuperGemBomb, cause: .SuperGemLine(index: line), processed: true))
        ret.nonUpdatingInsert(ExplodingGem(index: line, type: .SuperGemLine, cause: .SuperGemBomb(index: bomb), processed: true))
        clearGemAt(bomb)
        clearGemAt(line)
        // vertical sweep
        let minI = max(2, bomb.x - 1)
        let maxI = min(dimension + 1, bomb.x + 1)
        for i in minI...maxI {
            for j in 2..<(dimension + 2) {
                let currentIndex = GemIndex(x: i, y: j)
                ret.nonUpdatingInsert(ExplodingGem(index: currentIndex, type: board[currentIndex.x][currentIndex.y].type, cause: .SuperGemLine(index: line)))
                clearGemAt(currentIndex)
            }
        }
        // horizontal sweep
        let minJ = max(2, bomb.y - 1)
        let maxJ = min(dimension + 1, bomb.y + 1)
        for j in minJ...maxJ {
            for i in 2..<(dimension + 2) {
                let currentIndex = GemIndex(x: i, y: j)
                ret.nonUpdatingInsert(ExplodingGem(index: currentIndex, type: board[currentIndex.x][currentIndex.y].type, cause: .SuperGemLine(index: line)))
                clearGemAt(currentIndex)
            }
        }
        return ret
    }
    
    private func explosionsForSwap(color1 color1: GemIndex, color2: GemIndex) -> Set<ExplodingGem> {
        var ret = Set<ExplodingGem>()
        for i in 2..<(dimension + 2) {
            for j in 2..<(dimension + 2) {
                let index = GemIndex(x: i, y: j)
                ret.nonUpdatingInsert(ExplodingGem(index: index, type: board[i][j].type, cause: .SuperGemColor(index: color1), processed: true))
                clearGemAt(index)
            }
        }
        return ret
    }
    
    private func explosionsForSwap(color color: GemIndex, line: GemIndex) -> Set<ExplodingGem> {
        var ret = Set<ExplodingGem>()
        ret.nonUpdatingInsert(ExplodingGem(index: line, type: .SuperGemLine, cause: .SuperGemColor(index: color), processed: true))
        ret.nonUpdatingInsert(ExplodingGem(index: color, type: .SuperGemColor, cause: .SuperGemLine(index: line), processed: true))
        clearGemAt(color)
        clearGemAt(line)
        let type = randomType(fromSet: normalGemTypesOnBoard(excludedIndexes: Set<GemIndex>()))
        let indexes = collectGemIndexes(ofType: type)
        for index in indexes {
            ret.nonUpdatingInsert(ExplodingGem(index: index, type: .SuperGemLine, cause: .SuperGemColor(index: color)))
            clearGemAt(index)
        }
        return ret
    }
    
    private func explosionsForSwap(line1 line1: GemIndex, line2: GemIndex) -> Set<ExplodingGem> {
        var ret = Set<ExplodingGem>()
        ret.nonUpdatingInsert(ExplodingGem(index: line1, type: .SuperGemLine, cause: .SuperGemLine(index: line2), processed: true))
        ret.nonUpdatingInsert(ExplodingGem(index: line2, type: .SuperGemLine, cause: .SuperGemLine(index: line1), processed: true))
        clearGemAt(line1)
        clearGemAt(line2)
        // vertical sweep
        // horizontal sweep
        // 2x diagonal sweep
        for i in 2..<(dimension + 2) {
            for j in 2..<(dimension + 2) {
                let index = GemIndex(x: i, y: j)
                if line1.x == i || line1.y == j  || abs((i - j) - (line1.x - line1.y)) == 0 || abs((i + j) - (line1.x + line1.y)) == 0 {
                    ret.nonUpdatingInsert(ExplodingGem(index: index, type: board[i][j].type, cause: .SuperGemLine(index: line1)))
                    clearGemAt(index)
                    continue
                }
                if line2.x == i || line2.y == j || abs((i - j) - (line2.x - line2.y)) == 0 || abs((i + j) - (line2.x + line2.y)) == 0 {
                    ret.nonUpdatingInsert(ExplodingGem(index: index, type: board[i][j].type, cause: .SuperGemLine(index: line2)))
                    clearGemAt(index)
                    continue
                }
            }
        }
        return ret
    }

    func calculateNextExplosion(withExplosions explosions: Set<ExplodingGem>) -> Set<ExplodingGem> {
        func updateStatusIn(inout explosions: Set<ExplodingGem>, forExplosion explosion: ExplodingGem) {
            var updating = explosions.remove(explosion)!
            updating.processed = true
            explosions.insert(updating)
        }
        var ret = explosions
        for explosion in explosions.filter({!$0.processed}) {
            switch explosion.type {
            case .SuperGemBomb:
                updateStatusIn(&ret, forExplosion: explosion)
                let iMin = max(2, explosion.index.x - 1)
                let iMax = min(dimension + 1, explosion.index.x + 1)
                for i in iMin...iMax {
                    let jMin = max(2, explosion.index.y - 1)
                    let jMax = min(dimension + 1, explosion.index.y + 1)
                    for j in jMin...jMax {
                        let index = GemIndex(x: i, y: j)
                        ret.nonUpdatingInsert(ExplodingGem(index: index, type: board[i][j].type, cause: .SuperGemBomb(index: explosion.index)))
                        clearGemAt(index)
                    }
                }
            case .SuperGemColor:
                updateStatusIn(&ret, forExplosion: explosion)
                let type = randomType(fromSet: normalGemTypesOnBoard(excludedIndexes: Set<GemIndex>(explosions.map({ $0.index }))))
                if type == .None {
                    break
                }
                let indexes = collectGemIndexes(ofType: type)
                for index in indexes {
                    ret.nonUpdatingInsert(ExplodingGem(index: index, type: type, cause: .SuperGemColor(index: explosion.index)))
                    clearGemAt(index)
                }
            case .SuperGemLine:
                updateStatusIn(&ret, forExplosion: explosion)
                for i in 2..<(dimension + 2) {
                    let currentIndex = GemIndex(x: i, y: explosion.index.y)
                    ret.nonUpdatingInsert(ExplodingGem(index: currentIndex, type: board[currentIndex.x][currentIndex.y].type, cause: .SuperGemLine(index: explosion.index)))
                    clearGemAt(currentIndex)
                }
                for j in 2..<(dimension + 2) {
                    let currentIndex = GemIndex(x: explosion.index.x, y: j)
                    ret.nonUpdatingInsert(ExplodingGem(index: currentIndex, type: board[currentIndex.x][currentIndex.y].type, cause: .SuperGemLine(index: explosion.index)))
                    clearGemAt(currentIndex)
                }
            default:
                break
            }
        }
        return ret
    }
    
    private func collectGemIndexes(ofType type: GemType) -> Set<GemIndex> {
        var ret = Set<GemIndex>()
        for i in 2..<(dimension + 2) {
            for j in 2..<(dimension + 2) {
                if board[i][j].type == type {
                    ret.nonUpdatingInsert(GemIndex(x: i, y: j))
                }
            }
        }
        return ret
    }
    
    private func normalGemTypesOnBoard(excludedIndexes excluding: Set<GemIndex>) -> Set<GemType> {
        var types = Set<GemType>()
        for i in 2..<(dimension + 2) {
            for j in 2..<(dimension + 2) {
                if !excluding.contains(GemIndex(x: i, y: j)) {
                    types.nonUpdatingInsert(board[i][j].type)
                }
            }
        }
        return types.intersect([GemType.Gem1, GemType.Gem2, GemType.Gem3, GemType.Gem4, GemType.Gem5])
    }
    
    // MARK: NSCoding
    
    struct PropertyKey {
        static let dimensionKey = "dimension"
        static let boardKey = "board"
    }
    
    init(coder aDecoder: NSCoder) {
        dimension = aDecoder.decodeIntegerForKey(PropertyKey.dimensionKey)
        board = aDecoder.decodeObjectForKey(PropertyKey.boardKey) as! [[Gem]]
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(dimension, forKey: PropertyKey.dimensionKey)
        aCoder.encodeObject(board, forKey: PropertyKey.boardKey)
    }
    
    // MARK: Debug
    
    override var description: String {
        var desc = "Dimension: \(dimension) \n["
        for outer in board {
            desc += "["
            for inner in outer {
                desc += ", \(inner)"
            }
            desc += "]\n"
        }
        desc += "]"
        
        return desc
    }
}
