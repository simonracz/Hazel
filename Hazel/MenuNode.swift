//
//  MenuNode.swift
//  Hazel
//
//  Created by Simon Racz on 21/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import SpriteKit

protocol SoundDelegate: class {
    var soundOn: Bool {get}
    var musicOn: Bool {get}
}

class MenuNode: SKSpriteNode, ResizableNode, SoundDelegate {
    var backButton: SKSpriteNode
    var soundLabel: SKLabelNode
    var musicLabel: SKLabelNode
    var resetHighScoreLabel: SKLabelNode
    var highScoreLabel: SKLabelNode
   
    weak var delegate: ModalDialogDelegate?
    weak var gameScoreDelegate: GameScoreDelegate?
    
    var soundOn: Bool
    var musicOn: Bool
    var highScore: Int
    
    struct UIHelpers {
        static let margin: CGFloat = 10
        static let biggestRowHeight: CGFloat = 60
        static let maxLabelWidth: CGFloat = 360
        static let maxFontSize: CGFloat = 60
    }
    
    init(parentSize size: CGSize) {
        let defaults = NSUserDefaults.standardUserDefaults()
        soundOn = defaults.boolForKey(PreferencesKeys.soundKey)
        musicOn = defaults.boolForKey(PreferencesKeys.musicKey)
        highScore = defaults.integerForKey(PreferencesKeys.highscoreKey)
        backButton = SKSpriteNode(imageNamed: "back_arrow")
        soundLabel = SKLabelNode()
        musicLabel = SKLabelNode()
        resetHighScoreLabel = SKLabelNode()
        highScoreLabel = SKLabelNode()
        super.init(texture: nil, color: UIGlobals.bgColor, size: size)
        userInteractionEnabled = true
        
        setupUI()
        
        self.relayout(parentSize: size)
    }
    
    private func setupUI() {
        soundLabel.fontName = UIGlobals.fontName
        soundLabel.fontColor = UIGlobals.fontColor
        soundLabel.horizontalAlignmentMode = .Left
        soundLabel.verticalAlignmentMode = .Center
        
        musicLabel.fontName = UIGlobals.fontName
        musicLabel.fontColor = UIGlobals.fontColor
        musicLabel.horizontalAlignmentMode = .Left
        musicLabel.verticalAlignmentMode = .Center
        
        resetHighScoreLabel.fontName = UIGlobals.fontName
        resetHighScoreLabel.fontColor = UIGlobals.fontColor
        resetHighScoreLabel.verticalAlignmentMode = .Center
        
        highScoreLabel.fontName = UIGlobals.fontName
        highScoreLabel.fontColor = UIGlobals.fontColor
        highScoreLabel.horizontalAlignmentMode = .Left
        highScoreLabel.verticalAlignmentMode = .Center
        
        backButton.color = UIGlobals.fontColor
        backButton.colorBlendFactor = 1
        
        addChild(backButton)
        addChild(soundLabel)
        addChild(musicLabel)
        addChild(resetHighScoreLabel)
        addChild(highScoreLabel)
    }
    
