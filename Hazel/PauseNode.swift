//
//  PauseNode.swift
//  Hazel
//
//  Created by Simon Racz on 15/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import SpriteKit

class PauseNode: SKSpriteNode, ResizableNode {
    var label: SKLabelNode
    weak var delegate: ModalDialogDelegate?
    
    init(parentSize size: CGSize) {
        self.label = SKLabelNode(text: "Tap anywhere to play")
        super.init(texture: nil, color: UIGlobals.bgColor, size: size)
        label.fontColor = UIGlobals.fontColor
        label.fontName = UIGlobals.fontName
        label.verticalAlignmentMode = .Center
        addChild(label)
        self.relayout(parentSize: size)
        userInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showScreen(parentSize: CGSize) {
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
        
        label.adjustLabelFontSizeToFitRect(CGRect(x: UIGlobals.margin, y: 0, width: size.width - 2 * UIGlobals.margin, height: size.height), centered: true, maxFontSize: UIGlobals.maxFontSize)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.delegate?.intermediateScreenDismissed()
    }
}
