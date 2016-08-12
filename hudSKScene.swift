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
	var game: Game!
	var scnView: SCNView!
	var levelScene: SCNScene!
	var player: SCNNode!
	
	init(size: CGSize, scnView: SCNView, levelScene: SCNScene, game: Game) {
		super.init(size: size)
		
		self.game = game

		self.scnView = scnView
		self.levelScene = levelScene

		
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
		switch game.state {
		case .TapToPlay:
			game.newGame()
		case .Play:
			for touch in touches {
				game.playerClass.moving = true
				if touch.locationInView(scnView).y > scnView.center.y + 50.0 { game.playerClass.direction = .Forward }
				else if touch.locationInView(scnView).y < scnView.center.y - 50.0 { game.playerClass.direction = .Backward }
				else if touch.locationInView(scnView).x > scnView.center.x + 20.0 { game.playerClass.direction = .Right }
				else if touch.locationInView(scnView).x < scnView.center.x - 20.0 { game.playerClass.direction = .Left }
				else { game.playerClass.moving = false }
			}
		case .GameOver: game.switchToTapToPlayScene()
		}
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if game.state == GameState.Play { game.playerClass.stopThePlayer() }
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
