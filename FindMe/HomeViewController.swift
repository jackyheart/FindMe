//
//  HomeViewController.swift
//  FindMe
//
//  Created by Jacky Tjoa on 28/9/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import GoogleMaps

import Alamofire
import SwiftyJSON

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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        //map
        let camera  = GMSCameraPosition.cameraWithLatitude(-33.86, longitude: 151.20, zoom: 6)
        
        mapView.camera = camera
        //mapView = GMSMapView.mapWithFrame(mapView.frame, camera: camera)
        mapView.myLocationEnabled = true
        self.view.addSubview(mapView)
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
        marker.title = "Sydney"
        marker.snippet = "Australia"
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
        
            //mapView.mapType = kGMSTypeNormal
            
            createRoute(self)
            
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
        
        /*
        let addressAlert = UIAlertController(title: "Address Finder", message: "Type the address you want to find:", preferredStyle: UIAlertControllerStyle.Alert)
        
        addressAlert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Address?"
        }
        
        let findAction = UIAlertAction(title: "Find Address", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            let address = (addressAlert.textFields![0]).text
            
            self.mapTasks.geocodeAddress(address, withCompletionHandler: { (status, success) -> Void in
              
                if !success {
                    print(status)
                    
                    if status == "ZERO_RESULTS" {
                        self.showAlertWithMessage("The location could not be found.")
                    }
                }
                else {
                    let coordinate = CLLocationCoordinate2D(latitude: self.mapTasks.fetchedAddressLatitude, longitude: self.mapTasks.fetchedAddressLongitude)
                    self.mapView.camera = GMSCameraPosition.cameraWithTarget(coordinate, zoom: 14.0)
                    
                    self.setuplocationMarker(coordinate)
                }
            })
        }
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
            
        }
        
        addressAlert.addAction(findAction)
        addressAlert.addAction(closeAction)
        
        presentViewController(addressAlert, animated: true, completion: nil)
        */
        
        self.mapTasks.geocodeAddress(address, withCompletionHandler: { (status, success) -> Void in
            
            self.searchTF.resignFirstResponder()
            
            if !success {
                print(status)
                
                if status == kGMAPSTATUS_ZERO_RESULTS {
                    self.showAlertWithMessage("The location could not be found.")
                }
            }
            else {
                let coordinate = CLLocationCoordinate2D(latitude: self.mapTasks.fetchedAddressLatitude, longitude: self.mapTasks.fetchedAddressLongitude)
                self.mapView.camera = GMSCameraPosition.cameraWithTarget(coordinate, zoom: 10.0)
                
                self.setuplocationMarker(coordinate)
            }
        })
    }
    
    func showAlertWithMessage(message: String) {
        let alertController = UIAlertController(title: "GMapsDemo", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
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
        
        locationMarker.title = mapTasks.fetchedFormattedAddress
        locationMarker.appearAnimation = kGMSMarkerAnimationPop
        locationMarker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
        locationMarker.opacity = 0.75
        
        locationMarker.flat = true
        locationMarker.snippet = "The best place on earth."
    }
    
    func createRoute(sender: AnyObject) {
        let addressAlert = UIAlertController(title: "Create Route", message: "Connect locations with a route:", preferredStyle: UIAlertControllerStyle.Alert)
        
        addressAlert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Origin?"
        }
        
        addressAlert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Destination?"
        }
        
        let createRouteAction = UIAlertAction(title: "Create Route", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            let origin = (addressAlert.textFields![0]).text!
            let destination = (addressAlert.textFields![1]).text!
            
            self.mapTasks.getDirections(origin, destination: destination, waypoints: nil, travelMode: self.travelMode, completionHandler: { (status, success) -> Void in
                
                self.searchTF.resignFirstResponder()
                
                if success {
                    self.configureMapAndMarkersForRoute()
                    self.drawRoute()
                    self.displayRouteInfo()
                }
                else {
                    print(status)
                }
            })
        }
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
            
        }
        
        addressAlert.addAction(createRouteAction)
        addressAlert.addAction(closeAction)
        
        presentViewController(addressAlert, animated: true, completion: nil)
    }
    
    func configureMapAndMarkersForRoute() {
    
        originMarker = GMSMarker(position: self.mapTasks.originCoordinate)
        originMarker.map = self.mapView
        originMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
        originMarker.title = self.mapTasks.originAddress
        
        destinationMarker = GMSMarker(position: self.mapTasks.destinationCoordinate)
        destinationMarker.map = self.mapView
        destinationMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        destinationMarker.title = self.mapTasks.destinationAddress
    }
    
    func drawRoute() {
        let route = mapTasks.overviewPolyline["points"] as! String
        
        let path: GMSPath = GMSPath(fromEncodedPath: route)
        routePolyline = GMSPolyline(path: path)
        routePolyline.map = mapView
    }
    
    func displayRouteInfo() {
        let distance = mapTasks.totalDistance + "\n" + mapTasks.totalDuration
        
        print("\(distance)\n")
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
                
                if success {
                    self.configureMapAndMarkersForRoute()
                    self.drawRoute()
                    self.displayRouteInfo()
                }
                else {
                    print(status)
                }
            })
        }
    }
    
    //MARK: - UITextFieldDelegate
    
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
