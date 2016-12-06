//
//  BoardNode.swift
//  Hazel
//
//  Created by Simon Racz on 05/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import Foundation
import SpriteKit
import AVFoundation

enum Placement {
    case Right
    case Bottom
    case Left
}

// A view of GameScene and also a controller for the board.
// Handles the presentation of the Board model.
class BoardNode: SKSpriteNode, ResizableNode, BoardDelegate {
    var placement: Placement!
    var dimension: Int!
    weak var boardTouchDelegate: BoardTouchDelegate?
    weak var presenterCallback: PresenterCallback?
    weak var soundDelegate: SoundDelegate?
    weak var player: AVAudioPlayer?
    
    let gemTextures: [GemType: SKTexture?] = [
        GemType.None: nil,
        GemType.Gem1: SKTexture(imageNamed: "cat"),
        GemType.Gem2: SKTexture(imageNamed: "tombstone"),
        GemType.Gem3: SKTexture(imageNamed: "cauldron"),
        GemType.Gem4: SKTexture(imageNamed: "skull"),
        GemType.Gem5: SKTexture(imageNamed: "lantern"),
        GemType.SuperGemBomb: SKTexture(imageNamed: "pumpkin"),
        GemType.SuperGemColor: SKTexture(imageNamed: "pit"),
        GemType.SuperGemLine: SKTexture(imageNamed: "bat")
    ]
    
    var tiles: [[SKSpriteNode]]
    
