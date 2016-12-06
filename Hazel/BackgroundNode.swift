//
//  Background.swift
//  Hazel
//
//  Created by Simon Racz on 05/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import Foundation
import SpriteKit

// Handles the background textures and positioning
class BackgroundNode: SKSpriteNode, ResizableNode {
    private var backgroundTexture: SKTexture!
    var board: BoardNode?
    var curtain: SKSpriteNode?
    var display: DisplayNode?
    var bgTextureRect: CGRect!
    
    init(parentSize size: CGSize) {
        super.init(texture: nil, color: UIColor.purpleColor(), size: size)
        self.relayout(parentSize: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addBoardTouchDelegate(boardTouchDelegate: BoardTouchDelegate) {
        self.display?.boardTouchDelegate = boardTouchDelegate
    }
    
    func addBoardNode(board: BoardNode) {
        self.board = board
        addChild(board)
        self.curtain = SKSpriteNode(texture: nil)
        layoutCurtain()
        self.display = DisplayNode(parentSize: self.curtain!.frame.size)
        self.curtain!.addChild(self.display!)
        addChild(self.curtain!)
    }
    
    private func layoutCurtain() {
        guard let curtain = self.curtain,
              let board = self.board else {
            return
        }
        switch board.placement! {
        case .Bottom:
            let boardFullHeight = board.position.y + board.size.height
            let heightRatio = boardFullHeight / self.size.height
            let sRect = CGRect(x: 0, y: heightRatio, width: 1, height: 1 - heightRatio)
            curtain.texture = SKTexture(rect: subTextureRect(rect: sRect, ofParentRect: self.bgTextureRect), inTexture: self.texture!)
            curtain.position = CGPoint(x: 0, y: boardFullHeight)
            curtain.anchorPoint = CGPoint(x: 0, y: 0)
            curtain.size = CGSize(width: self.size.width, height: self.size.height - boardFullHeight)
        case .Right:
            let boardLeftPosition = board.position.x
            let widthRatio = boardLeftPosition / self.size.width
            let sRect = CGRect(x: 0, y: 0, width: widthRatio, height: 1)
            curtain.texture = SKTexture(rect: subTextureRect(rect: sRect, ofParentRect: self.bgTextureRect), inTexture: self.texture!)
            curtain.position = CGPoint(x: 0, y: 0)
            curtain.anchorPoint = CGPoint(x: 0, y: 0)
            curtain.size = CGSize(width: boardLeftPosition, height: self.size.height)
        case .Left:
            let boardRightPosition = board.position.x + board.size.width
            let widthRatio = 1 - boardRightPosition / self.size.width
            let sRect = CGRect(x: boardRightPosition / self.size.width, y: 0, width: widthRatio, height: 1)
            curtain.texture = SKTexture(rect: subTextureRect(rect: sRect, ofParentRect: self.bgTextureRect), inTexture: self.texture!)
            curtain.position = CGPoint(x: boardRightPosition, y: 0)
            curtain.anchorPoint = CGPoint(x: 0, y: 0)
            curtain.size = CGSize(width: self.size.width - boardRightPosition, height: self.size.height)
        }
    }
    
    private func subTextureRect(rect child: CGRect, ofParentRect parent: CGRect) -> CGRect {
        let nx = parent.origin.x + child.origin.x * parent.width
        let ny = parent.origin.y + child.origin.y * parent.height
        let nw = parent.width * child.width
        let nh = parent.height * child.height
        return CGRect(x: nx, y: ny, width: nw, height: nh)
    }
    
    func relayout(parentSize size: CGSize) {
        let wide = size.width > size.height
        
        if wide {
            self.backgroundTexture = SKTexture(imageNamed: "Background-landscape")
        } else {
            self.backgroundTexture = SKTexture(imageNamed: "Background-portrait")
        }
        
        let tH = self.backgroundTexture.size().height
        let tW = self.backgroundTexture.size().width
        
        let vH = size.height
        let vW = size.width
        
        let textureRatio = tH / tW
        let viewRatio = vH / vW
        
        let bgTexture: SKTexture
        
        switch (textureRatio - viewRatio) {
        case let x where x == 0:
            self.bgTextureRect = CGRect(x: 0, y:0, width: 1, height: 1)
            bgTexture = self.backgroundTexture
        case let x where x > 0:
            let scale = tW / vW;
            let dH = vH * scale
            // Shows the middle part of the landscape texture
            let subTextureRect = CGRect(x: 0, y: 0.5 - (dH / (2 * tH)), width: 1, height: dH/tH)
            self.bgTextureRect = subTextureRect
            bgTexture = SKTexture(rect: subTextureRect, inTexture: self.backgroundTexture)
        case let x where x < 0:
            let scale = tH / vH;
            let dW = vW * scale
            // Shows the middle part of the portrait texture
            let subTextureRect = CGRect(x: 0.5 - (dW / (2 * tW)), y: 0, width: dW/tW, height: 1)
            self.bgTextureRect = subTextureRect
            bgTexture = SKTexture(rect: subTextureRect, inTexture: self.backgroundTexture)
        default:
            // Should never happen
            self.bgTextureRect = CGRect(x: 0, y:0, width: 1, height: 1)
            bgTexture = self.backgroundTexture
        }
        
        self.texture = bgTexture
        self.size = size
        anchorPoint = CGPoint.zero
        position = CGPoint.zero
        
        board?.relayout(parentSize: self.size)
        layoutCurtain()
        if let curtain = self.curtain {
            self.display?.relayout(parentSize: curtain.frame.size)
        }
    }
    
}
