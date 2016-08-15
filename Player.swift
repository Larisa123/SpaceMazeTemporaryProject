//
//  Player.swift
//  LabirintTest
//
//  Created by Lara Carli on 8/8/16.
//  Copyright © 2016 Larisa Carli. All rights reserved.
//

import SceneKit
import Darwin

enum PlayerCurrentDirection {
	case Forward, Backward, Right, Left
}

enum CameraCurrentDirection {
	case Forward, Backward, Right, Left
}

let pi = CGFloat(M_PI)


class Player {
	var gameViewController: GameViewController!
	var scnNode: SCNNode!
	var direction: PlayerCurrentDirection = .Forward
	var cameraDirection: CameraCurrentDirection = .Forward
	var velocityMagnitude: Float = 1.5
	var fadeAndIncreaseOpacityAction: SCNAction!
	//var light: SCNNode!
	
	var camera: SCNNode! //camera that follows the player
	var spotLight: SCNNode! //light that shines on the player
	
	var moving = false
	
	init(viewController: GameViewController) {
		self.gameViewController = viewController
		//light = levelScene.rootNode.childNodeWithName("playerLight reference", recursively: true)!
		
		setupThePlayer()
		setupPlayersCamera()
		
		let fadeOpacityAction = SCNAction.fadeOpacityTo(0.2, duration: 0.3)
		let increaseOpacityAction = SCNAction.fadeOpacityTo(1.0, duration: 0.3)
		fadeAndIncreaseOpacityAction = SCNAction.sequence([fadeOpacityAction, increaseOpacityAction])
	}
	
	func setupPlayersCamera() {
		camera = gameViewController.levelScene.rootNode.childNodeWithName("playerCamera", recursively: true)!
		spotLight = gameViewController.levelScene.rootNode.childNodeWithName("playerSpotLight", recursively: true)!
		
		camera.constraints = [SCNLookAtConstraint(target: self.scnNode.presentationNode)]
		spotLight.constraints = [SCNLookAtConstraint(target: self.scnNode.presentationNode)]
	}
	
	//Player animation:
	
	func setupThePlayer() {
		let shape = SCNPhysicsShape(geometry: SCNSphere(radius: 0.15), options: nil)
		self.scnNode = gameViewController.levelScene.rootNode.childNodeWithName("playerObject reference", recursively: true)!
		scnNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: shape)
		scnNode.physicsBody?.affectedByGravity = true
		scnNode.physicsBody?.categoryBitMask = PhysicsCategory.Player
		scnNode.physicsBody?.collisionBitMask = PhysicsCategory.Wall | PhysicsCategory.Floor
		scnNode.physicsBody?.contactTestBitMask = PhysicsCategory.WinningPearl | PhysicsCategory.Pearl | PhysicsCategory.Enemy
	}
	
	func animateTransparency() {
		scnNode.runAction(SCNAction.repeatAction(fadeAndIncreaseOpacityAction, count: 3))
	}
	
	func stopThePlayer() {
		moving = false
		scnNode.physicsBody?.velocity = SCNVector3Zero
		scnNode.physicsBody?.angularVelocity = SCNVector4Zero
	}
	
	func reducePlayerVelocity() {
		let currentVelocity = scnNode.physicsBody!.velocity
		scnNode.physicsBody?.velocity = SCNVector3Make(-currentVelocity.x / 4, 0 , -currentVelocity.z / 4)
	}
	
	func playerRoll() {
		if direction == .Forward {
			scnNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: velocityMagnitude)
			scnNode.physicsBody?.angularVelocity = SCNVector4Make(1, 0, 0, velocityMagnitude * 3.4)
		}
		else if direction == .Backward {
			scnNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: -velocityMagnitude)
			scnNode.physicsBody?.angularVelocity = SCNVector4Make(-1, 0, 0, velocityMagnitude * 3.4)
		}
		else if direction == .Right {
			scnNode.physicsBody?.velocity = SCNVector3(x: velocityMagnitude, y: 0, z: 0)
			scnNode.physicsBody?.angularVelocity = SCNVector4Make(0, 0, -1, velocityMagnitude * 3.4)
		}
		else if direction == .Left {
			scnNode.physicsBody?.velocity = SCNVector3(x: -velocityMagnitude, y: 0, z: 0)
			scnNode.physicsBody?.angularVelocity = SCNVector4Make(0, 0, 1, velocityMagnitude * 3.4)
		}
	}
	
	func removeThePlayer() {
		scnNode.removeAllActions()
		scnNode.removeFromParentNode()
	}
	
	func updateThePlayerInNewScene() {
		setupThePlayer()
	}
	
	//camera:
	
	func updateCameraBasedOnPlayerDirection() {
		camera.position = scnNode.presentationNode.position
		
		//if player changed direction, we have to rotate the cameraNode (a selfie stick for playerCamera)
		let playerDirectionUnchanged = cameraDirection == cameraDirection
		if !playerDirectionUnchanged {
			//updateCameraDirection()
		}
	}
	
	func updateCameraDirection() {
		let rotateAction: SCNAction!
		
		switch cameraDirection {
		case .Forward: rotateAction = SCNAction.rotateToX(0, y: 0, z: 0, duration: 0.1, shortestUnitArc: true)
		case .Backward: rotateAction = SCNAction.rotateToX(0, y: pi, z: 0, duration: 0.1, shortestUnitArc: true)
		case .Right: rotateAction = SCNAction.rotateToX(0, y: -pi/2, z: 0, duration: 0.1, shortestUnitArc: true)
		case .Left: rotateAction = SCNAction.rotateToX(0, y: pi/2, z: 0, duration: 0.1, shortestUnitArc: true)
		}
		camera.runAction(rotateAction)
	}
	
	required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented")}
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
