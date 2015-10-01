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
    
    var currentLocationString:String = "Hong Kong"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        //map
        //37.3319248,-122.0297007 (Apple, Cupertino)
        let camera  = GMSCameraPosition.cameraWithLatitude(37.3319248, longitude: -122.0297007, zoom: 6)
        
        mapView.camera = camera
        mapView.myLocationEnabled = true
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        
        //marker
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 37.3319248, longitude: -122.0297007)
        marker.title = "Apple"
        marker.snippet = "Cupertino"
        marker.map = mapView
        
        //observe change
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
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
    
    //MARK: - KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        let myLocation = change![NSKeyValueChangeNewKey] as! CLLocation
        mapView.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 10.0)
        mapView.settings.myLocationButton = true
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
        
        createRoute(self)
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
    
    //MARK: - Helpers
    
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
                    
                    self.setuplocationMarker(coordinate)
                }
            }
            else {
            
                self.showAlertWithMessage("Unknown Google Map Errors.")
            }
        })
    }
    
    func showAlertWithMessage(message: String) {
        
        let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as! String
        let alertController = UIAlertController(title: appName, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
        }
        
        alertController.addAction(closeAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func setuplocationMarker(coordinate: CLLocationCoordinate2D) {
        
        if locationMarker != nil {
            locationMarker.map = nil
        }
        
        locationMarker = GMSMarker(position: coordinate)
        locationMarker.map = mapView
        locationMarker.appearAnimation = kGMSMarkerAnimationPop
        
        locationMarker.title = mapTasks.fetchedFormattedAddress
        locationMarker.appearAnimation = kGMSMarkerAnimationPop
        locationMarker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
        locationMarker.opacity = 0.75
        
        locationMarker.flat = true
        locationMarker.snippet = "The best place on earth."
    }
    
    func createRoute(sender: AnyObject) {
        
        let origin = currentLocationString
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
                
                self.configureMapAndMarkersForRoute(selectedRoute)
                self.drawRoute(selectedRoute)
                self.displayRouteInfo(selectedRoute)
                
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
        destinationMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
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
            
            mapTasks.getDirections(mapTasks.originAddress, destination: mapTasks.destinationAddress, waypoints: waypointsArray, travelMode: nil, completionHandler: { (status, success) -> Void in
                
                /*
                if success {
                    self.configureMapAndMarkersForRoute()
                    self.drawRoute()
                    self.displayRouteInfo()
                }
                else {
                    print(status)
                }
                */
            })
        }
    }
    
    //MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        textField.text = ""
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        print("textFieldShouldReturn\n")
        
        findAddress(textField.text!)
        
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
