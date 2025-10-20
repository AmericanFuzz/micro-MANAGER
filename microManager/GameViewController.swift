//
//  GameViewController.swift
//  microManager
//
//  Created by Sebastian Kazakov on 3/15/24.
//



import UIKit //Library for "User Interface Kit"
import SpriteKit //Library to manage graphics

class GameViewController: UIViewController { // The view controller that hosts the Sprite Kit Scenes

    override func viewDidLoad() { // upon booting up the view controller
        super.viewDidLoad() // force parent to run this procedure, not just sit idly
        
        if let view = self.view as! SKView? { // Swift is a statically typed language! We need to assume that the view controller can simulate a Sprite Kit View!
            if let scene = SKScene(fileNamed: "HomeScreen") { // assume that a file we set can be the scene to be presented by the SKView
                scene.scaleMode = .aspectFill // Set the scale mode to scale to fit the window completely
                view.presentScene(scene) // Present the scene
            }
            
            view.ignoresSiblingOrder = true // debugging tool for layers of graphics
            view.showsPhysics = false // debugging tool for drawing out physics objects
            view.showsFPS = false // debugging tool for displaying frames per second statistics
            view.showsNodeCount = false // debugging tool for showing how many "sprites" are being used in a scene
        }
        self.becomeFirstResponder() // initialization call to allow shake sensing
    }
    
    override var canBecomeFirstResponder: Bool{ // make an initialization variable
        get{ // when called:
            return true // allow for the called entity to be the first to recieve update(shaking data in this case)
        }
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) { // if shaking is detected:
        if motion == .motionShake{ // if data sent to this viewcontroller is recognized as a "shaking" pattern:
            if isSpectating && !isLaunching && !isBlocking{ // if the player is observing but not choosing, and wants to act:
                let deactivate = SKAction.run{isSpectating = false} // set a timed action to turn off the variable that limits what the user can do
                viewPoint.run(SKAction.sequence([SKAction.move(to: charecter.position, duration: 0.1), deactivate])) // take the camera, and move it to where the character is, right before locking it to that character by removing it's "spectating handicap"
                heavy.impactOccurred() // add some cool clicks to the phone, so user can FEAL the update in their palm.
            }else{ // player is not observing already? They must want to start spectating:
                isSpectating = true // set the observing variable to true
                initialViewPoint = viewPoint.position // for the "pan" gesture, I need to know where the camera started to act as a spectator, not a third person view.
                heavy.impactOccurred() // add some cool clicks to the phone, so user can FEAL the update in their palm.
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { // function that will determine what orientations of my application are allowed:
        return .portrait // portrait is only orientation, otherwise my application looks lobsided
    }

    override var prefersStatusBarHidden: Bool { // bar with all of my debugging tools for framerate, sprites, etc.
        return true // hide this from users
    }
}
