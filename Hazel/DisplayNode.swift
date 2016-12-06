//
//  DisplayNode.swift
//  Hazel
//
//  Created by Simon Racz on 18/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import SpriteKit

class DisplayNode: SKNode, ResizableNode, GameScoreDelegate {
    var scoreLabel: SKLabelNode
    var menuButton: SKShapeNode
    var menuButtonLabel: SKLabelNode
    var timeLabel: SKLabelNode
    weak var boardTouchDelegate: BoardTouchDelegate?
    private var score = 0
    private var highScore = 0
    var time: CFTimeInterval = 0
    
    struct UIHelpers {
        static let margin: CGFloat = 10
        static let maxScoreLabelWidth: CGFloat = 160
        static let maxFontSize: CGFloat = 45
    }
    
    init(parentSize: CGSize) {
        scoreLabel = SKLabelNode()
        // fixed 80 x 50 size
        let path = CGPathCreateWithRoundedRect(CGRect(x: -40, y: -25, width: 80, height: 50), 4, 4, nil)
        menuButton = SKShapeNode(path: path, centered: true)
        menuButtonLabel = SKLabelNode(text: "Menu")
        timeLabel = SKLabelNode()
        super.init()
        setupUI()
        relayout(parentSize: parentSize)
        userInteractionEnabled = true
        setupActions()
    }
    
    private func setupUI() {
        scoreLabel.fontName = UIGlobals.fontName
        scoreLabel.fontColor = UIGlobals.fontColor       
        scoreLabel.horizontalAlignmentMode = .Center
        scoreLabel.verticalAlignmentMode = .Center
        timeLabel.fontName = UIGlobals.fontName
        timeLabel.fontColor = UIGlobals.fontColor
        timeLabel.horizontalAlignmentMode = .Right
        timeLabel.verticalAlignmentMode = .Center
        // fixed 80 x 50 size
        menuButton.strokeColor = UIGlobals.strokeColor
        menuButton.fillColor = UIGlobals.fillColor
        menuButtonLabel.fontColor = UIGlobals.fontColor
        menuButtonLabel.fontName = UIGlobals.fontName
        menuButtonLabel.verticalAlignmentMode = .Center
        menuButton.addChild(menuButtonLabel)
        addChild(menuButton)
        addChild(scoreLabel)
        addChild(timeLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func relayout(parentSize size: CGSize) {
        menuButton.position = CGPoint(x: UIHelpers.margin + 40, y: size.height - UIHelpers.margin - 25)
        menuButtonLabel.position = CGPointZero
        menuButtonLabel.fontSize = 26

        scoreLabel.text = "\(score)"
        updateTime()
        timeLabel.fontSize = 30
        timeLabel.position = CGPoint(x: size.width - UIHelpers.margin, y: size.height - UIHelpers.margin - 25)

        // scoreLabel.fontSize = UIHelpers.maxFontSize
        if size.width > 250 {
            scoreLabel.fontSize = 60
        } else {
            scoreLabel.fontSize = 40
        }
        scoreLabel.position = CGPoint(x: size.width / 2, y: (size.height - menuButton.frame.height - UIHelpers.margin) / 2)
    }

    private func timeToText(time: CFTimeInterval) -> String {
        func widen(seconds: Int) -> String {
            switch seconds {
            case let s where s > 9:
                return "\(s)"
            case let s:
                return "0\(s)"
            }
        }
        return "\(Int(time) / 60):\(widen(Int(time) % 60))"
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first!
        let node = nodeAtPoint(touch.locationInNode(self))
        if node == menuButton || node == menuButtonLabel {
            boardTouchDelegate?.menuPressed()
        }
    }
    
    private func updateTime() {
        timeLabel.text = timeToText(time)
    }
    
    private func updateScore() {
        scoreLabel.text = "\(score)"
    }
    
    // MARK: GameScoreDelegate
    func timePassed(delta: CFTimeInterval) {
        if time <= 0 {
            return
        }
        time -= delta
        updateTime()
        if time <= 0 {
            time = 0
            updateTime()
            boardTouchDelegate?.timeIsUp()
        }
    }
    
    func clearScore() {
        score = 0
        updateScore()
    }

    let zoomingAction1 = SKAction.sequence([SKAction.scaleTo(1.05, duration: UIGlobals.gameSpeed), SKAction.scaleTo(1.0, duration: UIGlobals.gameSpeed)])
    let zoomingAction2 = SKAction.sequence([SKAction.scaleTo(1.1, duration: UIGlobals.gameSpeed), SKAction.scaleTo(1.0, duration: UIGlobals.gameSpeed)])
    let zoomingAction3 = SKAction.sequence([SKAction.scaleTo(1.2, duration: UIGlobals.gameSpeed), SKAction.scaleTo(1.0, duration: UIGlobals.gameSpeed)])
    let zoomingAction4 = SKAction.sequence([SKAction.scaleTo(1.3, duration: UIGlobals.gameSpeed), SKAction.scaleTo(1.0, duration: UIGlobals.gameSpeed)])

    private func setupActions() {
        zoomingAction1.timingMode = .EaseInEaseOut
        zoomingAction2.timingMode = .EaseInEaseOut
        zoomingAction3.timingMode = .EaseInEaseOut
    }
    
    let timeAction = SKAction.sequence([SKAction.group([SKAction.scaleTo(2, duration: 3 * UIGlobals.gameSpeed), SKAction.fadeOutWithDuration(3 * UIGlobals.gameSpeed), SKAction.moveByX(10, y: 30, duration: 3 * UIGlobals.gameSpeed)]), SKAction.removeFromParent()])
    
    private func putUpTempTimeLabel(weight: Int) {
        let label = SKLabelNode(text: "+\(weight)")
        label.fontColor = UIGlobals.fontColor
        label.fontName = UIGlobals.fontName
        label.fontSize = timeLabel.fontSize
        label.position = CGPoint(x: timeLabel.frame.midX, y: timeLabel.frame.minY - 20)
        label.runAction(timeAction)
        addChild(label)
    }
    
    func addScore(score: Int) {
        self.score += score
        switch score {
        case 3...8:
            scoreLabel.runAction(zoomingAction1)
        case 9...15:
            scoreLabel.runAction(zoomingAction2)
        case 16...31:
            scoreLabel.runAction(zoomingAction2)
            time += 1
            putUpTempTimeLabel(1)
        case 32...49:
            scoreLabel.runAction(zoomingAction2)
            time += 2
            putUpTempTimeLabel(2)
        case 50...99:
            scoreLabel.runAction(zoomingAction3)
            time += 3
            putUpTempTimeLabel(3)
        case 100...149:
            scoreLabel.runAction(zoomingAction4)
            time += 4
            putUpTempTimeLabel(4)
        case let x where x >= 150:
            scoreLabel.runAction(zoomingAction4)
            time += 5
            putUpTempTimeLabel(5)
        default:
            break
        }
        updateScore()
        updateTime()
    }
    
    func subtractScore(score: Int) {
        self.score -= score
        updateScore()
    }
    
    func setHighScore(highScore: Int) {
        self.highScore = highScore
    }
    
    func currentScore() -> Int {
        return score
    }
    
    func currentHighScore() -> Int {
        return highScore
    }
    
    func newHighScore() -> Bool {
        return score >= highScore
    }

}