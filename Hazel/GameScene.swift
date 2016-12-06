//
//  GameScene.swift
//  Hazel
//
//  Created by Simon Racz on 27/12/15.
//  Copyright (c) 2015 Simon Racz. All rights reserved.
//

import SpriteKit
import AVFoundation

enum GameState {
    case Playing
    case NotPlayedYet
    indirect case Paused(previousState: GameState)
    case Ended
    case Menu
}

protocol ModalDialogDelegate: class {
    func intermediateScreenDismissed()
}

/**
 GameScene responsibilities:
    - create high level gameplay objects
    - start/pause originator
    - putting up dialogs
    - putting up other "screens" (There is only one SKScene)
*/
class GameScene: SKScene, GamePlayDelegate, ModalDialogDelegate {
    var background: BackgroundNode!
    var boardNode: BoardNode!
    var gameLogic: GameLogic!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var gameState: GameState = .NotPlayedYet
    var pauseNode: PauseNode!
    var gameEndNode: GameEndNode!
    var menuNode: MenuNode!
    var player: AVAudioPlayer?
    
    var soundOn: Bool = false
    var musicOn: Bool = false
    
    override func didMoveToView(view: SKView) {
        setUpPreferences()
        
        background = BackgroundNode(parentSize: view.frame.size)
        boardNode = BoardNode(parentSize: view.frame.size)
        background.addBoardNode(boardNode)
        gameLogic = GameLogic(boardDelegate: boardNode, gameScoreDelegate: nil, gamePlayDelegate: self)
        boardNode.boardTouchDelegate = gameLogic
        boardNode.presenterCallback = gameLogic
        background.addBoardTouchDelegate(gameLogic)
        
        gameLogic.gameScoreDelegate = background.display!
        if let view = self.view {
            panGestureRecognizer = UIPanGestureRecognizer(target: boardNode, action: Selector("handlePan:"))
            view.addGestureRecognizer(panGestureRecognizer)
        }
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.gameScene = self
        pauseNode = PauseNode(parentSize: self.frame.size)
        pauseNode.delegate = self
        background.addChild(pauseNode)
        gameEndNode = GameEndNode(parentSize: self.frame.size)
        menuNode = MenuNode(parentSize: self.frame.size)
        gameEndNode.delegate = self
        gameEndNode.hidden = true
        menuNode.hidden = true
        menuNode.delegate = self
        menuNode.gameScoreDelegate = background.display!
        boardNode.soundDelegate = menuNode
        setupMusic()
        background.addChild(gameEndNode)
        background.addChild(menuNode)
        pauseNode.showScreen(self.frame.size)
        background.curtain?.userInteractionEnabled = false
        panGestureRecognizer.enabled = false
        let defaults = NSUserDefaults.standardUserDefaults()
        background.display!.setHighScore(defaults.integerForKey(PreferencesKeys.highscoreKey))
        addChild(background)
    }
    
    private func setupMusic() {
        guard let bg_music_url = NSBundle.mainBundle().URLForResource("bg_music", withExtension: "wav") else {
            return
        }
        do {
            player = try AVAudioPlayer(contentsOfURL: bg_music_url)
            player?.numberOfLoops = -1
            boardNode.player = player
        } catch {
            return
        }
    }
    
