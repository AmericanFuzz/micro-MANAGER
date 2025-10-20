//
//  FieldScene.swift
//  microManager
//
//  Created by Sebastian Kazakov on 3/15/24.
//

import SpriteKit // The library that lets me control graphics a lot easier
import CoreHaptics // The library that lets me physically SHAKE the user's phone

class FieldScene: SKScene, SKPhysicsContactDelegate { // the parent scene of the actual game, which is also a physics engine
    
    // my gesture recognizers
    var swipeUp = UISwipeGestureRecognizer() // gesture recognizer to be in charge of detecting swipes up
    var swipeDown = UISwipeGestureRecognizer() // gesture recognizer to be in charge of detecting swipes down
    var swipeRight = UISwipeGestureRecognizer() // gesture recognizer to be in charge of detecting swipes right
    var swipeLeft = UISwipeGestureRecognizer() // gesture recognizer to be in charge of detecting swipes left
    var pinchSensor = UIPinchGestureRecognizer() // gesture recognizer to be in charge of pinches to the screen
    
    // my sprites
    var turnPopup = SKSpriteNode() // backdrop for the actions the player could chose
    var moveAction = SKSpriteNode() // the button to move the character
    var lookAction = SKSpriteNode() // the button to look around the field
    var launchAction = SKSpriteNode() // the button to launch the character into a runaway
    var blockAction = SKSpriteNode() // the button to drop a barrier that crushes any runaways to touch it
    
    // my labels
    var lookLabel = SKLabelNode() // the label that describes what the looking action does
    var moveLabel = SKLabelNode() // the label that describes what the moving action does
    var shootLabel = SKLabelNode() // the label that describes what the launching action does
    var blockLabel = SKLabelNode() // the label that describes what the barrier action does
    var currentLevelLabel = SKLabelNode() // the label that tells the player the current level they are on
    
    // my floating points, doubles, and integers
    var zoomAnchorHead: CGFloat = 1 // the Core Graphics floating point number that is the desired zoom of camera
    var zoomAnchorTail: CGFloat = 1 // the Core Graphics floating point number that is the previous zoom of camera
    // I need top two to let the camera zoom in and out smoothly with a pinch from the user, to the degree they desire.
    var zoom: CGFloat = 1 // the Core Graphics floating point number that is the current zoom of camera
    var outerLimit: CGFloat = 800 // the maximum extent of the field, just the void beyond, so lock the camer from being dragged away by any curious users
    var gridSpacing = 100.0 // the space between each dot on the field
    var dashSpeed = 0.25 // the delay that is takes for the characters to dash a single: "gridSpacing" amount
    
    // my booleans
    var initialLockOn: Bool = false // the boolean value that sets an anchor point of a pan gesture to find the delta from the desired position
    var isMoving: Bool = false // the boolean value that lets player move or not in the field
    var isLooking: Bool = false // the boolean value that lets player spectate or not to investigate runaways
    var didWin: Bool = false // the boolean value that triggers the next level
    var didLoseByEscapee: Bool = false // the boolean value that will trigger the end of the game
    var resultLockActivated: Bool = false // the boolean value that runs a lose / win routine only once, to prevent an overload crash
    var isChoosingAction: Bool = true // the boolean value that temporarily locks the player in place so they would choose an option and not mess up the action selection process
    
    // my points
    var outerDotArray: [CGPoint] = [] // the array of all the outmost green dots, to be filled for later use
    var escapeePosition = CGPoint() // the position of the runaway that managed to get on the green and use his next turn to escape, making you fail your job and lose the game.
    var initialTouchPosition = CGPoint(x: 0, y: 0) // the position where the player first touched to use the pan gesture in "spectator" mode.
    

