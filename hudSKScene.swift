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
	
	//Hearts:
	var lives = 9
	var hearts: [SKSpriteNode] = []
	
	
	init(gameViewController: GameViewController) {
		super.init(size: CGSize(width: 600, height: 300))
		self.gameViewController = gameViewController
		
		//setup the overlay scene
		self.anchorPoint = CGPoint.zero
		//automatically resize to fill the viewport
		self.scaleMode = .resizeFill
		
		//make UI larger on iPads:
		let scale: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 1.3 : 1
		
		setupController(scale: scale)
		setupHealthBar(scale: scale)
	}
	
	func setupController(scale: CGFloat) {
		controller = SKSpriteNode(imageNamed: "art.scnassets/circle-grey.png")
		controller.alpha = 0.2
		controller.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		controllerRadius = 65.0 * scale
		controller.size = CGSize(width: controllerRadius*2*scale, height: controllerRadius*2*scale)
		controller.position = CGPoint(x: controllerRadius * 1.2 * scale, y: controllerRadius * 1.2 * scale)
		
		//size je 368x664
		self.addChild(controller)
	}
	
	func setupHealthBar(scale: CGFloat) {
		let heartSize =  CGSize(width: 30 * scale, height: 30 * scale)
		
		for i in 0..<3 {
			let heart = SKSpriteNode(imageNamed: "art.scnassets/heart.png")
			heart.size = heartSize
			heart.position = CGPoint(x: heartSize.width + CGFloat(i) * heartSize.width * 1.1, y: 548 * scale)
			heart.isHidden = true
			hearts.append(heart)
			addChild(heart)
		}
	}
	
	func restoreHealthToFull() {
		for heart in hearts {
			heart.alpha = 1.0
			heart.isHidden = true
		}
		lives = 9
	}
	
	func makeHealthBarVisibleOrInvisible(visible: Bool) {
		for heart in hearts { heart.isHidden = visible ? false: true }
	}
	
	func changeHealth(collidedWithPearl: Bool) {
		if collidedWithPearl { healthUp() }
		else { healthDown() }
	}
	
	func healthUp() {
		if lives < 9 {
			let heart = lives >= 6 ? hearts[2] : (lives >= 3 ? hearts[1] : hearts[0])
			if heart.alpha < 0.7 { heart.run(SKAction.fadeAlpha(to: heart.alpha + 0.3, duration: 0.1)) }
			else {
				//ne vem se (naredit je treba da novega doda)
			}
			lives += 1
		}
	}
	
	func healthDown() {
		for _ in 0..<3 {
			let heart = lives >= 6 ? hearts[2] : (lives >= 3 ? hearts[1] : hearts[0])
			if heart.alpha > 0.4 {
				//heart.run(SKAction.fadeAlpha(by: 0.3, duration: 0.1))
				heart.alpha -= 0.3
			}
			else { heart.isHidden = true }
			lives -= 1
			if lives == 0 { gameViewController.game.gameOver() }
		}
	}
	
	func hideController() { controller.isHidden = true }
	func showController() { controller.isHidden = false }
	
	func isTouchOnTheOutsideEdge(touchLocation: CGPoint) -> Bool {
		return abs(touchLocation.x) > controllerRadius/2 || abs(touchLocation.y) > controllerRadius/2
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		switch gameViewController.game.state {
			case .tapToPlay: gameViewController.game.startTheGame()
			case .play:
				for touch in touches {
					if (atPoint(touch.location(in: self)) == controller) {
						let touchLocationInController = touch.location(in: controller)
						
						if isTouchOnTheOutsideEdge(touchLocation: touchLocationInController) {
							gameViewController.playerClass.moving = true
							
							let angle = atan2(touchLocationInController.y, touchLocationInController.x) * 180 / pi // in degrees
							
							switch angle {
							case -125...(-55): gameViewController.playerClass.direction = .backward
							case -35...35: gameViewController.playerClass.direction = .right
							case 55...125: gameViewController.playerClass.direction = .forward
							case 145...180, -180...(-145): gameViewController.playerClass.direction = .left
							default:
								gameViewController.playerClass.moving = false
								return
							}
							gameViewController.playerClass.playerRoll()
						}
					}
				}
			case .gameOver: gameViewController.game.newGameDisplay(newLevel: false)
		}
	}
	
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		if gameViewController.game.state == .play {
			for touch in touches {
				if (atPoint(touch.location(in: self)) == controller) {
					let touchLocationInController = touch.location(in: controller)
					
					if isTouchOnTheOutsideEdge(touchLocation: touchLocationInController) {
						gameViewController.playerClass.moving = true
						
						let angle = atan2(touchLocationInController.y, touchLocationInController.x) * 180 / pi // in degrees
						switch angle {
						case -125...(-55): gameViewController.playerClass.direction = .backward
						case -35...35: gameViewController.playerClass.direction = .right
						case 55...125: gameViewController.playerClass.direction = .forward
						case 145...180, -180...(-145): gameViewController.playerClass.direction = .left
						default:
							gameViewController.playerClass.moving = false
							return
						}
						gameViewController.playerClass.playerRoll()
					}
				}
			}
		}
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
