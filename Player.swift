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
	case forward, backward, right, left
}

enum CameraCurrentDirection {
	case forward, backward, right, left
}

let pi = CGFloat(M_PI)


class Player {
	var gameViewController: GameViewController!
	var scnNode: SCNNode?
	var nodesStartingPosition: SCNVector3!
	var direction: PlayerCurrentDirection = .forward
	var velocityMagnitude: Float = 1.0
	var fadeAndIncreaseOpacityAction: SCNAction!
	
	var camera: SCNNode? //camera that follows the player
	var cameraNode: SCNNode? //camera selfie stick
	
	var moving = false
	var cameraShaking = false
	
	init(viewController: GameViewController) {
		self.gameViewController = viewController
		
		setupThePlayer()
		nodesStartingPosition = scnNode?.position
		setupPlayersCamera()
		
		let fadeOpacityAction = SCNAction.fadeOpacity(to: 0.2, duration: 0.3)
		let increaseOpacityAction = SCNAction.fadeOpacity(to: 1.0, duration: 0.3)
		fadeAndIncreaseOpacityAction = SCNAction.sequence([fadeOpacityAction, increaseOpacityAction])
	}
	
	func setupPlayersCamera() {
		camera =  gameViewController.levelScene?.rootNode.childNode(withName: "playerCamera", recursively: true)
		cameraNode = gameViewController.levelScene?.rootNode.childNode(withName: "cameraNode reference", recursively: true)
		
		camera?.constraints = [SCNLookAtConstraint(target: self.scnNode?.presentation)]
	}
	
	//Player animation:
	
	func setupThePlayer() {
		self.scnNode = gameViewController.levelScene?.rootNode.childNode(withName: "playerObject reference", recursively: true)
		scnNode?.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
		scnNode?.physicsBody?.isAffectedByGravity = true
		scnNode?.physicsBody?.categoryBitMask = PhysicsCategory.Player
		scnNode?.physicsBody?.collisionBitMask = PhysicsCategory.Wall | PhysicsCategory.Floor
		scnNode?.physicsBody?.contactTestBitMask = PhysicsCategory.WinningPearl | PhysicsCategory.Pearl | PhysicsCategory.Enemy | PhysicsCategory.CornerNode 
	}
	
	func animateTransparency() {
		scnNode?.runAction(SCNAction.repeat(fadeAndIncreaseOpacityAction, count: 3))
	}
	
	func stopThePlayer() {
		moving = false
		scnNode?.physicsBody?.velocity = SCNVector3Zero
		scnNode?.physicsBody?.angularVelocity = SCNVector4Zero
	}
	
	func playerRoll() {
		if direction == .forward {
			scnNode?.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: -velocityMagnitude)
			scnNode?.physicsBody?.angularVelocity = SCNVector4Make(-velocityMagnitude, 0, 0, velocityMagnitude * 3.4)
		}
		else if direction == .backward {
			scnNode?.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: velocityMagnitude)
			scnNode?.physicsBody?.angularVelocity = SCNVector4Make(1, 0, 0, velocityMagnitude * 3.4)
		}
		else if direction == .right {
			scnNode?.physicsBody?.velocity = SCNVector3(x: velocityMagnitude, y: 0, z: 0)
			scnNode?.physicsBody?.angularVelocity = SCNVector4Make(0, 0, -1, velocityMagnitude * 3.4)
		}
		else if direction == .left {
			scnNode?.physicsBody?.velocity = SCNVector3(x: -velocityMagnitude, y: 0, z: 0)
			scnNode?.physicsBody?.angularVelocity = SCNVector4Make(0, 0, velocityMagnitude, velocityMagnitude * 3.4)
		}
	}
	
	func resetPlayersPosition() { scnNode?.position = nodesStartingPosition }
	
	//camera:
	func updateCameraThatFollowsThePlayer() {
		if cameraNode != nil && !cameraShaking {
			if scnNode != nil { cameraNode!.position = (scnNode?.presentation.position)! }
		}
	}
	
	func cameraShake() {
		let shakeAmount: Float = 100
		
		let left = SCNAction.move(by: SCNVector3(x: -shakeAmount, y: 0.0, z: 0.0), duration: 0.2)
		let right = SCNAction.move(by: SCNVector3(x: shakeAmount, y: 0.0, z: 0.0), duration: 0.2)
		let up = SCNAction.move(by: SCNVector3(x: 0.0, y: shakeAmount, z: 0.0), duration: 0.2)
		let down = SCNAction.move(by: SCNVector3(x: 0.0, y: -shakeAmount, z: 0.0), duration: 0.2)
		
		cameraShaking = true
		let cameraStopShaking = SCNAction.run({ _ in self.cameraShaking = false })
		
		camera?.runAction(SCNAction.sequence([
			left, up, down, right, left, right, down, up, right, down, left, up,
			left, up, down, right, left, right, down, up, right, down, left, up,
			cameraStopShaking]))
	}
	
	required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented")}
}

extension SCNAction {
	class func waitForDurationThenRemoveFromParent(_ duration:TimeInterval) -> SCNAction {
		let wait = SCNAction.wait(duration: duration)
		let remove = SCNAction.removeFromParentNode()
		return SCNAction.sequence([wait,remove])
	}
	
	class func waitForDurationThenRunBlock(_ duration:TimeInterval, block: @escaping ((SCNNode!) -> Void) ) -> SCNAction {
		let wait = SCNAction.wait(duration: duration)
		let runBlock = SCNAction.run { (node) -> Void in
			block(node)
		}
		return SCNAction.sequence([wait,runBlock])
	}
}
