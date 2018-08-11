//
//  ShowRoutesDetailVC.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 27/05/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit
import DropDown
import AVFoundation
import GooglePlaces
import GoogleMaps
import Alamofire
import CoreLocation
import Firebase
import UserNotifications
import Reachability
import SVProgressHUD


class ShowRoutesDetailVC: UIViewController,GMSMapViewDelegate, PlayerManagerDelegate, UNUserNotificationCenterDelegate, StopsMarkerDelegate
{
    
    var ref: DatabaseReference!         // FIREBASE REFERENCE
    
    @IBOutlet weak var lblStationHeightCons: NSLayoutConstraint!
    
    @IBOutlet weak var lblDirectionHeightCons: NSLayoutConstraint!
    
    @IBOutlet var btnPlayVideo: UIButton!
    @IBOutlet var lblPlayVideo : UILabel!
    @IBOutlet var btnRestartVideo: UIButton!
    
    var routeName: String! = nil
    
    var selectRoute: Routes! = nil
    
    var departureStops: Stops! = nil
    var destinationStops: Stops! = nil
    var videoGeoPoints = [VideoGeoPoints]()
    var mainVideoGeoPoints = [VideoGeoPoints]()
    var videoGeoCoordinatesArr = [CLLocation]()
    var routeRangeStopsArr = [Stops]()
    
    var videoPlayURL: NSString! = nil
    
    @IBOutlet var btnViewsSelection: UIButton!
    @IBOutlet var lblRouteName : UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var routeMapView: GMSMapView!
    
    private var stopsMarkerVw = StopsMarkerView()
    fileprivate var stopLocationMarker : GMSMarker? = GMSMarker()
    
    var playerManager: PlayerManager!
    
    var videoURLIndex: Int! = -1
    
    var stopDirectionIndex: Int! = -1
    //var carUpdateIndex: Int!
    
    @IBOutlet weak var stackView: UIStackView!
    
    var stopsMarker: GMSMarker?
    var carMarker: GMSMarker?
    var vPOIMarker: GMSMarker?
    var POIMarkerArr = [GMSMarker]()
    var poiDictResult = NSDictionary()
    
    var meetUpMarkerArr = [GMSMarker]()
    var meetUpDictResult = NSDictionary()
    
    var bikeDictResult = NSDictionary()
    var bikeMarkerArr = [GMSMarker]()
    
    var customPOIArr = [CustomPOI]()
    var customPOIMarker = [GMSMarker]()
    
    
    @IBOutlet weak var bottomBtnConstraint: NSLayoutConstraint!
    
    
    var directionVideoURLArr = [NSDictionary]()
    
    @IBOutlet weak var lblNextStationName : UILabel!
    @IBOutlet weak var lblNaviDirectionName: UILabel!
    
    var isZoom: Bool! = false
    
    var routeLine: GMSPolyline!
    
    
    var amenitiesFieldsArr = [AmenitiesFields]()
    
    @IBOutlet var btnMapSelection: UIButton!
    @IBOutlet var btnSatelliteSelection: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        mainVideoGeoPoints = videoGeoPoints
        
