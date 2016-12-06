//
//  GameViewController.swift
//  Hazel
//
//  Created by Simon Racz on 27/12/15.
//  Copyright (c) 2015 Simon Racz. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let scene = GameScene(size: self.view.bounds.size)
        scene.scaleMode = .ResizeFill
        
        let skView = self.view as! SKView
        // skView.showsFPS = true
        // skView.showsNodeCount = true
        skView.presentScene(scene)
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .Landscape
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
