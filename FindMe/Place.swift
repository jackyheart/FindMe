//
//  Place.swift
//  FindMe
//
//  Created by Jacky Tjoa on 1/10/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import CoreLocation

class Place: NSObject {

    var formattedAddress:String!
    var boundsNE:CLLocationCoordinate2D!
    var boundsSW:CLLocationCoordinate2D!
    var location:CLLocationCoordinate2D!
    var placeID:String!
}
