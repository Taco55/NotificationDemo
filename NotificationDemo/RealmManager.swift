//
//  RealmManager.swift
//  NotificationDemo
//
//  Created by Taco Kind on 30-03-17.
//  Copyright © 2017 Taco Kind. All rights reserved.
//

import RealmSwift
import UIKit

public struct Credentials {
    internal var username: String
    internal var password: String
    internal var email: String?
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
        self.email = nil
    }
    
    public init(username: String, password: String, email: String) {
        self.username = username
        self.password = password
        self.email = email
    }
}


public class RealmManager: NSObject  {
    
    
    //API
    public static var host: String!
    public static var appPath: String!
    
    // Computed values based on host and appPath
    public static var syncServerURL: URL {
        return URL(string: "realm://\(host!):9080/")!
    }
    public static var realmURL: URL {
        return syncServerURL.appendingPathComponent("~/\(appPath!)")
    }
    public static var syncAuthURL: URL {
        return URL(string: "http://\(host!):9080")!
    }
    
    static var realm: Realm { return try! Realm() }
    
    fileprivate static var sharedServerPath: String? {
        if let user = realm.objects(User.self).first  {
            return user.sharedServerPath
        } else {
            return nil
        }
    }
    
    
    fileprivate static var permissionChangetoken: NotificationToken?
    
    
    public static func configureRealmObjectServer(host: String, appPath: String, logging: SyncLogLevel = .warn) {
        self.host = host
        self.appPath = appPath
        SyncManager.shared.logLevel = logging
    }
    
    
    /////////////////////////////////////////////////////////////////
    // Mark: - Realm and realm configuration
    /////////////////////////////////////////////////////////////////
    
    // Get shared Realm
    public static var sharedRealmConfiguration: Realm.Configuration? {
        let user = Realm.Configuration.defaultConfiguration.syncConfiguration!.user
        if let sharedServerPath = self.sharedServerPath {
            let url = self.syncServerURL.appendingPathComponent("\(sharedServerPath)/\(self.appPath!)")
            return Realm.Configuration(syncConfiguration: SyncConfiguration(user: user, realmURL: url))
        } else {
            return nil
        }
    }
    
    class func setRealm(for realmUser: SyncUser) {
        
        // Configure Realm for SyncUser
        let configuration = Realm.Configuration(
            inMemoryIdentifier: "inMemoryRealm",
            syncConfiguration: SyncConfiguration(user: realmUser, realmURL: self.realmURL),
            
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 1) {
                }
        }
        )
        Realm.Configuration.defaultConfiguration = configuration
    }
    
    
    //////////////////////////////////////////////////////////////////////////////
    // MARK: - Authentication
    //////////////////////////////////////////////////////////////////////////////
    
    
    class func authenticate(with credentials: Credentials, register: Bool, completionHandler: @escaping (NSError?) -> Void)->Void {
        
        SyncUser.logIn(with: SyncCredentials.usernamePassword(username: credentials.username, password: credentials.password, register: register), server: RealmManager.syncAuthURL) { realmUser, error in
            
            if let error = error { completionHandler(error as NSError); return }
            
            DispatchQueue.main.async {
                guard let realmUser = realmUser else { fatalError(String(describing: error)) }
                // Set new Realm for logged in User
                self.setRealm(for: realmUser)
                
                // Seed database for new user
                if register {
                    print("New user \(credentials.username) registered: seed with a dog")
                    
                    // Create user
                    let user = User()
                    user.username = credentials.username
                    user.email = credentials.email
                    
                    // Add dog and link to current user
                    let dog = Dog()
                    dog.name = String(format: "%@_dog",credentials.username)
                    dog.owner = user
                    
                    try! realm.write {
                        realm.add(user)
                        realm.add(dog)
                    }
                }
                completionHandler(nil)
            }
            
        }
    }
    
    
    //////////////////////////////////////////////////////////////////////////////
    // MARK: - Authorization
    //////////////////////////////////////////////////////////////////////////////
    
    
    public class func changePermission(for user: SyncUser, anotherUserID: String) {
        let realmURL = realm.configuration.syncConfiguration!.realmURL.absoluteString
        
        let managementRealm = try! user.managementRealm()
        let permissionChange = SyncPermissionChange(realmURL: realmURL,    // The remote Realm URL on which to apply the changes
            userID: anotherUserID, // The user ID for which these permission changes should be applied
            mayRead: true,         // Grant read access
            mayWrite: true,        // Grant write access
            mayManage: true)      // Grant management access
        
        try! managementRealm.write { managementRealm.add(permissionChange) }
        
        self.permissionChangetoken = managementRealm.objects(SyncPermissionChange.self).filter("id = %@", permissionChange.id).addNotificationBlock { notification in
            if case .update(let changes, _, _, _) = notification, let change = changes.first {
                
                print("update")
                // Object Server processed the permission change operation
                switch change.status {
                case .notProcessed: break // handle case
                case .success: break // handle case
                case .error: break // handle case
                }
                print(change.statusMessage ?? "") // contains error or informational message
            }
        }
    }
}
