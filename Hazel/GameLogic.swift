//
//  GameLogic.swift
//  Hazel
//
//  Created by Simon Racz on 12/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import Foundation

protocol GameScoreDelegate: class {
    func clearScore()
    func addScore(score: Int)
    func subtractScore(score: Int)
    func setHighScore(highScore: Int)
    func currentScore() -> Int
    func currentHighScore() -> Int
    func newHighScore() -> Bool
    func timePassed(delta: CFTimeInterval)
    var time: CFTimeInterval {get set}
}

protocol BoardDelegate: class {
    func showBoard(board: Board, animate: Bool)
    func swapGems(gem1 gem1: GemIndex, gem2: GemIndex)    
    func firstExplosion(explosion: Set<ExplodingGem>, onNewBoard board: Board, gem1: GemType?, gem2: GemType?)
    func nextExplosion(explosion: Set<ExplodingGem>, previousExplosion pExplosion: Set<ExplodingGem>, onNewBoard board: Board)
    func fellGems(indexes: [(GemIndex, GemIndex)], withNewGems: [Int: [GemType]])
    func pause()
    func resume()
}

enum SwipeDirection {
    case Left
    case Right
    case Up
    case Down
}

protocol BoardTouchDelegate: class {
    func tile(tile: GemIndex, swipeDirection direction: SwipeDirection)
    func menuPressed()
    func timeIsUp()
}

protocol GamePlayDelegate: class {
    func gameEnded(score: Int, newHighScore: Bool, board: Board, timeIsUp: Bool)
    func menuPressed()
}

protocol PresenterCallback: class {
    func animationDone()
}

// STEP 0 : Call hint() to get a hint.
// STEP 1A : Call checkSwap() for swaps
// STEP 1B : Call gatherSimpleCollisions after new gems fell in place
// STEP 2 (repatedly) : Call calculateNextExplosion while there are new explosions
// Board is updated automatically
// Exploding gems are replaced with .None
// New SuperGems might appear in place of exploding gems.
// STEP 3 : Call fellOneStep() until no new nodes --> Go Back To STEP 1B
// STEP 4 : GameEnd

enum GameLogicState {
    case Step0(hintTile1: GemIndex, hintTile2: GemIndex, timeIsUp: Bool)
    case Step1a(tile: GemIndex, otherTile: GemIndex, timeIsUp: Bool, gem1: GemType?, gem2: GemType?)
    case Step1b(scoreMultiplier: Int, timeIsUp: Bool)
    case Step2(previousExplosion: Set<ExplodingGem>, scoreMultiplier: Int, timeIsUp: Bool)
    case Step3(scoreMultiplier: Int, timeIsUp: Bool)
    case Step4(timeIsUp: Bool)
}

/**
 GameLogic responsibilities:
    - drive the game logic, but not the presentation style
    - communicates through delegates and callbacks
    - independent of sprite kit, e.g. does not use skactions
 */
class GameLogic: BoardTouchDelegate, PresenterCallback {
    weak var boardDelegate: BoardDelegate?
    weak var gameScoreDelegate: GameScoreDelegate?
    weak var gamePlayDelegate: GamePlayDelegate?
    var board: Board!
    var state: GameLogicState
    var paused: Bool = false
    
    init(boardDelegate: BoardDelegate?, gameScoreDelegate: GameScoreDelegate?, gamePlayDelegate: GamePlayDelegate?) {
        self.boardDelegate = boardDelegate
        self.gameScoreDelegate = gameScoreDelegate
        self.gamePlayDelegate = gamePlayDelegate
        self.state = .Step4(timeIsUp: false)
    }
    
    func startWithBoard(board: Board) {
        self.board = board
        var index1 = GemIndex(x: 0, y: 0)
        var index2 = GemIndex(x: 0, y: 0)
        let hasHint = board.hint(index1: &index1, index2: &index2)
        if !hasHint {
            self.startNewGame()
            return
        }
        finalizeStartup(index1: GemIndex(x: index1.x - 2, y: index1.y - 2), index2: GemIndex(x: index2.x - 2, y: index2.y - 2))
    }
    
