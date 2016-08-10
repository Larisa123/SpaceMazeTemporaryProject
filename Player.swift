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
	var levelScene: SCNScene!
	var scnNode: SCNNode!
	var direction: PlayerCurrentDirection = .Forward
	var cameraDirection: CameraCurrentDirection = .Forward
	var velocityMagnitude: Float = 1.0
	//var light: SCNNode!
	
	var moving = false
	
	init(viewController: GameViewController, scene: SCNScene) {
		let shape = SCNPhysicsShape(geometry: SCNSphere(radius: 0.15), options: nil)
		levelScene = scene
		gameViewController = viewController
		//light = levelScene.rootNode.childNodeWithName("playerLight reference", recursively: true)!
		
		self.scnNode = levelScene.rootNode.childNodeWithName("playerObject reference", recursively: true)!
		scnNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: shape)
		scnNode.physicsBody?.affectedByGravity = true
		scnNode.physicsBody?.categoryBitMask = PhysicsCategory.Player.rawValue
		scnNode.physicsBody?.collisionBitMask = PhysicsCategory.Wall.rawValue | PhysicsCategory.Floor.rawValue
		scnNode.physicsBody?.contactTestBitMask = PhysicsCategory.Wall.rawValue | PhysicsCategory.Pearl.rawValue | PhysicsCategory.Enemy.rawValue
	}
	
	func collisionWithNode(node: SCNNode) {
		let geometry = node.name == "pearl" ? SCNSphere(radius: 0.1) : SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 1.0)
		let position = node.presentationNode.position
		let explosion = node.name == "pearl" ? gameViewController.pearlExplosionParticleSystem : gameViewController.enemyExplosionParticleSystem
		createExplosion(explosion, withGeometry: geometry, atPosition: position)
		
		node.hidden = true
		node.runAction(SCNAction.waitForDurationThenRunBlock(10.0) { node in node.hidden = false })
		
		if node.name == "pearl" {
			// + points?
		} else if node.name == "enemy" {
			//gameOver()
		}
	}
	
	func createExplosion(explosion: SCNParticleSystem, withGeometry geometry: SCNGeometry, atPosition position: SCNVector3) {
		let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
		explosion.emitterShape = geometry
		
		levelScene.addParticleSystem(explosion, withTransform: translationMatrix)
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
	
	func updateCameraDirection() -> SCNAction {
		let rotateAction: SCNAction!
		
		switch cameraDirection {
		case .Forward: rotateAction = SCNAction.rotateToX(0, y: 0, z: 0, duration: 0.1, shortestUnitArc: true)
		case .Backward: rotateAction = SCNAction.rotateToX(0, y: pi, z: 0, duration: 0.1, shortestUnitArc: true)
		case .Right: rotateAction = SCNAction.rotateToX(0, y: -pi/2, z: 0, duration: 0.1, shortestUnitArc: true)
		case .Left: rotateAction = SCNAction.rotateToX(0, y: pi/2, z: 0, duration: 0.1, shortestUnitArc: true)
		}
		return rotateAction
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
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
