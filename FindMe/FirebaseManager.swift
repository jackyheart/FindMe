//
//  FirebaseManager.swift
//  FindMe
//
//  Created by Jacky Tjoa on 7/10/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import Firebase

//config
let kFirebaseRef = Firebase(url: "https://intense-heat-4929.firebaseio.com")
let kFirebaseUserPath = kFirebaseRef.childByAppendingPath("users")

//manager
class FirebaseManager: NSObject {
    
    static let sharedInstance = FirebaseManager()
    var authData:FAuthData!
    
    override init() {
        
        super.init()
        
        //observe auth
        kFirebaseRef.observeAuthEventWithBlock { (authData) -> Void in
            
            self.authData = authData
        }
    }
    
    func listenForAuthEvent(callback: (authData:FAuthData) -> Void) {
    
        kFirebaseRef.observeAuthEventWithBlock { (authData) -> Void in
            
            callback(authData: authData)
        }
    }
}
