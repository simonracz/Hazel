//
//  ResizableNode.swift
//  Hazel
//
//  Created by Simon Racz on 05/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import SpriteKit

protocol ResizableNode {
    func relayout(parentSize size: CGSize)
}
