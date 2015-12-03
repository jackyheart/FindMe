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
    
    //user array
    var otherUserArray:[User] = []
    
    //User
    var currentUser:User! = nil
    
    //status
    var firstShowLocation:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //TODO: Internet connection check !
        
        //CLLocationManager
        self.locationManager.delegate = self
        self.locationManager.distanceFilter = 100.0//100 meters kCLDistanceFilterNone
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.requestWhenInUseAuthorization()
        
        //Map View
        self.mapView.delegate = self
        self.mapView.myLocationEnabled = true
        self.mapView.settings.myLocationButton = true
        self.mapView.settings.compassButton = true
        self.mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
        
        self.currentUser = FirebaseManager.sharedInstance.currentUser
        let currentUserRef = self.currentUser.ref
        
        //Read current User (single)
        currentUserRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
            
            //Right profile icon
            if self.currentUser.profileImage != nil {
                
                let profileImgView = UIImageView(frame: CGRectMake(100.0, 50.0, 40.0, 40.0))
                profileImgView.image = self.currentUser.profileImage
                Util.circleView(profileImgView)
                
                //right button item
                if self.tabBarController?.navigationItem.rightBarButtonItem == nil {
                    let barItem = UIBarButtonItem(customView: profileImgView)
                    self.tabBarController?.navigationItem.rightBarButtonItem = barItem
                }
            }
            
            //navigation title
            self.tabBarController?.navigationItem.title = "\(self.currentUser.firstName) \(self.currentUser.lastName)"
        })
        
        /*
        kFirebaseUserPath.observeEventType(.ChildChanged, withBlock: { (snapshot) -> Void in

            let userID = snapshot.value["id"] as! String
            
            if self.currentUser.id != userID {
            
                print("(global) ChildChanged, snapshot:\(snapshot)")
                print("(global) ChildChanged, snapshot.value:\(snapshot.value)")
            }
        })
        */
        
        //Get all users / Global (single)
        kFirebaseUserPath.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
            
            for child in snapshot.children.allObjects as! [FDataSnapshot] {
            
                let val = child.value
                
                if self.currentUser.ref.key == child.ref.key {
                    
                    //ignore current User
                    continue
                }

                //Add other Users to array
                let user = User(snapshot: child)
                
                //location
                let lat = val["latitude"] as! CLLocationDegrees
                let lng = val["longitude"] as! CLLocationDegrees
                user.location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                
                //profile image
                if let encodedImageString = val["encodedImageString"]! {
                    
                    print("(other user) encodedImageString not nil !\n")
                    
                    //Get profile image
                    let encodedImageString = encodedImageString as! String
                    let imageData = NSData(base64EncodedString: encodedImageString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)!
                    
                    //save reference to the profile image
                    let image = UIImage(data: imageData)!
                    user.profileImage = image
                }
                
                //add to array
                self.otherUserArray.append(user)
            }
        })

        //Observe change on all Users / Global (repeat)
        kFirebaseUserPath.observeEventType(.Value, withBlock: { (snapshot) -> Void in
        
            var i:Int = 0
            for child in snapshot.children.allObjects as! [FDataSnapshot] {
                
                print("child: \(i)")
                print("displayName: \(child.value["displayName"])")
                print("id: \(child.value["id"])")
                print("lat: \(child.value["latitude"])")
                print("long: \(child.value["longitude"])")
                print("\n")
                
                //let val = child.value
            
                if self.currentUser.ref.key == child.ref.key {
                    //ignore current User
                    continue
                }
                
                let searchUserArray = self.otherUserArray.filter() { $0.ref.key == child.ref.key }
                
                if searchUserArray.count == 1 {
                    
                    //User exist (exactly one match !), update marker
                    let retUser = searchUserArray.first!
                    
                    if retUser.profileImage != nil {
                        
                        let profileImage = retUser.profileImage
                        let radius = profileImage.size.width * 0.5
                        let resizedImage = Util.resizeImageWithImage(profileImage, scaledToSize: CGSize(width: radius, height: radius))
                        
                        if retUser.marker == nil {
                            
                            if self.mapView.myLocation != nil {
                            
                                //1.3034249, 103.7928852
                                let dummyLocation = CLLocationCoordinate2DMake(1.3034249, 103.7928852)
                                
                                let marker = GMSMarker(position: dummyLocation)
                                marker.icon = resizedImage
                                marker.appearAnimation = kGMSMarkerAnimationPop
                                marker.title = "\(retUser.firstName) \(retUser.lastName)"
                                marker.snippet = "\(retUser.location)"
                                marker.map = self.mapView
                                retUser.marker = marker
                            }
                        }
                    }
                }
                
                i++
            }
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.mapView.myLocation != nil {
            let cameraPosition = GMSCameraPosition(target: self.mapView.myLocation.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            self.mapView.animateToCameraPosition(cameraPosition)
        }
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
    
    func mapView(mapView: GMSMapView!, willMove gesture: Bool) {
        
        print("mapView willMove")
    }
    
    func mapView(mapView: GMSMapView!, didChangeCameraPosition position: GMSCameraPosition!) {
        
        print("didChangeCameraPosition")
    }
    
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {
        
        print("idle at pos: \(position.target)")
    }
    
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        
        print("didTapAtCoordinate: \(coordinate.latitude), \(coordinate.longitude)")
    }
    
    func mapView(mapView: GMSMapView!, didLongPressAtCoordinate coordinate: CLLocationCoordinate2D) {
       
        print("didLongPressAtCoordinate")
    }
    
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        
        print("didTapMarker")
        
        return true
    }
    
    func didTapMyLocationButtonForMapView(mapView: GMSMapView!) -> Bool {
        
        print("didTapMyLocationButtonForMapView")
        
        if self.mapView.myLocation != nil {
        
            let cameraPosition = GMSCameraPosition(target: self.mapView.myLocation.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            self.mapView.animateToCameraPosition(cameraPosition)
        }
        
        return true
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
        
        //print("\nmyLocation: \(mapView.myLocation.coordinate)\n")
        
        if !firstShowLocation {
        
            firstShowLocation = true
            
            let cameraPosition = GMSCameraPosition(target: self.mapView.myLocation.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            self.mapView.animateToCameraPosition(cameraPosition)
        }
        
        
        //User ref
        let currentUserRef = FirebaseManager.sharedInstance.currentUser.ref
        
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
        if self.currentUser != nil && self.currentUser.profileImage != nil {
            
            let profileImage = self.currentUser.profileImage
            let radius = profileImage.size.width * 0.5
            let resizedImage = Util.resizeImageWithImage(profileImage, scaledToSize: CGSize(width: radius, height: radius))

            if self.currentUser.marker == nil {
            
                let marker = GMSMarker(position: self.mapView.myLocation.coordinate)
                marker.icon = resizedImage
                marker.appearAnimation = kGMSMarkerAnimationPop
                marker.title = "\(self.currentUser.firstName) \(self.currentUser.lastName)"
                marker.snippet = "Me"
                marker.map = self.mapView
                self.currentUser.marker = marker
            }
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
