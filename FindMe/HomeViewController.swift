//
//  HomeViewController.swift
//  FindMe
//
//  Created by Jacky Tjoa on 28/9/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import GoogleMaps
import Parse
import Firebase

class HomeViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate {

    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var searchTF: UITextField!
    
    //maps
    let locationManager = CLLocationManager()
    let mapUtil = MapUtil()
    var myLocationMarker: GMSMarker!
    
    //places
    var placesClient:GMSPlacesClient!
    var placePicker:GMSPlacePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //CLLocationManager
        self.locationManager.delegate = self
        self.locationManager.distanceFilter = 100.0//100 meters kCLDistanceFilterNone
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.requestWhenInUseAuthorization()
        
        //Map View
        self.mapView.myLocationEnabled = true
        self.mapView.settings.myLocationButton = true
        self.mapView.settings.compassButton = true
        self.mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        print("HomeVC viewWillDisappear")
    
        self.mapView.removeObserver(self, forKeyPath: "myLocation")
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - GMSMapViewDelegate
    
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        
         NSLog("You tapped at %f,%f", coordinate.latitude, coordinate.longitude)
    }
    
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {
        
        print("idle at pos: \(position.target)")
    }
    
    //MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
        
            self.mapView.myLocationEnabled = true
            self.mapView.settings.myLocationButton = true
            self.locationManager.startUpdatingLocation()
        }
    }
    
    /*
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        
        print("oldLocation: \(oldLocation.coordinate)\n")
        print("newLocation: \(newLocation.coordinate)\n")
        
        self.mapView.camera = GMSCameraPosition(target: newLocation.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        
        //self.locationManager.stopUpdatingLocation()
    }
    */
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        print("locationManager error: \(error)\n")
    }
    
    //MARK: - GMS KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        print("\nmyLocation: \(mapView.myLocation.coordinate)\n")
        
        let currentUserRef = User.sharedInstance.userPathRef
        let userSnapshot = User.sharedInstance.snapshot
        
        //Save coordinate
        let coordinate = ["latitude":self.mapView.myLocation.coordinate.latitude, "longitude":self.mapView.myLocation.coordinate.longitude]
        currentUserRef.updateChildValues(coordinate, withCompletionBlock: {
            (error:NSError?, ref:Firebase!) in
            if (error != nil) {
                print("coordinate data could not be saved to Firebase.\n")
            } else {
                print("coordinate data saved successfully to Firebase!\n")
            }
        })
        
        //Update marker
        let profileImage = User.sharedInstance.profileImage
        let radius = profileImage.size.width * 0.5
        let resizedImage = Util.resizeImageWithImage(profileImage, scaledToSize: CGSize(width: radius, height: radius))
        
        self.myLocationMarker = GMSMarker(position: self.mapView.myLocation.coordinate)
        self.myLocationMarker.icon = resizedImage
        self.myLocationMarker.map = self.mapView
        self.myLocationMarker.appearAnimation = kGMSMarkerAnimationPop
        self.myLocationMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        
        self.myLocationMarker.title = userSnapshot.value["firstName"] as! String
        self.myLocationMarker.snippet = "Me"
        
        //self.mapView.camera = GMSCameraPosition(target: self.mapView.myLocation.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
    }

    //MARK: - IBActions
    
    @IBAction func segmentChanged(sender: AnyObject) {
    
        let segment = sender as! UISegmentedControl
        
        if segment.selectedSegmentIndex == 0 {
            
            self.mapView.mapType = kGMSTypeNormal
            
        } else if segment.selectedSegmentIndex == 1 {
            
            self.mapView.mapType = kGMSTypeSatellite
            
        } else if segment.selectedSegmentIndex == 2 {
            
            self.mapView.mapType = kGMSTypeHybrid
        }
    }
    
    @IBAction func getDirections(sender: AnyObject) {
        
        //TODO: For testing
    }
    
    //MARK: - Marker
    
    func placeLocationMarker(place: Place!) {
        
        if self.myLocationMarker != nil {
            self.myLocationMarker.map = nil
        }
        
        self.myLocationMarker = GMSMarker(position: place.coordinate)
        self.myLocationMarker.map = mapView
        self.myLocationMarker.appearAnimation = kGMSMarkerAnimationPop
        self.myLocationMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        
        self.myLocationMarker.title = place.name
        self.myLocationMarker.snippet = place.formattedAddress
        
        /*
        if let currentUser = PFUser.currentUser() {
            
            //profile picture
            let profileImageString = currentUser["profileImage"] as! String
            let imageData = NSData(base64EncodedString: profileImageString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)!
            let image = UIImage(data: imageData)!
            
            let radius = image.size.width * 0.5
            let resizedImage = Util.resizeImageWithImage(image, scaledToSize: CGSize(width: radius, height: radius))
            self.myLocationMarker.icon = resizedImage
            
            //title
            self.myLocationMarker.title = currentUser["name"] as! String
        }
        */
    }
    
    //MARK: - Geocoding
    
    func findAddress(address: String) {
        
        self.mapUtil.geocodeAddress(address, withCompletionHandler: { (success, results) -> Void in
            
            self.searchTF.resignFirstResponder()
            
            if (!success) {
            
                Util.showAlertWithMessage("Error getting location.", onViewController: self)
                return
            }
            
            let results = results!
            let status = results["status"] as! String
            
            if status == kGMAPSTATUS_ZERO_RESULTS {
                
                Util.showAlertWithMessage("The location could not be found.", onViewController: self)
                
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
            
                Util.showAlertWithMessage("Unknown Google Map Errors.", onViewController: self)
            }
        })
    }

    //MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        textField.text = ""
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        print("textFieldShouldReturn\n")
        
        let address = textField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if address?.characters.count == 0 {
        
            Util.showAlertWithMessage("Please enter a place name.", onViewController: self)
            
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
