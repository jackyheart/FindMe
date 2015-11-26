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
                
                //Get current User
                //let currentUser = FirebaseManager.sharedInstance.currentUser
                //let currentUserRef:Firebase = kFirebaseUserPath.childByAppendingPath(currentUser.id)
                
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

                FirebaseManager.sharedInstance.loginWithFacebook(accessToken, callback: { (authenticated) -> Void in
                    
                    if !authenticated {
                    
                        if error != nil {
                            Util.showAlertWithMessage(error.localizedDescription, onViewController: self)
                        }
                    }
                })
                
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
