//
//  AppDelegate.swift
//  NotificationDemo
//
//  Created by Taco Kind on 30-03-17.
//  Copyright © 2017 Taco Kind. All rights reserved.
//

import UIKit
import RealmSwift


// Define some arbitrary test users that are used to share data between each other
let user1 = Credentials(username: "user1", password: "user1", email: "user1@123.nl")
let user2 = Credentials(username: "user2", password: "user2", email: "user2@123.nl")

//////////////////////////////////////////
// Please change to corrrec host
let host: String = "192.168.2.217"
//////////////////////////////////////////

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // To be able to test the notifications two users will be registered in UserDefaults.
    // UserDefaults are used since it is not (yet) possible to determine whether a user is already registered using the ROS API.
    var user1created: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "user1Available")
        }
        set(user) {
            UserDefaults.standard.set(user, forKey: "user1Available")
        }
    }
    
    var user2created: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "user2Available")
        }
        set(user) {
            UserDefaults.standard.set(user, forKey: "user2Available")
        }
    }
    
    fileprivate var appUserNotificationToken: NotificationToken?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        RealmManager.configureRealmObjectServer(host: host, appPath: "notificationDemo", logging: .warn)
        
        // Logout a user that might be logge in already
        SyncUser.current?.logOut()


        // Create users for first run
        if !user1created || !user2created {
            print("Register user 2")
            RealmManager.authenticate(with: user2, register: true) { error in
                guard error == nil else { print(error!)
                    print("Users are probably already created. Unfortunatelly, this cannot be determined in advance with the current version of Realm. Please re-compile and run again")
                    self.user1created = true; self.user2created = true
                    return
                }
                
                print("user 2 is registered")
                self.user2created = true
                
                let user2Identity = SyncUser.current!.identity
                
                //
                // Login user 1 and provide permission to user 2
                //
                print("Register user 1")
                SyncUser.current!.logOut()
                RealmManager.authenticate(with: user1, register: true) { error in
                    guard error == nil else { print(error!); return }
                    
                    print("User 1 is registered")
                    self.user1created = true
                    
                    // Provide user2 permission to Realm of user1
                    RealmManager.changePermission(for: SyncUser.current!, anotherUserID: user2Identity!)
                    
                    
                    let user1Identity = SyncUser.current!.identity
                    //
                    // Login user 2 again -> to store the ID of user1 in appUser object of user2 (user 2 is than able to access the Realm of user 1)
                    //
                    SyncUser.current!.logOut()
                    RealmManager.authenticate(with: user2, register: false) { error in
                        guard error == nil else { print(error!); return }
                        
                        let realm = try! Realm()
                        let users = realm.objects(User.self)

                        // Waint until AppUser object of user2 is available in order to store the shared Realm path
                        self.appUserNotificationToken = users.addNotificationBlock { [unowned self] (changes: RealmCollectionChange) in
                            
                            guard let appUser = users.first else { print("AppUser info not yet available. Wait until data is available"); return }

                            if let syncUser = SyncUser.current {
                                // These actions should be performed only once

                                print("Add shared Realm path to AppUser object of user 2.")
                                
                                try! Realm().write {
                                    appUser.sharedServerPath = user1Identity
                                }
                                
                                syncUser.logOut()
                                self.initializeLandingViewController()
                            }
                        }
                    }
                }
            }
        } else {
            print("Users are already registered. Just login")
            self.initializeLandingViewController()
        }
        
        return true
    }
    
    
    func initializeLandingViewController() {
        self.window?.rootViewController = UINavigationController(rootViewController: ViewController())
        self.window?.makeKeyAndVisible()
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