    private func setUpPreferences() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let _ = defaults.objectForKey(PreferencesKeys.soundKey) {
            soundOn = defaults.boolForKey(PreferencesKeys.soundKey)
            musicOn = defaults.boolForKey(PreferencesKeys.musicKey)
        } else {
            soundOn = true
            musicOn = true
            defaults.setBool(soundOn, forKey: PreferencesKeys.soundKey)
            defaults.setBool(musicOn, forKey: PreferencesKeys.musicKey)
            defaults.setInteger(0, forKey: PreferencesKeys.highscoreKey)
        }
    }
    
    override func didChangeSize(oldSize: CGSize) {
        background?.relayout(parentSize: self.frame.size)
        pauseNode?.relayout(parentSize: self.frame.size)
        gameEndNode?.relayout(parentSize: self.frame.size)
        menuNode?.relayout(parentSize: self.frame.size)
    }

    var pauseHackToggled = true
    var lastUpdateTimeInterval: CFTimeInterval = 0
    
    override func update(currentTime: CFTimeInterval) {
        var delta = currentTime - lastUpdateTimeInterval
        lastUpdateTimeInterval = currentTime
        switch gameState {
        case .Paused(let pState):
            if !pauseHackToggled {
                pauseHackToggled = true
                switch pState {
                case .Playing:
                    boardNode.paused = true
                    background.curtain?.paused = true
                default:
                    break
                }
            }
        case .Menu:
            if !pauseHackToggled {
                pauseHackToggled = true
                boardNode.paused = true
                background.curtain?.paused = true
            }
        case .Playing:
            if delta > 1 {
                delta = 1.0 / 60.0
            }
            background.display!.timePassed(delta)
        default:
            break
        }
    }
    
    func pauseApp() {
        switch gameState {
        case .Paused(_):
            pauseHackToggled = false
        case .Menu:
            pauseHackToggled = false
        case .Ended:
            pauseHackToggled = false
            gameEndNode.tapLabel.removeAllActions()
            gameEndNode.tapLabel.alpha = 1
            // to pause bg music
            gameLogic.pause()
        case .Playing:
            background.curtain?.userInteractionEnabled = false
            panGestureRecognizer.enabled = false
            boardNode.paused = true
            background.curtain?.paused = true
            gameLogic.pause()
            pauseNode.hidden = false
            pauseNode.showScreen(self.frame.size)
            fallthrough
        default:
            pauseHackToggled = false
            gameState = .Paused(previousState: gameState)
        }
    }

    func resumeApp() {
        switch gameState {
        case .Ended:
            // to start bg music
            gameLogic.resume()
            gameEndNode?.touchEnabled = true
        default:
            break
        }
    }
    
    func resumeGame() {
        switch gameState {
        case .NotPlayedYet:
            fallthrough
        case .Ended:
            background.curtain?.userInteractionEnabled = true
            panGestureRecognizer.enabled = true
            gameLogic.startNewGame()
        case .Paused(let pState):
            switch pState {
            case .Playing:
                boardNode.paused = false
                background.curtain?.paused = false
                background.curtain?.userInteractionEnabled = true
                panGestureRecognizer.enabled = true
                gameLogic.resume()
                fallthrough
            default:
                gameState = pState
            }
        case .Playing:
            return
        case .Menu:
            boardNode.paused = false
            background.curtain?.paused = false
            background.curtain?.userInteractionEnabled = true
            panGestureRecognizer.enabled = true
            gameLogic.resume()
            gameState = .Playing
        }
        gameState = .Playing
    }
    
    // MARK: GamePlayDelegate
    
    func gameEnded(score: Int, newHighScore: Bool, board: Board, timeIsUp: Bool) {
        background.curtain?.userInteractionEnabled = false
        panGestureRecognizer.enabled = false
        gameEndNode.hidden = false
        if newHighScore {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setInteger(score, forKey: PreferencesKeys.highscoreKey)
            background.display!.setHighScore(score)
        }
        gameEndNode.showScreen(score, newHighScore: newHighScore, parentSize: self.frame.size)
        gameState = .Ended
    }
    
    func menuPressed() {
        background.curtain?.userInteractionEnabled = false
        panGestureRecognizer.enabled = false
        boardNode.paused = true
        background.curtain?.paused = true
        gameLogic.pause()
        menuNode.hidden = false
        menuNode.showScreen(self.frame.size)
        pauseHackToggled = false
        gameState = .Menu
    }
    
    // MARK: ModalDialogDelegate
    
    func intermediateScreenDismissed() {
        pauseNode.hidden = true
        gameEndNode.hidden = true
        menuNode.hidden = true
        resumeGame()
    }
    
}
