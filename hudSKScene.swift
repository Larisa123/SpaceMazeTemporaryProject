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
	var labelNode: SKLabelNode!
	var gameViewController: GameViewController!
	
	var arrows: [SKSpriteNode: SKSpriteNode] = [SKSpriteNode: SKSpriteNode]()
	
	/*
	var arrowUp: SKSpriteNode!
	var arrowRight: SKSpriteNode!
	var arrowDown: SKSpriteNode!
	var arrowLeft: SKSpriteNode!
	*/
	
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
		
		let scale: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 1.5 : 1
		
		setupArrows(scale: scale)
		setupController(scale: scale)
		setupHealthBar(scale: scale)
		setupLabelNode(scale: scale)
	}
	
	func setupController(scale: CGFloat) {
		
		controller = SKSpriteNode(imageNamed: "art.scnassets/circle-grey.png")
		controller.alpha = 0.2
		controller.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		controllerRadius = 65.0 * scale
		controller.size = CGSize(width: controllerRadius*2*scale, height: controllerRadius*2*scale)
		controller.position = CGPoint(x: controllerRadius * 1.2 * scale, y: controllerRadius * 1.2 * scale)
		
		self.addChild(controller)
	}
	
	func setupArrows(scale: CGFloat) {
		let controllerScene = SKScene(fileNamed: "controllerScene.sks")
		
		let arrowsNode = controllerScene?.childNode(withName: "arrows")
		let arrowsPressedNode = controllerScene?.childNode(withName: "arrowsPressed")
		
		let arrowUp = arrowsNode?.childNode(withName: "up") as! SKSpriteNode
		let arrowDown = arrowsNode?.childNode(withName: "down") as! SKSpriteNode
		let arrowLeft = arrowsNode?.childNode(withName: "left") as! SKSpriteNode
		let arrowRight = arrowsNode?.childNode(withName: "right") as! SKSpriteNode
		
		let arrowUpPressed = arrowsPressedNode?.childNode(withName: "upPressed") as! SKSpriteNode
		let arrowDownPressed = arrowsPressedNode?.childNode(withName: "downPressed") as! SKSpriteNode
		let arrowLeftPressed = arrowsPressedNode?.childNode(withName: "leftPressed") as! SKSpriteNode
		let arrowRightPressed = arrowsPressedNode?.childNode(withName: "rightPressed") as! SKSpriteNode
		
		arrows[arrowUp] = arrowUpPressed
		arrows[arrowDown] = arrowDownPressed
		arrows[arrowLeft] = arrowLeftPressed
		arrows[arrowRight] = arrowRightPressed
		
		let arrowsCenter = CGPoint(x: 130, y: 130)
		arrowsNode?.position = arrowsCenter
		arrowsPressedNode?.position = arrowsCenter
		
		for (arrow, arrowPressed) in arrows {
			arrow.isHidden = true
			arrowPressed.isHidden = true
			arrow.move(toParent: self)
			arrowPressed.move(toParent: self)
		}
	}
	
	//Health bar:
	
	func setupHealthBar(scale: CGFloat) {
		let heartSize =  CGSize(width: 30 * scale, height: 30 * scale)
		
		for i in 0..<3 {
			let heart: SKSpriteNode? = SKSpriteNode(imageNamed: "art.scnassets/heart.png")
			heart?.size = heartSize
			heart?.position = CGPoint(x: heartSize.width + CGFloat(i) * heartSize.width * 1.1, y: gameViewController.deviceSize.height * 0.95)
			heart?.isHidden = true
			if heart != nil {
				hearts.append(heart!)
				addChild(heart!)
			}
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
			if heart.alpha < 0.6 {
				//heart.run(SKAction.fadeAlpha(to: heart.alpha + 0.3, duration: 0.1)) 
				heart.alpha += 0.35
			}
			else { heart.isHidden = false // ?
				//ne vem se (naredit je treba da novega doda)
			}
			lives += 1
		}
	}
	
	func healthDown() {
		for _ in 0..<3 {
			let heart = lives > 6 ? hearts[2] : (lives > 3 ? hearts[1] : hearts[0])
			if heart.alpha > 0.2 {
				//heart.run(SKAction.fadeAlpha(by: 0.3, duration: 0.1))
				heart.alpha -= 0.35
			}
			else { heart.isHidden = true }
			lives -= 1
			if lives == 0 { gameViewController.game.gameOver() }
		}
	}
	
	func hideController() {
		for (arrow, arrowPressed) in arrows {
			arrow.isHidden = true
			arrowPressed.isHidden = true
		}
		controller.isHidden = true
	}
	func showController() {
		for (arrow, arrowPressed) in arrows {
			arrow.isHidden = false
			arrowPressed.isHidden = false
		}
		controller.isHidden = false
	}
	
	//Label:
	
	func setupLabelNode(scale: CGFloat) {
		labelNode = SKLabelNode(fontNamed: "Vollkorn")
		labelNode.fontColor = UIColor.white
		labelNode.fontSize = (scale == 1) ? 36: 72
		labelNode.position = CGPoint(x: gameViewController.deviceSize.width / 2, y: gameViewController.deviceSize.height * 0.9)
		labelNode.isHidden = true
		addChild(labelNode)
	}
	
	func setLabel(text: String) {
		labelNode.text = text
		showLabel()
		let scaleUpAndDown = SKAction.sequence([SKAction.scale(to: 1.1, duration: 1.5), SKAction.scale(to: 0.9, duration: 1.5)])
		labelNode.run(SKAction.repeatForever(scaleUpAndDown))
	}
	func hideLabel() { labelNode.isHidden = true }
	func showLabel() { labelNode.isHidden = false }
	
	//Touches:
	
	func isTouchOnTheOutsideEdge(touchLocation: CGPoint) -> Bool {
		return abs(touchLocation.x) > controllerRadius/2 || abs(touchLocation.y) > controllerRadius/2
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		switch gameViewController.game.state {
			case .tapToPlay: gameViewController.game.startTheGame()
			case .play:
				for touch in touches {
					if let spriteAtPoint = atPoint(touch.location(in: self)) as? SKSpriteNode {
						gameViewController.playerClass.moving = true

						let spriteName: String = spriteAtPoint.name!
						
						switch spriteName {
						case "up": gameViewController.playerClass.direction = .forward
						case "down": gameViewController.playerClass.direction = .backward
						case "left": gameViewController.playerClass.direction = .left
						case "right": gameViewController.playerClass.direction = .right
						default:
							gameViewController.playerClass.moving = false
							return
						}
						gameViewController.playerClass.playerRoll()
					}
				}
			case .gameOver: gameViewController.game.newGameDisplay(newLevel: false)
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
