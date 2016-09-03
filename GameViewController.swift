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
	
	func setupSceneLevel(_ level: Int) {
		if level <= 4 {
			levelScene = SCNScene(named: "Level\(level).scn")
			scnView.scene = levelScene
			currentLevel = level
			
			levelScene.physicsWorld.contactDelegate = self
		} else {
			// Player has cleared all levels!
		}
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
		levelScene.rootNode.enumerateChildNodes { node, stop in
			if node.name == "wallObject reference" {
				node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
				node.physicsBody?.categoryBitMask = PhysicsCategory.Wall
				node.categoryBitMask = PhysicsCategory.Wall
				node.physicsBody?.collisionBitMask = PhysicsCategory.Player
				node.physicsBody?.contactTestBitMask = PhysicsCategory.Player
				//node.name = "wall"
			}
			if self.currentLevel > 1 { //level 1 has no pearls or enemys
				if node.name == "pearl reference" {
					node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
					node.physicsBody?.categoryBitMask = PhysicsCategory.Pearl
					node.physicsBody?.collisionBitMask = PhysicsCategory.None
					node.physicsBody?.contactTestBitMask = PhysicsCategory.Player
					//node.name = "pearl"
					node.addParticleSystem(self.smallPearlParticleSystem)
				}
				if node.name == "enemy reference" {
					node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
					node.physicsBody?.categoryBitMask = PhysicsCategory.Enemy
					node.physicsBody?.collisionBitMask = PhysicsCategory.None
					node.physicsBody?.contactTestBitMask = PhysicsCategory.Player
					//node.name = "enemy"
					node.addParticleSystem(self.enemyParticleSystem)
				}
			}
		}
		
		floor = levelScene.rootNode.childNode(withName: "floorObject reference", recursively: true)!
		floor.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
		floor.physicsBody?.categoryBitMask = PhysicsCategory.Floor
		floor.physicsBody?.collisionBitMask = PhysicsCategory.Player
		floor.physicsBody?.contactTestBitMask = PhysicsCategory.None
		//floor.name = "floor"
	
		
		//winning pearl
		winningPearl = levelScene.rootNode.childNode(withName: "winningPearl reference", recursively: true)! //fatal error??
		winningPearl.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
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
	
	
	override func didReceiveMemoryWarning() { print("memory warning") }
}


extension GameViewController: SCNSceneRendererDelegate {
	
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		if game.state == .tapToPlay { game.newGameCameraSelfieStickNode.eulerAngles.y += 0.002 }
	}
}

extension GameViewController: SCNPhysicsContactDelegate {

	func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
		if game.state == .play {
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


