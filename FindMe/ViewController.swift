//
//  ViewController.swift
//  FindMe
//
//  Created by Jacky Tjoa on 28/9/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import Parse
import ParseFacebookUtilsV4
import Alamofire
import FBSDKCoreKit
import Firebase

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Observe login
        FirebaseManager.sharedInstance.listenForAuthEvent { (authenticated) -> Void in
            
            if authenticated {
                                
                //Segue
                self.performSegueWithIdentifier("SegueMain", sender: self)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginWithFacebook(sender: AnyObject) {
        
        //Firebase
        let fbLoginManager = FBSDKLoginManager()
        
        //login
        fbLoginManager.logInWithReadPermissions(["user_friends"], fromViewController: self) { (result, error) -> Void in
            
            if error != nil {
                
                print("fb error:\(error.localizedDescription)\n")
                
            } else if result.isCancelled {
                
                print("fb login cancelled\n")
                
            } else {
                
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString

                /*
                FirebaseManager.sharedInstance.loginWithFacebook(accessToken, callback: { (authenticated) -> Void in
                    
                    if !authenticated {
                    
                        if error != nil {
                            Util.showAlertWithMessage(error.localizedDescription, onViewController: self)
                        }
                    }
                })
                */
                
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
                
            }//end else
        }//end login
    }
    
    //MARK: Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "SegueMain" {
        
            print("proceed to Home screen")
        }
    }
}
