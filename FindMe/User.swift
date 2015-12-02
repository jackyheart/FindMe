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
    
    var ref:Firebase! = nil
    var firstName:String! = ""
    var lastName:String! = ""
    var gender:Int! = 1
    var profileImage:UIImage!
    var location:CLLocationCoordinate2D!
    var marker:GMSMarker! = nil //Google Map
    
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
        
    init(snapshot:FDataSnapshot) {
    
        self.ref = snapshot.ref
        self.firstName = snapshot.value["firstName"] as! String
        self.lastName = snapshot.value["lastName"] as! String
        self.gender = Int(snapshot.value["gender"] as! String)
    }
}
