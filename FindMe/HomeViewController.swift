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

enum TravelModes: Int {
    case Driving
    case Walking
    case Bicycling
    case Transit
}

class HomeViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate {

    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var searchTF: UITextField!
    
    //maps
    let locationManager = CLLocationManager()
    let mapTasks = MapTasks()
    var myLocationMarker: GMSMarker!
    
    //Firebase
    var currentUserRef:Firebase! = nil//reference to the current User Firebase path
    var currentUserSnapshot:FDataSnapshot! = nil//snapshot of the current User
    
    //User
    var myProfileImage:UIImage! = nil
    
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
        
        //Places
        /*
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
        */
        
        /*
        //Parse
        if let currentUser = PFUser.currentUser() {
        
            //profile picture
            let profileImageString = currentUser["profileImage"] as! String
            let imageData = NSData(base64EncodedString: profileImageString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)!
            
            let image = UIImage(data: imageData)
            
            let profileImgView = UIImageView(frame: CGRectMake(100.0, 50.0, 40.0, 40.0))
            profileImgView.image = image
            Util.circleView(profileImgView)
            
            let barItem = UIBarButtonItem(customView: profileImgView)
            self.tabBarController?.navigationItem.rightBarButtonItem = barItem
            
            //name
            let name = currentUser["name"] as! String
            self.tabBarController?.navigationItem.title = name
        }
        */
        
        //Firebase: observe auth
        kFirebaseRef.observeAuthEventWithBlock { (authData) -> Void in
            
            if authData != nil {
                
                //Observe data changed on child nodes
                kFirebaseUserPath.observeEventType(.ChildChanged, withBlock: { (snapshot) -> Void in
                    
                    if snapshot.value is NSNull {
                        
                        print("Users data is null")
                        
                    } else {
                        
                        print("Users list: \(snapshot.value)")
                    }
                })
                
                //Get current logged in User
                self.currentUserRef = kFirebaseUserPath.childByAppendingPath(authData.uid)
                
                //Get current User data (read once)
                self.currentUserRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                    
                    if snapshot.value is NSNull {
                        
                        print("User data is null")
                        
                    } else {
                        
                        //save reference to the snapshot
                        self.currentUserSnapshot = snapshot

                        //Get profile image
                        let encodedImageString = snapshot.value["encodedImageString"] as! String
                        
                        let imageData = NSData(base64EncodedString: encodedImageString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)!
                        let image = UIImage(data: imageData)!
                        
                        //save reference to the profile image
                        self.myProfileImage = image
                        
                        //profile ImageView
                        let profileImgView = UIImageView(frame: CGRectMake(100.0, 50.0, 40.0, 40.0))
                        profileImgView.image = image
                        Util.circleView(profileImgView)
                        
                        //right button item
                        let barItem = UIBarButtonItem(customView: profileImgView)
                        self.tabBarController?.navigationItem.rightBarButtonItem = barItem
                        
                        //title
                        let name = snapshot.value["firstName"] as! String
                        self.tabBarController?.navigationItem.title = name
                    }
                })
                
            } else {
                
                print("HomeViewController: User not authenticated\n")
            }
        }
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
        
        if let userRef = self.currentUserRef {
        
            //save coordinate
            let coordinate = ["latitude":self.mapView.myLocation.coordinate.latitude, "longitude":self.mapView.myLocation.coordinate.longitude]
            userRef.updateChildValues(coordinate, withCompletionBlock: {
                (error:NSError?, ref:Firebase!) in
                if (error != nil) {
                    print("coordinate data could not be saved to Firebase.\n")
                } else {
                    print("coordinate data saved successfully to Firebase!\n")
                }
            })
            
            //update marker
            if let snapshot = self.currentUserSnapshot {
            
                let radius = self.myProfileImage.size.width * 0.5
                let resizedImage = Util.resizeImageWithImage(self.myProfileImage, scaledToSize: CGSize(width: radius, height: radius))
                
                self.myLocationMarker = GMSMarker(position: self.mapView.myLocation.coordinate)
                self.myLocationMarker.icon = resizedImage
                self.myLocationMarker.map = self.mapView
                self.myLocationMarker.appearAnimation = kGMSMarkerAnimationPop
                self.myLocationMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
                
                self.myLocationMarker.title = snapshot.value["firstName"] as! String
                self.myLocationMarker.snippet = "Me"
            }
        
        } else {
        
            print("current user ref is nil")
        }

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
    }
    
    //MARK: - Geocoding
    
    func findAddress(address: String) {
        
        self.mapTasks.geocodeAddress(address, withCompletionHandler: { (success, results) -> Void in
            
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
