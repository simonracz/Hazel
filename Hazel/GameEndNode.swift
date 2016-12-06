//
//  GameEndNode.swift
//  Hazel
//
//  Created by Simon Racz on 15/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import SpriteKit

enum ScoreState {
    case NewHighScore(score: Int)
    case SimpleScore(score: Int)
}

class GameEndNode: SKSpriteNode, ResizableNode {
    static let gemTextures: [GemType: SKTexture] = [
        GemType.Gem1: SKTexture(imageNamed: "cat"),
        GemType.Gem2: SKTexture(imageNamed: "tombstone"),
        GemType.Gem3: SKTexture(imageNamed: "cauldron"),
        GemType.Gem4: SKTexture(imageNamed: "skull"),
        GemType.Gem5: SKTexture(imageNamed: "lantern"),
        GemType.SuperGemBomb: SKTexture(imageNamed: "pumpkin"),
        GemType.SuperGemColor: SKTexture(imageNamed: "pit"),
        GemType.SuperGemLine: SKTexture(imageNamed: "bat")
    ]

    var gem: SKSpriteNode!
    var noticeLabel: SKLabelNode
    var scoreLabel: SKLabelNode
    var tapLabel: SKLabelNode
    var touchEnabled = false
    
    struct UIHelpers {
        static let margin: CGFloat = 10
        static let maxGemWidth: CGFloat = 256
        static let maxLabelWidth: CGFloat = 360
    }
    
    var scoreState: ScoreState = .SimpleScore(score: 0)
    
    weak var delegate: ModalDialogDelegate?
    
    init(parentSize size: CGSize) {
        tapLabel = SKLabelNode(text: "Tap anywhere to play")
        noticeLabel = SKLabelNode()
        scoreLabel = SKLabelNode()
        gem = SKSpriteNode(texture: GameEndNode.gemTextures[GemType.Gem4])
        super.init(texture: nil, color: UIGlobals.bgColor, size: size)
        setupUI()

        self.relayout(parentSize: size)
        userInteractionEnabled = true
    }
    
    func showScreen(score: Int, newHighScore: Bool, parentSize: CGSize) {
        touchEnabled = false
        self.alpha = 0
        let fadeIn = SKAction.fadeInWithDuration(UIGlobals.gameSpeed)
        self.runAction(fadeIn)
        if newHighScore {
            scoreState = .NewHighScore(score: score)
        } else {
            scoreState = .SimpleScore(score: score)
        }
        randomizeGem()
        relayout(parentSize: parentSize)
        tapLabel.alpha = 0
        let enableTouchAction = SKAction.sequence([SKAction.fadeInWithDuration(3 * UIGlobals.gameSpeed), SKAction.runBlock({[weak self] in self?.touchEnabled = true})])
        tapLabel.runAction(enableTouchAction)
    }
    
    func setupUI() {
        tapLabel.fontColor = UIGlobals.fontColor
        noticeLabel.fontColor = UIGlobals.fontColor
        scoreLabel.fontColor = UIGlobals.fontColor

        tapLabel.fontName = UIGlobals.fontName
        noticeLabel.fontName = UIGlobals.fontName
        scoreLabel.fontName = UIGlobals.fontName
        
        tapLabel.verticalAlignmentMode = .Center
        noticeLabel.verticalAlignmentMode = .Center
        scoreLabel.verticalAlignmentMode = .Center
        
        addChild(tapLabel)
        addChild(noticeLabel)
        addChild(scoreLabel)
        
        addChild(gem)
    }
    