    init(parentSize size: CGSize, boardTouchDelegate: BoardTouchDelegate? = nil, withDimension dimension: Int = 8) {
        self.boardTouchDelegate = boardTouchDelegate
        let boardWidth = min(size.width, size.height) * 0.95
        let boardSize = CGSize(width: boardWidth, height: boardWidth)
        self.dimension = dimension
        self.tiles = [[SKSpriteNode]]()
        for var i=0; i<dimension; ++i {
            var arr = [SKSpriteNode]()
            for var j=0; j<dimension; ++j {
                arr.append(SKSpriteNode())
            }
            tiles.append(arr)
        }
        super.init(texture: nil, color: UIColor(white: 0.8, alpha: 0.5), size: boardSize)
        self.anchorPoint = CGPointZero
        for column in tiles {
            for row in column {
                self.addChild(row)
            }
        }
        self.relayout(parentSize: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var currentTileSize: CGFloat = 0
    
    func relayout(parentSize size: CGSize) {
        let boardWidth = min(size.width, size.height) * 0.95
        let margin = min(size.width, size.height) * 0.025
        let boardSize = CGSize(width: boardWidth, height: boardWidth)

        //calculate position
        let wide = size.width > size.height ? true : false
        let boardPosition: CGPoint
        if wide {
            //iPad
            boardPosition = CGPoint(x:size.width - size.height + margin, y:margin)
            placement = .Right
        } else {
            //iPhone
            boardPosition = CGPoint(x:margin, y:margin)
            placement = .Bottom
        }
        
        self.size = boardSize
        self.position = boardPosition
        
        currentTileSize = boardWidth / 8
        for (i, column) in tiles.enumerate() {
            for (j, row) in column.enumerate() {
                row.size = CGSize(width: currentTileSize, height: currentTileSize)
                row.position = CGPoint(x: CGFloat(i) * currentTileSize, y: boardWidth - CGFloat(j) * currentTileSize)
                row.anchorPoint = CGPoint(x: 0, y: 1)
            }
        }
    }
    
    // MARK: TouchHandling

    private var panStart: CGPoint?
    
    private func cancelPan(pan: UIPanGestureRecognizer) {
        pan.enabled = false
        pan.enabled = true
    }
    /*
    func debugTap(tap: UITapGestureRecognizer) {
        guard let scene = self.scene else {
            return
        }
        switch tap.state {
        case .Ended:
            let locationInView = tap.locationInView(scene.view)
            let location = scene.convertPointFromView(locationInView)
            let locationInNode = convertPoint(location, fromNode: scene)
            print(locationInNode)
        default:
            break
        }
    }
    */
    
    func handlePan(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .Began:
            guard let scene = self.scene else {
                panStart = nil
                cancelPan(pan)
                return
            }
            let locationInView = pan.locationInView(scene.view)
            let location = scene.convertPointFromView(locationInView)
            let locationInNode = convertPoint(location, fromNode: scene)
            let nodeFrame = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
            if !nodeFrame.contains(locationInNode) {
                panStart = nil
                cancelPan(pan)
                return
            }
            panStart = locationInNode
        case .Ended:
            guard let scene = self.scene,
                  let panStart = self.panStart else {
                return
            }
            let translation = pan.translationInView(scene.view)
            let index = GemIndex(x: Int(panStart.x / currentTileSize), y: 7 - Int(panStart.y / currentTileSize))
            let mx = abs(translation.x)
            let my = abs(translation.y)
            if mx >= my {
                if translation.x > 0 {
                    boardTouchDelegate?.tile(index, swipeDirection: SwipeDirection.Right)
                } else {
                    boardTouchDelegate?.tile(index, swipeDirection: SwipeDirection.Left)
                }
            } else {
                if translation.y > 0 {
                    boardTouchDelegate?.tile(index, swipeDirection: SwipeDirection.Down)
                } else {
                    boardTouchDelegate?.tile(index, swipeDirection: SwipeDirection.Up)
                }
            }
        default:
            break
        }
    }
    
    // MARK: BoardDelegate
    func showBoard(board: Board, animate: Bool) {
        if animate {
            for i in 0..<board.dimension {
                for j in 0..<board.dimension {
                    tiles[i][j].texture = gemTextures[board.board[i + 2][j + 2].type]!
                    tiles[i][j].alpha = 0.0
                    let fadeIn = SKAction.fadeInWithDuration(UIGlobals.gameSpeed)
                    tiles[i][j].runAction(fadeIn)
                }
            }
            tiles[0][0].runAction(SKAction.sequence([SKAction.waitForDuration(UIGlobals.gameSpeed), SKAction.runBlock({[weak self] in self?.presenterCallback?.animationDone()})]))
        } else {
            for i in 0..<board.dimension {
                for j in 0..<board.dimension {
                    tiles[i][j].texture = gemTextures[board.board[i + 2][j + 2].type]!
                }
            }
        }
    }
    
    func swapGems(gem1 gem1: GemIndex, gem2: GemIndex) {
        let lastRowHeight = CGFloat(dimension) * currentTileSize
        let location1 = CGPoint(x: CGFloat(gem1.x) * currentTileSize, y: lastRowHeight - CGFloat(gem1.y) * currentTileSize)
        let location2 = CGPoint(x: CGFloat(gem2.x) * currentTileSize, y: lastRowHeight - CGFloat(gem2.y) * currentTileSize)
        let moveAction1 = SKAction.moveTo(location1, duration: UIGlobals.gameSpeed)
        moveAction1.timingMode = .EaseInEaseOut
        let moveAction2 = SKAction.moveTo(location2, duration: UIGlobals.gameSpeed)
        moveAction2.timingMode = .EaseInEaseOut
        tiles[gem1.x][gem1.y].runAction(moveAction2)
        tiles[gem2.x][gem2.y].runAction(SKAction.sequence([moveAction1, SKAction.runBlock({[weak self] in self?.presenterCallback?.animationDone()})]))
        let sprite = tiles[gem1.x][gem1.y]
        tiles[gem1.x][gem1.y] = tiles[gem2.x][gem2.y]
        tiles[gem2.x][gem2.y] = sprite
    }
    
    let batSound = SKAction.playSoundFileNamed("bat.wav", waitForCompletion: false)
    let pitSound = SKAction.playSoundFileNamed("pit.wav", waitForCompletion: false)
    let pumpkinSound = SKAction.playSoundFileNamed("pumpkin.wav", waitForCompletion: false)
    let bigSound = SKAction.playSoundFileNamed("big.wav", waitForCompletion: false)
    let bigbigSound = SKAction.playSoundFileNamed("bigbig.wav", waitForCompletion: false)
    let normalSounds = [
        SKAction.playSoundFileNamed("normal1.wav", waitForCompletion: false),
        SKAction.playSoundFileNamed("normal2.wav", waitForCompletion: false),
        SKAction.playSoundFileNamed("normal3.wav", waitForCompletion: false),
        SKAction.playSoundFileNamed("normal4.wav", waitForCompletion: false),
        SKAction.playSoundFileNamed("normal5.wav", waitForCompletion: false),
        SKAction.playSoundFileNamed("normal6.wav", waitForCompletion: false),
        SKAction.playSoundFileNamed("normal7.wav", waitForCompletion: false),
        SKAction.playSoundFileNamed("normal8.wav", waitForCompletion: false)
    ]
    
    private func randomNormalSoundAction() -> SKAction {
        let dice = Int(arc4random_uniform(UInt32(normalSounds.count)))
        return normalSounds[dice]
    }
    
    private func soundForFirstExplosion(count: Int, gem1: GemType?, gem2: GemType?) {
        guard let soundDelegate = soundDelegate else {
            return
        }
        if !soundDelegate.soundOn {
            return
        }
        if let gem1 = gem1, let gem2 = gem2 {
            switch (gem1, gem2) {
            case (.SuperGemColor, _):
                fallthrough
            case (_, .SuperGemColor):
                runAction(pitSound)
                return
            case (.SuperGemBomb, _):
                fallthrough
            case (_, .SuperGemBomb):
                runAction(pumpkinSound)
                return
            case (.SuperGemLine, _):
                fallthrough
            case (_, .SuperGemLine):
                runAction(batSound)
                return
            default:
                break
            }
        }
        switch count {
        case 1...9:
            runAction(randomNormalSoundAction())
        case 10...24:
            runAction(bigSound)
        case let x where x >= 25:
            runAction(bigbigSound)
        default:
            break
        }
    }
    
    private func soundForExplosion(iterSet: Set<ExplodingGem>) {
        guard let soundDelegate = soundDelegate else {
            return
        }
        if !soundDelegate.soundOn {
            return
        }
        let elem = iterSet.first!
        switch elem.cause {
        case .SuperGemColor:
            runAction(pitSound)
            return
        case .SuperGemBomb:
            runAction(pumpkinSound)
            return
        case .SuperGemLine:
            runAction(batSound)
            return
        default:
            break
        }
        switch iterSet.count {
        case 1...9:
            runAction(randomNormalSoundAction())
        case 10...24:
            runAction(bigSound)
        case let x where x >= 25:
            runAction(bigbigSound)
        default:
            break
        }
    }
    
    func firstExplosion(explosion: Set<ExplodingGem>, onNewBoard board: Board, gem1: GemType?, gem2: GemType?) {
        for i in 0..<board.dimension {
            for j in 0..<board.dimension {
                tiles[i][j].texture = gemTextures[board.board[i + 2][j + 2].type]!
            }
        }
        soundForFirstExplosion(explosion.count, gem1: gem1, gem2: gem2)
        
        for gem in explosion {
            let emitter = SKEmitterNode(fileNamed: "explosion")!
            emitter.position = CGPoint(x: currentTileSize / 2, y: -currentTileSize / 2)
            emitter.particlePositionRange = CGVector(dx: currentTileSize * 0.9, dy: currentTileSize * 0.9)
            switch gem.cause {
            case .SuperGemBomb(index: _):
                emitter.particleColor = UIColor.orangeColor()
            case .SuperGemColor(index: _):
                emitter.particleColor = UIColor.blackColor()
            case .SuperGemLine(index: _):
                emitter.particleColor = UIColor.purpleColor()
            default:
                break
            }
            let action = SKAction.sequence([SKAction.waitForDuration(UIGlobals.gameSpeed), SKAction.removeFromParent()])
            tiles[gem.index.x - 2][gem.index.y - 2].addChild(emitter)
            emitter.runAction(action)
        }
        tiles[0][0].runAction(SKAction.sequence([SKAction.waitForDuration(UIGlobals.gameSpeed), SKAction.runBlock({[weak self] in self?.presenterCallback?.animationDone()})]))
    }
    
    func nextExplosion(explosion: Set<ExplodingGem>, previousExplosion pExplosion: Set<ExplodingGem>, onNewBoard board: Board) {
        for i in 0..<board.dimension {
            for j in 0..<board.dimension {
                tiles[i][j].texture = gemTextures[board.board[i + 2][j + 2].type]!
            }
        }
        let iterSet = explosion.subtract(pExplosion)
        soundForExplosion(iterSet)
        switch iterSet.first!.cause {
        case .SuperGemBomb:
            break
        case .SuperGemColor:
            break
        case .SuperGemLine:
            break
        default:
            break
        }
        for gem in iterSet {
            let emitter = SKEmitterNode(fileNamed: "explosion")!
            emitter.position = CGPoint(x: currentTileSize / 2, y: -currentTileSize / 2)
            emitter.particlePositionRange = CGVector(dx: currentTileSize * 0.9, dy: currentTileSize * 0.9)
            switch gem.cause {
            case .SuperGemBomb(index: _):
                emitter.particleColor = UIColor.orangeColor()
            case .SuperGemColor(index: _):
                emitter.particleColor = UIColor.blackColor()
            case .SuperGemLine(index: _):
                emitter.particleColor = UIColor.purpleColor()
            default:
                break
            }
            let action = SKAction.sequence([SKAction.waitForDuration(UIGlobals.gameSpeed), SKAction.removeFromParent()])
            tiles[gem.index.x - 2][gem.index.y - 2].addChild(emitter)
            emitter.runAction(action)
        }
        tiles[0][0].runAction(SKAction.sequence([SKAction.waitForDuration(UIGlobals.gameSpeed), SKAction.runBlock({[weak self] in self?.presenterCallback?.animationDone()})]))
    }
    
    func fellGems(indexes: [(GemIndex, GemIndex)], withNewGems: [Int: [GemType]]) {
        var longestFall = 0
        let lastRowHeight = CGFloat(dimension) * currentTileSize
        for index in indexes {
            let tile = tiles[index.0.x - 2][index.0.y - 2]
            let targetTile = tiles[index.1.x - 2][index.1.y - 2]
            targetTile.texture = tile.texture
            targetTile.position = tile.position
            let location = CGPoint(x: CGFloat(index.1.x - 2) * currentTileSize, y: lastRowHeight - CGFloat(index.1.y - 2) * currentTileSize)
            let action = SKAction.moveTo(location , duration: UIGlobals.gameSpeed * NSTimeInterval(index.1.y - index.0.y) / 3)
            targetTile.runAction(action)
        }
        for (coloumn, gemArr) in withNewGems {
            let gemCount = gemArr.count
            if longestFall < gemCount {
                longestFall = gemCount
            }
            for (count, gem) in gemArr.enumerate() {
                let tile = tiles[coloumn - 2][gemCount - 1 - count]
                tile.texture = gemTextures[gem]!
                let fromLocation = CGPoint(x: CGFloat(coloumn - 2)  * currentTileSize, y: lastRowHeight + CGFloat(count + 1) * currentTileSize)
                let toLocation = CGPoint(x: CGFloat(coloumn - 2)  * currentTileSize, y: lastRowHeight - CGFloat(gemCount - 1 - count) * currentTileSize)
                let action = SKAction.moveTo(toLocation , duration: UIGlobals.gameSpeed * NSTimeInterval(gemCount) / 3)
                tile.position = fromLocation
                tile.runAction(action)
            }
        }
        tiles[0][0].runAction(SKAction.sequence([SKAction.waitForDuration(UIGlobals.gameSpeed * NSTimeInterval(longestFall) / 3), SKAction.runBlock({[weak self] in self?.presenterCallback?.animationDone()})]))
    }
    
    func pause() {
        player?.stop()
    }
    
    func resume() {
        if let soundDelegate = soundDelegate {
            if soundDelegate.musicOn {
                player?.prepareToPlay()
                player?.play()
            }
        }
    }
}
