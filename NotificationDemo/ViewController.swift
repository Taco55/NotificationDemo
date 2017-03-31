//
//  ViewController.swift
//  NotificationDemo
//
//  Created by Taco Kind on 30-03-17.
//  Copyright © 2017 Taco Kind. All rights reserved.
//

import UIKit
import RealmSwift

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    // User data
    fileprivate enum UserLoggedIn: Int {
        case user1 = 0, user2, none
    }
    fileprivate var userLoggedIn: UserLoggedIn = .none
    fileprivate var currentAppUser: User? {
        return (try! Realm()).objects(User.self).first // Only one User object exists per user's Realm
    }
    
    // Default Realm
    fileprivate var realm: Realm { return try! Realm() }
    
    // Realm to store data in (i.e. user2 stores data in shared Realm of user 1)
    fileprivate var dataRealm: Realm {
        if let configuration = RealmManager.sharedRealmConfiguration {
            return try! Realm(configuration: configuration)
        } else {
            return try! Realm()
        }
    }
    
    // Data
    fileprivate var dogs: Results<Dog>!
    
    // Controls
    fileprivate var tableView: UITableView!
    fileprivate var textField: UITextField!
    fileprivate var button: UIButton!
    fileprivate var reloadButton: UIButton!
    fileprivate var logoutButton: UIButton!
    fileprivate var realmLabel = UILabel()
    
    // Notification token
    fileprivate var notificationToken: NotificationToken?
    fileprivate var appUserNotificationToken: NotificationToken?
    
    // Escape method when notifications are not delivered
    fileprivate var _dataChanged: Bool = false
    fileprivate var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.tableView = UITableView()
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.bounces = false
        self.tableView.separatorStyle = .singleLine
        self.tableView.delegate      =   self
        self.tableView.dataSource    =   self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.keyboardDismissMode = .onDrag
        self.view.addSubview(self.tableView)
        
        self.realmLabel = UILabel()
        self.realmLabel.text = "No user logged in"
        self.realmLabel.textAlignment = .left
        self.realmLabel.font = UIFont.systemFont(ofSize: 16)
        self.realmLabel.numberOfLines = 1
        self.realmLabel.textColor = UIColor.black
        self.realmLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.realmLabel)
        
        self.textField = UITextField()
        self.textField.textColor = UIColor.black
        self.textField.font = UIFont.systemFont(ofSize: 14)
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.autocorrectionType = UITextAutocorrectionType.no
        self.textField.textAlignment = .left
        self.textField.backgroundColor = UIColor.clear
        self.textField.layer.cornerRadius = 6.0
        self.textField.layer.masksToBounds = true
        self.textField.layer.borderColor = UIColor.gray.cgColor
        self.textField.layer.borderWidth = 1.0
        self.textField.placeholder = "Dog name here"
        self.view.addSubview(self.textField)
        
        self.button = UIButton()
        self.button.titleLabel!.font =  UIFont.systemFont(ofSize: 16)
        self.button.contentHorizontalAlignment = .center
        self.button.setTitle("Create dog", for: .normal)
        self.button.setTitleColor(UIColor.black, for: UIControlState())
        self.button.addTarget(self, action: #selector(ViewController.addDogAction(_:)), for: .touchUpInside)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.button)
        
        self.reloadButton = UIButton()
        self.reloadButton.titleLabel!.font =  UIFont.systemFont(ofSize: 18)
        self.reloadButton.contentHorizontalAlignment = .center
        self.reloadButton.setTitle("Manual reload", for: .normal)
        self.reloadButton.setTitleColor(UIColor.black, for: UIControlState())
        self.reloadButton.addTarget(self, action: #selector(ViewController.reloadAction(_:)), for: .touchUpInside)
        self.reloadButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.reloadButton )
        
        self.logoutButton = UIButton()
        self.logoutButton.titleLabel!.font =  UIFont.systemFont(ofSize: 18)
        self.logoutButton.contentHorizontalAlignment = .center
        self.logoutButton.setTitle("Logout", for: .normal)
        self.logoutButton.setTitleColor(UIColor.black, for: UIControlState())
        self.logoutButton.addTarget(self, action: #selector(ViewController.logoutAction(_:)), for: .touchUpInside)
        self.logoutButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.logoutButton )
        
        let loginUser1Button = UIBarButtonItem(title: "Login user1", style: .plain, target: self, action: #selector(authenticate(_:)))
        loginUser1Button.tag = UserLoggedIn.user1.rawValue
        loginUser1Button.isEnabled = false
        
        let loginUser2Button = UIBarButtonItem(title: "Login user2", style: .plain, target: self, action: #selector(authenticate(_:)))
        loginUser2Button.tag = UserLoggedIn.user2.rawValue
        loginUser2Button.isEnabled = true
        
        navigationItem.leftBarButtonItem = loginUser1Button
        navigationItem.rightBarButtonItem = loginUser2Button
        
        self.authenticate(loginUser1Button)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let margins = view.layoutMarginsGuide
        
        self.realmLabel.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.realmLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        self.realmLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        self.realmLabel.bottomAnchor.constraint(equalTo: self.textField.topAnchor, constant: -8).isActive = true
        
        self.textField.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        self.textField.trailingAnchor.constraint(equalTo: self.button.leadingAnchor, constant: 8).isActive = true
        self.textField.bottomAnchor.constraint(equalTo: self.tableView.topAnchor, constant: -8).isActive = true
        self.textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        self.button.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 8).isActive = true
        self.button.widthAnchor.constraint(equalToConstant: 100).isActive = true
        self.button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.button.centerYAnchor.constraint(equalTo: self.textField.centerYAnchor).isActive = true
        
        self.tableView.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        self.tableView.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.logoutButton.topAnchor, constant: -8).isActive = true
        
        self.logoutButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        self.logoutButton.widthAnchor.constraint(equalToConstant: 120).isActive = true
        self.logoutButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        self.logoutButton.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor, constant: -20).isActive = true
        
        self.reloadButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        self.reloadButton.widthAnchor.constraint(equalToConstant: 120).isActive = true
        self.reloadButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        self.reloadButton.centerYAnchor.constraint(equalTo: self.logoutButton.centerYAnchor).isActive = true
    }
    
    deinit {
        self.notificationToken?.stop()
        self.appUserNotificationToken?.stop()
    }
    
    // Authentica user
    func authenticate(_ sender: UIBarButtonItem) {
        
        self.notificationToken?.stop()
        
        var userCredentials: Credentials!
        
        switch sender.tag {
        case UserLoggedIn.user1.rawValue:
            userLoggedIn = .user1
            userCredentials = user1
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        case UserLoggedIn.user2.rawValue:
            userLoggedIn = .user2
            userCredentials = user2
            self.navigationItem.leftBarButtonItem?.isEnabled = true
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        default: fatalError()
        }
        
        // Logout any previous user
        if let currentUser = SyncUser.current { currentUser.logOut() }
        
        RealmManager.authenticate(with: userCredentials, register: false) { error in
            guard error == nil else { print(error!); return }
            
            print(String(format: "%@ logged", userCredentials.username))
            
            // We should now wait until User object is synced (i.e. for user details and, for example, to obtain the serverPath of the shared Realm for user2.
            // Two main limitations with ROS:
            // - no user info can be stored in SyncUser so that the information should be stored in a custom Realm object
            // - we must wait until this data is available before we cannot proceed. Unfortunatelly, no priorization of some objects can be applied resulting in a delay
            
            self.realmLabel.text = String(format: "%@ logged in: realm", userCredentials.username)
            
            self.appUserNotificationToken = self.realm.objects(User.self).addNotificationBlock { [unowned self] (changes: RealmCollectionChange) in
                
                guard self.currentAppUser != nil else { print("User info not yet available. Wait until data is available"); return }
                
                let serverPathID = self.dataRealm.configuration.syncConfiguration!.realmURL.absoluteString.components(separatedBy: "/")[3]
                
                // For user1 ID will be "~"
                self.realmLabel.text = String(format: "%@ logged in: realm %@", self.currentAppUser!.username!, serverPathID)
                
                self.searchForDogs()
            }
        }
    }
    
    // Get data for display in table view
    func searchForDogs() {
        
        self.notificationToken?.stop()
        self.dogs = self.dataRealm.objects(Dog.self)
        self.notificationToken = self.dogs.addNotificationBlock { [unowned self] (changes: RealmCollectionChange) in
            
            self._dataChanged = false // Escape variable in case notification is not triggered
            switch changes {
            case .initial(let dogs):
                print("Dog notification: initial run. Number of dogs", dogs.count)
                self.tableView.reloadData()
            case .update(_, let deletions, let insertions, _):
                print(String(format: "Dog notification: update. Deletions: %i - Insertions: %i", deletions.count, insertions.count))
                
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: insertions.map {IndexPath(row: $0, section: 0)}, with: .automatic)
                self.tableView.deleteRows(at: deletions.map {IndexPath(row: $0, section: 0)}, with: .automatic)
                self.tableView.endUpdates()
                
            case .error(let error):
                fatalError(String(describing: error))
            }
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Actions
    ///////////////////////////////////////////////////////////////////////////////////////////
    
    func reloadAction(_ sender: UIButton) {
        guard SyncUser.current != nil else { print("Please login first"); return  }
        
        searchForDogs()
        self.tableView.reloadData()
    }
    
    func logoutAction(_ sender: UIButton) {
        if let currentUser = SyncUser.current { currentUser.logOut() }
        self.realmLabel.text = "No user logged in"
        
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        
        self.dogs = nil
        self.tableView.reloadData()
    }
    
    func addDogAction(_ sender: UIButton) {
        guard SyncUser.current != nil else { print("Please login first"); return  }
        
        if let text = self.textField.text {
            try! dataRealm.write {
                let dog = Dog()
                dog.name = String(format: "%@ - added by %@", text, currentAppUser!.username!)
                self.dataRealm.add(dog)
            }
            self.textField.text = nil
            print("Dog added")
            setEscapeTimer()
        }
    }
    
    func deleteDogAction(_ dog: Dog) {
        try! self.dataRealm.write {
            self.dataRealm.delete(dog)
        }
        print("Dog deleted")
        setEscapeTimer()
    }

    ///////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Escape mechanism
    ///////////////////////////////////////////////////////////////////////////////////////////

    // When notifications are not deliverd, tableview will be updated after the timer has been fired
    func setEscapeTimer() {
        // Set time for escape mechanism
        _dataChanged = true
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.timerFired(_:)), userInfo: nil, repeats: false)
    }

    func timerFired(_ timer: Timer) {
        if _dataChanged {
            print("Notification not triggered. Manual update")
            self.tableView.reloadData()
            _dataChanged = false
        }
        self.timer?.invalidate()
    }
    ///////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Table View Data Sources and Delegate
    ///////////////////////////////////////////////////////////////////////////////////////////
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dogs != nil ? dogs.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = dogs[indexPath.row].name
        cell.accessoryType = .none
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete") { (action, indexPath) -> Void in
            self.deleteDogAction(self.dogs[indexPath.row])
        }
        return [deleteAction]
    }
}

