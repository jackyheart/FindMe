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
        
        //observe login
        kFirebaseRef.observeAuthEventWithBlock { (authData) -> Void in
            
            if authData != nil {
                
                //Get current logged in User
                let currentUserRef = kFirebaseUserPath.childByAppendingPath(authData.uid)
                User.sharedInstance.userPathRef = currentUserRef
                
                //Get current User data
                currentUserRef.observeEventType(.Value, withBlock: { (snapshot) -> Void in
                    
                    print("child Value snapshot:\n\(snapshot)\n")
                    
                    if snapshot.value is NSNull {
                        
                        print("User data is NULL")
                        
                    } else {
                        
                        //save reference to the snapshot
                        User.sharedInstance.snapshot = snapshot
                        
                        if let encodedImageString = snapshot.value["encodedImageString"]! {
                        
                            //Get profile image
                            let encodedImageString = encodedImageString as! String
                            let imageData = NSData(base64EncodedString: encodedImageString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)!
                            
                            //save reference to the profile image
                            let image = UIImage(data: imageData)!
                            User.sharedInstance.profileImage = image
                            
                            //profile ImageView
                            let profileImgView = UIImageView(frame: CGRectMake(100.0, 50.0, 40.0, 40.0))
                            profileImgView.image = image
                            Util.circleView(profileImgView)
                            
                            //right button item
                            let barItem = UIBarButtonItem(customView: profileImgView)
                            self.tabBarController?.navigationItem.rightBarButtonItem = barItem
                        }
                        
                        //navigation title
                        let name = snapshot.value["firstName"] as! String
                        self.tabBarController?.navigationItem.title = name
                    }
                })
                
                //observe change
                currentUserRef.observeEventType(.ChildChanged, withBlock: { (snapshot) -> Void in
                    
                    print("child changed snapshot:\n\(snapshot)\n")
                })
                
                //Segue
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
                
                print("fb login cancelled\n")
                
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
                                
                                print("Retrieved profile image data\n")
                                
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
