//
//  MapUtil.swift
//  FindMe
//
//  Created by Jacky Tjoa on 29/9/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class MapUtil: NSObject {

    let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json"
    var lookupAddressResults: Dictionary<NSObject, AnyObject>!
    var fetchedFormattedAddress: String!
    var fetchedAddressLongitude: Double!
    var fetchedAddressLatitude: Double!
    
    let baseURLDirections = "https://maps.googleapis.com/maps/api/directions/json"
    var selectedRoute: Dictionary<NSObject, AnyObject>!
    var overviewPolyline: Dictionary<NSObject, AnyObject>!
    var originCoordinate: CLLocationCoordinate2D!
    var destinationCoordinate: CLLocationCoordinate2D!
    var originAddress: String!
    var destinationAddress: String!
    
    var totalDistanceInMeters: UInt = 0
    var totalDistance: String!
    var totalDurationInSeconds: UInt = 0
    var totalDuration: String!
    
    override init() {
        super.init()
    }

    func geocodeAddress(address: String!, withCompletionHandler completionHandler: (success:Bool, routes:[String:AnyObject]?) -> Void) {

        /*
        {
            results =     (
                {
                    "address_components" =             (
                        {
                            "long_name" = Singapore;
                            "short_name" = SG;
                            types =                     (
                                country,
                                political
                            );
                        }
                    );
                    "formatted_address" = Singapore;
                    geometry =             {
                        bounds =                 {
                            northeast =                     {
                                lat = "1.4707592";
                                lng = "104.0884808";
                            };
                            southwest =                     {
                                lat = "1.1587023";
                                lng = "103.6055448";
                            };
                        };
                        location =                 {
                            lat = "1.352083";
                            lng = "103.819836";
                        };
                        "location_type" = APPROXIMATE;
                        viewport =                 {
                            northeast =                     {
                                lat = "1.4707592";
                                lng = "104.0884808";
                            };
                            southwest =                     {
                                lat = "1.1587023";
                                lng = "103.6055448";
                            };
                        };
                    };
                    "place_id" = ChIJdZOLiiMR2jERxPWrUs9peIg;
                    types =             (
                        country,
                        political
                    );
                }
            );
            status = OK;
        }
        */
        
        Alamofire.request(.GET, baseURLGeocode, parameters: ["address":address], encoding: ParameterEncoding.URLEncodedInURL, headers: nil).response(completionHandler: { (request, response, data, errorType) -> Void in
            
            do {
            
                let dictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                print("geocode dictionary:\n\(dictionary)\n")
                completionHandler(success: true, routes: dictionary as? [String : AnyObject])
            }
            catch {
            
                print("geocode error: \(error)\n")
                completionHandler(success: false, routes: nil)
            }
        })
    }
    
    func getDirections(origin: CLLocationCoordinate2D, destination: String!, waypoints: Array<String>!, travelMode: TravelModes!, completionHandler: (success:Bool, routes:[String:AnyObject]?) -> Void) {
     
        var travelModeString = ""
        
        switch travelMode.rawValue {
            
        case TravelModes.Walking.rawValue:
            travelModeString = "walking"
            
        case TravelModes.Bicycling.rawValue:
            travelModeString = "bicycling"
            
        case TravelModes.Transit.rawValue:
            travelModeString = "transit"
            
        default:
            travelModeString = "driving"
        }
        
        let originCoordinateString = "\(origin.latitude),\(origin.longitude)"
        
        Alamofire.request(.GET, baseURLDirections, parameters: ["origin":originCoordinateString, "destination":destination, "mode":travelModeString], encoding: .URLEncodedInURL, headers: nil).response { (request, response, data, error) -> Void in
            
            print("request:\(request)\n")
            print("response:\(response)\n")
            
            do {
                
                let dictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                
                print("direction dictionary:\n\(dictionary)\n")
                completionHandler(success: true, routes: dictionary as? [String : AnyObject])
            }
            catch {
                
                print("direction error: \(error)\n")
                completionHandler(success: false, routes: nil)
            }
        }
    }
    
    class func calculateTotalDistanceAndDuration(routeDictionary: [NSObject:AnyObject]) {
        
        let legs = routeDictionary["legs"] as! Array<Dictionary<NSObject, AnyObject>>
        
        var totalDistanceInMeters:UInt = 0
        var totalDurationInSeconds:UInt = 0
        
        for leg in legs {
            totalDistanceInMeters += (leg["distance"] as! Dictionary<NSObject, AnyObject>)["value"] as! UInt
            totalDurationInSeconds += (leg["duration"] as! Dictionary<NSObject, AnyObject>)["value"] as! UInt
        }
        
        let distanceInKilometers: Double = Double(totalDistanceInMeters / 1000)
        let totalDistance = "Total Distance: \(distanceInKilometers) Km"
        
        let mins = totalDurationInSeconds / 60
        let hours = mins / 60
        let days = hours / 24
        let remainingHours = hours % 24
        let remainingMins = mins % 60
        let remainingSecs = totalDurationInSeconds % 60
        
        let totalDuration = "Duration: \(days) d, \(remainingHours) h, \(remainingMins) mins, \(remainingSecs) secs"
        
        print(totalDistance + " " + totalDuration)
    }
}
