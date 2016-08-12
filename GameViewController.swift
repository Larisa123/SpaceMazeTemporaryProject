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

struct PhysicsCategory {
	static let None: Int = 0
	static let Player: Int = 1
	static let Wall: Int = 2
	static let Pearl: Int = 4
	static let WinningPearl: Int = 8
	static let Floor: Int = 16
	static let Enemy: Int = 32
}


class GameViewController: UIViewController {
	
	var scnView: SCNView!
	var levelScene: SCNScene!
	var floor: SCNNode!
	
	var enemyExplosionParticleSystem: SCNParticleSystem!
	var enemyParticleSystem: SCNParticleSystem!
	var pearlExplosionParticleSystem: SCNParticleSystem!
	var smallPearlParticleSystem: SCNParticleSystem!
	var pearlParticleSystem: SCNParticleSystem!
	var starsParticleSystem: SCNParticleSystem!
	
	var playerNode: SCNNode! //parent of player and playerSpotLight
	var playerClass: Player!
	var player: SCNNode!
	var winningPearl: SCNNode!
	
	//HUD
	var skHUDScene: SKScene!
	var hudNode: SCNNode!
	
	var game: Game!
	var currentLevel = 1
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupView()
		setupSceneLevel(1, gameSet: false)
		
		setupGameAndPlayerClasses()
		setupNodes()
		game.setupSounds()
		game.setupCamera()
		game.setupRotatingCamera()
	}
	
	func setupView() {
		scnView = self.view as! SCNView
		scnView.delegate = self
	}
	
	func setupSceneLevel(level: Int, gameSet: Bool) {
		var previousLevel: SCNScene? = levelScene
		levelScene = SCNScene(named: "Level\(level).scn")
		if previousLevel != nil {  previousLevel = nil }
		
		scnView.scene = levelScene
		currentLevel = level
		if gameSet { game.level = level }
		
		levelScene.physicsWorld.contactDelegate = self
	}
	
	func setupGameAndPlayerClasses() {
		game = Game(scnView: scnView, levelScene: levelScene, gameViewController: self)
		
		playerClass = Player(viewController: self, scene: levelScene)
		player = playerClass.scnNode
		
		game.setupHUD()
		skHUDScene = game.HUDScene
		let hudScene = hudSKSScene(size: CGSizeZero, scnView: scnView, levelScene: levelScene, game: game)
		scnView.overlaySKScene = hudScene
		game.level = currentLevel
	}
	
	func setupNodes() {
		
		//particle systems:
		enemyExplosionParticleSystem = SCNParticleSystem(named: "enemyExplodeParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
		enemyParticleSystem = SCNParticleSystem(named: "enemyParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
		pearlExplosionParticleSystem = SCNParticleSystem(named: "pearlExplodeParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
		pearlParticleSystem = SCNParticleSystem(named: "pearlParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
		smallPearlParticleSystem = SCNParticleSystem(named: "smallPearlParticleSystem.scnp", inDirectory: "art.scnassets/Particles")! //change the texture?
		starsParticleSystem = SCNParticleSystem(named: "starsParticleSystem.scnp", inDirectory: "art.scnassets/Particles/starsParticleSystem.scnp")
		
		levelScene.rootNode.enumerateChildNodesUsingBlock { node, stop in
			if node.name == "wallObject reference" {
				node.physicsBody = SCNPhysicsBody(type: .Kinematic, shape: SCNPhysicsShape(geometry: SCNBox(width: 0.1, height: 0.5, length: 0.5, chamferRadius: 1.0) , options: nil))
				node.physicsBody?.categoryBitMask = PhysicsCategory.Wall
				node.categoryBitMask = PhysicsCategory.Wall
				node.physicsBody?.collisionBitMask = PhysicsCategory.Player
				node.physicsBody?.contactTestBitMask = PhysicsCategory.Player
			}
			if self.currentLevel > 1 { //level 1 has no pearls or enemys
				if node.name == "pearl reference" {
					node.physicsBody = SCNPhysicsBody(type: .Static, shape: nil)
					node.categoryBitMask = PhysicsCategory.Pearl
					node.physicsBody?.collisionBitMask = PhysicsCategory.None
					node.physicsBody?.contactTestBitMask = PhysicsCategory.Player
					node.addParticleSystem(self.smallPearlParticleSystem)
				}
				if node.name == "enemy reference" {
					node.physicsBody = SCNPhysicsBody(type: .Kinematic, shape: nil)
					node.categoryBitMask = PhysicsCategory.Enemy
					node.physicsBody?.collisionBitMask = PhysicsCategory.None
					node.physicsBody?.contactTestBitMask = PhysicsCategory.Player
					node.addParticleSystem(self.enemyParticleSystem)
				}
			}
		}
		
		floor = levelScene.rootNode.childNodeWithName("floorObject reference", recursively: true)!
		floor.physicsBody = SCNPhysicsBody(type: .Static, shape: nil)
		floor.physicsBody?.categoryBitMask = PhysicsCategory.Floor
		floor.physicsBody?.collisionBitMask = PhysicsCategory.Player
	
		
		//winning pearl
		winningPearl = levelScene.rootNode.childNodeWithName("winningPearl reference", recursively: true)!
		winningPearl.physicsBody = SCNPhysicsBody(type: .Static, shape: nil)
		winningPearl.categoryBitMask = PhysicsCategory.WinningPearl
		winningPearl.physicsBody?.collisionBitMask = PhysicsCategory.None
		winningPearl.physicsBody?.contactTestBitMask = PhysicsCategory.Player
		winningPearl.addParticleSystem(pearlParticleSystem)
	}
	
	override func shouldAutorotate() -> Bool { return true }
	
	override func prefersStatusBarHidden() -> Bool { return true }
	
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		print("I/m in touchesBegan in GameViewController")
	}
}

extension GameViewController: SCNSceneRendererDelegate {
	
	func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
		if game.state == .TapToPlay { game.newGameCameraSelfieStickNode.eulerAngles.y += 0.002 }
		else if game.state == .Play {
			if playerClass.moving {
				playerClass.playerRoll()
				game.updateCameraBasedOnPlayerDirection()
				
			}
		}
	}
}

extension GameViewController: SCNPhysicsContactDelegate {

	func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
		if game.state == .Play {
			let otherNode: SCNNode!			
			
			if contact.nodeA.categoryBitMask == PhysicsCategory.Player { otherNode = contact.nodeB }
			else { otherNode = contact.nodeA }
			
			switch otherNode.categoryBitMask {
			case PhysicsCategory.Wall: game.playSound(otherNode, name: "wallCrash")
			case PhysicsCategory.Enemy: game.collisionWithNode(otherNode)
			case PhysicsCategory.Pearl: game.collisionWithNode(otherNode)
			case PhysicsCategory.WinningPearl: game.collisionWithWinningPearl(otherNode)
			default: break
			}
		}
	}
}


