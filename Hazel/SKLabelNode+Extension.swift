//
//  SKLabelNode+Extension.swift
//  Hazel
//
//  Created by Simon Racz on 15/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import SpriteKit

extension SKLabelNode {
    func adjustLabelFontSizeToFitRect(rect: CGRect, centered: Bool = false, maxFontSize: CGFloat = 100) {
        // Determine the font scaling factor that should let the label text fit in the given rectangle.
        let scalingFactor = min(rect.width / self.frame.width, rect.height / self.frame.height)
        
        // Change the fontSize.
        let fontSize = self.fontSize * scalingFactor
        
        self.fontSize = min(fontSize, maxFontSize)
        
        // Optionally move the SKLabelNode to the center of the rectangle.
        if centered {
            self.position = CGPoint(x: rect.midX, y: rect.midY)
        }
    }

}
