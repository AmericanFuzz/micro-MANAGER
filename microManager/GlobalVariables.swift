//
//  GlobalVariables.swift
//  microManager
//
//  Created by Sebastian Kazakov on 3/15/24.
//

import SpriteKit // The library that lets me control graphics a lot easier
import CoreHaptics // The library that lets me physically SHAKE the user's phone

// ALL OF THESE VARIABLES AND STRUCTS ARE IN "open air" SO THEY CAN BE ACCESSED GLOBALLY!

struct CharecterClasses{ // the NOT inhereting structure I need to hold all of the unsigned integers, to split them up into categories, so that the physics of the game can be controlled:
    static let collidionNeutral: UInt32 = 0 // 0 means anything with this category will act as if it cannot collide with anything
    static let player: UInt32 = 1 // player is 1, the first unsigned integer value because - UNSIGNED INTEGERS ARE BINARY!!!(2^0)
    static let escapee: UInt32 = 2 // this is the runaway, set to a different number than player so they are not the same(2^1)
    static let point: UInt32 = 4 // 3 does not work, use 4 to follow binary rules(2^2)
}

// My textures! *Interchangable images* ALL ARE HANDDRAWN, "imageNamed" links them to the assets folder
let transitionBarsTexture = SKTexture(imageNamed: "transitionBars") // image for the transition bar "shutter" effect I like
let pointDotTexture = SKTexture(imageNamed: "pointDot") // image for the regular field dot
let escapeDotTexture = SKTexture(imageNamed: "escapeDot") // image for the border dots
var blockDotTexture = SKTexture(imageNamed: "blockDot") // image for the barrier dots the player can place
let charecterTexture = SKTexture(imageNamed: "charecter") // image for the cyan square character
let runawayTexture = SKTexture(imageNamed: "runaway") // image for the orange triangle runaway guys
let popupTexture = SKTexture(imageNamed: "popupVeil") // image for the popup black background to choose action
var moveTexture = SKTexture(imageNamed: "move") // image for the move action option button
var lookTexture = SKTexture(imageNamed: "look") // image for the look action option button
var launchTexture = SKTexture(imageNamed: "launch") // image for the launch action option button
var blockTexture = SKTexture(imageNamed: "block") // image for the block action option button
var startGameTexture = SKTexture(imageNamed: "startGame") // image for the giant start button on home page

// options how to shake the user's phone
var heavy = UIImpactFeedbackGenerator(style: .heavy) // shake it with a hard click
var rigid = UIImpactFeedbackGenerator(style: .rigid) // shake it with a slower, but firm pop
var medium = UIImpactFeedbackGenerator(style: .medium) // shake it with a hard tap
var light = UIImpactFeedbackGenerator(style: .light) // shake it with a soft twitch
var soft = UIImpactFeedbackGenerator(style: .soft) // // shake it with a faint crack

// all of the boolean variables to monitor the phase the user is in
var isBlocking: Bool = false // whether or not the user is placing a barrier
var isSpectating: Bool = false // whether or not the user is looking around
var isLaunching: Bool = false // whether or not the user is lining up shot into a runaway

// different nodes
var viewPoint = SKCameraNode() // the camera set up universally for the field scene so it may be controlled by the shaking actions set up in the view controller file, and not be trapped in the field scene container
var charecter = SKSpriteNode() // the character, that also needs to be monitored universally to accomodate for the phone shaking action

var currentLevel = 0 // the local variable that helps the permanent vault with what the current level is

var initialViewPoint = CGPoint(x: 0, y: 0) // the global variable that helps set and anchor point so that later I can find how much the user moved FROM the anchor, and use that delta to move the camera smoothly, and not have the game go haywire.

var MemoryVault = UserDefaults() // the bridge that lets me store data permanantly in the users device, like statistics:
// levelHigh is highest level reached
// attempts is how many times game was started
// enemiesCrushed is how many enemies were stomped out

func moveToScene(sceneFrom: SKScene, sceneTo: SKScene){ // function to easily move from one scene to another, with my: "shutter click" animation simulated with four black bars coming together and apart, parameters have the scene I am right now, and the scene I would like to go to, respectively.
    
    sceneTo.scaleMode = .aspectFill // set the presentation to fill, to have no ugly cutoff sides, and to maximize the quality of the display, using each and every pixel of the device
    
    let topBar = makeTransitionBar(whichOne: "top", sceneFor: sceneFrom, opening: false) // set up black bar
    let bottomBar = makeTransitionBar(whichOne: "bottom", sceneFor: sceneFrom, opening: false) // set up black bar
    let rightBar = makeTransitionBar(whichOne: "right", sceneFor: sceneFrom, opening: false) // set up black bar
    let leftBar = makeTransitionBar(whichOne: "left", sceneFor: sceneFrom, opening: false) // set up black bar
    
    // As I said, these bars are going to make my shutter effect to change scenes seamlessly.
    
    let presentNextScene = SKAction.run{topBar.scene?.view!.presentScene(sceneTo)} // timed action that presents the scene, from the view of the scene that one of the bars is attatched to. I have to do all of that to avoid errors, and it is gosh annoying.
    topBar.run(SKAction.sequence([SKAction.moveBy(x: 0, y: -900, duration: 0.75), presentNextScene])) // move in the shutter in three quarters of a second, and present the next scene
    bottomBar.run(SKAction.moveBy(x: 0, y: 900, duration: 0.75)) // move in the shutter in three quarters of a second
    rightBar.run(SKAction.moveBy(x: -400, y: 0, duration: 0.75)) // move in the shutter in three quarters of a second
    leftBar.run(SKAction.moveBy(x: 400, y: 0, duration: 0.75)) // move in the shutter in three quarters of a second
}

