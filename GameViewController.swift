//
//  GameViewController.swift
//  LabirintTest
//
//  Created by Lara Carli on 7/28/16.
//  Copyright (c) 2016 Larisa Carli. All rights reserved.
//


	
import UIKit
import SceneKit
import Darwin
import SpriteKit
import ModelIO


enum PhysicsCategory: Int {
	case None = 0
	case Player = 0b1 //1
	case Wall = 0b10 //2
	case Pearl = 0b100 //4
	case WinningPearl = 0b1000
	case Floor = 0b10000
	case Enemy = 0b100000
}

enum GameState {
	case TapToPlay
	case Play
	case GameOver
}


class GameViewController: UIViewController {
	var currentLevel: Int = 0
	
	var scnView: SCNView!
	var levelScene: SCNScene!
	var floor: SCNNode!
	var cameraNode: SCNNode!
	
	// to se je treba prestavit?
	var playerCamera: SCNNode! //camera that follows the player
	var playerSpotLight: SCNNode! //light that shines on the player
	//
	
	var enemyExplosionParticleSystem: SCNParticleSystem!
	var pearlExplosionParticleSystem: SCNParticleSystem!
	
	var newGameCameraSelfieStickNode: SCNNode!
	var newGameCamera: SCNNode!
	
	var playerNode: SCNNode! //parent of player and playerSpotLight
	var playerClass: Player!
	var player: SCNNode!
	
	//HUD
	//var skHUDScene: SKScene!
	//var directionsNode: SKLabelNode!
	
