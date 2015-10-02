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

    var name:String = ""
    var formattedAddress:String = ""
    var boundsNE:CLLocationCoordinate2D!
    var boundsSW:CLLocationCoordinate2D!
    var coordinate:CLLocationCoordinate2D!
    var placeID:String = ""
    
    init(coordinate: CLLocationCoordinate2D) {
    
        self.coordinate = coordinate
    }
}
