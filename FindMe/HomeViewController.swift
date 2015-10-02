//
//  HomeViewController.swift
//  FindMe
//
//  Created by Jacky Tjoa on 28/9/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import GoogleMaps

enum TravelModes: Int {
    case Driving
    case Walking
    case Bicycling
    case Transit
}

class HomeViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {

    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var searchTF: UITextField!
    
    let locationManager = CLLocationManager()
    let mapTasks = MapTasks()
    var locationMarker: GMSMarker!

    var markersArray: Array<GMSMarker> = []
    var waypointsArray: Array<String> = []
    
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    var travelMode = TravelModes.Driving
    
    var placesClient:GMSPlacesClient!
    var placePicker:GMSPlacePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        //map
        //37.3319248,-122.0297007 (Apple, Cupertino)
        /*
        let camera  = GMSCameraPosition.cameraWithLatitude(37.3319248, longitude: -122.0297007, zoom: 6)
        
        mapView.camera = camera
        mapView.myLocationEnabled = true
        mapView.settings.compassButton = true
        
        //marker
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 37.3319248, longitude: -122.0297007)
        marker.title = "Apple"
        marker.snippet = "Cupertino"
        marker.map = mapView
        
        //observe change
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
        */
        
        //places
        self.placesClient = GMSPlacesClient()
        
