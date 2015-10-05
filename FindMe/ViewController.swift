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

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let _ = PFUser.currentUser() {
        
            print("User exist, proceed to next screen")
            
            self.performSegueWithIdentifier("SegueMain", sender: self)
            
            //TODO: For testing purposes only... 
            
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
            
        } else {
        
            print("User doesn't exist\n")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginWithFacebook(sender: AnyObject) {
        
        //let currentUser = PFUser.currentUser()
        
        //if currentUser == nil {
        
            let permissions = ["user_friends"]
            PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) {
                (user: PFUser?, error: NSError?) -> Void in
                if let user = user {
                    if user.isNew {
                        print("User signed up and logged in through Facebook!\n")
                    } else {
                        print("User logged in through Facebook!\n")
                    }
                    
                    if ((FBSDKAccessToken.currentAccessToken()) != nil) {
                        
                        FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, gender, birthday, email"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                            
                            if error != nil {
                                
                                print("error: \(error)")
                            }
                            else {
                                
                                print("fetched user: \(result)\n")
                                
                                /*
                                fetched user: {
                                gender = male;
                                id = 10153232677869541;
                                name = "Jacky Coolheart";
                                }
                                */
                                
                                let curUser = PFUser.currentUser()!
                                
                                curUser["name"] = result["name"]
                                curUser["facebookID"] = result["id"]
                                
                                if result["gender"] as! String == "male" {
                                
                                    curUser["gender"] = "1"
                                
                                } else {
                                
                                    curUser["gender"] = "0"
                                }
                                
                                //save in Parse
                                curUser.saveInBackgroundWithBlock({ (success, error) -> Void in
                                    
                                    if error != nil  {
                                    
                                        print("save failed, error:\(error)\n")
                                    
                                    } else {
                                    
                                        if success {
                                        
                                            print("User saved !\n")
                                        }
                                    }
                                })
                                
                                //get profile picture
                                let fbID = curUser["facebookID"]
                                let profilePictureURL = NSURL(string: "https://graph.facebook.com/\(fbID)/picture?type=large")!
                                
                                Alamofire.request(.GET, profilePictureURL).response(completionHandler: { (request, response, data, errorType) -> Void in
                                    
                                    //print("imageData:\(data)\n")
                                    
                                    if let imageData = data {
                                        
                                        //Parse
                                        let encodedImageString = imageData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
                                        curUser["profileImage"] = encodedImageString
                                        
                                        //save in Parse
                                        curUser.saveInBackgroundWithBlock({ (success, error) -> Void in
                                            
                                            if error != nil  {
                                                
                                                print("save profile picture failed, error:\(error)\n")
                                                
                                            } else {
                                                
                                                if success {
                                                    
                                                    print("User profile picture saved !\n")
                                                }
                                            }
                                        })
                                        
                                        //UIView
                                        let image = UIImage(data: imageData)
                                        
                                        let imageView = UIImageView(frame: CGRectMake(10.0, 50.0, 100.0, 100.0))
                                        imageView.image = image
                                        
                                        self.view.addSubview(imageView)
                                    }
                                })
                            }
                        })
                    }
                    
                    /*
                    PF_FBSession *fbSession = [PFFacebookUtils session];
                    NSString *accessToken = [fbSession accessToken];
                    self.imageData = [[NSMutableData alloc] init];
                    NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me/picture?type=large&return_ssl_resources=1&access_token=%@", accessToken]];
                    */
                    
                    /*
                    NSURL *profilePictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [[PFUser currentUser] objectForKey:facebookId]]];
                    NSURLRequest *profilePictureURLRequest = [NSURLRequest requestWithURL:profilePictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f]; // Facebook profile picture cache policy: Expires in 2 weeks
                    [NSURLConnection connectionWithRequest:profilePictureURLRequest delegate:self];
                    */
                    
                    /*
                    let fbID = PFUser.currentUser()!["facebookId"]
                    let profilePictureURL = NSURL(string: "https://graph.facebook.com/\(fbID)/picture?type=large")!
                    
                    Alamofire.request(.GET, profilePictureURL).response(completionHandler: { (request, response, data, errorType) -> Void in
                        
                        print("imageData:\(data)\n")
                    })
                    
                    self.performSegueWithIdentifier("SegueMain", sender: self)
                    */
                    
                } else {
                    print("Uh oh. The user cancelled the Facebook login.\n")
                }
            }
        //}
    }
    
    //MARK: Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "SegueMain" {
        
            print("proceed")
        }
    }
}

