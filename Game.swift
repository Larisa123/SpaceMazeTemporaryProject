//
//  HUDScene.swift
//  LabirintTest
//
//  Created by Lara Carli on 8/11/16.
//  Copyright © 2016 Larisa Carli. All rights reserved.
//

import SpriteKit
import SceneKit

enum GameState {
	case TapToPlay
	case Play
	case GameOver
}


class Game {
	var level = 1
	var score = 0
	var highScore = 0
	var lives:Int = 10
	var state: GameState = .TapToPlay
	
	var HUDScene: SKScene!
	var controller: SKSpriteNode!
	var controllerRadius: CGFloat!

	var sounds: [String:SCNAudioSource] = [:]
	var scnView: SCNView!
	var gameViewController: GameViewController!
	var playerClass: Player!
	var levelScene: SCNScene!
	
	var cameraNode: SCNNode!
	var newGameCameraSelfieStickNode: SCNNode!
	var newGameCamera: SCNNode!
	
	init(scnView: SCNView, levelScene: SCNScene, gameViewController: GameViewController) {
		//self.sceneSize = sceneSize
		self.scnView = scnView
		self.levelScene = levelScene
		self.gameViewController = gameViewController
		self.playerClass = gameViewController.playerClass
	}
	
	// Setups:
	
	func setupCamera() {
		cameraNode = levelScene.rootNode.childNodeWithName("cameraNode", recursively: true)!
		
		newGameCamera = levelScene.rootNode.childNodeWithName("newGameCamera", recursively: true)!
		newGameCameraSelfieStickNode = levelScene.rootNode.childNodeWithName("newGameCameraSelfieStick", recursively: true)!
		newGameCamera.constraints = [SCNLookAtConstraint(target: gameViewController.floor)]
	}
	
	func setupHUD() {
		HUDScene = SKScene()
		
		HUDScene.size = CGSizeMake(1000, 500)
		HUDScene.scaleMode = .ResizeFill
		HUDScene.anchorPoint = CGPointMake(0, 0)
		
		controller = SKSpriteNode(imageNamed: "art.scnassets/controller.png")
		controller.anchorPoint = CGPointZero
		//controllerRadius = sceneSize * 0.25
		controllerRadius = 50.0
		controller.size = CGSizeMake(controllerRadius*2, controllerRadius*2)
		controller.position = CGPointMake(10, 10)
		controller.zPosition = 15
		
		HUDScene.addChild(controller)
	}
	
	// Camera:
	
	func updateCameraBasedOnPlayerDirection() {
		cameraNode.position = playerClass.scnNode.presentationNode.position
		
		//if player changed direction, we have to rotate the cameraNode (a selfie stick for playerCamera)
		let playerDirectionUnchanged = playerClass.cameraDirection == playerClass.cameraDirection
		if !playerDirectionUnchanged {
			let rotateAction = playerClass.updateCameraDirection()
			cameraNode.runAction(rotateAction)
		}
	}
	
	func setupRotatingCamera() {
		scnView.pointOfView = newGameCamera
		setupHUD()
		
		//floor.addParticleSystem(starsParticleSystem)
	}
	
	// Game:
	
	func newGame() {
		//scnView.pointOfView = playerClass.camera
		
		// fatal error: playerClass.camera = nil?
		
		state = .Play
		lives = 10
	}
	
	func switchToTapToPlayScene() {
		state = .TapToPlay
		setupRotatingCamera()
	}
		
	func gameOver() {
		state = .GameOver
	}
	
	func collisionWithNode(node: SCNNode) {
		let geometry = node.categoryBitMask == PhysicsCategory.Pearl ? SCNSphere(radius: 0.1) : SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 1.0)
		let position = node.presentationNode.position
		let explosion = node.categoryBitMask == PhysicsCategory.Pearl ? gameViewController.pearlExplosionParticleSystem : gameViewController.enemyExplosionParticleSystem
		createExplosion(explosion, withGeometry: geometry, atPosition: position)
		
		node.hidden = true
		node.runAction(SCNAction.waitForDurationThenRunBlock(12.0) { node in node.hidden = false })
		
		if node.categoryBitMask == PhysicsCategory.Pearl {
			node.removeFromParentNode() // unless the player can wait on pearls to reappear and collect points
			lives += 1
		} else if node.categoryBitMask == PhysicsCategory.Enemy {
			playerClass.animateTransparency()
			lives -= 2
		}
	}
	func collisionWithWinningPearl(pearl: SCNNode) {
		//add particle system
		pearl.removeFromParentNode()
		
		gameViewController.setupSceneLevel(level + 1, gameSet: true)
		gameViewController.setupNodes()
	}
	
	func createExplosion(explosion: SCNParticleSystem, withGeometry geometry: SCNGeometry, atPosition position: SCNVector3) {
		let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
		explosion.emitterShape = geometry
		
		levelScene.addParticleSystem(explosion, withTransform: translationMatrix)
	}
	
	//Sounds:
	
	func loadSound(name:String, fileNamed:String) {
		let sound = SCNAudioSource(fileNamed: fileNamed)!
		sound.load()
		sounds[name] = sound
	}
	
	func playSound(node:SCNNode, name:String) {
		let sound = sounds[name]
		node.runAction(SCNAction.playAudioSource(sound!, waitForCompletion: false))
	}
	
	func setupSounds() {
		loadSound("wallCrash", fileNamed: "art.scnassets/Sounds/projectileHit.flac")
		
	}
	
	// Scoring:
	
	func bestScore() -> Int {
		return NSUserDefaults.standardUserDefaults().integerForKey("BestScore")
	}
	
	func setBestScore(bestScore: Int) {
		NSUserDefaults.standardUserDefaults().setInteger(bestScore, forKey: "BestScore")
		NSUserDefaults.standardUserDefaults().synchronize()
	}
	
	func saveState() {
		highScore = max(score, highScore)
		let defaults = NSUserDefaults.standardUserDefaults()
		defaults.setInteger(highScore, forKey: "highScore")
		NSUserDefaults.standardUserDefaults().synchronize()
	}
	
	func determineBestScore() {
		if score > bestScore() {
			setBestScore(score)
			//congratulations?
		}
	}
}
