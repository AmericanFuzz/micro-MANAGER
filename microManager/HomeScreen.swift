//
//  GameScene.swift
//  microManager
//
//  Created by Sebastian Kazakov on 3/15/24.
//

import SpriteKit // The library that lets me control graphics a lot easier

class HomeScreen: SKScene { // The main page, where the whole app "starts". This is called by the view controller when it boots up, and it uses this scenes file name to locate it, and then simulate it on top of itself.
    
    var uberTitle = SKLabelNode() // the "superscript" for the title
    var title = SKLabelNode() // the title of the application, in giant letters to contrast with the tiny superscript
    var creditForMwah = SKLabelNode() // I want to get my credit where it is due!
    var highestLevel = SKLabelNode() // the statistics label for the highest level you reached
    var attempts = SKLabelNode() // the statistics label for the amount of times you tried, but lost(there is no intended way to win, just have fun in the process)
    var enemiesCrushed = SKLabelNode() // the statistics label for the amount of enemies you crushed to bits
    var startGameButton = SKSpriteNode() // the giant start button that lets you start the game
    
    override func didMove(to view: SKView) { // once the view controller boots up the graphics layout, run this:
        self.backgroundColor = .white // set background to white
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5) // make origin the middle of the screen, to make life easier
        
        revealScene(sceneFor: self) // my function to do a super cool shutter animation to open page
        
        var levelHigh = 0 // local variable for highest level reached, set to someting to later be changed
        var runAttempts = 0 // local variable for the times played & lost, set to someting to later be changed
        var crushedEnemies = 0 // local variable for amount of enemies crushed, set to someting to later be changed
        
        if let levels = MemoryVault.value(forKey: "levelHigh"){ // search for a permanantly stored value in device for highest level reached
            levelHigh = levels as! Int // if value is found, save it to local variable
        }else{ // if no value is found:
            MemoryVault.set(0, forKey: "levelHigh") // set the permanent value to 0 to have placeholder
        }
        
        if let runs = MemoryVault.value(forKey: "attempts"){ // search for a permanantly stored value in device for games played
            runAttempts = runs as! Int // if value is found, save it to local variable
        }else{ // if no value is found:
            MemoryVault.set(0, forKey: "attempts") // set the permanent value to 0 to have placeholder
        }
        
        if let crushes = MemoryVault.value(forKey: "enemiesCrushed"){ // search for a permanantly stored value in device for enemies crushed
            crushedEnemies = crushes as! Int // if value is found, save it to local variable
        }else{ // if no value is found:
            MemoryVault.set(0, forKey: "enemiesCrushed") // set the permanent value to 0 to have placeholder
        }
        
        uberTitle = createLabel(fontSize: 20, position: CGPoint(x: 0, y: 500), text: "[micro]", sceneTo: self, zPosition: 1, color: .black) // set up the superscript title
        
        title = createLabel(fontSize: 100, position: CGPoint(x: 0, y: 400), text: "MANAGER", sceneTo: self, zPosition: 1, color: .black) // set up the main title
        
        creditForMwah = createLabel(fontSize: 25, position: CGPoint(x: 0, y: 350), text: "Made by: Sebastian Kazakov", sceneTo: self, zPosition: 1, color: .black) // set up the label to brand my name into the app, because I have learned in some of the most painful ways just how important credit is in anything you do. *BUDget Marketing reference*
        
        highestLevel = createLabel(fontSize: 40, position: CGPoint(x: 0, y: -400), text: "highest level reached: \(levelHigh)", sceneTo: self, zPosition: 1, color: .black) // set up the highest level statistic
        
        attempts = createLabel(fontSize: 40, position: CGPoint(x: 0, y: -490), text: "attempts: \(runAttempts)", sceneTo: self, zPosition: 1, color: .black) // set up the games played statistic
        
        enemiesCrushed = createLabel(fontSize: 40, position: CGPoint(x: 0, y: -580), text: "enemies crushed: \(crushedEnemies)", sceneTo: self, zPosition: 1, color: .black) // set up the enemies crushed statistic
        
        
        startGameButton = SKSpriteNode(texture: startGameTexture) // initialize the button by giving it its image
        startGameButton.position = CGPoint(x: 0, y: 0) // put the button smack - dab into the middle of the screen
        startGameButton.zPosition = 1 // place the button on top of the background "layer"
        startGameButton.setScale(1) // make it 500 by 500 pixels large(original file size)
        self.addChild(startGameButton) // add this new graphic node to the parent scene
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { // for every time the screen is pressed:
        for touch in touches{ // for every press that came to touch the screen and activate this function:
            let position = touch.location(in: self) // get the location of that press relative to the scene's origin
            if startGameButton.contains(position){ // if the giant start button is pressed:
                let move = SKAction.run { // set up timed action to:
                    moveToScene(sceneFrom: self, sceneTo: FieldScene(size: self.size)) // move to the field scene for the actual game
                    MemoryVault.set(MemoryVault.value(forKey: "attempts") as! Int + 1, forKey: "attempts") // and save another tally for attempts
                }
                startGameButton.run(SKAction.sequence([SKAction.scale(to: 0.75, duration: 0.1), SKAction.scale(to: 1, duration: 0.1), move])) // make the start button shrink then grow(bounce to represent tap), and then have it do the timed action previously mentioned.
            }
        }
    }
}




