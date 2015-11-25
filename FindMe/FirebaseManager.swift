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
            
            var isAuthenticated:Bool = false
            
            if authData != nil {
                
                isAuthenticated = true
                print("\nauthData != nil, uid: \(authData.uid)")
                
                //Get current logged in User
                let currentUserRef = kFirebaseUserPath.childByAppendingPath(authData.uid)
                
                //Initialize User object
                self.currentUser = User(userID: authData.uid)
                self.currentUser.userPathRef = currentUserRef
                
                //Observe event of current User
                currentUserRef.observeEventType(.Value, withBlock: { (snapshot) -> Void in
                    
                    //print("\nuserRef .Value snapshot:\n\(snapshot)\n")
                    print("\nuserRef .Value updated\n")
                    
                    if snapshot.value is NSNull {
                        
                        print("User data is NULL")
                        
                    } else {
                        
                        //fetch data
                        self.currentUser.firstName = snapshot.value["firstName"] as! String
                        self.currentUser.lastName = snapshot.value["lastName"] as! String
                        self.currentUser.gender = Int(snapshot.value["gender"] as! String)
                        
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
                })
                
                //observe change
                currentUserRef.observeEventType(.ChildChanged, withBlock: { (snapshot) -> Void in
                    
                    print("userRef .ChildChanged snapshot:\n\(snapshot)\n")
                })
            }
            else {
            
                print("User not authenticated\n")
            }
            
            //return function
            callback(isAuthenticated)
            
        }//end block
    }//end func
    
    func loginWithFacebook(accessToken:String, callback: (Bool) -> Void) {
    
        var isAuthenticatedAndSaved:Bool = false
        
        kFirebaseRef.authWithOAuthProvider("facebook", token: accessToken, withCompletionBlock: { (error, authData) -> Void in
            
            if error != nil {
                
                print("login failed: \(error.localizedDescription)\n")

                if let errorCode = FAuthenticationError(rawValue: error.code) {
                    switch (errorCode) {
                    case .UserDoesNotExist:
                        print("Handle invalid user\n")
                    case .InvalidEmail:
                        print("Handle invalid email\n")
                    case .InvalidPassword:
                        print("Handle invalid password\n")
                    default:
                        print("Handle default situation\n")
                    }
                }
                
            } else {
                
                print("\n(fb) login success, authData: \n\(authData)\n")
                print("(fb) uid:\(authData.uid)\n")
                
                let gender = authData.providerData["cachedUserProfile"]!["gender"] as! String
                let genderString = (gender == kStringMale) ? "1" : "0"
                
                let newUser = [
                    "id":authData.uid,
                    "provider": authData.provider,
                    "firstName": authData.providerData["cachedUserProfile"]!["first_name"] as! String,
                    "lastName": authData.providerData["cachedUserProfile"]!["last_name"] as! String,
                    "profileImageURL": authData.providerData["profileImageURL"] as! String,
                    "displayName": authData.providerData["displayName"] as! String,
                    "gender": genderString
                ]
                
                //save to Firebase
                print("Saving new User.\n")
                
                let currentUser:Firebase = kFirebaseUserPath.childByAppendingPath(authData.uid)
                
                currentUser.setValue(newUser, withCompletionBlock: {
                    (error:NSError?, ref:Firebase!) in
                    if (error != nil) {
                        print("New user Data could not be saved.\n")
                    } else {
                        
                        isAuthenticatedAndSaved = true //update status
                        print("New user Data saved successfully!\n")
                    }
                })
                
                //get profile picture
                let urlString = authData.providerData["profileImageURL"] as! String
                let profilePictureURL = NSURL(string: urlString)!
                
                print("Request profile picture from profileImageURL.\n")
                Alamofire.request(.GET, profilePictureURL).response(completionHandler: { (request, response, data, errorType) -> Void in
                    
                    if let imageData = data {
                        
                        //Save encoded image to Firebase
                        let encodedImageString = imageData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
                        
                        print("Retrieved profile image data\n")
                        
                        currentUser.updateChildValues(["encodedImageString":encodedImageString], withCompletionBlock: {
                            (error:NSError?, ref:Firebase!) in
                            if (error != nil) {
                                print("Image Data could not be saved to Firebase.\n")
                            } else {
                                print("Image Data saved successfully to Firebase!\n")
                            }
                        })
                    }//end imageData
                })//end request
            }//else
        })//end auth
        
        //return function
        callback(isAuthenticatedAndSaved)
    }
}