	//gameplay variables
	var gameState = GameState.TapToPlay
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupView()
		setupSceneLevel(2)
		setupHUD()
		setupNodes()
		setupRotatingCamera()
	}
	
	func setupView() {
		scnView = self.view as! SCNView
		scnView.delegate = self
	}
	
	func setupSceneLevel(level: Int) {
		levelScene = sceneBasedOnLevel(level)!
		scnView.scene = levelScene
		
		levelScene.physicsWorld.contactDelegate = self
	}
	
	func sceneBasedOnLevel(levelNumber: Int) -> SCNScene? {
		let scene = SCNScene(named: "Level\(levelNumber).scn")
		currentLevel = levelNumber
		return scene
	}
	
	func setupHUD() {
		//skHUDScene = SKScene(fileNamed: "art.scnassets/displaySKScene.sks")
		
		//scnView.overlaySKScene = skHUDScene
	}
	
	func setupNodes() {
		// player
		playerClass = Player(viewController: self, scene: levelScene)
		player = playerClass.scnNode
		
		levelScene.rootNode.enumerateChildNodesUsingBlock { node, stop in
			if node.name == "wallObject reference" {
				node.physicsBody = SCNPhysicsBody(type: .Kinematic, shape: SCNPhysicsShape(geometry: SCNBox(width: 0.1, height: 0.5, length: 0.5, chamferRadius: 1.0) , options: nil))
				node.physicsBody?.categoryBitMask = PhysicsCategory.Wall.rawValue
				node.physicsBody?.collisionBitMask = PhysicsCategory.Player.rawValue
				node.physicsBody?.contactTestBitMask = PhysicsCategory.Player.rawValue
				node.name = "wall"
			}
			if self.currentLevel > 1 { //level 1 has no pearls or enemys
				if node.name == "pearl reference" {
					node.physicsBody = SCNPhysicsBody(type: .Static, shape: nil)
					node.physicsBody?.categoryBitMask = PhysicsCategory.Pearl.rawValue
					node.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
					node.physicsBody?.contactTestBitMask = PhysicsCategory.Player.rawValue
					node.name = "pearl"
				}
				if node.name == "enemy reference" {
					node.physicsBody = SCNPhysicsBody(type: .Kinematic, shape: nil)
					node.physicsBody?.categoryBitMask = PhysicsCategory.Enemy.rawValue
					node.physicsBody?.collisionBitMask = PhysicsCategory.None.rawValue
					node.physicsBody?.contactTestBitMask = PhysicsCategory.Player.rawValue
					node.name = "enemy"
				}
			}
		}
		
		floor = levelScene.rootNode.childNodeWithName("floorObject reference", recursively: true)!
		floor.physicsBody = SCNPhysicsBody(type: .Static, shape: nil)
		floor.physicsBody?.categoryBitMask = PhysicsCategory.Floor.rawValue
		floor.physicsBody?.collisionBitMask = PhysicsCategory.Player.rawValue
		
		
		//particle systems:
		enemyExplosionParticleSystem = SCNParticleSystem(named: "enemyExplodeParticleSystem.scnp", inDirectory: "art.scnassets")!
		pearlExplosionParticleSystem = SCNParticleSystem(named: "pearlExplodeParticleSystem.scnp", inDirectory: "art.scnassets")!
		
		
		// camera and lights
		cameraNode = levelScene.rootNode.childNodeWithName("cameraNode", recursively: true)!
		playerCamera = levelScene.rootNode.childNodeWithName("playerCamera", recursively: true)!
		playerSpotLight = levelScene.rootNode.childNodeWithName("playerSpotLight", recursively: true)!
		
		playerCamera.constraints = [SCNLookAtConstraint(target: player.presentationNode)]
		playerSpotLight.constraints = [SCNLookAtConstraint(target: player.presentationNode)]
		
		newGameCamera = levelScene.rootNode.childNodeWithName("newGameCamera", recursively: true)!
		newGameCameraSelfieStickNode = levelScene.rootNode.childNodeWithName("newGameCameraSelfieStick", recursively: true)!
		newGameCamera.constraints = [SCNLookAtConstraint(target: floor)]
	}
	
	func newGame() {
		scnView.pointOfView = playerCamera
		gameState = .Play
	}
	
	func switchToTapToPlayScene() {
		gameState = .TapToPlay
		setupRotatingCamera()
	}
	
	func setupRotatingCamera() {
		scnView.pointOfView = newGameCamera
		//level1Scene.paused = true
	}
	
	func updateCameraBasedOnPlayerDirection() {
		cameraNode.position = player.presentationNode.position
		
		//if player changed direction, we have to rotate the cameraNode (a selfie stick for playerCamera)
		let playerDirectionUnchanged = playerClass.cameraDirection == playerClass.cameraDirection
		if !playerDirectionUnchanged {
			let rotateAction = playerClass.updateCameraDirection()
			cameraNode.runAction(rotateAction)
		}
	}
	
	func gameOver() {
		gameState = .GameOver
	}
	
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		switch gameState {
		case .TapToPlay:
			newGame()
		case .Play:
			for touch in touches {
				playerClass.moving = true
				if touch.locationInView(scnView).y > scnView.center.y + 50.0 { playerClass.direction = .Forward }
				else if touch.locationInView(scnView).y < scnView.center.y - 50.0 { playerClass.direction = .Backward }
				else if touch.locationInView(scnView).x > scnView.center.x + 20.0 { playerClass.direction = .Right }
				else if touch.locationInView(scnView).x < scnView.center.x - 20.0 { playerClass.direction = .Left }
				else {playerClass.moving = false}
			}
		case .GameOver: switchToTapToPlayScene()
		}
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		playerClass.moving = false
		player.physicsBody?.velocity = SCNVector3Zero
		player.physicsBody?.angularVelocity = SCNVector4Zero
	}
	
	override func shouldAutorotate() -> Bool { return true }
	
	override func prefersStatusBarHidden() -> Bool { return true }
}

extension GameViewController: SCNSceneRendererDelegate {
	
	func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
		if gameState == .TapToPlay {newGameCameraSelfieStickNode.eulerAngles.y += 0.002 }
		if gameState == .Play {
			if playerClass.moving {
				playerClass.playerRoll()
				updateCameraBasedOnPlayerDirection()
			}
		}
	}
}

extension GameViewController: SCNPhysicsContactDelegate {
	
	func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
		if gameState == .Play {
			//playerNode.physicsBody?.velocity = SCNVector3Zero
			let otherNode: SCNNode!
			
			if contact.nodeA.categoryBitMask == PhysicsCategory.Player.rawValue { otherNode = contact.nodeB }
			else { otherNode = contact.nodeA }
			
			if otherNode.name == "wall" {
				//bounce off
			} else if currentLevel > 1 && (otherNode.name == "pearl" || otherNode.name == "enemy") { playerClass.collisionWithNode(otherNode) }
			//if otherNode.name == "pearl" { setupSceneLevel(1) }
		}
	}
}

