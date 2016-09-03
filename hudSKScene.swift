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
		super.init(size: CGSize(width: 600, height: 300))
		self.gameViewController = gameViewController
		
		//setup the overlay scene
		self.anchorPoint = CGPoint.zero
		//automatically resize to fill the viewport
		self.scaleMode = .resizeFill
		//make UI larger on iPads
		//var iPad: Bool = (UIDevice.currentDevice().userInterfaceIdiom() == .Pad)
		//var scale: Float = iPad ? 1.5 : 1
		//myImage.xScale = 0.8 * scale
		//myImage.yScale = 0.8 * scale
		
		controller = SKSpriteNode(imageNamed: "art.scnassets/circle-grey.png")
		controller.alpha = 0.3
		controller.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		controllerRadius = 65.0
		controller.size = CGSize(width: controllerRadius*2, height: controllerRadius*2)
		controller.position = CGPoint(x: controllerRadius + 10.0, y: controllerRadius + 10.0)
		controller.zPosition = 10
		
		//size je 368x664?
		self.addChild(controller)
	}
	
	func hideController() { controller.isHidden = true }
	func showController() { controller.isHidden = false }
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		switch gameViewController.game.state {
			case .tapToPlay: gameViewController.game.startTheGame()
			case .play:
				for touch in touches {
					if (atPoint(touch.location(in: self)) == controller) {
						let touchLocationInController = touch.location(in: controller)
						
						gameViewController.playerClass.moving = true
						
						if touchLocationInController.y > 10.0 {
							gameViewController.playerClass.direction = .forward
						}
						else if touchLocationInController.y < -10.0 {
							gameViewController.playerClass.direction = .backward
						}
						else if touchLocationInController.x > 10.0 {
							gameViewController.playerClass.direction = .right
						}
						else if touchLocationInController.x < -10.0 {
							gameViewController.playerClass.direction = .left
						}
						else { gameViewController.playerClass.moving = false }
						
						if gameViewController.playerClass.moving {
							gameViewController.playerClass.playerRoll()
							//playerClass.updateCameraBasedOnPlayerDirection()
						}
					}
				}
			case .gameOver: break //gameViewController.game.switchToTapToPlayScene()
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		gameViewController.game.newGameDisplay(newLevel: true)
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		if gameViewController.game.state == GameState.play {
			gameViewController.playerClass.stopThePlayer()
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
