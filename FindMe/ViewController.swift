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
    
    /*
    //get friends
    if ((FBSDKAccessToken.currentAccessToken()) != nil) {
    
        FBSDKGraphRequest(graphPath: "me/friends", parameters: ["fields": "id, name"]).startWithCompletionHandler({ (connection, result, error) -> Void in
        
            if error != nil {
            
                print("error: \(error)")
            }
            else {
            
                print("fetched user: \(result)\n")
            }
        })
    }
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //observe auth
        kFirebaseRef.observeAuthEventWithBlock { (authData) -> Void in
            
            if authData != nil {
                
                self.performSegueWithIdentifier("SegueMain", sender: self)
                
            } else {
                
                print("User not authenticated\n")
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
                
                print("FB login cancelled\n")
                
            } else {
                
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                
                kFirebaseRef.authWithOAuthProvider("facebook", token: accessToken, withCompletionBlock: { (error, authData) -> Void in
                    
                    if error != nil {
                        
                        print("login failed: \(error.localizedDescription)\n")
                        
                        Util.showAlertWithMessage(error.localizedDescription, onViewController: self)

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
                                                
                        print("logged in, authData: \(authData)\n")
                        print("uid:\(authData.uid)\n")
                        
                        let gender = authData.providerData["cachedUserProfile"]!["gender"] as? NSString as? String
                        let genderString = (gender == kStringMale) ? "1" : "0"
                        
                        let newUser = [
                            "provider": authData.provider,
                            "firstName": authData.providerData["cachedUserProfile"]!["first_name"] as? NSString as? String,
                            "lastName": authData.providerData["cachedUserProfile"]!["last_name"] as? NSString as? String,
                            "profileImageURL": authData.providerData["profileImageURL"] as? NSString as? String,
                            "displayName": authData.providerData["displayName"] as? NSString as? String,//TODO: check this !
                            "gender": genderString
                        ]
                        
                        //save to Firebase
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
                        
                        Alamofire.request(.GET, profilePictureURL).response(completionHandler: { (request, response, data, errorType) -> Void in
                            
                            if let imageData = data {
                                
                                //Save encoded image to Firebase
                                let encodedImageString = imageData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
                                
                                currentUser.updateChildValues(["encodedImageString":encodedImageString], withCompletionBlock: {
                                    (error:NSError?, ref:Firebase!) in
                                    if (error != nil) {
                                        print("Image Data could not be saved to Firebase.\n")
                                    } else {
                                        print("Image Data saved successfully to Firebase!\n")
                                    }
                                })
                            }
                        })//end request
                    }//else
                })//end auth
            }//end else
        }//end login
    }
    
    //MARK: Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "SegueMain" {
        
            print("proceed")
        }
    }
}
