//
//  hudSKScene.swift
//  LabirintTest
//
//  Created by Lara Carli on 8/11/16.
//  Copyright © 2016 Larisa Carli. All rights reserved.
//

import SpriteKit
import SceneKit

class hudSKSScene: SKScene {
	var controller: SKSpriteNode!
	var controllerRadius: CGFloat!
	var gameViewController: GameViewController!
	
	init(gameViewController: GameViewController) {
		super.init(size: CGSizeMake(600, 300))
		self.gameViewController = gameViewController
		
		//setup the overlay scene
		self.backgroundColor = UIColor.redColor()
		self.anchorPoint = CGPointZero
		//automatically resize to fill the viewport
		self.scaleMode = .ResizeFill
		//make UI larger on iPads
		//var iPad: Bool = (UIDevice.currentDevice().userInterfaceIdiom() == .Pad)
		//var scale: Float = iPad ? 1.5 : 1
		//myImage.xScale = 0.8 * scale
		//myImage.yScale = 0.8 * scale
		
		controller = SKSpriteNode(imageNamed: "art.scnassets/circle-grey.png")
		controller.anchorPoint = CGPointZero
		controllerRadius = 60.0
		controller.size = CGSizeMake(controllerRadius*2, controllerRadius*2)
		controller.position = CGPointMake(30, 30)
		controller.zPosition = 10
		
		//size je 368x664?

		//controller.position = CGPointMake(10, 10)
		
		self.addChild(controller)
	}
	
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		switch gameViewController.game.state {
		case .TapToPlay: gameViewController.game.startTheGame()
		case .Play:
			for touch in touches {
				let touchLocationInView = touch.locationInView(gameViewController.scnView)
				gameViewController.playerClass.moving = true
				
				if touchLocationInView.y > gameViewController.scnView.center.y + 50.0 {
					gameViewController.playerClass.direction = .Forward
				}
				else if touchLocationInView.y < gameViewController.scnView.center.y - 50.0 {
					gameViewController.playerClass.direction = .Backward
				}
				else if touchLocationInView.x > gameViewController.scnView.center.x + 20.0 {
					gameViewController.playerClass.direction = .Right
				}
				else if touchLocationInView.x < gameViewController.scnView.center.x - 20.0 {
					gameViewController.playerClass.direction = .Left
				}
				else { gameViewController.playerClass.moving = false }
			}
			if gameViewController.playerClass.moving {
				gameViewController.playerClass.playerRoll()
				//playerClass.updateCameraBasedOnPlayerDirection()
			}
		case .GameOver: gameViewController.game.switchToTapToPlayScene()
		}
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if gameViewController.game.state == GameState.Play {
			gameViewController.playerClass.stopThePlayer()
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
