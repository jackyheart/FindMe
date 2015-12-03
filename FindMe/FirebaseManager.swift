//
//  FirebaseManager.swift
//  FindMe
//
//  Created by Jacky Tjoa on 7/10/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import Firebase
import UIKit
import Alamofire

//config
let kFirebaseRef = Firebase(url: "https://intense-heat-4929.firebaseio.com")
let kFirebaseUserPath = kFirebaseRef.childByAppendingPath("users")

//manager
class FirebaseManager: NSObject {
    
    static let sharedInstance = FirebaseManager()
    var currentUser:User! = nil

    func listenForAuthEvent(callback: (Bool) -> Void) {
        
        kFirebaseRef.observeAuthEventWithBlock { (authData) -> Void in
            
            if authData != nil {
                
                print("\nauthData != nil, uid: \(authData.uid)")
                
                //Get current logged in User
                let currentUserRef = kFirebaseUserPath.childByAppendingPath(authData.uid)
                
                //Read current User
                currentUserRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                    
                    print("\nuserRef .Value updated\n")
                    
                    if snapshot.value is NSNull {
                        
                        print("User data is NULL")
                        
                    } else {
                        
                        //Initialize User object
                        self.currentUser = User(snapshot: snapshot)
                        
                        if let encodedImageString = snapshot.value["encodedImageString"]! {
                            
                            print("encodedImageString not nil !\n")
                            
                            //Get profile image
                            let encodedImageString = encodedImageString as! String
                            let imageData = NSData(base64EncodedString: encodedImageString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)!
                            
                            //save reference to the profile image
                            let image = UIImage(data: imageData)!
                            self.currentUser.profileImage = image
                        }
                    }
                    
                    //return function
                    callback(true)
                })
            }
            else {
            
                print("User not authenticated\n")
                callback(false)
            }
            
        }//end block
    }//end func
    
    func loginWithFacebook(accessToken:String, callback: (Bool) -> Void) {
    
        //var isAuthenticatedAndSaved:Bool = false
    
        //return function
        //callback(isAuthenticatedAndSaved)
    }
}