func revealScene(sceneFor: SKScene){ // the animation function to run once you have arrived at next scene to make it look like everything really was just a slow shutter transition
    
    let topBar = makeTransitionBar(whichOne: "top", sceneFor: sceneFor, opening: true) // set up black bar
    let bottomBar = makeTransitionBar(whichOne: "bottom", sceneFor: sceneFor, opening: true) // set up black bar
    let rightBar = makeTransitionBar(whichOne: "right", sceneFor: sceneFor, opening: true) // set up black bar
    let leftBar = makeTransitionBar(whichOne: "left", sceneFor: sceneFor, opening: true) // set up black bar
    
    // Notice how here, the bars are set to TRUE in opening parameter, because they are opening, and not closing, and they need different starting positions
    
    topBar.run(SKAction.sequence([SKAction.moveBy(x: 0, y: 1300, duration: 0.75), SKAction.removeFromParent()])) // move black bar then delete it to save on graphics processing power
    bottomBar.run(SKAction.sequence([SKAction.moveBy(x: 0, y: -1300, duration: 0.75), SKAction.removeFromParent()])) // move black bar then delete it to save on graphics processing power
    rightBar.run(SKAction.sequence([SKAction.moveBy(x: 700, y: 0, duration: 0.75), SKAction.removeFromParent()])) // move black bar then delete it to save on graphics processing power
    leftBar.run(SKAction.sequence([SKAction.moveBy(x: -700, y: 0, duration: 0.75), SKAction.removeFromParent()])) // move black bar then delete it to save on graphics processing power
}

func createLabel(fontSize: CGFloat, position: CGPoint, text: String, sceneTo: SKScene, zPosition: CGFloat, color: UIColor) -> SKLabelNode{ // function to set up a label in a single line of code with parameters handling most common neccessary attributes
    let label = SKLabelNode(fontNamed: "MarkerFelt-Wide") // initialize variable with the font name
    label.position = position // move this label's bottom center to where I ask it to
    label.fontSize = fontSize // set the size of this label to whatever I ask
    label.fontColor = color // set color of label to whatever I ask
    label.text = text // set text of label to whatever I ask
    label.zPosition = zPosition // set zPosition of label to whatever I ask
    sceneTo.addChild(label) // add this label to the scene I ask it to be in
    
    return label // return the raw node of this label to a local variable for furthur usage
}

func makeTransitionBar(whichOne: String, sceneFor: SKScene, opening: Bool) -> SKSpriteNode{ // function that makes a black bar for the shutter transition, which one of the four depending on what I put into parameters
    
    let bar = SKSpriteNode(texture: transitionBarsTexture) // initialize the bar sprite with it's image, which is the black rectangle
    bar.setScale(100) // make the bar huge
    bar.zPosition = 100 // make the bar cover anything and everything that could be previously seen by user
    
    let xBase = 1275 // set up an "anchor" for easier testing and tweaking for best result for x - axis sliding bars
    let yBase = 1600 // set up an "anchor" for easier testing and tweaking for best result for y - axis sliding bars
    
    switch whichOne{ // use bada*s conditional statement that can simplify the syntax(switch statement)
    case "top": // If I ask for a top bar in parameters:
        if !opening{ // Do I want one that will be shutting in:
            bar.position = CGPoint(x: 0, y: yBase + 200) // Set the bar to it's outmost position
        }else{ // Or do I want one that will be opening:
            bar.position = CGPoint(x: 0, y: yBase - 1500) // Set the bar to it's innermost position
        }
    case "bottom": // If I ask for a bottom bar in parameters:
        if !opening{ // Do I want one that will be shutting in:
            bar.position = CGPoint(x: 0, y: -yBase - 200) // Set the bar to it's outmost position
        }else{ // Or do I want one that will be opening:
            bar.position = CGPoint(x: 0, y: -yBase + 1500) // Set the bar to it's innermost position
        }
    case "right": // If I ask for a right side bar in parameters:
        bar.zRotation = .pi/2 // rotate the bar by 90 degrees, but swift uses radians, so 1/4 of a radian
        if !opening{ // Do I want one that will be shutting in:
            bar.position = CGPoint(x: xBase + 75, y: 0) // Set the bar to it's outmost position
        }else{ // Or do I want one that will be opening:
            bar.position = CGPoint(x: xBase - 800, y: 0) // Set the bar to it's innermost position
        }
    case "left": // If I ask for a left side bar in parameters:
        bar.zRotation = .pi/2 // rotate the bar by 90 degrees, but swift uses radians, so 1/4 of a radian
        if !opening{ // Do I want one that will be shutting in:
            bar.position = CGPoint(x: -xBase - 75, y: 0) // Set the bar to it's outmost position
        }else{ // Or do I want one that will be opening:
            bar.position = CGPoint(x: -xBase + 800, y: 0) // Set the bar to it's innermost position
        }
    default: // if none of those work, still do this:
        break // nothing. nothing because I should have typed the type of bar in correctly
    }
    sceneFor.addChild(bar) // whatever this bar has become, add it to the scene that is input into the parameters
    
    return bar // return this raw node to a local variable for further usage later on
}

func findDistance(from: CGPoint, to: CGPoint) -> CGFloat{ // function to find distance between two coordinates, and return a floating point in unit of pixel goups
    return sqrt(pow(from.x - to.x, 2) + pow(from.y - to.y, 2)) // use distance formula to return answer of two given points from the parameter. *order does not matter, put in any two points in any order* 
}



