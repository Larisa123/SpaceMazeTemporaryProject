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
	case tapToPlay
	case play
	case gameOver
}


class Game {
	var level = 1
	//var score = 0
	//var highScore = 0
	var livesLeft:Int = 9
	var state: GameState = .tapToPlay
	
	//var HUDScene: SKScene!
	//var controller: SKSpriteNode!
	//var controllerRadius: CGFloat!

	var sounds: [String:SCNAudioSource] = [:]
	var gameViewController: GameViewController!
	
	var cameraNode: SCNNode!
	var newGameCameraSelfieStickNode: SCNNode!
	var newGameCamera: SCNNode!
	
	init(gameViewController: GameViewController) {
		//self.sceneSize = sceneSize
		self.gameViewController = gameViewController
		setupRotatingCamera()
		switchToRotatingCamera()
		setupSounds()
	}
	
	
	// Camera (is .TapToPlay mode):
	
	func setupRotatingCamera() {
		cameraNode = gameViewController.levelScene.rootNode.childNode(withName: "cameraNode", recursively: true)!
		
		newGameCamera = gameViewController.levelScene.rootNode.childNode(withName: "newGameCamera", recursively: true)!
		newGameCameraSelfieStickNode = gameViewController.levelScene.rootNode.childNode(withName: "newGameCameraSelfieStick", recursively: true)!
		newGameCamera.constraints = [SCNLookAtConstraint(target: gameViewController.floor)]
	}
	
	func switchToRotatingCamera() {
		gameViewController.scnView.pointOfView = newGameCamera
		gameViewController.hudScene.hideController()
		gameViewController.hudScene.makeHealthBarVisibleOrInvisible(visible: false)
	}
	
	func cameraShake(_ camera: SCNNode) {
		let left = SCNAction.move(by: SCNVector3(x: -1, y: 0.0, z: 0.0), duration: 0.2)
		let right = SCNAction.move(by: SCNVector3(x: 1, y: 0.0, z: 0.0), duration: 0.2)
		let up = SCNAction.move(by: SCNVector3(x: 0.0, y: 1, z: 0.0), duration: 0.2)
		let down = SCNAction.move(by: SCNVector3(x: 0.0, y: -1, z: 0.0), duration: 0.2)
				
		camera.runAction(SCNAction.sequence([
			left, up, down, right, left, right, down, up, right, down, left, up,
			left, up, down, right, left, right, down, up, right, down, left, up]))
	}
	
	// Game:
	
	func newGameDisplay(newLevel: Bool) {
		state = .tapToPlay
		
		if newLevel {
			self.level += 1
			//remove the current player, set new scene and all the nodes with new player
			//gameViewController.playerClass.removeThePlayer()
			gameViewController.setupSceneLevel(level)
			gameViewController.playerClass.setupThePlayer()
			gameViewController.playerClass.setupPlayersCamera()
			gameViewController.setupNodes() // We have to set them again, because we changed the scene
			setupRotatingCamera() //the camera that is set is not the right one!
			switchToRotatingCamera()
			gameViewController.scnView.overlaySKScene = gameViewController.hudScene
			//playBackgroundMusic()
			gameViewController.hudScene.restoreHealthToFull()
		}
		
		//level cleared and restart the game should have diffrent labels
		gameViewController.scnView.pointOfView = newGameCamera
		
		//lives = 9
		//do sem dela
	}
	
	func startTheGame() {
		gameViewController.scnView.pointOfView = gameViewController.playerClass.camera
		gameViewController.hudScene.showController()
		gameViewController.hudScene.makeHealthBarVisibleOrInvisible(visible: true)
		
		state = .play
	}
		
	func gameOver() {
		state = .gameOver
	}
	
	func collisionWithNode(_ node: SCNNode) {
		node.isHidden = true

		let nodeMask = node.physicsBody?.categoryBitMask
		let geometry = nodeMask == PhysicsCategory.Pearl ? SCNSphere(radius: 0.1) : SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 1.0)
		let position = node.presentation.position
		let explosion = nodeMask == PhysicsCategory.Pearl ? gameViewController.pearlExplosionParticleSystem : gameViewController.enemyExplosionParticleSystem
		createExplosion(explosion!, node: node,  withGeometry: geometry, atPosition: position)
		
		
		if nodeMask == PhysicsCategory.Pearl {
			node.removeFromParentNode() // otherwise the player can wait on pearls to reappear and collect points
			gameViewController.hudScene.changeHealth(collidedWithPearl: true)
		} else if nodeMask == PhysicsCategory.Enemy {
			node.runAction(SCNAction.waitForDurationThenRunBlock(12.0) { node in node.isHidden = false })
			//cameraShake(gameViewController.playerClass.camera!)
			gameViewController.playerClass.animateTransparency()
			gameViewController.hudScene.changeHealth(collidedWithPearl: false)
		}
	}
	func collisionWithWinningPearl(_ pearl: SCNNode) {
		pearl.removeFromParentNode()
		newGameDisplay(newLevel: true) //pointOfView: newGameCamera, hide controller, state: .TapToPlay, set 10 lives
		//add particle system?
		//do sem dela
	}
	
	func createExplosion(_ explosion: SCNParticleSystem, node: SCNNode, withGeometry geometry: SCNGeometry, atPosition position: SCNVector3) {
		let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
		explosion.emitterShape = geometry
		
		gameViewController.levelScene.addParticleSystem(explosion, transform: translationMatrix) //potem nastavi da bo node ekspolidro, ne levelScene?
		
	}
	
	//Sounds:
	
	func loadSound(_ name:String, fileNamed:String) {
		let sound = SCNAudioSource(fileNamed: fileNamed)!
		sound.load()
		sounds[name] = sound
	}
	
	func playSound(node:SCNNode, name:String) {
		//let sound = sounds[name]
		//node.runAction(SCNAction.playSound(sound!, waitForCompletion: false))
	}
	
	func playBackgroundMusic() {
		//let sound = sounds["background"]
		//gameViewController.playerClass.scnNode.runAction(SCNAction.repeatActionForever(SCNAction.playAudioSource(sound!, waitForCompletion: true)))
		
		//game crashes when the music is playing
	}
	
	func setupSounds() {
		loadSound("wallCrash", fileNamed: "art.scnassets/Sounds/projectileHit.wav") // I have to fix it so it only plays once and more quitely
		loadSound("background", fileNamed: "art.scnassets/Sounds/Puzzle-Game_Looping.mp3")
	}
	
	// Scoring?:
	
	/*
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
	}*/
}
