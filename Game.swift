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
	var gameViewController: GameViewController!
	
	var cameraNode: SCNNode!
	var newGameCameraSelfieStickNode: SCNNode!
	var newGameCamera: SCNNode!
	
	init(gameViewController: GameViewController) {
		//self.sceneSize = sceneSize
		self.gameViewController = gameViewController
		setupHUD()
		setupCamera()
		setupRotatingCamera()
		setupSounds()
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
		controller.hidden = true
		
		HUDScene.addChild(controller)
	}
	
	// Camera (is .TapToPlay mode):
	
	func setupCamera() {
		cameraNode = gameViewController.levelScene.rootNode.childNodeWithName("cameraNode", recursively: true)!
		
		newGameCamera = gameViewController.levelScene.rootNode.childNodeWithName("newGameCamera", recursively: true)!
		newGameCameraSelfieStickNode = gameViewController.levelScene.rootNode.childNodeWithName("newGameCameraSelfieStick", recursively: true)!
		newGameCamera.constraints = [SCNLookAtConstraint(target: gameViewController.floor)]
	}
	
	func setupRotatingCamera() {
		gameViewController.scnView.pointOfView = newGameCamera
		
		//floor.addParticleSystem(starsParticleSystem)
	}
	
	// Game:
	
	func newGameDisplay() {
		//level cleared and restart the game should have diffrent labels
		print("new game display")
		gameViewController.scnView.pointOfView = newGameCamera
		controller.hidden = true
		
		state = .TapToPlay
		lives = 10
	}
	
	func startTheGame() {
		gameViewController.scnView.pointOfView = gameViewController.playerClass.camera
		controller.hidden = false
		
		state = .Play
	}
	
	func switchToTapToPlayScene() {
		state = .TapToPlay
		controller.hidden = true //in .TapToPlay, we shoudnt be able to see the controller
		lives = 10
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
			gameViewController.playerClass.animateTransparency()
			lives -= 2
		}
	}
	func collisionWithWinningPearl(pearl: SCNNode) {
		newGameDisplay() //pointOfView: newGameCamera, hide controller, state: .TapToPlay, set 10 lives
		//add particle system?
		pearl.removeFromParentNode()
		
		gameViewController.setupSceneLevel(level + 1, gameSet: true)
	}
	
	func createExplosion(explosion: SCNParticleSystem, withGeometry geometry: SCNGeometry, atPosition position: SCNVector3) {
		let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
		explosion.emitterShape = geometry
		
		gameViewController.levelScene.addParticleSystem(explosion, withTransform: translationMatrix)
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
	
	func playBackgroundMusic() {
		//let sound = sounds["background"]
		//gameViewController.playerClass.scnNode.runAction(SCNAction.repeatActionForever(SCNAction.playAudioSource(sound!, waitForCompletion: true)))
		
		//game crashes when music is playing
	}
	
	func setupSounds() {
		loadSound("wallCrash", fileNamed: "art.scnassets/Sounds/projectileHit.wav") // I have to fix it so it only plays once and more quitely
		loadSound("background", fileNamed: "art.scnassets/Sounds/Puzzle-Game_Looping.mp3")
	}
	
	// Scoring?:
	
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