        self.placesClient.currentPlaceWithCallback { (likelihoodList, error) -> Void in
            
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)\n")
                return
            }
            
            if let placeLikelihoodList = likelihoodList {
            
                let gmsPlace = placeLikelihoodList.likelihoods.first?.place
                
                if let gmsPlace = gmsPlace {
                
                    let place = Place(coordinate: gmsPlace.coordinate)
                    place.name = gmsPlace.name
                    place.formattedAddress = gmsPlace.formattedAddress
                    
                    print("gmsPlace: \(gmsPlace)\n")
                    
                    self.mapView.camera = GMSCameraPosition.cameraWithTarget(gmsPlace.coordinate, zoom: 12.0)
                    self.placeLocationMarker(place)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
        
            mapView.myLocationEnabled = true
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        
        print("oldLocation: \(oldLocation)\n")
        print("newLocation: \(newLocation)\n")
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        print("locationManager error: \(error)\n")
    }
    
    //MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        let myLocation = change![NSKeyValueChangeNewKey] as! CLLocation
        mapView.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 10.0)
        mapView.settings.myLocationButton = true
        
        print("\nmyLocation: \(mapView.myLocation.coordinate)\n")
        //22.284681, 114.158177
    }
    
    //MARK: - IBActions
    
    @IBAction func segmentChanged(sender: AnyObject) {
    
        let segment = sender as! UISegmentedControl
        
        if segment.selectedSegmentIndex == 0 {
            
            mapView.mapType = kGMSTypeNormal
            
        } else if segment.selectedSegmentIndex == 1 {
            
            mapView.mapType = kGMSTypeSatellite
            
        } else if segment.selectedSegmentIndex == 2 {
            
            mapView.mapType = kGMSTypeHybrid
        }
    }
    
    @IBAction func getDirections(sender: AnyObject) {
        
        //createRoute(self)
        
        /*
        if UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!) {
        
            print("Google Maps app installed. Do something.\n")
            
            UIApplication.sharedApplication().openURL(NSURL(string:
                "comgooglemaps://?center=40.765819,-73.975866&zoom=14&views=traffic")!)
            
        } else {
        
            self.showAlertWithMessage("No Google Maps app installed on this device.")
        }
        */
        
        let center = CLLocationCoordinate2DMake(37.788204, -122.411937)
        let northEast = CLLocationCoordinate2DMake(center.latitude + 0.001, center.longitude + 0.001)
        let southWest = CLLocationCoordinate2DMake(center.latitude - 0.001, center.longitude - 0.001)
        let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let config = GMSPlacePickerConfig(viewport: viewport)
        placePicker = GMSPlacePicker(config: config)
        
        placePicker?.pickPlaceWithCallback({ (place: GMSPlace?, error: NSError?) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)\n")
                return
            }
            
            if let place = place {
                let nameLabelText = place.name
                let addressLabelText = place.formattedAddress.componentsSeparatedByString(", ").joinWithSeparator("\n")
                print("\(nameLabelText) \(addressLabelText)\n")
                
            } else {
                
                let nameLabelText = "No place selected"
                let addressLabelText = ""
                
                print("\(nameLabelText) \(addressLabelText)\n")
            }
        })
    }
    
    @IBAction func changeTransitModes(sender: AnyObject) {
    
        let segment = sender as! UISegmentedControl
        
        switch segment.selectedSegmentIndex {
        
        case TravelModes.Walking.rawValue:
            self.travelMode = TravelModes.Walking
            break
            
        case TravelModes.Bicycling.rawValue:
            self.travelMode = TravelModes.Bicycling
            break
            
        case TravelModes.Transit.rawValue:
            self.travelMode = TravelModes.Transit
            break
            
        default:
            self.travelMode = TravelModes.Driving
            break
        }
        
        self.recreateRoute()
    }
    
    //MARK: - Geocoding
    
    func findAddress(address: String) {
        
        self.mapTasks.geocodeAddress(address, withCompletionHandler: { (success, results) -> Void in
            
            self.searchTF.resignFirstResponder()
            
            if (!success) {
            
                self.showAlertWithMessage("Error getting location.\n")
                return
            }
            
            let results = results!
            let status = results["status"] as! String
            
            if status == kGMAPSTATUS_ZERO_RESULTS {
                
                self.showAlertWithMessage("The location could not be found.")
                
            } else if status == kGMAPSTATUS_OK {
            
                let allResults = results["results"] as! [[NSObject:AnyObject]]
                
                if allResults.count > 0 {
                
                    let result = allResults[0]
                    
                    let geometry = result["geometry"] as! [NSObject:AnyObject]
                    let latitude = ((geometry["location"]as! [NSObject:AnyObject])["lat"] as! NSNumber).doubleValue
                    let longitude = ((geometry["location"] as! [NSObject:AnyObject])["lng"] as! NSNumber).doubleValue
                    
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    self.mapView.camera = GMSCameraPosition.cameraWithTarget(coordinate, zoom: 10.0)
                    
                    let place:Place = Place(coordinate: coordinate)
                    place.placeID = result["place_id"] as! String
                    place.name = result["address_components"]![0]["long_name"] as! String
                    place.formattedAddress = result["formatted_address"] as! String
                    
                    self.placeLocationMarker(place)
                }
            }
            else {
            
                self.showAlertWithMessage("Unknown Google Map Errors.")
            }
        })
    }
    
    //MARK: - Helpers
    
    func showAlertWithMessage(message: String) {
        
        let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as! String
        let alertController = UIAlertController(title: appName, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
        }
        
        alertController.addAction(closeAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func placeLocationMarker(place: Place!) {
        
        if locationMarker != nil {
            locationMarker.map = nil
        }
        
        locationMarker = GMSMarker(position: place.coordinate)
        locationMarker.map = mapView
        locationMarker.appearAnimation = kGMSMarkerAnimationPop
        locationMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        
        locationMarker.title = place.name
        locationMarker.snippet = place.formattedAddress
    }
    
    //MARK: - Directions / Routing
    
    func createRoute(sender: AnyObject) {
        
        let origin = self.mapView.myLocation.coordinate
        let destination = self.searchTF.text!
        
        self.mapTasks.getDirections(origin, destination: destination, waypoints: nil, travelMode: self.travelMode, completionHandler: { (success, dictionary) -> Void in
            
            self.searchTF.resignFirstResponder()
            
            if (!success) {
                
                self.showAlertWithMessage("Error calculating route.\n")
                return
            }
            
            let dictionary = dictionary!
            let status = dictionary["status"] as! String
            
            if status == kGMAPSTATUS_OK {
                
                let selectedRoute = (dictionary["routes"] as! [[NSObject:AnyObject]])[0]
                
                //plot route
                self.configureMapAndMarkersForRoute(selectedRoute)
                self.drawRoute(selectedRoute)
                self.displayRouteInfo(selectedRoute)
                
                //camera
                let legs = selectedRoute["legs"] as! [[NSObject:AnyObject]]
                let startLocationDictionary = legs[0]["start_location"] as! [NSObject:AnyObject]
                let originCoordinate = CLLocationCoordinate2DMake(startLocationDictionary["lat"] as! Double, startLocationDictionary["lng"] as! Double)
                
                self.mapView.camera = GMSCameraPosition.cameraWithTarget(originCoordinate, zoom: 6.0)
            }
            else {
                
                self.showAlertWithMessage("No routes found !")
            }
        })
    }
    
    func configureMapAndMarkersForRoute(routeDict:[NSObject:AnyObject]) {
    
        let legs = routeDict["legs"] as! Array<Dictionary<NSObject, AnyObject>>
        
        let startLocationDictionary = legs[0]["start_location"] as! [NSObject:AnyObject]
        let originCoordinate = CLLocationCoordinate2DMake(startLocationDictionary["lat"] as! Double, startLocationDictionary["lng"] as! Double)
        
        let endLocationDictionary = legs[legs.count - 1]["end_location"] as! [NSObject:AnyObject]
        let destinationCoordinate = CLLocationCoordinate2DMake(endLocationDictionary["lat"] as! Double, endLocationDictionary["lng"] as! Double)
        
        let originAddress = legs[0]["start_address"] as! String
        let destinationAddress = legs[legs.count - 1]["end_address"] as! String
        
        let originMarker = GMSMarker(position: originCoordinate)
        originMarker.map = self.mapView
        originMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
        originMarker.title = originAddress
        
        let destinationMarker = GMSMarker(position: destinationCoordinate)
        destinationMarker.map = self.mapView
        destinationMarker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
        destinationMarker.title = destinationAddress
    }
    
    func drawRoute(routeDict:[NSObject:AnyObject]) {
        
        let overviewPolyline = routeDict["overview_polyline"] as! [NSObject:AnyObject]
        let route = overviewPolyline["points"] as! String
        
        let path: GMSPath = GMSPath(fromEncodedPath: route)
        let routePolyline = GMSPolyline(path: path)
        routePolyline.map = mapView
    }
    
    func displayRouteInfo(routeDict:[NSObject:AnyObject]) {
        
        MapTasks.calculateTotalDistanceAndDuration(routeDict)
    }
    
    func clearRoute() {
        
        originMarker.map = nil
        destinationMarker.map = nil
        routePolyline.map = nil
        
        originMarker = nil
        destinationMarker = nil
        routePolyline = nil
        
        if markersArray.count > 0 {
            for marker in markersArray {
                marker.map = nil
            }
            
            markersArray.removeAll(keepCapacity: false)
        }
    }
    
    func recreateRoute() {
        
        if let _ = routePolyline {
            clearRoute()
            
            /*
            mapTasks.getDirections(mapTasks.originAddress, destination: mapTasks.destinationAddress, waypoints: waypointsArray, travelMode: nil, completionHandler: { (status, success) -> Void in
                
                
                if success {
                    self.configureMapAndMarkersForRoute()
                    self.drawRoute()
                    self.displayRouteInfo()
                }
                else {
                    print(status)
                }
                
            })
            */
        }
    }
    
    //MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        textField.text = ""
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        print("textFieldShouldReturn\n")
        
        let address = textField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if address?.characters.count == 0 {
        
            self.showAlertWithMessage("Please enter a place name")
            
        } else {
        
            findAddress(address!)
        }
        
        return true
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
