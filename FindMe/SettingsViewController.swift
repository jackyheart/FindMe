//
//  SettingsViewController.swift
//  FindMe
//
//  Created by Jacky Tjoa on 5/10/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import Parse
import Firebase

class SettingsViewController: UIViewController, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var profileImgBtn: UIButton!
    @IBOutlet weak var usernameTF: UITextField!
    let kTextCancel = NSLocalizedString("Cancel", comment: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if let currentUser = PFUser.currentUser() {
            
            //profile picture
            let profileImageString = currentUser["profileImage"] as! String
            let imageData = NSData(base64EncodedString: profileImageString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)!
            let image = UIImage(data: imageData)
            
            self.profileImgBtn.setImage(image, forState: .Normal)
            
            //Username
            self.usernameTF.text = currentUser["name"] as? String
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - IBActions
    
    @IBAction func profileImgBtnTapped(sender: AnyObject) {
    
       let alertController = UIAlertController(title: "Choose Sources", message: "Pick media from sources", preferredStyle: .ActionSheet)
        
        //Cancel
        let cancelAction = UIAlertAction(title: kTextCancel, style: .Cancel) { (action) -> Void in
            
            print("Cancel")
        }
        alertController.addAction(cancelAction)
        
        //Camera source
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
        
            let cameraAction = UIAlertAction(title: "Camera", style: .Default) { (action) -> Void in
            
                let picker = UIImagePickerController()
                picker.sourceType = .Camera
                picker.allowsEditing = false
                picker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.Camera)!
                picker.delegate = self
                
                self.presentViewController(picker, animated: true, completion: nil)
            }
            
            alertController.addAction(cameraAction)
        }
    
        //Photo source
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
        
            let photoAction = UIAlertAction(title: "Photo Library", style: .Default) { (action) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                  
                    let picker = UIImagePickerController()
                    picker.sourceType = .PhotoLibrary
                    picker.allowsEditing = false
                    picker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary)!
                    picker.delegate = self
                    
                    self.presentViewController(picker, animated: true, completion: nil)
                })
            }
            alertController.addAction(photoAction)
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
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

    @IBAction func logout(sender: AnyObject) {
        
        kFirebaseRef.unauth()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        
         dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        //Update UI
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        self.profileImgBtn.setImage(image, forState: .Normal)
        
        //Save encoded image to Firebase
        let currentUserRef = FirebaseManager.sharedInstance.currentUser.ref
        let imageData = UIImagePNGRepresentation(image)!
        let encodedImageString = imageData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        
        currentUserRef.updateChildValues(["encodedImageString":encodedImageString], withCompletionBlock: {
            (error:NSError?, ref:Firebase!) in
            if (error != nil) {
                print("Image Data could not be saved to Firebase.\n")
            } else {
                print("Image Data saved successfully to Firebase!\n")
            }
        })
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
     
        self.profileImgBtn.setImage(image, forState: .Normal)
        dismissViewControllerAnimated(true, completion: nil)
        
        /*
        //User ref
        let currentUserRef = FirebaseManager.sharedInstance.currentUser.ref
        
        //Save encoded image to Firebase
        let imageData = UIImagePNGRepresentation(image)!
        let encodedImageString = imageData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        
        currentUserRef.updateChildValues(["encodedImageString":encodedImageString], withCompletionBlock: {
            (error:NSError?, ref:Firebase!) in
            if (error != nil) {
                print("Image Data could not be saved to Firebase.\n")
            } else {
                print("Image Data saved successfully to Firebase!\n")
            }
        })
        */
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
