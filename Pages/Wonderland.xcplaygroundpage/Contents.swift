import UIKit
import PlaygroundSupport

/*
This project demonstrates simple things that can be achieved simply by using UIViews, simple animations and some touch gestures
 
 All animated images and characters in this project is drawn by me using a mouse.
 */
//: ## Evan in the Wonderland
//: #### Make sure the Assistant editor is open with Timeline displayed.
let view = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
view.backgroundColor = UIColor(red: 65/255, green: 65/255, blue: 75/255, alpha: 1)


// Creating Wonderland where Evan lives in.
let wonderland = Wonderland()
wonderland.skyColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
wonderland.groundColor = #colorLiteral(red: 0.584132339, green: 0.2527932002, blue: 0.1236199935, alpha: 1)
view.addSubview(wonderland)
//: Meet Evan.
let evan = wonderland.showEvan()
//: #### Try tapping and dragging around the scene and see what you can find! 😎 (I've heard things about THAT tree)

/*:
 Evan can do alot of things, such as
 - __walk()__
 - __speedWalk()__
 - __stop()__
 */
/*:
 * *__Swiping right__* on Evan makes him walk faster
 * *__swiping left__* makes him slow.
 */
// Below are the commands to make Evan walk.
//evan.walk()
//evan.speedWalk()
//evan.stop()
//evan.walk(seconds: 5)
/*:
There's also a really cool surprise. Try swiping down on Evan when he's not walking to make him sit down.
 */
//: ### Nightfall
//: Tap on the ☀️ icon on the top left corner to change to night time.
// Or uncomment the lines below
//wonderland.toNightTime()
//evan.walk()
/*:
 It's getting dark, lets help Evan navigate by turning on the torch light. *__Tap and hold__* on the screen to turn on the torch light. Then, drag up and down to navigate.
 */

//: You can also try doing that while evan is 🚶 *__walking__*








PlaygroundPage.current.liveView = view