    func randomizeGem() {
        let dice = Int(arc4random_uniform(UInt32(GameEndNode.gemTextures.count)))
        for (count, item) in GameEndNode.gemTextures.enumerate() {
            if count == dice {
                gem.texture = item.1
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        let wide = size.width > size.height
        
        switch scoreState {
        case .NewHighScore(let score):
            noticeLabel.text = "New highscore :"
            scoreLabel.text = "\(score)"
        case .SimpleScore(let score):
            noticeLabel.text = "Your score :"
            scoreLabel.text = "\(score)"
        }

        if wide {
            
            let optimal_width = UIHelpers.maxGemWidth + 6 * UIHelpers.margin + UIHelpers.maxLabelWidth
            if size.width >= optimal_width && size.height >= (UIHelpers.maxGemWidth + 4 * UIHelpers.margin) {
                let bigMarginH = (size.width - UIHelpers.maxGemWidth - 2 * UIHelpers.margin - UIHelpers.maxLabelWidth) / 2
                let bigMarginV = (size.height - UIHelpers.maxGemWidth) / 2
                gem.size = CGSize(width: UIHelpers.maxGemWidth, height: UIHelpers.maxGemWidth)
                gem.position = CGPoint(x: bigMarginH + UIHelpers.maxGemWidth / 2, y: bigMarginV + UIHelpers.maxGemWidth / 2)
                
                tapLabel.adjustLabelFontSizeToFitRect(CGRect(x: bigMarginH + UIHelpers.maxGemWidth + 2 * UIHelpers.margin, y: bigMarginV, width: UIHelpers.maxLabelWidth, height: UIHelpers.maxGemWidth / 3 - UIHelpers.margin), centered: true)
                
                noticeLabel.fontSize = tapLabel.fontSize
                scoreLabel.fontSize = tapLabel.fontSize
                
                scoreLabel.position = CGPoint(x: tapLabel.position.x, y: size.height / 2)
                noticeLabel.position = CGPoint(x: tapLabel.position.x, y: scoreLabel.position.y + scoreLabel.frame.height / 2 + UIHelpers.margin + noticeLabel.frame.height / 2)
                tapLabel.position = CGPoint(x: tapLabel.position.x, y: scoreLabel.position.y - scoreLabel.frame.height / 2 - UIHelpers.margin - tapLabel.frame.height / 2)
            } else {
                let gemWidth = (size.width - 6 * UIHelpers.margin) / (1 + UIHelpers.maxLabelWidth / UIHelpers.maxGemWidth)
                let marginV = (size.height - gemWidth) / 2
                
                gem.size = CGSize(width: gemWidth, height: gemWidth)
                gem.position = CGPoint(x: 2 * UIHelpers.margin + gemWidth / 2, y:  marginV + gemWidth / 2)
                
                tapLabel.adjustLabelFontSizeToFitRect(CGRect(x: 4 * UIHelpers.margin + gemWidth, y: marginV, width: size.width - gemWidth - 6 * UIHelpers.margin, height: gemWidth / 3 - UIHelpers.margin), centered: true)
                
                noticeLabel.fontSize = tapLabel.fontSize
                scoreLabel.fontSize = tapLabel.fontSize
                
                scoreLabel.position = CGPoint(x: tapLabel.position.x, y: size.height / 2)
                noticeLabel.position = CGPoint(x: tapLabel.position.x, y: scoreLabel.position.y + scoreLabel.frame.height / 2 + UIHelpers.margin + noticeLabel.frame.height / 2)
                tapLabel.position = CGPoint(x: tapLabel.position.x, y: scoreLabel.position.y - scoreLabel.frame.height / 2 - UIHelpers.margin - tapLabel.frame.height / 2)
            }
        } else {
            let gemWidth = min(UIHelpers.maxGemWidth, (size.height - 7 * UIHelpers.margin) / (3 / 4 + 2))
            let marginV = gemWidth + UIHelpers.margin
            
            gem.size = CGSize(width: gemWidth, height: gemWidth)
            gem.position = CGPoint(x: size.width / 2, y: size.height - 2 * UIHelpers.margin - gemWidth / 2)
            
            tapLabel.adjustLabelFontSizeToFitRect(CGRect(x: UIHelpers.margin, y: marginV, width: size.width - 2 * UIHelpers.margin, height: gemWidth / 4), centered: true)
            
            noticeLabel.fontSize = tapLabel.fontSize
            scoreLabel.fontSize = tapLabel.fontSize
            
            noticeLabel.position = CGPoint(x: size.width / 2, y: gem.position.y - gemWidth / 2 - 2 * UIHelpers.margin - noticeLabel.frame.height / 2)
            scoreLabel.position = CGPoint(x: size.width / 2, y: noticeLabel.position.y - noticeLabel.frame.height / 2 - UIHelpers.margin - scoreLabel.frame.height / 2)
            tapLabel.position.y = scoreLabel.position.y - scoreLabel.frame.height / 2 - UIHelpers.margin - tapLabel.frame.height / 2
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if touchEnabled {
            self.delegate?.intermediateScreenDismissed()
        }
    }
}