        //   carUpdateIndex = 0
        lblRouteName.text = routeName
        DropDown.appearance().textAlignment = NSTextAlignment.center
        self.perform(#selector(onSetupRouteVideoPlayer), with: nil, afterDelay: 0.1)
        self.setupCarMarker()
        self.setupGoogleMapView()
        
        let nextStop = routeRangeStopsArr.filter({ $0.sec! > departureStops.sec!}).first
        if nextStop != nil {
            self.updateNextStationNameLbl(nextStops: nextStop!, currentSec: 0)
        }
        
        self.getAmenitiesFields()
        self.getCustomePOI()
        lblDirectionHeightCons.constant = 0
        lblStationHeightCons.constant = 0
        
        self.perform(#selector(showRouteMapPOIMeetupBike), with: nil, afterDelay: 1.0)
        
    }
    
    func loadNiB() -> StopsMarkerView {
        let infoWindow = StopsMarkerView.instanceFromNib() as! StopsMarkerView
        return infoWindow
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //        ReachabilityManager.shared.removeListener(listener: self)
        //        ReachabilityManager.shared.addListener(listener: self)
        //
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.isTranslucent = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ReachabilityManager.shared.removeListener(listener: self)
    }
    
    
    let viewsDropDown = DropDown()
    
    
    lazy var dropDowns: [DropDown] = {  // DROP DOWN ARRAY
        return [
            self.viewsDropDown,
            ]
    }()
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func showRouteMapPOIMeetupBike() {
        
        let poiGeoPoint = videoGeoPoints[0]
        
        let lat:String = String(format:"%f", poiGeoPoint.lat!)
        let lng: String = String(format:"%f",poiGeoPoint.lng!)
        //let latLngStr = lat + "," + lng
        
      //  self.getPOIs(latLong: latLngStr, type: "bank")
        self.getMeetUps(lat: lat, lon: lng)
        self.getBikeIntegrationData(lat: lat, lon: lng)
        self.showCustomPOIsOnPauseVideo()
    }
    
    //MARK: - POIs
    
//    func getPOIs(latLong : String, type: String)
//    {
//        let strURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=" + latLong + "&rankby=distance&type=" + type + "&key=\(API_KEY.GetPOI)"
//
//        Alamofire.request(strURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
//
//
//            if let json = response.result.value
//            {
//                self.poiDictResult = json as! NSDictionary
//                //  print(self.dictResult)
//                self.POIMarkerArr.removeAll()
//                if !self.btnPlayVideo.isSelected {
//                    self.showPOIsOnPauseVideo()
//                }
//            }
//            else
//            {
//                //  print(response)
//
//                let alertController = UIAlertController(title: "Virtualtour", message: "Could not connect to the server.\n Please try again." as String, preferredStyle: .alert)
//                let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: { action in})
//                alertController.addAction(okAction)
//                self.present(alertController, animated: true, completion: nil)
//            }
//        }
//    }
    
    //MARK:- SHOW ANIMATIES
    
    func getAmenitiesFields()
    {
        self.ref.child("amenitiesFields").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            if snapshot.childrenCount > 0 {
                
                for snapValue in snapshot.children.allObjects as! [DataSnapshot] {
                    //getting values
                    let amenitiesField = snapValue.value as? [String: AnyObject]
                    
                    let enable  = amenitiesField?["enabled"]
                    let key  = amenitiesField?["key"]
                    
                    let obj = AmenitiesFields(isEnable: enable as? Bool, key: key as? String, value: "" )
                    self.amenitiesFieldsArr.append(obj)
                }
            }
        })
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        if marker.accessibilityValue == "stops"  && (marker.userData != nil) {
            stopsMarkerVw.removeFromSuperview()
            stopsMarkerVw = loadNiB()
            stopsMarkerVw.delegate = self
            stopLocationMarker = marker
            guard let location = stopLocationMarker?.position  else {
                print("locationMarker is nil")
                return false
            }
            
            stopsMarkerVw.center = mapView.projection.point(for: location)
            
            if containerView.isHidden {
                stopsMarkerVw.center.y =  stopsMarkerVw.center.y - 80
            }
            else {
                stopsMarkerVw.center.y = stopsMarkerVw.center.y - (stopsMarkerVw.frame.height) + 20
            }
            
            routeMapView.addSubview(stopsMarkerVw)
            btnMapSelection.isHidden = true
            btnSatelliteSelection.isHidden = true
            
            let selectStops: Stops = marker.userData as! Stops
            
            print("select stops code ==\(String(describing: selectStops.name!))")
            
            var tempStr = "Connections: \(String(selectStops.route_list!))\nAmenities: " as String
            
            self.ref.child("amenities").child((selectStops.code)!).observeSingleEvent(of: DataEventType.childAdded, with: { (snapshot) in
                
                if snapshot.childrenCount > 0 {
                    
                    for snapShotObj in snapshot.children.allObjects as! [DataSnapshot] {
                        print(snapShotObj)
                        
                        let amenitiesObj = snapShotObj.value as? [String: AnyObject]
                        
                        let enable  = amenitiesObj?["enabled"]
                        let key  = amenitiesObj?["key"]
                        let value  = amenitiesObj? ["value"]
                        
                        let amiobj = AmenitiesFields(isEnable: enable as? Bool, key: key as? String, value: value as? String )
                        
                        if (amiobj.enabled == true && !(amiobj.amenitiesValue == "0") && !(amiobj.amenitiesKey == "stop_id"))
                        {
                            if (amiobj.amenitiesValue == "1") || (amiobj.amenitiesValue == "") {
                                tempStr = tempStr + amiobj.amenitiesKey! + ", "
                            }
                            else {
                                tempStr = tempStr + amiobj.amenitiesKey! + ": " + amiobj.amenitiesValue! + ", "
                            }
                            print("Temp Str === \(tempStr)")
                        }
                        print(tempStr)
                        
                    }
                    // marker.snippet = tempStr
                    
                    DispatchQueue.main.async {
                        self.stopsMarkerVw.title.text = selectStops.name
                        self.stopsMarkerVw.snippet.text = tempStr
                    }
                }
            })
        }
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        if (stopLocationMarker != nil){
            guard let location = stopLocationMarker?.position else {
                print("locationMarker is nil")
                btnMapSelection.isHidden = false
                btnSatelliteSelection.isHidden = false
                return
            }
            stopsMarkerVw.center = routeMapView.projection.point(for: location)
            if containerView.isHidden {
                stopsMarkerVw.center.y =  stopsMarkerVw.center.y - 80
            }
            else {
                stopsMarkerVw.center.y = stopsMarkerVw.center.y - (stopsMarkerVw.frame.height) + 20
            }
        }
    }
    
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        print("Tap Info window")
        
        if marker.accessibilityValue == "meetup" {
            
            if let meetupURL = marker.userData {
                UIApplication.shared.open(URL(string : meetupURL as! String)!, options: [:], completionHandler: { (status) in
                })
            }
        }
    }
    
    //MARK: - Stops Marker Delegate
    func dismissStopsMarkerView() {
        stopsMarkerVw.removeFromSuperview()
        btnMapSelection.isHidden = false
        btnSatelliteSelection.isHidden = false
    }

    
    // MARK:- MEETUP
    func getMeetUps(lat : String, lon: String)
    {
        let strURL = "https://api.meetup.com/2/groups/?lat=" + lat + "&lon=" + lon + "&key=\(API_KEY.MeetUp)&radius=5"
        
        print(" Str URL ==\(strURL)")
        Alamofire.request(strURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
            
            if let json = response.result.value
            {
                self.meetUpDictResult = json as! NSDictionary
                //  print(self.dictResult)
                self.meetUpMarkerArr.removeAll()
                if !self.btnPlayVideo.isSelected {
                    self.showMeetUpOnPauseVideo()
                }
            }
            else
            {
                //  print(response)
                
                let alertController = UIAlertController(title: "Virtualtour", message: "Could not connect to the server.\n Please try again." as String, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: { action in})
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    
//    func showPOIsOnPauseVideo()
//    {
//        if (poiDictResult != nil && poiDictResult.count > 0)
//        {
//            let resultArr = poiDictResult.value(forKey: "results") as! NSArray
//
//            for dict in resultArr {
//
//                let strLat = (dict as! NSDictionary).value(forKeyPath: "geometry.location.lat") as! NSNumber
//
//                let strLng = (dict as! NSDictionary).value(forKeyPath: "geometry.location.lng") as! NSNumber
//
//
//                let strName = (dict as! NSDictionary).value(forKey: "name") as! String
//
//                let position = CLLocationCoordinate2D(latitude: strLat.doubleValue, longitude: strLng.doubleValue)
//                let marker = GMSMarker(position: position)
//                marker.title = strName
//                marker.iconView = UIImageView.init(image: #imageLiteral(resourceName: "ic_vpois"))
//                marker.tracksViewChanges = true
//                marker.map = routeMapView
//                POIMarkerArr.append(marker)
//            }
//        }
//    }
    
    func showMeetUpOnPauseVideo() {
        
        if (meetUpDictResult != nil && meetUpDictResult.count > 0)
        {
            let resultArr = meetUpDictResult.value(forKey: "results") as! NSArray
            
            for dict in resultArr {
                
                let strLat = (dict as! NSDictionary).value(forKey: "lat") as! NSNumber
                
                let strLng = (dict as! NSDictionary).value(forKey: "lon") as! NSNumber
                
                let strName = (dict as! NSDictionary).value(forKey: "name") as! String
                
                let member = (dict as! NSDictionary).value(forKey: "members") as! Int
                
                let position = CLLocationCoordinate2D(latitude: strLat.doubleValue, longitude: strLng.doubleValue)
                let marker = GMSMarker(position: position)
                marker.title = strName
                marker.iconView = UIImageView.init(image: #imageLiteral(resourceName: "ic_meetup"))
                marker.snippet = "Members: \(member)"
                marker.tracksViewChanges = true
                marker.map = routeMapView
                marker.userData = (dict as! NSDictionary).value(forKey: "link") as! String
                marker.accessibilityValue = "meetup"
                meetUpMarkerArr.append(marker)
            }
        }
    }
    
    
    // MARK:- GET BIKE ON VIDEO
    func getBikeIntegrationData(lat : String, lon: String)
    {
        let bikeURL = "https://api.coord.co/v1/bike/location?latitude=" + lat + "&longitude=" + lon + "&radius_km=5&access_key=\(API_KEY.BIKE_INTEGRATION)"
        
        print(" Str URL ==\(bikeURL)")
        
        Alamofire.request(bikeURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
            
            if let json = response.result.value
            {
                self.bikeDictResult = json as! NSDictionary
                //  print(self.dictResult)
                self.bikeMarkerArr.removeAll()
                if !self.btnPlayVideo.isSelected {
                    self.showBikeOnPauseVideo()
                }
            }
            else
            {
                print(response)
                
                let alertController = UIAlertController(title: "Virtualtour", message: "Could not connect to the server.\n Please try again." as String, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: { action in})
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func showBikeOnPauseVideo() {
        
        if (bikeDictResult != nil && bikeDictResult.count > 0)
        {
            let resultArr = bikeDictResult.value(forKey: "features") as? NSArray
            
            if resultArr != nil {
                for dict in resultArr! {
                    
                    let strLat = (dict as! NSDictionary).value(forKeyPath: "properties.lat") as! NSNumber
                    
                    let strLng = (dict as! NSDictionary).value(forKeyPath: "properties.lon") as! NSNumber
                    
                    let strName = (dict as! NSDictionary).value(forKeyPath: "properties.name") as! String
                    
                    let bikeAvailable = (dict as! NSDictionary).value(forKeyPath: "properties.num_bikes_available") as? Int
                    let bikeDockAvailable = (dict as! NSDictionary).value(forKeyPath: "properties.num_docks_available") as? Int
                    
                    let position = CLLocationCoordinate2D(latitude: strLat.doubleValue, longitude: strLng.doubleValue)
                    let marker = GMSMarker(position: position)
                    marker.title = strName
                    marker.iconView = UIImageView.init(image: #imageLiteral(resourceName: "bike"))
                    marker.snippet = "Bikes Available: \(bikeAvailable ?? 0), Docks Available: \(bikeDockAvailable ?? 0) "
                    marker.tracksViewChanges = true
                    marker.map = routeMapView
                    bikeMarkerArr.append(marker)
                }
            }
        }
        
    }
    
    //MARK: - NAVIGATION
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "navigationSegue"
        {
            if let showNavigation = segue.destination as? NavigationVC {
                showNavigation.navigationRouteName = routeName
                showNavigation.departureStops = departureStops
                showNavigation.destinationStops = destinationStops
                showNavigation.videoGeoPointsArr = videoGeoPoints
                showNavigation.routeRangeStopsArr = routeRangeStopsArr
            }
        }
        else if segue.identifier == "show_pois"
        {
            if let obj = segue.destination as? ViewPOIs
            {
                let index = playerManager.playerView.currentTime - departureStops.sec!
                if index >= 0 {
                    
                    let posGeoPoints = videoGeoPoints[index]
                    let lat:String = String(format:"%f", posGeoPoints.lat!)
                    let lng: String = String(format:"%f",posGeoPoints.lng!)
                    
                    let posGeoPointsStr = lat + "," + lng
                    
                    obj.strLatLong = posGeoPointsStr
                }
                else {
                    let lat:String = String(format:"%f", departureStops.lat!)
                    let lng: String = String(format:"%f",destinationStops.lng!)
                    
                    let posGeoPointsStr = lat + "," + lng
                    
                    obj.strLatLong = posGeoPointsStr
                }
                
            }
        }
    }
    
    
    
    //MARK : - IBACTION METHOD
    
    @IBAction func onViewsSelectionBtn(_sender: UIButton)
    {
        let directionName = directionVideoURLArr.map({$0["name"]})
        self.setupViewsDropDown(views: directionName as! [String])
        
        self.dropDowns.forEach { $0.dismissMode = .onTap }
        self.dropDowns.forEach { $0.direction = .any }
        viewsDropDown.show()
    }
    
    @IBAction func onNavigationBtn(_sender: UIButton)
    {
        if btnPlayVideo.accessibilityValue == "1" {
            self.onPlayRouteVideoBtn(_sender: btnPlayVideo)
        }
        
        self.performSegue(withIdentifier: "navigationSegue", sender: nil)
    }
    
    @IBAction func btnPOIS(_sender: UIButton)
    {
        self.stopVideoPlayer()
        self.performSegue(withIdentifier: "show_pois", sender: nil)
    }
    
    //MARK: - Setup
    func setupViewsDropDown(views: [String]) { // Setup Routes
        viewsDropDown.anchorView = btnViewsSelection
        viewsDropDown.bottomOffset = CGPoint(x: 0, y: btnViewsSelection.bounds.height)
        
        viewsDropDown.dataSource = views as [String]
        
        viewsDropDown.selectionAction = { [weak self] (index, item) in
            
            if index != self?.videoURLIndex {
                self?.btnViewsSelection.titleLabel?.text = item
                
                self?.videoURLIndex = index
                
                let reachability = Reachability()!
                
                if reachability.connection == .wifi {
                    print("Reachable via WiFi")
                    self?.videoPlayURL = self?.directionVideoURLArr[index].value(forKey:"high_res_url") as! NSString
                    
                } else {
                    print("Reachable via Cellular")
                    if let lowResURl = self?.directionVideoURLArr[index].value(forKey:"low_res_url")
                    {
                        self?.videoPlayURL = lowResURl as! NSString
                    }
                    else
                    {
                        self?.videoPlayURL = self?.directionVideoURLArr[index].value(forKey:"high_res_url") as! NSString
                    }
                }
                
                if case let (nightView as String) = self?.directionVideoURLArr[index].value(forKey:"name") {
                    
                    if nightView != "Night View" {
                        
                        let geoPointstr = self?.directionVideoURLArr[index].value(forKey:"geo_point")
                        self?.getUpdatedVideoGeoPoints(geoPointName: geoPointstr as! String)
                    }
                    else{
                        self?.playerManager.playUrlStr = self?.videoPlayURL! as String?
                        
                        self?.playerManager.playerView.currentTime = (self?.departureStops.sec!)!
                        self?.playerManager.playerView.startTimeValue = Double((self?.departureStops.sec!)!)
                        let endTime = Double((self?.departureStops.sec!)!) + Double((self?.videoGeoPoints.count)!-1) as Double
                        self.self?.playerManager.playerView.endTimeValue = endTime
                        
                        self?.playerManager.seekToTime(Int((self.self?.playerManager.playerView.startTimeValue)!))
                        
                        self?.btnPlayVideo.accessibilityValue = "0"
                        self?.playerManager.pause()
                        self?.btnPlayVideo.isSelected = false
                        self?.lblPlayVideo.text = "PLAY"
                        self?.btnPlayVideo.isEnabled = true
                    }
                    
                }
            }
        }
    }
    
    // GET VIDEO GEO POINT ACCORDING VIDEO VIEWS
    
    func getUpdatedVideoGeoPoints(geoPointName: String) {
        
        var directionStr: String!
        
        if (stopDirectionIndex == 0)
        {
            directionStr = "a"
        }
        else
        {
            directionStr = "c"
        }
        
        let code = "\(self.selectRoute.code!)"
        
        var startSec: String!
        var endSec: String!
        
        let start: Int = departureStops.sec!
        let end: Int = destinationStops.sec!
        
        if start < end {
            startSec = "\(self.departureStops.sec!)"
            endSec = "\(destinationStops.sec!)"
        } else {
            startSec = "\(self.destinationStops.sec!)"
            endSec = "\(self.departureStops.sec!)"
        }
        
        
        self.videoGeoPoints.removeAll()
        
        let departureGeoPoints = VideoGeoPoints(lat: departureStops.lat, lng: departureStops.lng)
        self.videoGeoPoints.append(departureGeoPoints)
        
        self.ref.child(geoPointName).child(code).child(directionStr!).queryOrderedByKey().queryStarting(atValue: startSec).queryEnding(atValue: endSec).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            if snapshot.childrenCount > 0 {
                
                for geoPoint in snapshot.children.allObjects as! [DataSnapshot] {
                    //getting values
                    
                    let geoPointObj = geoPoint.value as? [String: AnyObject]
                    
                    let lat  = geoPointObj?["lat"]
                    let lng  = geoPointObj?["lng"]
                    
                    let videoGeoPointObj = VideoGeoPoints(lat: lat as? Double, lng: (lng as! Double))
                    self.videoGeoPoints.append(videoGeoPointObj)
                }
            }
            let destinationGeoPoints = VideoGeoPoints(lat: self.destinationStops.lat, lng: self.destinationStops.lng)
            self.videoGeoPoints.append(destinationGeoPoints)
            
            if snapshot.childrenCount == 0 {
                self.videoGeoPoints = self.mainVideoGeoPoints
            }
            
            // print(self.videoGeoPointsArr.count)
            SVProgressHUD.dismiss()
            self.playerManager.pause()
            DispatchQueue.main.async {
                self.drawRouteLine()
                self.playerManager.playUrlStr = self.videoPlayURL! as String?
                
                self.playerManager.playerView.currentTime = (self.departureStops.sec!)
                self.playerManager.playerView.startTimeValue = Double((self.departureStops.sec!))
                let endTime = Double((self.departureStops.sec!)) + Double((self.videoGeoPoints.count)-1) as Double
                self.playerManager.playerView.endTimeValue = endTime
                
                self.playerManager.seekToTime(Int((self.self.playerManager.playerView.startTimeValue)!))
                
                self.btnPlayVideo.accessibilityValue = "0"
                self.playerManager.pause()
                self.btnPlayVideo.isSelected = false
                self.lblPlayVideo.text = "PLAY"
                self.btnPlayVideo.isEnabled = true

            }
        })
    }
    
    
    
    // MARK: SETUP AVPLAYER
    
    @objc func onSetupRouteVideoPlayer() {
        
        playerManager = PlayerManager(playerFrame: CGRect(x: 0, y: 0, width: containerView.width, height: containerView.height), contentView: containerView)
        
        self.playerManager.playerView.currentTime = self.departureStops.sec!
        playerManager.playerView.startTimeValue = Double(departureStops.sec!)
        let endTime = Double(departureStops.sec!) + Double(videoGeoPoints.count-1) as Double
        playerManager.playerView.endTimeValue = endTime
        
        
        playerManager.delegate = self
        playerManager.playUrlStr = videoPlayURL! as String
        playerManager.seekToTime(Int(playerManager.playerView.startTimeValue))//Jump to the Nth progress position, starting from scratch is 0
        
        print("Play Video URL ===\(videoPlayURL)")
    }
    
    // MARK: SET UP GOOGLE MAP ACCORDING USER SELECT ROUTE
    
    func setupGoogleMapView()
    {
        //Set up Google Map
        
        let camera = GMSCameraPosition.camera(withLatitude: departureStops.lat! ,
                                              longitude: departureStops.lng!,
                                              zoom: 12.6)
        routeMapView.camera = camera
        routeMapView.mapType = .normal
        routeMapView.delegate = self
        routeMapView.settings.compassButton = true
        
        
        for stops in routeRangeStopsArr {
            let position = CLLocationCoordinate2D(latitude: stops.lat!, longitude: stops.lng!)
            let marker = GMSMarker(position: position)
          //  marker.title = stops.name
            marker.iconView = UIImageView.init(image: #imageLiteral(resourceName: "map_Stop"))
            marker.tracksViewChanges = true
            marker.map = routeMapView
            marker.accessibilityValue = "stops"
            marker.userData = stops
            stopsMarker = marker
        }
        
        
        let path = GMSMutablePath()
        
        path.add(CLLocationCoordinate2DMake(departureStops.lat!, departureStops.lng!))
        path.add(CLLocationCoordinate2DMake(destinationStops.lat!, destinationStops.lng!))
        
        let bounds = GMSCoordinateBounds(path: path)
        routeMapView!.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50.0))
        
        self.drawRouteLine()
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        UIView.animate(withDuration: 5.0, animations: { () -> Void in
        }, completion: {(finished) in
            // Stop tracking view changes to allow CPU to idle.
            self.stopsMarker?.tracksViewChanges = false
            self.carMarker?.tracksViewChanges = false
        })
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("Coordinate ===> ===\(coordinate.latitude)     ====Long ===> \(coordinate.longitude)")
        stopsMarkerVw.removeFromSuperview()
        self.findClosestDistance(lat: coordinate.latitude, lon: coordinate.longitude)
        btnMapSelection.isHidden = false
        btnSatelliteSelection.isHidden = false
    }
    
    @IBAction func restartVideo(_ sender: UIButton)
    {
        sender.isEnabled = false
        self.stopVideoPlayer()
        playerManager.playerView.startTimeValue = Double(departureStops.sec!)
        let endTime = Double(departureStops.sec!) + Double(videoGeoPoints.count-1) as Double
        playerManager.playerView.endTimeValue = endTime
        
        playerManager.seekToTime(Int(playerManager.playerView.startTimeValue))
        
        //carMarker?.position = CLLocationCoordinate2D(latitude: departureStops.lat!, longitude: destinationStops.lng!)
        
        btnPlayVideo.accessibilityValue = "1"
        playerManager.play()
        btnPlayVideo.isSelected = true
        lblPlayVideo.text = "Pause"
        btnPlayVideo.isEnabled = true
    }
    
    @IBAction func onPlayRouteVideoBtn(_sender: UIButton)
    {
        if _sender.accessibilityValue == "1" {
            _sender.accessibilityValue = "0"
            playerManager.pause()
            _sender.isSelected = false
            lblPlayVideo.text = "PLAY"
            
            var index = playerManager.playerView.currentTime - departureStops.sec!
            
            if index < 0 {
                index = 0
            }
            let poiGeoPoint = videoGeoPoints[index]
            
            let lat:String = String(format:"%f", poiGeoPoint.lat!)
            let lng: String = String(format:"%f",poiGeoPoint.lng!)
            let latLngStr = lat + "," + lng
            
            
           // self.getPOIs(latLong: latLngStr, type: "bank")
            self.getMeetUps(lat: lat, lon: lng)
            self.getBikeIntegrationData(lat: lat, lon: lng)
            self.showCustomPOIsOnPauseVideo()
        }
        else {
            
            vPOIMarker?.map = nil
            vPOIMarker?.map?.clear()
            _sender.accessibilityValue = "1"
            playerManager.play()
            _sender.isSelected = true
            lblPlayVideo.text = "PAUSE"
            // self.showPOIsOnPauseVideo(isShow: false)
            
            if POIMarkerArr.count > 0 {
                for marker in POIMarkerArr {
                    marker.map = nil
                }
            }
            
            if meetUpMarkerArr.count > 0 {
                for marker in meetUpMarkerArr {
                    marker.map = nil
                }
            }
            
            if bikeMarkerArr.count > 0  {
                for marker in bikeMarkerArr {
                    marker.map = nil
                }
            }
            
            if customPOIMarker.count > 0 {
                for marker in customPOIMarker {
                    marker.map = nil
                }
            }
        }
    }
    
    func drawRouteLine(){
        /* create the path */
        let path = GMSMutablePath()
        
        for geoPoint in videoGeoPoints {
            path.add(CLLocationCoordinate2D(latitude: geoPoint.lat!, longitude: geoPoint.lng!))
        }
        
        if (routeLine != nil) {
             routeLine.map = nil
        }
        
        /* show what you have drawn */
        routeLine = GMSPolyline(path: path)
        routeLine.strokeColor = UIColor.init(red: 11.0/255.0, green: 83.0/255.0, blue: 138.0/255.0, alpha: 1.0)
        routeLine.strokeWidth = 2.0
        // routeLine.isTappable = true
        routeLine.map = routeMapView
    }
    
    
    func setupCarMarker()
    {
        let position = CLLocationCoordinate2D(latitude: departureStops.lat!, longitude: departureStops.lng!)
        let marker = GMSMarker(position: position)
        marker.iconView = UIImageView.init(image: #imageLiteral(resourceName: "ic_car"))
        marker.iconView?.size = CGSize(width: 25, height: 25)
        marker.tracksViewChanges = true
        marker.map = routeMapView
        marker.isTappable =  true
        marker.zIndex = 1
        carMarker = marker
        
    }
    
    
    @objc func updateMarkerPosition(updateIndex: Int)
    {
        if updateIndex > videoGeoPoints.count {
            // carUpdateIndex = 0
            print("Reach DEsit")
        }
        else
        {
            if updateIndex >= 0
            {
                if !btnRestartVideo.isEnabled {
                    btnRestartVideo.isEnabled = true
                }
                
                let updateGeoPoints = videoGeoPoints[updateIndex]
                //   print("Update GEO POINT  ===>\(updateGeoPoints.lat) ==== LONG ====\(updateGeoPoints.lng)")
                carMarker?.position = CLLocationCoordinate2D(latitude: updateGeoPoints.lat!, longitude: updateGeoPoints.lng!)
                
                let location = CLLocation(latitude: updateGeoPoints.lat!, longitude: updateGeoPoints.lng!)
                
                if btnPlayVideo.accessibilityValue == "1" {
                    
                    if !isZoom {
                        isZoom = true
                        self.delay(seconds: 0.3, closure: { () -> () in
                            let updatePosition = GMSCameraUpdate.setTarget(location.coordinate)
                            self.routeMapView.animate(with: updatePosition)
                            self.delay(seconds: 0.5, closure: { () -> () in
                                let zoomIn = GMSCameraUpdate.zoom(to: 16.0)
                                self.routeMapView.animate(with: zoomIn)
                            })
                        })
                    }
                }
                
//                let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 16.0)
//                routeMapView.camera = camera
                
                let nextStop = routeRangeStopsArr.filter({ $0.sec! > playerManager.playerView.currentTime}).first
                
                if nextStop != nil {
                    self.updateNextStationNameLbl(nextStops: nextStop!, currentSec: updateIndex)
                }
                
                if (updateIndex + 1) < videoGeoPoints.count
                {
                    let currentGeoPoint = videoGeoPoints[updateIndex]
                    let strOrigin: String! = String(format:"%f,%f", currentGeoPoint.lat!,currentGeoPoint.lng!)
                    
                    let nextGeoPoint = videoGeoPoints[updateIndex + 1]
                    let strDestination: String! = String(format:"%f,%f", nextGeoPoint.lat!,nextGeoPoint.lng!)
                    
                    self.getNavigationRouteDIrection(origin: strOrigin, destination: strDestination)
                }
                else{
                    
                    lblStationHeightCons.constant = 0
                    lblNaviDirectionName.text = "Reached destination, Connection is available for route: \(destinationStops.route_list!)"
                    self.stopVideoPlayer()
                    btnPlayVideo.isEnabled = false
                }
            }
        }
    }
    
    @IBAction func onmapBackgroundSelectionBtn(_ sender: UIButton)
    {
        if sender.tag == 60 {   // On Map Normal
            routeMapView.mapType = .normal
        }
        else if sender.tag == 61    // On Satellite Background
        {
            routeMapView.mapType = .satellite
        }
    }
    
    @IBAction func onZoomInOutBtn(_ sender: UIButton)
    {
        let zoom = routeMapView.camera.zoom
        if sender.tag == 70 {   // On Zoom In
            routeMapView.animate(toZoom: zoom + 1)
        }
        else if sender.tag == 71 {  // On Zoom out
            routeMapView.animate(toZoom: zoom - 1)
        }
    }
    
    @IBAction func fullScreenMap(_ sender: UIButton) {
        stopsMarkerVw.removeFromSuperview()
        if containerView.isHidden {
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.navigationBar.isTranslucent = false
            
            UIView.animate(withDuration: 0.3) {
                self.containerView.isHidden = false
                self.bottomBtnConstraint.constant = 70
            }
        }
        else
        {
            self.navigationController?.navigationBar.isHidden = true
            self.navigationController?.navigationBar.isTranslucent = true
            UIView.animate(withDuration: 0.3) {
                self.containerView.isHidden = true
                self.bottomBtnConstraint.constant = 0
            }
        }
        self.view.layoutIfNeeded()
    }
    
    // MARK:- PLAYER MANAGER DELEGATE
    
    func playerViewBack() {
        
        self.stopVideoPlayer()
        playerManager.playUrlStr = videoPlayURL! as String
        playerManager.seekToTime(Int(playerManager.playerView.startTimeValue))
    }
    
    func playCurrentTime(currentTime: Int) {
        print("Play Current Time")
        
        if btnPlayVideo.accessibilityValue == "0" {
            self.stopVideoPlayer()
            if !btnPlayVideo.isEnabled {
                btnPlayVideo.isEnabled = true
            }
        }
        
        
        let index = currentTime - departureStops.sec!
        self.updateMarkerPosition(updateIndex: index)
    }
    
    func resetRouteVideoPlayer() {
        self.stopVideoPlayer()
        playerManager.playUrlStr = videoPlayURL! as String
        playerManager.seekToTime(Int(playerManager.playerView.startTimeValue))
    }
    
    func  stopVideoPlayer() {
        btnPlayVideo.accessibilityValue = "0"
        playerManager.pause()
        btnPlayVideo.isSelected = false
        lblPlayVideo.text = "Play"
    }
    
    func  updateNextStationNameLbl(nextStops: Stops, currentSec: Int)
    {
        if lblStationHeightCons.constant == 0 {
            lblStationHeightCons.constant = 25
        }
        
        if nextStops != nil {
            let strUpdate = nextStops.name! + " (Connects-\(nextStops.route_list!))"
            lblNextStationName.text = strUpdate
            
            //            if nextStops.sec! == (currentSec + 10)
            //            {
            //                print("SHow Local Notification")
            //                self.scheduleLocalNotificationForNextStops(stopsName: nextStops.name!)
            //            }
        }
    }
    
    
    func findClosestDistance(lat: Double, lon: Double) {
        
        if videoGeoCoordinatesArr.count == 0 {
            for geo in videoGeoPoints
            {
                let coordinates = CLLocation(latitude: geo.lat!, longitude: geo.lng!)
                videoGeoCoordinatesArr.append(coordinates)
            }
        }
        
        let userLocation = CLLocation(latitude: lat, longitude: lon)
        let closest = videoGeoCoordinatesArr.min(by:{ $0.distance(from: userLocation) < $1.distance(from: userLocation) }) as CLLocation?
        
        if (closest?.distance(from: userLocation))! < Double(500) {
            print("Update Car Position")
            let index = videoGeoCoordinatesArr.index(of: closest!) as! Int
            //  print("Updater index====> \(index)")
            playerManager.playerView.seekToVideo(index + departureStops.sec!)
            
            carMarker?.position = CLLocationCoordinate2D(latitude: (closest?.coordinate.latitude)!, longitude: (closest?.coordinate.longitude)!)
        }
    }
    
    
    
    func getCustomePOI() {
        self.ref.child("customPois").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            if snapshot.childrenCount > 0 {
                
                for customPOIObj in snapshot.children.allObjects as! [DataSnapshot] {
                    //getting values
                    
                    let customPOI = customPOIObj.value as? [String: AnyObject]
                    
                    let address = customPOI?["address"]
                    let code = customPOI?["code"]
                    let icon = customPOI?["icon"]
                    let name = customPOI?["name"]
                    let vicinity = customPOI?["vicinity"]
                    let web_link = customPOI?["web_link"]
                    let lat  = customPOI?["latitude"]
                    let lng  = customPOI?["longitude"]
                    
                    let customPOIs = CustomPOI.init(address: address as? String, code: code as? String, icon: icon as? String, latitude: lat as? String, longitude: lng as? String, name: name as? String, vicinity: vicinity as? String, web_link: web_link as? String)
                    
                    self.customPOIArr.append(customPOIs)
                }
            }
        })
    }
    
    
    func showCustomPOIsOnPauseVideo() {
        
        for customPOI in customPOIArr
        {
            let position = CLLocationCoordinate2D(latitude:(customPOI.latitude! as NSString).doubleValue, longitude: (customPOI.longitude! as NSString).doubleValue)
            let marker = GMSMarker(position: position)
            marker.title = customPOI.name
            if customPOI.icon != nil && customPOI.icon != "" && !(customPOI.icon?.isEmpty)!
            {
                var str = customPOI.icon ?? ""
                str = str.replacingOccurrences(of: "data:image/png;base64,", with: "")
                str = str.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                
                let dataDecoded:NSData = NSData(base64Encoded: str, options: NSData.Base64DecodingOptions(rawValue: 0))!
                
                let decodedimage:UIImage = UIImage(data: dataDecoded as Data)!
                
                marker.iconView = UIImageView.init(image: decodedimage)
                marker.iconView?.size = CGSize(width: 20, height: 20)
            }
            marker.snippet = customPOI.address
            
            marker.tracksViewChanges = true
            marker.map = routeMapView
            marker.isTappable =  true
            marker.zIndex = 1
            customPOIMarker.append(marker)
        }
    }
    
    
    func getNavigationRouteDIrection(origin: String, destination: String) {
        
        let strURL = "https://maps.googleapis.com/maps/api/directions/json?origin=" + origin + "&destination=" + destination + "&key=\(API_KEY.GetPOI)"
        
        Alamofire.request(strURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
            
            if let json = response.result.value
            {
                // print(json)
                let directionDict = json as! NSDictionary
                
                let routes = directionDict.value(forKey: "routes") as! NSArray
                
                if routes.count > 0 {
                    
                    let arr = routes.value(forKeyPath: "legs.steps") as! NSArray
                    let steps = (arr.firstObject as! NSArray).firstObject as! NSArray
                    
                    // print("Steps COunt ===\(steps.count)")
                    
                    if steps.count > 0 {
                        
                        var instrcution = (steps.firstObject as! NSDictionary).value(forKey: "html_instructions") as! String
                        
                        instrcution = instrcution.replacingOccurrences(of: "Head", with: "Heading")
                        
                        let directionStr = "<div style=\"font-size:1.20em;font-family:'OpenSans'\">" + instrcution + "</div>"
                        let attribute = directionStr.htmlAttributed(using: UIFont.systemFont(ofSize: 12.0))
                        //let attr = try? NSAttributedString(htmlString: directionStr)

                        self.lblNaviDirectionName.attributedText = attribute
                        self.lblNaviDirectionName.textAlignment = .center
                        self.lblNaviDirectionName.adjustsFontSizeToFitWidth = true
                        self.lblNaviDirectionName.textColor = UIColor.white
                        
                        if self.lblDirectionHeightCons.constant == 0 {
                            self.lblDirectionHeightCons.constant = 25
                        }
                        
                    }
                }
            }
            else
            {
                //  print(response)
                
                let alertController = UIAlertController(title: "Virtualtour", message: "Could not connect to the server.\n Please try again." as String, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: { action in})
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func delay(seconds: Double, closure: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            closure()
        }
    }
}

extension ShowRoutesDetailVC: NetworkStatusListener {
    
    func networkStatusDidChange(status: Reachability.Connection) {
        
        switch status {
        case .none:
            debugPrint("ViewController: Network became unreachable")
            
            
        case .wifi:
            debugPrint("ViewController: Network reachable through WiFi")
        case .cellular:
            debugPrint("ViewController: Network reachable through Cellular Data")
        }
    }
}
