//
//  User.swift
//  FindMe
//
//  Created by Jacky Tjoa on 11/11/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import GoogleMaps

class User: NSObject {

    //static let sharedInstance = User() //singleton
    var id:String!
    var userPathRef:Firebase!
    var profileImage:UIImage!
    
    var firstName:String! = ""
    var lastName:String! = ""
    var location:CLLocationCoordinate2D!
    var gender:Int! = 1
    
    //Google Map
    var marker:GMSMarker! = nil
    
    /*
    firstName = Jacky;
    gender = 1;
    lastName = Coolheart;
    latitude = "1.303553811781307";
    longitude = "103.7972148923184";
    profileImageURL = "https://scontent.xx.fbcdn.net/hprofile-ash2/v/t1.0-1/
    displayName = "Jacky Coolheart";
    encodedImageString = "xxx"
    */
    
    init(userID:String) {
        super.init()
        
        self.id = userID
    }
}