    func startNewGame() {
        self.board = Board(dimension: 8)
        var hasHint = false
        var index1 = GemIndex(x: 0, y: 0)
        var index2 = GemIndex(x: 0, y: 0)
        while !hasHint {
            board.populateBoard()
            hasHint = board.hint(index1: &index1, index2: &index2)
        }
        finalizeStartup(index1: GemIndex(x: index1.x - 2, y: index1.y - 2), index2: GemIndex(x: index2.x - 2, y: index2.y - 2))
    }
    
    private func finalizeStartup(index1 index1: GemIndex, index2: GemIndex) {
        gameScoreDelegate?.clearScore()
        state = .Step0(hintTile1: index1, hintTile2: index2, timeIsUp: false)
        boardDelegate?.resume()
        boardDelegate?.showBoard(board, animate: true)
        gameScoreDelegate?.time = 155
    }
    
    func pause() {
        paused = true
        boardDelegate?.pause()
    }
    
    func resume() {
        paused = false
        boardDelegate?.resume()
    }
    
    func clearBoard() {
        board.clearBoard()
    }
    
    // MARK: BoardTouchDelegate
    
    func tile(tile: GemIndex, swipeDirection direction: SwipeDirection) {
        if paused {
            return
        }
        let otherTile: GemIndex
        switch direction {
        case .Down:
            otherTile = GemIndex(x: tile.x, y: tile.y + 1)
        case .Up:
            otherTile = GemIndex(x: tile.x, y: tile.y - 1)
        case .Left:
            otherTile = GemIndex(x: tile.x - 1, y: tile.y)
        case .Right:
            otherTile = GemIndex(x: tile.x + 1, y: tile.y)
        }
        if !tileIsOnBoard(otherTile) {
            return
        }
        let gem1 = board.board[tile.x + 2][tile.y + 2].type
        let gem2 = board.board[otherTile.x + 2][otherTile.y + 2].type
        switch state {
        case .Step0(_, _, let timeIsUp):
            if !timeIsUp {
                state = .Step1a(tile: tile, otherTile: otherTile, timeIsUp: false, gem1: gem1, gem2: gem2)
                boardDelegate?.swapGems(gem1: tile, gem2: otherTile)
            }
        default:
            break
        }
    }
    
    private func tileIsOnBoard(tile: GemIndex) -> Bool {
        return tile.x >= 0 && tile.x < board.dimension && tile.y >= 0 && tile.y < board.dimension
    }
    
    func menuPressed() {
        gamePlayDelegate?.menuPressed()
    }
    
    func timeIsUp() {
        switch state {
        case .Step0(_, _, _):
            gameEnded()
        case .Step1a(let tile, let otherTile, _, let gem1, let gem2):
            state = .Step1a(tile: tile, otherTile: otherTile, timeIsUp: true, gem1: gem1, gem2: gem2)
        case .Step1b(let scoreMultiplier, _):
            state = .Step1b(scoreMultiplier: scoreMultiplier, timeIsUp: true)
        case .Step2(let previousExplosion, let scoreMultiplier, _):
            state = .Step2(previousExplosion: previousExplosion, scoreMultiplier: scoreMultiplier, timeIsUp: true)
        case .Step3(let scoreMultiplier, _):
            state = .Step3(scoreMultiplier: scoreMultiplier, timeIsUp: true)
        case .Step4(_):
            state = .Step4(timeIsUp: true)
        }
    }
    