    private func setupLabelTexts() {
        if soundOn {
            soundLabel.text = "Sound is ON"
        } else {
            soundLabel.text = "Sound is OFF"
        }
        
        if musicOn {
            musicLabel.text = "Music is ON"
        } else {
            musicLabel.text = "Music is OFF"
        }
        
        resetHighScoreLabel.text = "Reset HighScore"
        
        if let gameScoreDelegate = gameScoreDelegate {
            highScoreLabel.text = "Highscore : \(gameScoreDelegate.currentHighScore())"
        } else {
            highScoreLabel.text = "Highscore : ?"
        }        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showScreen(parentSize: CGSize) {
        self.alpha = 0
        let fadeIn = SKAction.fadeInWithDuration(UIGlobals.gameSpeed)
        self.runAction(fadeIn)
        relayout(parentSize: parentSize)
    }
    
    private func relayoutBG(parentSize size: CGSize) {
        let wide = size.width > size.height
        
        let backgroundTexture: SKTexture
        if wide {
            backgroundTexture = SKTexture(imageNamed: "Background-landscape")
        } else {
            backgroundTexture = SKTexture(imageNamed: "Background-portrait")
        }
        
        let tH = backgroundTexture.size().height
        let tW = backgroundTexture.size().width
        
        let vH = size.height
        let vW = size.width
        
        let textureRatio = tH / tW
        let viewRatio = vH / vW
        
        let bgTexture: SKTexture
        
        switch (textureRatio - viewRatio) {
        case let x where x == 0:
            bgTexture = backgroundTexture
        case let x where x > 0:
            let scale = tW / vW;
            let dH = vH * scale
            // Shows the middle part of the landscape texture
            let subTextureRect = CGRect(x: 0, y: 0.5 - (dH / (2 * tH)), width: 1, height: dH/tH)
            bgTexture = SKTexture(rect: subTextureRect, inTexture: backgroundTexture)
        case let x where x < 0:
            let scale = tH / vH;
            let dW = vW * scale
            // Shows the middle part of the portrait texture
            let subTextureRect = CGRect(x: 0.5 - (dW / (2 * tW)), y: 0, width: dW/tW, height: 1)
            bgTexture = SKTexture(rect: subTextureRect, inTexture: backgroundTexture)
        default:
            // Should never happen
            bgTexture = backgroundTexture
        }
        
        self.texture = bgTexture
        self.size = size
        anchorPoint = CGPointZero
        position = CGPointZero
    }
    
    func relayout(parentSize size: CGSize) {
        relayoutBG(parentSize: size)
        
        setupLabelTexts()
        resetHighScoreLabel.text = "Reset HighScore 99999"

        backButton.size = CGSize(width: 90, height: 40)
        
        if size.width > 414 {
            // backButton to the center
            // labels to center, center
            let optimal_height = UIHelpers.biggestRowHeight * 4 + UIHelpers.margin * 6 + 40
            var row_height: CGFloat
            var bigMargin: CGFloat
            if optimal_height >= size.height {
                row_height = UIHelpers.biggestRowHeight
                bigMargin = (size.height - optimal_height) / 2
            } else {
                bigMargin = UIHelpers.margin
                row_height = (size.height - 40 - 6 * UIHelpers.margin) / 4
            }
            let labelWidth = min(UIHelpers.maxLabelWidth, size.width - 2 * UIHelpers.margin)
            resetHighScoreLabel.adjustLabelFontSizeToFitRect(CGRect(x: UIHelpers.margin, y: bigMargin + UIHelpers.margin + row_height, width: labelWidth, height: row_height), centered: true)
            let calculatedFontSize = min(UIHelpers.maxFontSize, resetHighScoreLabel.fontSize)
            setupLabelTexts()
            resetHighScoreLabel.adjustLabelFontSizeToFitRect(CGRect(x: UIHelpers.margin, y: bigMargin + UIHelpers.margin + row_height, width: labelWidth, height: row_height), centered: true)
            resetHighScoreLabel.fontSize = calculatedFontSize
            row_height = resetHighScoreLabel.frame.height
            bigMargin = (size.height - 7 * UIHelpers.margin - 40 - row_height * 4) / 2
            resetHighScoreLabel.position.x = size.width / 2
            resetHighScoreLabel.position.y = bigMargin + UIHelpers.margin + row_height * 3 / 2
            soundLabel.fontSize = resetHighScoreLabel.fontSize
            soundLabel.position = CGPoint(x: resetHighScoreLabel.frame.minX, y: resetHighScoreLabel.position.y + UIHelpers.margin + row_height)
            musicLabel.fontSize = resetHighScoreLabel.fontSize
            musicLabel.position = CGPoint(x: resetHighScoreLabel.frame.minX, y: resetHighScoreLabel.position.y + 2 * UIHelpers.margin + 2 * row_height)
            
            highScoreLabel.fontSize = resetHighScoreLabel.fontSize
            highScoreLabel.position = CGPoint(x: resetHighScoreLabel.frame.minX, y: resetHighScoreLabel.position.y - UIHelpers.margin - row_height)
            
            backButton.position = CGPoint(x: size.width / 2, y: size.height - bigMargin - 20)
        } else {
            // backButton to the left side
            // labels below it
            let optimal_height = UIHelpers.biggestRowHeight * 4 + UIHelpers.margin * 6 + 40
            var row_height: CGFloat
            var downMargin: CGFloat
            if optimal_height >= size.height {
                row_height = UIHelpers.biggestRowHeight
                downMargin = (size.height - optimal_height)
            } else {
                downMargin = UIHelpers.margin
                row_height = (size.height - 6 * UIHelpers.margin - 40) / 4
            }
            
            let labelWidth = min(UIHelpers.maxLabelWidth, size.width - 2 * UIHelpers.margin)
            resetHighScoreLabel.adjustLabelFontSizeToFitRect(CGRect(x: UIHelpers.margin, y: downMargin + row_height + UIHelpers.margin, width: labelWidth, height: row_height), centered: true)
            let calculatedFontSize = min(UIHelpers.maxFontSize, resetHighScoreLabel.fontSize)
            setupLabelTexts()
            resetHighScoreLabel.adjustLabelFontSizeToFitRect(CGRect(x: UIHelpers.margin, y: downMargin + row_height + UIHelpers.margin, width: labelWidth, height: row_height), centered: true)
            resetHighScoreLabel.fontSize = calculatedFontSize
            row_height = resetHighScoreLabel.frame.height
            downMargin = size.height - 7 * UIHelpers.margin - 40 - row_height * 4
            resetHighScoreLabel.position.x = size.width / 2
            resetHighScoreLabel.position.y = downMargin + UIHelpers.margin + row_height * 3 / 2
            soundLabel.fontSize = resetHighScoreLabel.fontSize
            soundLabel.position = CGPoint(x: resetHighScoreLabel.frame.minX, y: resetHighScoreLabel.position.y + UIHelpers.margin + row_height)
            musicLabel.fontSize = resetHighScoreLabel.fontSize
            musicLabel.position = CGPoint(x: resetHighScoreLabel.frame.minX, y: resetHighScoreLabel.position.y + 2 * UIHelpers.margin + 2 * row_height)

            highScoreLabel.fontSize = resetHighScoreLabel.fontSize
            highScoreLabel.position = CGPoint(x: resetHighScoreLabel.frame.minX, y: resetHighScoreLabel.position.y - UIHelpers.margin - row_height)
            
            backButton.position = CGPoint(x: UIHelpers.margin + 45, y: size.height - UIHelpers.margin - 20)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first!
        let node = nodeAtPoint(touch.locationInNode(self))
        switch node {
        case backButton:
            self.delegate?.intermediateScreenDismissed()
        case soundLabel:
            soundOn = !soundOn
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(soundOn, forKey: PreferencesKeys.soundKey)
            relayout(parentSize: size)
        case musicLabel:
            musicOn = !musicOn
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(musicOn, forKey: PreferencesKeys.musicKey)
            relayout(parentSize: size)
        case resetHighScoreLabel:
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setInteger(0, forKey: PreferencesKeys.highscoreKey)
            gameScoreDelegate?.setHighScore(0)
            setupLabelTexts()
        default:
            break
        }
    }
}
