//
//  AppDelegate.swift
//  microManager
//
//  Created by Sebastian Kazakov on 3/15/24.
//

// Acknowledgements:

// Apple for: Swift programming language, Swift Documentation, Xcode for developing environment, and device for programming.
// Mom & Dad: Shelter, food, unconditional love, brutal feedback.
// Sisters: Unofficial cure from any mental ailment, Official source for some good physical trauma, enthusiastic feedback.
// Myself: Borrowing the physics engine I made for a different project, programming everything else, and drawing all of the graphics by hand.




import UIKit // Library for "User Interface Kit"

@main // set as backbone file
class AppDelegate: UIResponder, UIApplicationDelegate { // backbone of my application, that is the parent for everything.

    var window: UIWindow? // the child of the UIResponder, which is the parent for the view controller.


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }


}
