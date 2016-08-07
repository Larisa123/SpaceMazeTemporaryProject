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

enum PlayerCurrentDirection {
	case Forward, Backward, Right, Left
}

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
	let pi = CGFloat(M_PI)
	let stepDistance: Float = 0.5
	var playerDirection = PlayerCurrentDirection.Forward
	var playerMoving = false
	var playerVelocityMagnitude: Float = 2.0
	
	var scnView: SCNView!
	var level1Scene: SCNScene!
	var cameraNode: SCNNode!
	var playerCamera: SCNNode!
	var playerLight: SCNNode!
	var playerSpotLight: SCNNode!
	var enemyExplosionParticleSystem: SCNParticleSystem!
	var pearlExplosionParticleSystem: SCNParticleSystem!
	
	var newGameCameraSelfieStickNode: SCNNode!
	var newGameCamera: SCNNode!
	
	var playerNode: SCNNode!
	var floor: SCNNode!
	
	//HUD
	var skHUDScene: SKScene!
	//var directionsNode: SKLabelNode!
	
	//gameplay variables
	var gameState = GameState.TapToPlay

    override func viewDidLoad() {
        super.viewDidLoad()
		
		setupScene()
		setupHUD()
		setupNodes()
		setupRotatingCamera()
    }
	
	func setupScene() {
		scnView = self.view as! SCNView
		level1Scene = SCNScene(named: "Level1.scn")
		level1Scene.physicsWorld.contactDelegate = self
		scnView.scene = level1Scene

		scnView.delegate = self
		
		scnView.showsStatistics = true
	}
	
	func setupHUD() {
		skHUDScene = SKScene(fileNamed: "art.scnassets/displaySKScene.sks")
		
		//scnView.overlaySKScene = skHUDScene
	}
	
	func setupNodes() {
		// player
		playerNode = level1Scene.rootNode.childNodeWithName("playerNode", recursively: true)!
		playerNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
		playerNode.physicsBody?.affectedByGravity = false
		playerNode.physicsBody?.angularVelocityFactor = SCNVector3Zero // so it can't rotate
		playerNode.physicsBody?.categoryBitMask = PhysicsCategory.Player.rawValue
		playerNode.physicsBody?.collisionBitMask = PhysicsCategory.Wall.rawValue | PhysicsCategory.Floor.rawValue
		playerNode.physicsBody?.contactTestBitMask = PhysicsCategory.Wall.rawValue | PhysicsCategory.Pearl.rawValue | PhysicsCategory.Enemy.rawValue
		
		
		level1Scene.rootNode.enumerateChildNodesUsingBlock { node, stop in
			if node.name == "wallObject reference" {
				node.physicsBody = SCNPhysicsBody(type: .Kinematic, shape: SCNPhysicsShape(geometry: SCNBox(width: 0.1, height: 0.5, length: 0.5, chamferRadius: 1.0) , options: nil))
				node.physicsBody?.categoryBitMask = PhysicsCategory.Wall.rawValue
				node.physicsBody?.collisionBitMask = PhysicsCategory.Player.rawValue
				node.physicsBody?.contactTestBitMask = PhysicsCategory.Player.rawValue
				node.name = "wall"
			}
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
		
		floor = level1Scene.rootNode.childNodeWithName("floorObject reference", recursively: true)!
		floor.physicsBody = SCNPhysicsBody(type: .Static, shape: nil)
		floor.physicsBody?.categoryBitMask = PhysicsCategory.Floor.rawValue
		floor.physicsBody?.collisionBitMask = PhysicsCategory.Player.rawValue
		

		//particle systems:
		enemyExplosionParticleSystem = SCNParticleSystem(named: "enemyExplodeParticleSystem.scnp", inDirectory: "art.scnassets")!
		pearlExplosionParticleSystem = SCNParticleSystem(named: "pearlExplodeParticleSystem.scnp", inDirectory: "art.scnassets")!

		
		// camera and lights
		cameraNode = level1Scene.rootNode.childNodeWithName("cameraNode", recursively: true)!
		playerCamera = level1Scene.rootNode.childNodeWithName("playerCamera", recursively: true)!
		playerLight = level1Scene.rootNode.childNodeWithName("playerLight", recursively: true)!
		playerSpotLight = level1Scene.rootNode.childNodeWithName("playerSpotLight", recursively: true)!
		
		playerCamera.constraints = [SCNLookAtConstraint(target: playerNode.presentationNode)]
		playerSpotLight.constraints = [SCNLookAtConstraint(target: playerNode.presentationNode)]
		
		newGameCamera = level1Scene.rootNode.childNodeWithName("newGameCamera", recursively: true)!
		newGameCameraSelfieStickNode = level1Scene.rootNode.childNodeWithName("newGameCameraSelfieStick", recursively: true)!
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
	
	func createExplosion(explosion: SCNParticleSystem, withGeometry geometry: SCNGeometry, atPosition position: SCNVector3) {
		let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
		explosion.emitterShape = geometry
		
		level1Scene.addParticleSystem(explosion, withTransform: translationMatrix)
	}
	
	func collisionWithNode(node: SCNNode) {
		let geometry = node.name == "pearl" ? SCNSphere(radius: 0.1) : SCNTorus(ringRadius: 0.25, pipeRadius: 0.07)
		let position = node.presentationNode.position
		let explosion = node.name == "pearl" ? pearlExplosionParticleSystem : enemyExplosionParticleSystem
		node.runAction(SCNAction.fadeOutWithDuration(0.1))
		createExplosion(explosion, withGeometry: geometry, atPosition: position)
		
		node.hidden = true
		node.runAction(SCNAction.waitForDurationThenRunBlock(6.0) { node in node.hidden = false })
		
		if node.name == "pearl" {
			// + points?
		} else if node.name == "enemy" {
			//gameOver()
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
				playerMoving = true
				if touch.locationInView(scnView).y > scnView.center.y + 50.0 { playerDirection = .Forward }
				else if touch.locationInView(scnView).y < scnView.center.y - 50.0 { playerDirection = .Backward }
				else if touch.locationInView(scnView).x > scnView.center.x + 20.0 { playerDirection = .Right }
				else if touch.locationInView(scnView).x < scnView.center.x - 20.0 { playerDirection = .Left }
				else {playerMoving = false}
			}
		case .GameOver: switchToTapToPlayScene()
		}
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		 playerMoving = false
		 playerNode.physicsBody?.velocity = SCNVector3Zero
	}
	
    override func shouldAutorotate() -> Bool { return true }
    
    override func prefersStatusBarHidden() -> Bool { return true }
}