    override func didMove(to view: SKView) { // once the view controller boots up the graphics layout, run this:
        self.backgroundColor = .darkGray // set the background color to dark grey
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5) // set the origin to the middle of the screen for convenience
        self.physicsWorld.contactDelegate = self // initialize the physics engine to the current scene
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0) // turn off the scenes gravity to prevent any nonesense from occouring
        
        self.camera = viewPoint // set the scene's camera to something I can mutate to my and player's desire
        viewPoint.setScale(1) // reset the global variable to default
        self.addChild(viewPoint) // recognize all of these commands in the current scene
        
        revealScene(sceneFor: self) // function to open up the scene in style with my shutter effect
        createPointNet(sceneTo: self, spacingOfPoints: gridSpacing) // set up the entire field, based on the spacing I ask it to use
        addGestureCapabilities() // function to allow the scene to understand gesture commands
        
        charecter = SKSpriteNode(texture: charecterTexture) // initialize the charecter with it's cyan square image
        charecter.position = CGPoint(x: 0, y: 0) // place the charecter right in the middle of the screen
        charecter.setScale(0.35) // shrink the charecter down a little
        charecter.zPosition = 1 // put the charecter just above the field dots
        charecter.name = "charecter" // give the charecter a name to be later used by the physics engine as an ID
        charecter.physicsBody = SKPhysicsBody(texture: charecter.texture!, size: charecter.size) // setup physics bounds of charecter
        charecter.physicsBody?.categoryBitMask = CharecterClasses.player // place charecter into player physics category
        charecter.physicsBody?.contactTestBitMask = CharecterClasses.escapee // make charecter look out for contact with escapee(runaway) physics category
        charecter.physicsBody?.collisionBitMask = CharecterClasses.collidionNeutral // do not collide with anything
        self.addChild(charecter) // add this charecter to the current scene
        
        currentLevel += 1 // add to the current level, so you go from 0 - 1, or if you came back victorious from other level, 1 - up it.
        if let highestSoFar = MemoryVault.value(forKey: "levelHigh") as? Int{ // look for highest level stored
            if currentLevel > highestSoFar{ // if found highest level is less than what player has right now:
                MemoryVault.set(currentLevel, forKey: "levelHigh") // update the player's new high score
            }
        }
        
        isLaunching = false // these are global, and do not get wiped for new level, so do it manually
        isBlocking = false // these are global, and do not get wiped for new level, so do it manually
        isSpectating = false // these are global, and do not get wiped for new level, so do it manually
        
        generateEnemyField(levelOfIntensity: currentLevel) // function to create all of the enemies, based on the level player is on
        
        turnPopup = SKSpriteNode(texture: popupTexture) // initialize the backdrop for all of the action options
        turnPopup.position = CGPoint(x: 0, y: 0) // put it in the middle of the screen
        turnPopup.setScale(10) // make the popup huge to cover entire screen
        turnPopup.zPosition = 10 // make sure it is above everything to cover it
        self.addChild(turnPopup) // add this popup backdrop to the current scene
        
        makeActionOption(action: &moveAction, textureForAction: moveTexture) // setup the action option for moving
        makeActionOption(action: &lookAction, textureForAction: lookTexture) // setup the action option for looking
        makeActionOption(action: &launchAction, textureForAction: launchTexture)  // setup the action option for launching
        makeActionOption(action: &blockAction, textureForAction: blockTexture) // setup the action option for blocking
        
        lookLabel = createLabel(fontSize: 20, position: CGPoint(x: lookAction.position.x, y: lookAction.position.x - 100), text: "look around", sceneTo: self, zPosition: turnPopup.zPosition + 1, color: .white) // set up the description label for the spectating action button, right on op of the popup, and snugly under the action button
        
        moveLabel = createLabel(fontSize: 20, position: CGPoint(x: moveAction.position.x, y: lookAction.position.x - 100), text: "move around", sceneTo: self, zPosition: turnPopup.zPosition + 1, color: .white) // set up the description label for the moving action button, right on op of the popup, and snugly under the action button
        
        shootLabel = createLabel(fontSize: 20, position: CGPoint(x: launchAction.position.x, y: lookAction.position.x - 100), text: "ranged attack", sceneTo: self, zPosition: turnPopup.zPosition + 1, color: .white) // set up the description label for the launching action button, right on op of the popup, and snugly under the action button
        
        blockLabel = createLabel(fontSize: 20, position: CGPoint(x: blockAction.position.x, y: lookAction.position.x - 100), text: "place barrier", sceneTo: self, zPosition: turnPopup.zPosition + 1, color: .white) // set up the description label for the blocking action button, right on op of the popup, and snugly under the action button
        
        
        currentLevelLabel = createLabel(fontSize: 80, position: CGPoint(x: 0, y: 400), text: "Level: \(currentLevel)", sceneTo: self, zPosition: turnPopup.zPosition + 1, color: .white) // giant label at the top of the popup, to show what level it is, and exactly how many runaways player should expect to have to crush. Level 1 means 1 enemy, Level 12 means 12 enemies, and so on.
    }
    
    @objc func swopeUp(){ // function called by gesture recognizer responsible for upwards swipe
        moveCharecter(moveByX: 0, moveByY: gridSpacing) // move character up by one grid unit
    }
    
    @objc func swopeDown(){ // function called by gesture recognizer responsible for downwards swipe
        moveCharecter(moveByX: 0, moveByY: -gridSpacing) // move character down by one grid unit
    }
    
    @objc func swopeRight(){ // function called by gesture recognizer responsible for rightwards swipe
        moveCharecter(moveByX: gridSpacing, moveByY: 0) // move character right by one grid unit
    }
    
    @objc func swopeLeft(){ // function called by gesture recognizer responsible for leftwards swipe
        moveCharecter(moveByX: -gridSpacing, moveByY: 0) // move character left by one grid unit
    }
    
    @objc func pinched(){ // function that as a pinch scale from 0 to about 12, that recognizes if and how the screen is pinched
        if !isChoosingAction{ // if the player is allowed to be zooming in and out:
            let currentZoom: CGFloat = 1 / pinchSensor.scale // get the desired zoom fraction of the default of 1
            let currentDelta: CGFloat = zoomAnchorHead - currentZoom // get delta from initial pinch to desired pinch
            
            var viewZoom = zoomAnchorTail - currentDelta // set a variable to the current zoom of camera to the delta it needs to move
            
            if viewZoom > 3{ // if too much zoom
                viewZoom = 3 // go back(set roof)
            }else if viewZoom < 0.5{ // if to little zoom
                viewZoom = 0.5 // go back(set roof)
            }
            
            viewPoint.setScale(viewZoom) // set the camera zoom to the processed variable
            initialViewPoint = viewPoint.position // adjust camera position because of zoom translation
            zoom = viewZoom // set a class - local variable to send back current zoom as later tail(later initial position) to keep function working
        }
    }
    
    func moveCharecter(moveByX: CGFloat, moveByY: CGFloat){ // function to move the character by parameter given amount
        if !isChoosingAction && !isSpectating && isMoving{ // if character is allowed to move in first place:
            let popChoice = SKAction.run{self.popupChoices()} // timed action to pop up choices
            let postMove = SKAction.wait(forDuration: 0.5) // timed action to delay half a second
            let moveRunaways = SKAction.run{self.moveAllRunaways(allSprites: self.children)} // timed action to move all runaways
            charecter.run(SKAction.sequence([SKAction.moveBy(x: moveByX, y: moveByY, duration: dashSpeed), moveRunaways, postMove, popChoice])) // move charecter by a variable speed, then move all runaways, then delay a little for aesthetics, and then present new action options for new turn
            isMoving = false // turn off the permission to move, it was used up
            light.impactOccurred() // give user gentle feedback that their turn is up again
        }
    }
    
    func initializeSwipeGesture(variable: inout UISwipeGestureRecognizer, direction: UISwipeGestureRecognizer.Direction, function: Selector){ // function to set up the swipe gesture recognizers(THIS IS AN "inout" FUNCTION AND IT CHANGES PARAMETERS )
        variable = UISwipeGestureRecognizer(target: self, action: function) // initialize the parameter with the given function
        variable.direction = direction // give parameter a direction
        variable.cancelsTouchesInView = false // do not disturb other senses of screen with recognition
        self.view?.addGestureRecognizer(variable) // let the view of the current scene have this gesture recognizer
    }
    
    func addGestureCapabilities(){
        initializeSwipeGesture(variable: &swipeUp, direction: .up, function: #selector(swopeUp)) // add up
        initializeSwipeGesture(variable: &swipeDown, direction: .down, function: #selector(swopeDown)) // add down
        initializeSwipeGesture(variable: &swipeRight, direction: .right, function: #selector(swopeRight)) // add right
        initializeSwipeGesture(variable: &swipeLeft, direction: .left, function: #selector(swopeLeft)) // add left
        // all of these can be done in one line thanks to the previously made function to add gesture recognizers
        
        pinchSensor = UIPinchGestureRecognizer(target: self, action: #selector(pinched)) // initialize pinch sensor
        pinchSensor.cancelsTouchesInView = true // make a pinch override other gestures so it does not get confused for two swipes
        self.view?.addGestureRecognizer(pinchSensor) // append this pinch gesture to the current scene's view
    }
    
    func makeActionOption(action: inout SKSpriteNode, textureForAction: SKTexture){ // function to make an action option
        action = SKSpriteNode(texture: textureForAction) // initialize action graphic with an image
        action.setScale(0.3) // shrink down the action button by a little
        action.zPosition = turnPopup.zPosition + 1 // place this action button right on top of the popup screen
        self.addChild(action) // add this action button to the current scene
    }
    
    func popupChoices(){ // function to pop up all of action selection elements
        isChoosingAction = true // turn off permissions to let user choose next action in peace
        viewPoint.run(SKAction.scale(to: 1, duration: 0.2)) // zoom back to defaut to see clearly
        turnPopup.setScale(zoom*15) // set the backdrop for action selection to a size that will cover all visible background
        let fadeIn = SKAction.fadeIn(withDuration: 0.1) // action all of elements will follow
        let elementsArraySprites: [SKSpriteNode] = [turnPopup, moveAction, lookAction, launchAction, blockAction] // all of sprite elements
        let elementsArrayLabels: [SKLabelNode] = [moveLabel, lookLabel, shootLabel, blockLabel, currentLevelLabel] // all of label elements
        
        for index in elementsArraySprites.indices{ // for every sprite:
            elementsArraySprites[index].run(fadeIn) // run the fading action
        }
        
        for index in elementsArrayLabels.indices{ // for every label:
            elementsArrayLabels[index].run(fadeIn) // run the fading action
        }
    }
    
    func dropChoices(){
        let fadeOut = SKAction.fadeOut(withDuration: 0.1) // action all of elements will follow
        let elementsArraySprites: [SKSpriteNode] = [turnPopup, moveAction, lookAction, launchAction, blockAction] // all of sprite elements
        let elementsArrayLabels: [SKLabelNode] = [moveLabel, lookLabel, shootLabel, blockLabel, currentLevelLabel] // all of label elements
        
        for index in elementsArraySprites.indices{ // for every sprite:
            elementsArraySprites[index].run(fadeOut) // run the fading action
        }
        
        for index in elementsArrayLabels.indices{ // for every label:
            elementsArrayLabels[index].run(fadeOut) // run the fading action
        }
        isChoosingAction = false
        heavy.impactOccurred()
    }
    
    func createPointNet(sceneTo: SKScene, spacingOfPoints: CGFloat){ // function to make 17 * 17 grid of dots to be used for the field
        
        var xPosition = 0.0 // dummy x - position of dot
        var yPosition = 0.0 // dummy y - position of dot
        
        let dotCount = 17.0 // set the amount of dots you want squared
        let dotSpacingFactor = (dotCount - 1) / 2 // how many dots squared in a quadrant
        let loopDots = pow(dotCount, 2) // total amount of dots needed
        
        xPosition -= spacingOfPoints*dotSpacingFactor // create top left most x position to start
        yPosition += spacingOfPoints*dotSpacingFactor // create top left most y position to start
        
        let xMax = spacingOfPoints*dotSpacingFactor // set a maximum x to watch out for before skipping to next line below
        
        for _ in 1 ... Int(loopDots){ // for every dot needed
            let dot = SKSpriteNode(texture: pointDotTexture) // initialize a dot with a default dot image
            dot.position = CGPoint(x: xPosition, y: yPosition) // set the dots position to where the loop has set the x and y variables to
            dot.zPosition = 0 // put the dot below everything but the background
            dot.setScale(0.1) // shrink the dots
            dot.name = "dot" // add physics name for dot
            dot.physicsBody = SKPhysicsBody(texture: dot.texture!, size: dot.size) // define physics bounds for dot
            dot.physicsBody?.categoryBitMask = CharecterClasses.point // put dot into rightful physics category
            dot.physicsBody?.contactTestBitMask = CharecterClasses.escapee // have dot detect contact with runaways
            dot.physicsBody?.collisionBitMask = CharecterClasses.collidionNeutral // do not have the dot colide with anything
            self.addChild(dot) // add dot to current scene
            
            if xPosition == -spacingOfPoints*dotSpacingFactor || xPosition == spacingOfPoints*dotSpacingFactor || yPosition == -spacingOfPoints*dotSpacingFactor || yPosition == spacingOfPoints*dotSpacingFactor{ //
                dot.texture = escapeDotTexture // if the x or the y variable are at their min / max, that means it is a border point, and it should be green
            }
            
            if xPosition < xMax{ // if the variable x has not reached the other side
                xPosition += spacingOfPoints // keep inching forward, unit by unit
            }else{ // if x has reached other side
                xPosition = -spacingOfPoints*dotSpacingFactor // reset x back to leftmost side
                yPosition -= spacingOfPoints // lower y by one unit
            }
        }
    }
    
    func cutOffPan(maximumSquare: CGFloat, minimumSquare: CGFloat, currentPosition: inout CGFloat){ // function to limit the movement of the pan feature of the camera by setting borders without jumpy glitches
        if currentPosition > maximumSquare{ // if the given value is more than the maximum:
            currentPosition = maximumSquare // set it to the maximum
        }
        
        if currentPosition < minimumSquare{ // if the given value is less than the minimum:
            currentPosition = minimumSquare // set the value to the minimum
        }
        
        // otherwise, just let the value be!
    }
    
    func bounceRun(forAction: inout SKSpriteNode, realAction: SKAction){ // function to give buttons fun little "bounce" when they are pressed:
        forAction.run(SKAction.sequence([SKAction.scale(to: 0.15, duration: 0.1), SKAction.scale(to: 0.3, duration: 0.1), realAction])) // take the parameter sprite, then crush it, expand it, and then run another action that can be determined based on the parameter input
    }
    
    func explodeRunaway(runawaySprite: SKNode){ // function to create a spectacular destruction of a runaway:
        let emitterNode = SKEmitterNode(fileNamed: "smashedRunaway")! // initialize file emitter with the file name
        emitterNode.setScale(0.5) // shrink the emmitter a bit
        emitterNode.zPosition = 10 // put the emitter above most things to see it decently
        emitterNode.position = runawaySprite.position // put the emitter right above the runaway
        emitterNode.numParticlesToEmit = 100 // only emit 100 particles before stopping to make it seem more real
        self.addChild(emitterNode) // add the emitter to the current scene
        
        runawaySprite.removeFromParent() // remove the runaway
        rigid.impactOccurred() // give a celebratory shake of the phone to the user
        
        var runawaysLeft = 0 // set a dummy variable to see if any runaways are left
        for child in self.children{ // for every sprite in current scene:
            if child.name == "runaway"{ // if the sprite is a runaway:
                runawaysLeft += 1 // add to the runaway survivors left list
            }
        }
        
        MemoryVault.set(MemoryVault.value(forKey: "enemiesCrushed") as! Int + 1, forKey: "enemiesCrushed") // add another tally for enemies crushed
        
        if runawaysLeft == 0{ // if all enemies have been crushed:
            didWin = true // give the victory to the player
            isLaunching = false // remove shooting permisions
            isBlocking = false // remove blocking permisions
        }else if isLaunching{ // if there are any enemies left
            isLaunching = false // remove shooting permisions
            isBlocking = false // remove blocking permisions
            let delay = SKAction.wait(forDuration: 1) // timed action
            let popChoice = SKAction.run{self.popupChoices()} // timed action
            self.run(SKAction.sequence([delay, popChoice])) // wait for effect, then present next set of action options
        }
    }
    
    func generateEnemyField(levelOfIntensity: Int){ // function to set up all of enemies, following level difficulty
        var xVal = -gridSpacing * 4 // set up the top left corner to be starting position
        var yVal = gridSpacing * 4 // set up the top left corner to be starting position
        
        for _ in 1 ... 80{ // for the entire 9 by 9 square except for the center
            createRunaway(position: CGPoint(x: xVal, y: yVal)) // place a runaway there
            if xVal < gridSpacing * 4{ // if x can keep inching to the right:
                xVal += gridSpacing // do so
            }else{ // if x has reached the other side:
                xVal = -gridSpacing * 4 // go back to leftmost side
                yVal -= gridSpacing // drop the height by one unit
            }
            if xVal == 0 && yVal == 0{ // if the middle is reached where the player is:
                xVal += gridSpacing // skip over the player
            }
        }
        
        var runawayArray: [SKSpriteNode] = [] // make an empty array to be filled with 80 runaways
        for child in self.children{ // for every sprite in the current scene:
            if child.name == "runaway"{ // if the sprite is a runaway:
                runawayArray.append(child as! SKSpriteNode) // add that runaway to the list
            }
        }
        
        runawayArray.shuffle() // shuffle array for randomness
        
        for _ in 0 ... 79 - levelOfIntensity{ // remove all except for level difficulty:
            runawayArray.remove(at: 0) // by removing from the randomized front for simplicity
        }
        
        for child in self.children{ // for every sprite in the current scene:
            if let sprite = child as? SKSpriteNode{ // for every true sprite
                if sprite.name == "runaway"{ // if the sprite is a runaway:
                    var canStay = false // dummy variable to see if runaway needs removal
                    for currentRunaway in runawayArray{ // go through all of filtered runaways
                        if sprite == currentRunaway{ // if the filtered matches with one of the ones in the scene
                            canStay = true // keep the sprite
                        }
                    }
                    if !canStay{ // if the sprite does not get approved by the array
                        child.removeFromParent() // remove the runaway
                    }
                }
            }
        }
    }
    
    func createRunaway(position: CGPoint){ // function to make a single runaway with everything it needs to later be brought to life:
        let runaway = SKSpriteNode(texture: runawayTexture) // initialize runaway with it's image
        runaway.position = position // move the runaway to the parameter set
        runaway.zPosition = 1 // place the runaway right abothe the dots
        runaway.setScale(0.2) // shrink the runaway down a little
        runaway.name = "runaway" // give the runaway a physics name
        runaway.physicsBody = SKPhysicsBody(texture: runaway.texture!, size: runaway.size) // define the bounds for the physics body of the runaway
        runaway.physicsBody?.categoryBitMask = CharecterClasses.escapee // set the physics category of the runaway to it's own respective category
        runaway.physicsBody?.contactTestBitMask = CharecterClasses.player | CharecterClasses.point // allow for the runaway to sense contact with the player OR the points on the field(both, really)
        runaway.physicsBody?.collisionBitMask = CharecterClasses.collidionNeutral // make the runaway collide with nothing
        self.addChild(runaway) // add the runaway to the current scene
    }
    
    func moveAllRunaways(allSprites: [SKNode]){ // function that takes a list of nodes and moves each runaway there in a way that reseambles real life intelligence, and real life stupidity
        for child in allSprites{ // for every sprite in the parameter list given
            if child.name == "dot"{ // if the sprite is a dot
                if let dot = child as? SKSpriteNode{ // and the dot is a true sprite
                    if dot.position.x == -outerLimit || dot.position.x == outerLimit || dot.position.y == -outerLimit || dot.position.y == outerLimit{ // if the dot is on the border of the field
                        outerDotArray.append(dot.position) // add that dot position to an array of border positions
                    }
                }
            }
        }
        
        for child in allSprites{ // for every sprite in the parameter list given
            if child.name == "runaway"{ // if the sprite is a runaway
                if let runaway = child as? SKSpriteNode{ // if runaway is true sprite
                    if abs(runaway.position.x) >= 800 || abs(runaway.position.y) >= 800{ // if runaway is already on or beyond border:
                        didLoseByEscapee = true // player lost
                        escapeePosition = runaway.position // report the position of the escapee as last camera focus and outro
                    }
                    let currentPosition = runaway.position // otherwise, take current position of runaway
                    var closestDistance: CGFloat = 1000 // make dummy variable for distance
                    var closestDot = CGPoint() // make a slot for the closest dot
                    let runDuration = TimeInterval(0.3) // set a dash speed for rhe runaways
                    
                    for dotPosition in outerDotArray{ // for every dot position in the perimiter of the field:
                        if findDistance(from: dotPosition, to: currentPosition) < closestDistance{ // if the distance to there is less than the shortest distance yet:
                            closestDistance = findDistance(from: dotPosition, to: currentPosition) // update closest position
                            closestDot = dotPosition // update closest dot
                        }
                    }
                    
                    //using closest dot & point
                    let predictedMoveRight = findDistance(from: closestDot, to: CGPoint(x: currentPosition.x + gridSpacing, y: currentPosition.y)) // move right option
                    let predictedMoveLeft = findDistance(from: closestDot, to: CGPoint(x: currentPosition.x - gridSpacing, y: currentPosition.y)) // move left option
                    let predictedMoveUp = findDistance(from: closestDot, to: CGPoint(x: currentPosition.x, y: currentPosition.y + gridSpacing)) // move up option
                    let predictedMoveDown = findDistance(from: closestDot, to: CGPoint(x: currentPosition.x, y: currentPosition.y - gridSpacing)) // move down option
                    
                    let randomInt = Int.random(in: 0..<10) // random integer to choose how to act.
                    let goNuts: Bool = (randomInt <= 2) // 33.33% chance the behaviour is random, 66.67% chance that the movement is mathematically the best.
                    
                    if !goNuts{ // if the movement behaviour is the smarter, mathematically shortest path to escape:
                        if predictedMoveRight < predictedMoveLeft{ // if right is closer to border than left:
                            if predictedMoveRight < predictedMoveUp{ // if right is closer to border than up:
                                if predictedMoveRight < predictedMoveDown{ // if right is closer to border than down:
                                    runaway.run(SKAction.moveBy(x: gridSpacing, y: 0, duration: runDuration)) // move right
                                }else{
                                    runaway.run(SKAction.moveBy(x: 0, y: -gridSpacing, duration: runDuration)) // move down
                                }
                            }else{ // if up is closer to border than down
                                if predictedMoveUp < predictedMoveDown{ //
                                    runaway.run(SKAction.moveBy(x: 0, y: gridSpacing, duration: runDuration)) // move up
                                }else{
                                    runaway.run(SKAction.moveBy(x: 0, y: -gridSpacing, duration: runDuration)) // move down
                                }
                            }
                        }else{
                            if predictedMoveLeft < predictedMoveUp{ // if left is closer to border than up:
                                if predictedMoveLeft < predictedMoveDown{ // if left is closer to border than down:
                                    runaway.run(SKAction.moveBy(x: -gridSpacing, y: 0, duration: runDuration)) // move left
                                }else{
                                    runaway.run(SKAction.moveBy(x: 0, y: -gridSpacing, duration: runDuration)) // move down
                                }
                            }else{
                                if predictedMoveUp < predictedMoveDown{ // if up is closer to border than down
                                    runaway.run(SKAction.moveBy(x: 0, y: gridSpacing, duration: runDuration)) // move up
                                }else{
                                    runaway.run(SKAction.moveBy(x: 0, y: -gridSpacing, duration: runDuration)) // move down
                                }
                            }
                        }
                    }else{ // if chance decided to go nuts:
                        let randomDirection = Int.random(in: 0...4) // choose a random direction:
                        switch randomDirection{ // if the random direction was:
                        case 0:
                            runaway.run(SKAction.moveBy(x: gridSpacing, y: 0, duration: runDuration)) // move right
                        case 1:
                            runaway.run(SKAction.moveBy(x: -gridSpacing, y: 0, duration: runDuration)) // move left
                        case 2:
                            runaway.run(SKAction.moveBy(x: 0, y: gridSpacing, duration: runDuration)) // move up
                        case 3:
                            runaway.run(SKAction.moveBy(x: 0, y: -gridSpacing, duration: runDuration)) // move down
                        case 4:
                            runaway.run(SKAction.moveBy(x: 0, y: 0, duration: runDuration)) // do not move
                        default: // and then:
                            break // nothing, the job was done
                        }
                    }
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // for every time the screen is pressed:
        for touch in touches{ // for every press that came to touch the screen and activate this function:
            let position = touch.location(in: self)
            // get the location of that press relative to the scene's origin
            
            if isChoosingAction && turnPopup.alpha == 1{ // if the player is in choosing mode:
                
                if moveAction.contains(position){ // if the player chose to move:
                    let localTask = SKAction.run { // timed action to run AFTER animation
                        self.dropChoices() // drop down action choices
                        self.isMoving = true // enable permissions
                    }
                    bounceRun(forAction: &moveAction, realAction: localTask) // run timed action AFTER animation
                }
                
                if lookAction.contains(position){ // if the player chose to spectate:
                    let localTask = SKAction.run { // timed action to run AFTER animation
                        self.dropChoices() // drop down action choices
                        self.isLooking = true // enable permissions
                        isSpectating = true // enable permissions
                    }
                    bounceRun(forAction: &lookAction, realAction: localTask) // run timed action AFTER animation
                }
                
                if launchAction.contains(position){ // if the player chose to launch:
                    let localTask = SKAction.run { // timed action to run AFTER animation
                        self.dropChoices() // drop down action choices
                        isLaunching = true // enable permissions
                        isSpectating = true // enable permissions
                    }
                    bounceRun(forAction: &launchAction, realAction: localTask)
                    // run timed action AFTER animation
                }
                
                if blockAction.contains(position){ // if the player chose to block:
                    let localTask = SKAction.run { // timed action to run AFTER animation
                        self.dropChoices() // drop down action choices
                        isBlocking = true // enable permissions
                        isSpectating = true // enable permissions
                    }
                    bounceRun(forAction: &blockAction, realAction: localTask)
                    // run timed action AFTER animation
                }
            }
            
            
            for index in self.children.indices{ // for every sprite in this scene:
                if children[index].name == "runaway" && children[index].contains(position) &&
                isLaunching{ // if the target is a runaway, and permission to fire:
                    let moveCharecter = SKAction.run{charecter.run(SKAction.move(to:
                    self.children[index].position, duration: 0.25))} // timed action
                    let waitForCharecter = SKAction.wait(forDuration: 0.25) // timed action
                    let postMove = SKAction.wait(forDuration: 0.5) // timed action
                    let moveRunaways = SKAction.run{self.moveAllRunaways(allSprites: self.children)}
                    // timed action
                    self.run(SKAction.sequence([moveCharecter, waitForCharecter, moveRunaways, postMove,
                    moveRunaways, postMove])) // launch character into runaway, wait for shatter effect, move
                    // other runaways, wait for effect, repeat that again, and then the popup will be brought.
                }
                
            
                if children[index].name == "dot" && children[index].contains(position) &&
                (children[index] as? SKSpriteNode)?.texture == pointDotTexture && (children[index] as?
                SKSpriteNode)?.zPosition == 0 && isBlocking{ // on other hand, if a dot has all permissions and
                    // player has permision to place barrier on said dot:
                    isBlocking = false // remove permission
                    let popChoice = SKAction.run{self.popupChoices()} // timed action
                    let postMove = SKAction.wait(forDuration: 0.5) // timed action
                    let moveRunaways = SKAction.run{self.moveAllRunaways(allSprites: self.children)}
                    // timed action
                    (children[index] as? SKSpriteNode)?.texture = blockDotTexture
                    // change image of selected dot
                    (children[index] as? SKSpriteNode)?.run(SKAction.sequence([SKAction.scale(to: 0.3,
                    duration: 0.25), moveRunaways, postMove, popChoice])) // swell the dot, move the runaways,
                    // wait for asthetics, and then pop up the next options
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { // for every continouos drag along the screen in the current scene of the view:
        for touch in touches{ // for each of those points in the drag path:
            let position = touch.location(in: viewPoint) // get the position of each point realtive to the origin of the current scene:
            
            if isSpectating{ // if the charecter is allowed to spectate
                if !initialLockOn{ // if not ran yet:
                    initialLockOn = true // cut the loop to not move anchor
                    initialTouchPosition = position // drop anchor
                }

                let positionDeltaX = position.x - initialTouchPosition.x // get delta of current position and initially dropped anchor on x - axis
                let positionDeltaY = position.y - initialTouchPosition.y // get delta of current position and initially dropped anchor on y - axis

                var viewPositionX = initialViewPoint.x - positionDeltaX // get the initial view of the camera and move it by the delta on x - axis
                var viewPositionY = initialViewPoint.y - positionDeltaY // get the initial view of the camera and move it by the delta on y - axis
                
                cutOffPan(maximumSquare: outerLimit, minimumSquare: -outerLimit, currentPosition: &viewPositionX) // put a limit on how far the camera can move, by changing the x - axis if needed
                cutOffPan(maximumSquare: outerLimit, minimumSquare: -outerLimit, currentPosition: &viewPositionY) // put a limit on how far the camera can move, by changing the y - axis if needed
                
                viewPoint.position = CGPoint(x: viewPositionX, y: viewPositionY) // move the camera to the adjusted variables to follow the pan gesture of the player
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { // if there has been no touching activity on the screen for even just a second:
        initialLockOn = false // allow for a new anchor to be set for pan gesture
        initialViewPoint = viewPoint.position // set the new viewpoint anchor for the pan gesture
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) { // the function for the physics engine collidion detection, which is why the CharecterClasses are so important
        var firstBody = SKPhysicsBody() // initialize one physics body
        var secondBody = SKPhysicsBody() // initialize another physics body
        
        if contact.bodyA.node?.name == "charecter" || contact.bodyA.node?.name == "dot"{ // assume that the first physics body will be either the player or the dot
            firstBody = contact.bodyA // set first to the first body
            secondBody = contact.bodyB // set second to the second body
        }else{ // if there is a swap in the physics bodies heirechy:
            firstBody = contact.bodyB // flip
            secondBody = contact.bodyA //flip
        }
        
        if firstBody.node?.name == "charecter" && secondBody.node?.name == "runaway"{ // if player and runaway collide:
            explodeRunaway(runawaySprite: (secondBody.node!)) // call function to explode the runaway
        }
        
        if firstBody.node?.name == "dot" && secondBody.node?.name == "runaway"{ // if dot and runaway collide:
            if (firstBody.node as? SKSpriteNode)?.texture == pointDotTexture{ // check to see if dot is normal:
                firstBody.node?.zPosition = -1 // if it is, set it's zPosition to -1 to indicate barriers cannot be placed there
            }else if (firstBody.node as? SKSpriteNode)?.texture == blockDotTexture{ // if the dot was a barrier type:
                explodeRunaway(runawaySprite: (secondBody.node!)) // call function to explode the runaway
            }
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) { // the function for the physics engine collidion detection, which is why the CharecterClasses are so important, but this is when there is an END of collidion(no more)
        var firstBody = SKPhysicsBody() // initialize one physics body
        var secondBody = SKPhysicsBody() // initialize another physics body
        
        if contact.bodyA.node?.name == "dot"{ // assume that the first physics body will be either the player or the dot
            firstBody = contact.bodyA // set first to the first body
            secondBody = contact.bodyB // set second to the second body
        }else{ // if there is a swap in the physics bodies heirechy:
            firstBody = contact.bodyB // flip
            secondBody = contact.bodyA //flip
        }
        
        if firstBody.node?.name == "dot" && secondBody.node?.name == "runaway"{ // if a dot STOPS touching a runaway:
            firstBody.node?.zPosition = 0 // set it's zPosition back to 0, so I can see that the spot is abvailable for a barrier
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        if !didLoseByEscapee && !didWin{ // if the game is still running, not worn and not lost:
            let cx = charecter.position.x // make charecter position shortcut
            let cy = charecter.position.y // make charecter position shortcut
            
            let tpX = turnPopup.position.x // make turn popup position shortcut
            let tpY = turnPopup.position.y // make turn popup position shortcut
            
            turnPopup.position = viewPoint.position // keep the popup right under the camera
            moveAction.position = CGPoint(x: tpX + 150, y: tpY + 150) // keep the move action button locked in it's place relative to the popup screen
            lookAction.position = CGPoint(x: tpX - 150, y: tpY + 150) // keep the look action button locked in it's place relative to the popup screen
            launchAction.position = CGPoint(x: tpX - 150, y: tpY - 150) // keep the launch action button locked in it's place relative to the popup screen
            blockAction.position = CGPoint(x: tpX + 150, y: tpY - 150) // keep the block action button locked in it's place relative to the popup screen
            moveLabel.position = CGPoint(x: tpX + 150, y: tpY + 50) // keep the move label locked in it's place relative to the popup screen
            lookLabel.position = CGPoint(x: tpX - 150, y: tpY + 50) // keep the look label locked in it's place relative to the popup screen
            shootLabel.position = CGPoint(x: tpX - 150, y: tpY - 250) // keep the shoot label locked in it's place relative to the popup screen
            blockLabel.position = CGPoint(x: tpX + 150, y: tpY - 250) // keep the block label locked in it's place relative to the popup screen
            currentLevelLabel.position = CGPoint(x: tpX, y: tpY + 400) // keep the current level label locked in it's place relative to the popup screen
            
            if !isSpectating{ // if the player is not spectating:
                viewPoint.position = CGPoint(x: cx, y: cy) // keep camera locked on the player
                if isLooking{ // if the player was using the spectate action and they turned it off by shaking phone:
                    isLooking = false // disable permission to look around
                    popupChoices() // give player new options
                }
            }else if isSpectating && isChoosingAction{ // if the player is spectating, but also choosing action:
                isSpectating = false // turn off permission, do not allow that
            }
            
            if pinchSensor.state == .began{ // if a pinch began, put in an initial anchor:
                zoomAnchorHead = 1 / pinchSensor.scale // set anchor to fraction of what the sensor currently is at
            }
            
            if pinchSensor.state.rawValue == 0{ // if a pinch ended, put in an anchor to prepare for next pinch:
                zoomAnchorTail = zoom // set the tail anchor to the current zoom to be used later for delta and new zoom calculations
            }
        }else if didLoseByEscapee{ // if player lost because runaway escaped:
            if !resultLockActivated{ // check this is first time:
                resultLockActivated = true // do not let loop run again to prevent crashes
                for child in children{ // for every sprite:
                    child.removeAllActions() // stop everything
                }
                currentLevel = 0 // reset the current level
                let goBack = SKAction.run{moveToScene(sceneFrom: self, sceneTo: HomeScreen(size: self.size))} // timed action to go back to home screen
                viewPoint.run(SKAction.sequence([SKAction.scale(to: 3, duration: 0.25), SKAction.move(to: escapeePosition, duration: 0.5), SKAction.scale(to: 0.3, duration: 0.25), SKAction.wait(forDuration: 0.5), goBack])) // zoom out, move to the escapee, zoom in, wait for dramatic effect, and go back to main screen
            }
        }else if didWin{ // if player won:
            if !resultLockActivated{ // check this is first time:
                resultLockActivated = true // do not let loop run again to prevent crashes
                for child in children{ // for every sprite:
                    child.removeAllActions() // stop everything
                }
                let goBack = SKAction.run{ // timed action
                    self.removeAllChildren() // erase everything for next level
                    moveToScene(sceneFrom: self, sceneTo: FieldScene(size: self.size)) // move to next level
                }
                viewPoint.run(SKAction.sequence([SKAction.scale(to: 3, duration: 0.25), SKAction.move(to: charecter.position, duration: 0.5), SKAction.scale(to: 0.3, duration: 0.25), SKAction.wait(forDuration: 0.5), goBack])) // zoom out, move to the player, zoom in, wait for dramatic effect, and go back to next level
            }
        }
    }
}



