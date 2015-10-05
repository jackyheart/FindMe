//
//  SettingsViewController.swift
//  FindMe
//
//  Created by Jacky Tjoa on 5/10/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import Parse

class SettingsViewController: UIViewController {

    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet weak var usernameTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if let currentUser = PFUser.currentUser() {
            
            //profile picture
            let profileImageString = currentUser["profileImage"] as! String
            let imageData = NSData(base64EncodedString: profileImageString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)!
            let image = UIImage(data: imageData)
            
            //display profile picture
            self.profileImgView.image = image
            Util.circleView(self.profileImgView)
            
            //Username
            self.usernameTF.text = currentUser["name"] as? String
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func updateTapped(sender: AnyObject) {
    
        let username = self.usernameTF.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if username.characters.count == 0 {
            
            Util.showAlertWithMessage("Please type a Username", onViewController: self)
        
        } else {
        
            if let currentUser = PFUser.currentUser() {
                
                //update username
                currentUser["name"] = username
                
                //save in Parse
                currentUser.saveInBackgroundWithBlock({ (success, error) -> Void in
                    
                    if error != nil  {
                        
                        print("save failed, error:\(error)\n")
                        
                    } else {
                        
                        if success {
                            
                            print("User saved !\n")
                        }
                    }
                })
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
