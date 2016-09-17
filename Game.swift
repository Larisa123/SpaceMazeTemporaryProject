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

enum TutorialState {
	case firstTap
	case secondTap
	case tapToComplete
	case completed
}


class Game {
	var level = 1
	var state: GameState = .tapToPlay
	var tutorialState: TutorialState = .firstTap

	var sounds: [String:SCNAudioSource] = [:]
	var gameViewController: GameViewController!
	
	var newGameCameraSelfieStickNode: SCNNode?
	var newGameCamera: SCNNode?
	
	init(gameViewController: GameViewController) {
		self.gameViewController = gameViewController
		setupRotatingCamera()
		switchToRotatingCamera()
		setupSounds()
	}
	
	
	// Camera (in .TapToPlay mode):
	
	func setupRotatingCamera() {
		newGameCamera = gameViewController.levelScene?.rootNode.childNode(withName: "newGameCamera", recursively: true)
		newGameCameraSelfieStickNode = gameViewController.levelScene?.rootNode.childNode(withName: "newGameCameraSelfieStick reference", recursively: true)
		newGameCamera?.constraints = [SCNLookAtConstraint(target: gameViewController.floor)]
	}
	
	func switchToRotatingCamera() {
		gameViewController.scnView.pointOfView = newGameCamera
		gameViewController.hudScene.hideController()
		gameViewController.hudScene.makeHealthBar(visible: false)
		
		gameViewController.hudScene.setLabel(text: "Tap To Play!")
	}
	
	// Game:
	
	func newGameDisplay(newLevel: Bool) {
		state = .tapToPlay
		
		if newLevel {
			self.level += 1
			gameViewController.setupSceneLevel(level)
			gameViewController.playerClass.setupThePlayer()
			gameViewController.playerClass.setupPlayersCamera()
			gameViewController.setupNodes() // We have to set them again, because we changed the scene
			setupRotatingCamera() //the camera that is set is not the right one!
			switchToRotatingCamera()
			gameViewController.scnView.overlaySKScene = gameViewController.hudScene
			gameViewController.hudScene.restoreHealthToFull()
			gameViewController.hudScene.setLabel(text: "Level \(level-1) cleared!\nTap To Play!")
		} else {
			gameViewController.hudScene.setLabel(text: "Game Over!\nTap To Play Again!")
			gameViewController.playerClass.resetPlayersPosition()
		}
		
		//level cleared and restart the game should have diffrent labels
		gameViewController.scnView.pointOfView = newGameCamera
		gameViewController.hudScene.restoreHealthToFull()
	}
	
	func startTheGame() {
		gameViewController.scnView.pointOfView = gameViewController.playerClass.camera
		gameViewController.hudScene.hideLabel()
		gameViewController.hudScene.showController()
		gameViewController.playerClass.resetPlayersPosition()
		gameViewController.hudScene.restoreHealthToFull()
		gameViewController.hudScene.makeHealthBar(visible: true)
		
		state = .play
		if level == 1 { tutorial() }
	}
	
	func tutorial() {
		switch tutorialState {
		case .firstTap:
			gameViewController.hudScene.setLabel(text: "Tutorial")
			performScalingActionOn(nodes: gameViewController.hudScene.arrowDictionary["right"]!)
		case .secondTap: performScalingActionOn(nodes: gameViewController.hudScene.arrowDictionary["down"]!)
		case .tapToComplete: gameViewController.hudScene.setLabel(text: "You have completed tutorial!\n Tap To Play")
		case .completed: return
		}
	}
	func performScalingActionOn(nodes: [SKSpriteNode]) {
		for node in nodes {
			let scaleUpAndDown = SKAction.sequence([SKAction.scale(to: 1.1, duration: 1.5), SKAction.scale(to: 0.9, duration: 1.5)])
			node.run(SKAction.repeatForever(scaleUpAndDown))
		}
	}
	func tutorialNextStep(stopActionForName name: String) {
		for node in gameViewController.hudScene.arrowDictionary[name]! {
			node.removeAllActions()
			node.size = CGSize(width: 75, height: 75)
		}
		
		if gameViewController.game.tutorialState == .firstTap { gameViewController.game.tutorialState = .secondTap }
		else if gameViewController.game.tutorialState == .secondTap { gameViewController.game.tutorialState = .tapToComplete }
		gameViewController.game.tutorial()
	}
	
	func gameOver() {
		state = .gameOver
		newGameDisplay(newLevel: false)
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
			playSound(node: gameViewController.playerClass.scnNode, name: "PowerUp")
			
		} else if nodeMask == PhysicsCategory.Enemy {
			node.runAction(SCNAction.waitForDurationThenRunBlock(12.0) { node in node.isHidden = false })
			gameViewController.playerClass.cameraShake()
			gameViewController.playerClass.animateTransparency()
			playSound(node: gameViewController.playerClass.scnNode, name: "PowerDown")
			gameViewController.hudScene.changeHealth(collidedWithPearl: false)
		}
	}
	func collisionWithWinningPearl(_ pearl: SCNNode) {
		if tutorialState == .tapToComplete {
			tutorialState = .completed
			tutorial()
			state = .tapToPlay
			return
		}
		
		playSound(node: gameViewController.playerClass.scnNode, name: "LevelUp")
		newGameDisplay(newLevel: true) //sets pointOfView: newGameCamera, hides controller, sets state to .TapToPlay, restores health
		//add explosion particle system
	}
	
	func createExplosion(_ explosion: SCNParticleSystem, node: SCNNode, withGeometry geometry: SCNGeometry, atPosition position: SCNVector3) {
		let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
		explosion.emitterShape = geometry
		
		gameViewController.levelScene?.addParticleSystem(explosion, transform: translationMatrix)	
	}
	
	//Sounds:
	
	func loadSound(_ name:String, fileNamed:String) {
		let sound = SCNAudioSource(fileNamed: fileNamed)!
		sound.load()
		sounds[name] = sound
	}
	
	func playSound(node:SCNNode?, name:String) {
		if node != nil {
			if let sound = sounds[name] { node!.runAction(SCNAction.playAudio(sound, waitForCompletion: true)) }
		}
	}
	
	func setupSounds() {
		loadSound("WallCrash", fileNamed: "art.scnassets/Sounds/WallCrash.wav")
		loadSound("PowerDown", fileNamed: "art.scnassets/Sounds/Explosion.wav")
		loadSound("LevelUp", fileNamed: "art.scnassets/Sounds/LevelUp.mp3")
		loadSound("PowerUp", fileNamed: "art.scnassets/Sounds/PowerUp.mp3")
	}
}