extension GameViewController: SCNSceneRendererDelegate {
	
	func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
		if gameState == .TapToPlay {newGameCameraSelfieStickNode.eulerAngles.y += 0.01 }
		if gameState == .Play {
			if playerMoving {
				if playerDirection == .Forward {
					playerNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: playerVelocityMagnitude)
				}
				else if playerDirection == .Backward {
					playerNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: -playerVelocityMagnitude)
				}
				else if playerDirection == .Right {
					playerNode.physicsBody?.velocity = SCNVector3(x: playerVelocityMagnitude, y: 0, z: 0)
				}
				else if playerDirection == .Left {
					playerNode.physicsBody?.velocity = SCNVector3(x: -playerVelocityMagnitude, y: 0, z: 0)
				}
			}
			cameraNode.position = playerNode.presentationNode.position
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
			} else if otherNode.name == "pearl" || otherNode.name == "enemy" { collisionWithNode(otherNode) }
		}
	}
}

extension SCNAction {
	class func waitForDurationThenRemoveFromParent(duration:NSTimeInterval) -> SCNAction {
		let wait = SCNAction.waitForDuration(duration)
		let remove = SCNAction.removeFromParentNode()
		return SCNAction.sequence([wait,remove])
	}
	
	class func waitForDurationThenRunBlock(duration:NSTimeInterval, block: ((SCNNode!) -> Void) ) -> SCNAction {
		let wait = SCNAction.waitForDuration(duration)
		let runBlock = SCNAction.runBlock { (node) -> Void in
			block(node)
		}
		return SCNAction.sequence([wait,runBlock])
	}
}
