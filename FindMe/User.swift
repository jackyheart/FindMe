//
//  User.swift
//  FindMe
//
//  Created by Jacky Tjoa on 11/11/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import Firebase

class User: NSObject {

    static let sharedInstance = User() //singleton
    var userPathRef:Firebase!
    var snapshot:FDataSnapshot!
    var profileImage:UIImage!
    
    private override init() {}
}
