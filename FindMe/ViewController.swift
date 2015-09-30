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
import GoogleMaps

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let currentUser = PFUser.currentUser()
        
        if currentUser == nil {
        
            print("user doesn't exist")
        }
        else {
        
            print("User exist, proceed to next screen")
            
            self.performSegueWithIdentifier("SegueMain", sender: self)
            
            //TODO: For testing purposes only...
            /*
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
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginWithFacebook(sender: AnyObject) {
        
        let currentUser = PFUser.currentUser()
        
        if currentUser == nil {
        
            let permissions = ["user_friends"]
            PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) {
                (user: PFUser?, error: NSError?) -> Void in
                if let user = user {
                    if user.isNew {
                        print("User signed up and logged in through Facebook!\n")
                    } else {
                        print("User logged in through Facebook!\n")
                    }
                } else {
                    print("Uh oh. The user cancelled the Facebook login.\n")
                }
            }
        }
    }
    
    //MARK: Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "SegueMain" {
        
            print("proceed")
        }
    }
}

