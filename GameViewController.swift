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
	static let Enemy: Int = 8
	static let WinningPearl: Int = 16
	static let Floor: Int = 32
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
	
	var playerClass: Player!
	var winningPearl: SCNNode!
	
	//HUD
	var hudScene: hudSKSScene!
	
	var game: Game!
	var currentLevel = 1
	var didNewLevelLoad = false
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupView()
		setupSceneLevel(2) //which level to load
		setupHUD()
		setupPlayerClass()
		setupParticleSystems()
		setupNodes()
		
		setupGameClass() //on Game class initialization, cameras and sounds are automatically initializied
	}
	
	func setupView() {
		scnView = self.view as! SCNView
		scnView.delegate = self
	}
	
	func setupSceneLevel(level: Int) {
		didNewLevelLoad = false
		levelScene = SCNScene(named: "Level\(level).scn")
		scnView.scene = levelScene
		currentLevel = level
		
		levelScene.physicsWorld.contactDelegate = self
		didNewLevelLoad = true
	}
	
	func setupHUD() {
		hudScene = hudSKSScene(gameViewController: self)
		scnView.overlaySKScene = hudScene
	}
	
	func setupPlayerClass() { playerClass = Player(viewController: self) }
	
	func setupParticleSystems() {
		enemyExplosionParticleSystem = SCNParticleSystem(named: "enemyExplodeParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
		enemyParticleSystem = SCNParticleSystem(named: "enemyParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
		pearlExplosionParticleSystem = SCNParticleSystem(named: "pearlExplodeParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
		pearlParticleSystem = SCNParticleSystem(named: "pearlParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
		smallPearlParticleSystem = SCNParticleSystem(named: "smallPearlParticleSystem.scnp", inDirectory: "art.scnassets/Particles")! //change the texture?
		starsParticleSystem = SCNParticleSystem(named: "starsParticleSystem.scnp", inDirectory: "art.scnassets/Particles/starsParticleSystem.scnp")
	}
	
	func setupNodes() {
		levelScene.rootNode.enumerateChildNodesUsingBlock { node, stop in
			if node.name == "wallObject reference" {
				node.physicsBody = SCNPhysicsBody(type: .Kinematic, shape: SCNPhysicsShape(geometry: SCNBox(width: 0.1, height: 0.5, length: 0.5, chamferRadius: 1.0) , options: nil))
				node.physicsBody?.categoryBitMask = PhysicsCategory.Wall
				node.categoryBitMask = PhysicsCategory.Wall
				node.physicsBody?.collisionBitMask = PhysicsCategory.Player
				node.physicsBody?.contactTestBitMask = PhysicsCategory.Player
				//node.name = "wall"
			}
			if self.currentLevel > 1 { //level 1 has no pearls or enemys
				if node.name == "pearl reference" {
					node.physicsBody = SCNPhysicsBody(type: .Static, shape: nil)
					node.physicsBody?.categoryBitMask = PhysicsCategory.Pearl
					node.physicsBody?.collisionBitMask = PhysicsCategory.None
					node.physicsBody?.contactTestBitMask = PhysicsCategory.Player
					//node.name = "pearl"
					node.addParticleSystem(self.smallPearlParticleSystem)
				}
				if node.name == "enemy reference" {
					node.physicsBody = SCNPhysicsBody(type: .Kinematic, shape: nil)
					node.physicsBody?.categoryBitMask = PhysicsCategory.Enemy
					node.physicsBody?.collisionBitMask = PhysicsCategory.None
					node.physicsBody?.contactTestBitMask = PhysicsCategory.Player
					//node.name = "enemy"
					node.addParticleSystem(self.enemyParticleSystem)
				}
			}
		}
		
		floor = levelScene.rootNode.childNodeWithName("floorObject reference", recursively: true)!
		floor.physicsBody = SCNPhysicsBody(type: .Static, shape: nil)
		floor.physicsBody?.categoryBitMask = PhysicsCategory.Floor
		floor.physicsBody?.collisionBitMask = PhysicsCategory.Player
		floor.physicsBody?.contactTestBitMask = PhysicsCategory.None
		//floor.name = "floor"
	
		
		//winning pearl
		winningPearl = levelScene.rootNode.childNodeWithName("winningPearl reference", recursively: true)! //fatal error??
		winningPearl.physicsBody = SCNPhysicsBody(type: .Static, shape: nil)
		winningPearl.physicsBody?.categoryBitMask = PhysicsCategory.WinningPearl
		winningPearl.physicsBody?.collisionBitMask = PhysicsCategory.None
		winningPearl.physicsBody?.contactTestBitMask = PhysicsCategory.Player
		//winningPearl.name = "winningPearl"
		winningPearl.addParticleSystem(pearlParticleSystem)
	}
	
	func setupGameClass() {
		game = Game(gameViewController: self)
		game.level = currentLevel
	}
	
	override func shouldAutorotate() -> Bool { return true }
	
	override func prefersStatusBarHidden() -> Bool { return true }
	
	override func didReceiveMemoryWarning() { print("memory warning") }
}


extension GameViewController: SCNSceneRendererDelegate {
	
	func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
		if game.state == .TapToPlay { game.newGameCameraSelfieStickNode.eulerAngles.y += 0.002 }
	}
}

extension GameViewController: SCNPhysicsContactDelegate {

	func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
		if game.state == .Play {
			let otherNode: SCNNode!			
			
			if contact.nodeA.categoryBitMask == PhysicsCategory.Player { otherNode = contact.nodeB }
			else { otherNode = contact.nodeA }
			
			if otherNode.physicsBody?.categoryBitMask == PhysicsCategory.Pearl || otherNode.physicsBody?.categoryBitMask == PhysicsCategory.Enemy {
				game.collisionWithNode(otherNode)
			} else if otherNode.physicsBody?.categoryBitMask == PhysicsCategory.WinningPearl {
				game.collisionWithWinningPearl(otherNode)
				return
			}
		}
	} //do sem dela
}