    private func transitionToBaseState() {
        var index1 = GemIndex(x: 0, y: 0)
        var index2 = GemIndex(x: 0, y: 0)
        let hasHint = board.hint(index1: &index1, index2: &index2)
        switch state {
        case .Step1a(_, _, let timeIsUp, _, _):
            if timeIsUp {
                gameEnded()
                return
            }
        case .Step1b(_, let timeIsUp):
            if timeIsUp {
                gameEnded()
                return
            }
        default:
            break
        }
        if hasHint {
            state = .Step0(hintTile1: GemIndex(x: index1.x - 2, y: index1.y - 2), hintTile2: GemIndex(x: index2.x - 2, y: index2.y - 2), timeIsUp: false)
            return
        }
        state = .Step4(timeIsUp: false)
        gameEnded(timeIsUp: false)
    }
    
    private func gameEnded(timeIsUp timeIsUp: Bool = true) {
        state = .Step4(timeIsUp: timeIsUp)
        if let scoreDelegate = gameScoreDelegate {
            gamePlayDelegate?.gameEnded(scoreDelegate.currentScore(), newHighScore: scoreDelegate.newHighScore(), board: board, timeIsUp: timeIsUp)
        } else {
            gamePlayDelegate?.gameEnded(0, newHighScore: false, board: board, timeIsUp: timeIsUp)
        }
    }
    
    // MARK: PresenterCallback
    
    private func countToScore(count: Int) -> Int {
        switch count {
        case 9...15:
            return 2 * count
        case 16...31:
            return 3 * count
        case 32...64:
            return 4 * count
        default:
            return count
        }
    }
    
    func animationDone() {
        switch state {
        case .Step0(_, _, let timeIsUp):
            if timeIsUp {
                gameEnded()
            }
        case .Step1a(let tile, let otherTile, let timeIsUp, let gem1, let gem2):
            let index1 = GemIndex(x: tile.x + 2, y: tile.y + 2)
            let index2 = GemIndex(x: otherTile.x + 2, y: otherTile.y + 2)
            let explosion = board.checkSwap(forGemIndex: index1, withGemIndex: index2)
            if explosion.count == 0 {
                boardDelegate?.swapGems(gem1: tile, gem2: otherTile)
                transitionToBaseState()
                return
            }
            state = .Step2(previousExplosion: explosion, scoreMultiplier: 2, timeIsUp: timeIsUp)
            gameScoreDelegate?.addScore(countToScore(explosion.count))
            boardDelegate?.firstExplosion(explosion, onNewBoard: board, gem1: gem1, gem2: gem2)
        case .Step1b(let scoreMultiplier, let timeIsUp):
            let explosion = board.gatherSimpleCollisions()
            if explosion.count == 0 {
                transitionToBaseState()
                return
            }
            gameScoreDelegate?.addScore(scoreMultiplier * countToScore(explosion.count))
            boardDelegate?.firstExplosion(explosion, onNewBoard: board, gem1: nil, gem2: nil)
            state = .Step2(previousExplosion: explosion, scoreMultiplier: scoreMultiplier + 1, timeIsUp: timeIsUp)
        case .Step2(let explosion, let scoreMultiplier, let timeIsUp):
            let nextExplosion = board.calculateNextExplosion(withExplosions: explosion)
            if nextExplosion.count == explosion.count {
                state = .Step3(scoreMultiplier: scoreMultiplier, timeIsUp: timeIsUp)
                animationDone()
                return
            }
            gameScoreDelegate?.addScore(scoreMultiplier * countToScore(nextExplosion.count))
            state = .Step2(previousExplosion: nextExplosion, scoreMultiplier: scoreMultiplier + 1, timeIsUp: timeIsUp)
            boardDelegate?.nextExplosion(nextExplosion, previousExplosion: explosion, onNewBoard: board)
        case .Step3(let scoreMultiplier, let timeIsUp):
            let (indexPairs, newGems) = board.fellGems()
            if newGems.count == 0 {
                state = .Step1b(scoreMultiplier: scoreMultiplier, timeIsUp: timeIsUp)
                animationDone()
                return
            }
            boardDelegate?.fellGems(indexPairs, withNewGems: newGems)
        case .Step4:
            break
        }
    }
}
