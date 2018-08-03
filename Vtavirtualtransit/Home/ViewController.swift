//
//  ViewController.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 05/05/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit
import Firebase
import DropDown
import FirebaseDatabase
import SVProgressHUD
import MapViewPlus
import CoreLocation
import Reachability

class ViewController: UIViewController , UITextFieldDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var chooseRouteView: UIView!
    @IBOutlet weak var nearByView: UIView!
    @IBOutlet var txtRoutes : UITextField!      // SELECT ROUTES
    @IBOutlet var txtDirection : UITextField!   // SELECT DIRECTION
    @IBOutlet var txtDeparture : UITextField!   // SELECT DEPARTURE
    @IBOutlet var txtDestination : UITextField! // SELECT DESTINATION
    @IBOutlet var txtNearByRoutes : UITextField!    // SELECT NEARME ROUTES
    @IBOutlet var txtNearByDirection : UITextField! // SELECT NEARME DIRECTION
    @IBOutlet var btnDirection : UIButton!      // BTN DIRECTION
    @IBOutlet var btnDeparture : UIButton!      // BTN DEPARTURE
    @IBOutlet var btnDestination : UIButton!    // BTN DESTINATION
    @IBOutlet var btnViewRoutes : UIButton!
    @IBOutlet var scrollVwHeightCons: NSLayoutConstraint!
    @IBOutlet weak var naviVirtualTourVw: UIView!
    @IBOutlet weak var btnVirtualTour: UIButton!
    @IBOutlet weak var btnNearMe: UIButton!
    @IBOutlet weak var naviNearMeVw: UIView!
    @IBOutlet weak var lblNrRute: UILabel!
    @IBOutlet weak var lblBtmNrRute: UILabel!
    @IBOutlet weak var lblNrDir: UILabel!
    @IBOutlet weak var lblBtmNrDir: UILabel!
    
    var ref: DatabaseReference!         // FIREBASE REFERENCE
    var mainRoutesArr = [Routes]()    // MAIN ROUTES OBJECT ARRAY
    var selectRoutesStopsArr = [Stops]()    // SELECT ROUTES STOP ARRAY
    var videoGeoPointsArr = [VideoGeoPoints]() // VIDEO GEO POINT ARRAY
    var selectRoutesIndex: Int!
    var departureIndex: Int! = -1
    var destinationIndex: Int! = -1
    var directionIndex: Int! = -1
    var selectViewRoute: Routes!
    var selectVideoURL: NSString!
    var routesNameArr = [NSString]()
    var routesDirectionArr = [NSString]()
    var routesDepartureArr = [NSString]()
    var routesDestinationArr = [NSString]()
    var txtCurrent: UITextField!
    var isNearBy: Bool! = false
    var departureStops: Stops!
    var destinationStops: Stops!
    var directionVideoURLArr = [NSDictionary]()
    var select_Color: UIColor!
    let routesDropDown = DropDown()
    let directionDropDown = DropDown()
    let departureDropDown = DropDown()
    let destinationDropDown = DropDown()
    let locationManager = CLLocationManager()
    var arrNearMeStops: [Stops]!
    
    // SELECT COLOR VIEW ROUTES PROPERTY
    lazy var dropDowns: [DropDown] = {  // DROP DOWN ARRAY
        return [
            self.routesDropDown,
            self.directionDropDown,
            self.departureDropDown,
            self.destinationDropDown
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ReachabilityManager.shared.addListener(listener: self)

        
        self.setupDefaultDropDown()
        
        ref = Database.database().reference()
        SVProgressHUD.show()
        self.getRoutesDetailFromFireBase(isUserLocation: false)
        self.setupBorderView()
        
        select_Color = UIColor.init(red: 167.0/255.0, green: 2.0/255.0, blue: 46.0/255.0, alpha: 1.0)
        
        naviNearMeVw.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        naviVirtualTourVw.backgroundColor = #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7921568627, alpha: 1)
        
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 960:
                scrollVwHeightCons.constant = scrollVwHeightCons.constant + 100
                self.view.layoutIfNeeded()
            default: break
            }
        }
        nearByView.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        DropDown.appearance().textAlignment = NSTextAlignment.left
        
        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier ==  "viewRoutesSegue" {
            
            let routeNameStr = txtDirection.text! + " / V Tour / " + txtRoutes.text!
            
            let range = self.departureIndex...self.destinationIndex
            let filterArr = self.selectRoutesStopsArr[range]
            
            // print(filterArr.count)
            
            if let showRouteVC = segue.destination as? ShowRoutesDetailVC {
                showRouteVC.routeName = routeNameStr
                showRouteVC.selectRoute = selectViewRoute
                showRouteVC.videoPlayURL = selectVideoURL
                showRouteVC.departureStops = departureStops
                showRouteVC.destinationStops = destinationStops
                showRouteVC.videoGeoPoints = videoGeoPointsArr
                showRouteVC.routeRangeStopsArr = Array(filterArr)
                showRouteVC.directionVideoURLArr = directionVideoURLArr
                showRouteVC.stopDirectionIndex = directionIndex
            }
        }
        else if segue.identifier == "show_NearMe_Amenities_Segue"
        {
            if let nearMeVC = segue.destination as? ShowNearMeVC
            {
                nearMeVC.arrNearMeStops = arrNearMeStops
                btnViewRoutes.isEnabled = true
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func chooseRoutes(_ sender: AnyObject)
    {
        // FIRST SELECT ROUTES
        routesDropDown.show()
        self.onSetDefaultColorOnSelectField()
        
        let lbl = self.view.viewWithTag(400) as! UILabel
        lbl.backgroundColor = select_Color
        
        let lblSelectField = self.view.viewWithTag(500) as! UILabel
        lblSelectField.textColor = select_Color
        
        lblBtmNrRute.backgroundColor = select_Color
        lblNrRute.textColor = select_Color
    }
    
    @IBAction func chooseDirection(_ sender: AnyObject) {  // SELECT DIRECTION //  WEST, EAST etc
        
        self.setupDirectionDropDown(direction: self.routesDirectionArr as [String])
        
        btnViewRoutes.isEnabled = true
        self.dropDowns.forEach { $0.dismissMode = .onTap }
        self.dropDowns.forEach { $0.direction = .any }
        directionDropDown.show()
        self.onSetDefaultColorOnSelectField()
        
        let lbl = self.view.viewWithTag(401) as! UILabel
        lbl.backgroundColor = select_Color
        
        let lblSelectField = self.view.viewWithTag(501) as! UILabel
        lblSelectField.textColor = select_Color
        
        lblBtmNrDir.backgroundColor = select_Color
        lblNrDir.textColor = select_Color
        
    }
    
    @IBAction func chooseDeparture(_sender: AnyObject)
    {
        self.setupDepartureDropDown(departure: self.routesDepartureArr as [String])
        
        self.dropDowns.forEach { $0.dismissMode = .onTap }
        self.dropDowns.forEach { $0.direction = .bottom }
        departureDropDown.show()
        self.onSetDefaultColorOnSelectField()
        
        let lbl = self.view.viewWithTag(402) as! UILabel
        lbl.backgroundColor = select_Color
        
        let lblSelectField = self.view.viewWithTag(502) as! UILabel
        lblSelectField.textColor = select_Color
    }
    
    @IBAction func chooseDestination(_sender: AnyObject) {
        if (txtDeparture.text?.isEmpty)! {
            return
        }
        
        self.setupDestinationDropDown(destination: self.routesDestinationArr as [String])
        
        self.dropDowns.forEach { $0.dismissMode = .onTap }
        self.dropDowns.forEach { $0.direction = .bottom }
        destinationDropDown.show()
        self.onSetDefaultColorOnSelectField()
        
        let lbl = self.view.viewWithTag(403) as! UILabel
        lbl.backgroundColor = select_Color
        
        let lblSelectField = self.view.viewWithTag(503) as! UILabel
        lblSelectField.textColor = select_Color
    }
    
    @IBAction func changeDIsmissMode(_ sender: UISegmentedControl) {
        
        
        switch sender.selectedSegmentIndex {
        case 0: dropDowns.forEach { $0.dismissMode = .automatic }
        case 1: dropDowns.forEach { $0.dismissMode = .onTap }
        default: break;
        }
    }
    
    @IBAction func hideKeyboard(_ sender: AnyObject) {
        view.endEditing(false)
    }
    
    @IBAction func onViewRoutesBtn(_sender: UIButton)
    {
        if isNearBy {
            if !(txtNearByRoutes.text?.isEmpty)! && !(txtNearByDirection.text?.isEmpty)! {
                
                if locationManager.location?.coordinate.latitude == nil {
                    
                    let alertController = UIAlertController(title: "Virtualtour", message: "Allow to location access to help find nearest route" as String, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: { action in})
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
                else {
                    self.performSegue(withIdentifier: "show_NearMe_Amenities_Segue", sender: nil)
                }
            }
        }
        else {
            if !(txtRoutes.text?.isEmpty)! && !(txtDeparture.text?.isEmpty)! && !(txtDirection.text?.isEmpty)! && !(txtDestination.text?.isEmpty)! {
                
                SVProgressHUD.show()
                self.getVideoGeoPoints()
            }
        }
    }
    
    @IBAction func onNearMeBtn(_ sender: UIButton) {
        
        isNearBy = true
        naviNearMeVw.backgroundColor = #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7921568627, alpha: 1)
        naviVirtualTourVw.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        
        nearByView.isHidden = false
        chooseRouteView.isHidden = true
        
        btnViewRoutes.setTitle("View Near Me", for: .normal)
        
        self.clearSelection()
        
        locationManager.requestWhenInUseAuthorization()
        
        // If location services is enabled get the users location
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest // You can change the locaiton accuary here.
            locationManager.startUpdatingLocation()
        }
        else {
            
            if let url = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    @IBAction func onVirtualTourBtn(_ sender: UIButton) {
        
        isNearBy = false
        naviNearMeVw.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        naviVirtualTourVw.backgroundColor = #colorLiteral(red: 0.262745098, green: 0.5725490196, blue: 0.7921568627, alpha: 1)
        
        chooseRouteView.isHidden = false
        nearByView.isHidden = true
        btnViewRoutes.setTitle("View Route", for: .normal)
        
        self.clearSelection()
        
        self.getRoutesDetailFromFireBase(isUserLocation: false)
    }
    
    
    func setupDefaultDropDown() {
        DropDown.setupDefaultAppearance()
        dropDowns.forEach {
            $0.cellNib = UINib(nibName: "DropDownCell", bundle: Bundle(for: DropDownCell.self))
            $0.customCellConfiguration = nil
        }
    }
    
    @IBAction func onUseCurrentLocationBtn(_ sender: UIButton) {
        
        sender.isSelected = !sender.isSelected
        
        if  sender.isSelected {
            // For use when the app is open
            locationManager.requestWhenInUseAuthorization()
            
            // If location services is enabled get the users location
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBest // You can change the locaiton accuary here.
                locationManager.startUpdatingLocation()
                
                selectViewRoute = nil
                routesDestinationArr.removeAll()
                routesDepartureArr.removeAll()
                routesDirectionArr.removeAll()
                txtDeparture.text = ""
                txtRoutes.text = ""
                txtDirection.text = ""
                txtDestination.text = ""
                
                departureIndex = -1
                destinationIndex = -1
                directionIndex = -1
            }
        }
        else
        {
            self.getRoutesDetailFromFireBase(isUserLocation: false)
        }
    }
    
    
    
    //MARK: - Setup
    func setupRoutesDropDown(routes: [String]) { // Setup Routes
        routesDropDown.anchorView = txtRoutes
        routesDropDown.bottomOffset = CGPoint(x: 0, y: txtRoutes.bounds.height + 10)
        
        routesDropDown.dataSource = routes as [String]
        
        routesDropDown.selectionAction = { [weak self] (index, item) in
            
            self?.txtCurrent.text = item
            self?.txtCurrent.resignFirstResponder()
            
            let routeIndex = self?.routesNameArr.index(of: item as NSString)
            
            self?.selectViewRoute = self?.mainRoutesArr[routeIndex!]
            
            self?.routesDirectionArr.removeAll()
            
            self?.routesDirectionArr.append((self?.selectViewRoute.directionAName as NSString?)!)
            self?.routesDirectionArr.append((self?.selectViewRoute.directionBName as NSString?)!)
            
            self?.selectRoutesIndex = routeIndex
            self?.onSetDefaultColorOnSelectField()
        }
    }
    
    
    func setupDirectionDropDown(direction: [String])    // Setup Direction
    {
        directionDropDown.anchorView = txtDirection
        directionDropDown.bottomOffset = CGPoint(x: 0, y: txtDirection.bounds.height + 10)
        
        // You can also use localizationKeysDataSource instead. Check the docs.
        directionDropDown.dataSource = direction as [String]
        
        // Action triggered on selection
        directionDropDown.selectionAction = {
            [weak self] (index, item) in
            
            self?.onSetDefaultColorOnSelectField()
            
            if (self?.isNearBy)! {
                if self?.txtNearByDirection.text == item {
                    return
                }
            }
            else {
                if self?.txtDirection.text == item {
                    return
                }
            }
            
            self?.directionIndex = index
            self?.txtDeparture.text = ""
            self?.txtDestination.text = ""
            
            self?.departureStops = nil
            self?.destinationStops = nil
            
            self?.txtDirection.text = item
            self?.txtNearByDirection.text = item
            
            var directionStr: String!
            
            if index == 0 {
                directionStr = "a"
            }
            else
            {
                directionStr = "b"
            }
            
            self?.routesDepartureArr.removeAll()
            self?.selectRoutesStopsArr.removeAll()
            
            self?.getRoutesVideoURL()
            
            let code = self?.selectViewRoute.code
            
            
            SVProgressHUD.show()
            self?.ref.child("route-details").child(code!).child(directionStr).child("stops").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                
                if snapshot.childrenCount > 0 {
                    
                    for stops in snapshot.children.allObjects as! [DataSnapshot] {
                        //getting values
                        let stopObj = stops.value as? [String: AnyObject]
                        
                        let stopsCode  = stopObj?["code"]
                        let stopsLat  = stopObj?["lat"]
                        let stopsLng = stopObj?["lng"]
                        let stopsName = stopObj?["name"]
                        let stopsRoute_list = stopObj?["route_list"]
                        let stopsSec = stopObj?["sec"]
                        let stopCode = stopObj?["stop_code"]
                        
                        let stopsObj = Stops(code: stopsCode as? String, lat: stopsLat as? Double, lng: stopsLng as? Double, name: stopsName as? String, route_list: stopsRoute_list as? String, sec: stopsSec as? Int, stop_code: stopCode as? String)
                        
                        self?.selectRoutesStopsArr.append(stopsObj)
                    }
                }
                
                self?.routesDepartureArr = self?.selectRoutesStopsArr.map{$0.name} as! [NSString]
                self?.routesDestinationArr = self?.selectRoutesStopsArr.map{$0.name} as! [NSString]
                
                if (self?.isNearBy)! {
                    self?.getNearestStopsAccordingRoutes()
                }
                
                SVProgressHUD.dismiss()
                DispatchQueue.main.async {
                    
                    if self?.selectRoutesStopsArr.count == 0 {
                        self?.btnViewRoutes.isEnabled = false
                        
                        let alertController = UIAlertController(title: "Virtualtour", message: "Stops not available in this routes" as String, preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: { action in})
                        alertController.addAction(okAction)
                        self?.present(alertController, animated: true, completion: nil)
                    }
                }
            })
        }
    }
    
    
    func setupDepartureDropDown(departure: [String])    // Setup Departure
    {
        departureDropDown.anchorView = txtDeparture
        departureDropDown.bottomOffset = CGPoint(x: 0, y: txtDeparture.bounds.height+10)
        
        // You can also use localizationKeysDataSource instead. Check the docs.
        departureDropDown.dataSource = departure as [String]
        
        // Action triggered on selection
        departureDropDown.selectionAction = {
            [weak self] (index, item) in
            
            self?.onSetDefaultColorOnSelectField()
            
            self?.txtDeparture.text = item
            self?.departureIndex = index
            self?.departureStops = self?.selectRoutesStopsArr[index]
            
            if (self?.departureIndex)! >= (self?.destinationIndex)! {
                self?.txtDestination.text = ""
                return
            }
        }
    }
    
    
    func setupDestinationDropDown(destination: [String])    // Setup Destination
    {
        destinationDropDown.anchorView = txtDestination
        destinationDropDown.bottomOffset = CGPoint(x: 0, y: txtDestination.bounds.height + 10)
        
        destinationDropDown.dataSource = destination as [String]
        
        // Action triggered on selection
        destinationDropDown.selectionAction = {
            [weak self] (index, item) in
            
            self?.onSetDefaultColorOnSelectField()
            
            if (self?.departureIndex)! >= index {
                let alertController = UIAlertController(title: "Message", message: "Please select valid destination", preferredStyle: .alert)
                
                let dismiss = UIAlertAction(title: "Dismiss", style: .default) { (action:UIAlertAction) in
                }
                alertController.addAction(dismiss)
                self?.present(alertController, animated: true, completion: nil)
                self?.txtDestination.text = ""
                return
            }
            
            self?.txtDestination.text = item
            self?.destinationIndex = index
            self?.destinationStops = self?.selectRoutesStopsArr[index]
            
            if self?.departureStops.name == self?.destinationStops.name {
                self?.btnViewRoutes.isEnabled = false
            }
            else {
                self?.btnViewRoutes.isEnabled = true
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    //MARK: - GET DATA FROM FIREBASE
    
    func getRoutesDetailFromFireBase(isUserLocation: Bool)
    {
        ref.child("routes").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            var tempRouteArr = [Routes]()
            if snapshot.childrenCount > 0 {
                self.mainRoutesArr.removeAll()
                
                for routes in snapshot.children.allObjects as! [DataSnapshot] {
                    //getting values
                    let routeObj = routes.value as? [String: AnyObject]
                    let routeCode  = routeObj?["code"]
                    let routeDeparture  = routeObj?["departure"]
                    let routeDirection = routeObj?["direction"]
                    let routeDirectionAName = routeObj?["directionAName"]
                    let routeDirectionBName = routeObj?["directionBName"]
                    let routeName = routeObj?["name"]
                    let lat = routeObj?["latitude"]
                    let lon = routeObj?["longitude"]
                    
                    let routesObj = Routes.init(code: routeCode as? String, departure: routeDeparture as? String, destination: routeDirection as? String, directionAName: routeDirectionAName as? String, directionBName: routeDirectionBName as? String, name: routeName as? String, lat: lat as? Double, lon: lon as? Double)
                    tempRouteArr.append(routesObj)
                }
            }
            tempRouteArr.sorted(by: { (s1, s2) -> Bool in
                (s1.name)! < (s2.name)!
            })
            
            
            if isUserLocation && self.isNearBy {
                
                tempRouteArr = tempRouteArr.sorted(by: { (s1, s2) -> Bool in
                    (s1.location?.distance(from: self.locationManager.location!))! < (s2.location?.distance(from: self.locationManager.location!))!
                })
                
                self.mainRoutesArr = Array(tempRouteArr[0..<4])
                if self.mainRoutesArr.count == 0 {
                    
                    let alertController = UIAlertController(title: "Alert", message: "No nearest route available", preferredStyle: .alert)
                    
                    let dismiss = UIAlertAction(title: "Dismiss", style: .default) { (action:UIAlertAction) in
                        self.getRoutesDetailFromFireBase(isUserLocation: false)
                    }
                    alertController.addAction(dismiss)
                    self.present(alertController, animated: true, completion: nil)
                    
                    self.selectViewRoute = nil
                    self.routesDestinationArr.removeAll()
                    self.routesDepartureArr.removeAll()
                    self.routesDirectionArr.removeAll()
                    
                    self.txtDeparture.text = ""
                    self.txtRoutes.text = ""
                    self.txtDirection.text = ""
                    self.txtDestination.text = ""
                    
                    self.departureIndex = -1
                    self.destinationIndex = -1
                    self.directionIndex = -1
                    
                    return
                }
            }
            else {
                self.mainRoutesArr = tempRouteArr
            }
            
            self.routesNameArr = self.mainRoutesArr.map{$0.name} as! [NSString]
            
            SVProgressHUD.dismiss()
            
            self.setupRoutesDropDown(routes: self.routesNameArr as [String])
            self.dropDowns.forEach { $0.dismissMode = .onTap }
            self.dropDowns.forEach { $0.direction = .any }
        }, withCancel: nil)
    }
    
    
    //MARK : UITEXTFIELD DELEGATE
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        txtCurrent = textField
        routesDropDown.show()
        self.onSetDefaultColorOnSelectField()
        
        let lbl = self.view.viewWithTag(400) as! UILabel
        lbl.backgroundColor = select_Color
        
        let lblSelectField = self.view.viewWithTag(500) as! UILabel
        lblSelectField.textColor = select_Color
        
        lblBtmNrRute.backgroundColor = select_Color
        lblNrRute.textColor = select_Color
        
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? "") as NSString
        let searchTextStr = textFieldText.replacingCharacters(in: range, with: string)
        
        let searchRoutes = routesNameArr.filter { routeName in
            return routeName.localizedCaseInsensitiveContains(searchTextStr)
        }
        // print(searchRoutes)
        routesDropDown.dataSource = searchRoutes as [String]
        
        if routesDropDown.isHidden
        {
            routesDropDown.show()
        }
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        selectViewRoute = nil
        routesDestinationArr.removeAll()
        routesDepartureArr.removeAll()
        routesDirectionArr.removeAll()
        
        txtDeparture.text = ""
        txtRoutes.text = ""
        txtDirection.text = ""
        txtDestination.text = ""
        
        departureIndex = -1
        destinationIndex = -1
        directionIndex = -1
        
        routesDropDown.dataSource = routesNameArr as [String]
        
        if routesDropDown.isHidden
        {
            routesDropDown.show()
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func getRoutesVideoURL()
    {
        var directionStr: NSString!
        if (directionIndex == 0)
        {
            directionStr = "a"
        }
        else
        {
            directionStr = "b"
        }
        
        self.directionVideoURLArr.removeAll()
        self.ref.child("route-details").child((self.selectViewRoute.code)!).child(directionStr as String).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let value = snapshot.value as! NSDictionary
            //  print(value)
            
            let reachability = Reachability()!
            
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
                self.selectVideoURL = value.value(forKey: "videoUrl") as! NSString
            } else {
                print("Reachable via Cellular")
                if let lowResURl = value.value(forKey: "videoUrlLowRes")
                {
                    self.selectVideoURL = lowResURl as! NSString
                }
                else
                {
                    self.selectVideoURL = value.value(forKey: "videoUrl") as! NSString
                }
            }
            
            if value.value(forKey: "videoUrl") as! String != ""
            {
                let dict = ["name"          : "Front View",
                            "high_res_url"  : value.value(forKey: "videoUrl") as! String,
                            "geo_point"     : kvideo_geo_point_front,
                            "low_res_url"   : value.value(forKey: "videoUrlLowRes") as! String] as NSDictionary
                
                self.directionVideoURLArr.append(dict as NSDictionary)
            }
            
            if value.value(forKey: "videoLeftUrl") as! String != ""
            {
                let dict = ["name" : "Left View",
                            "high_res_url"  : value.value(forKey: "videoLeftUrl") as! String,
                            "geo_point"     : kvideo_geo_point_left,
                            "low_res_url"   : value.value(forKey: "videoLeftUrlLowRes") as! String] as NSDictionary
                
                self.directionVideoURLArr.append(dict as NSDictionary)
            }
            
            if value.value(forKey: "videoRightUrl") as! String != ""
            {
                let dict = ["name" : "Right View",
                            "high_res_url"  : value.value(forKey: "videoRightUrl") as! String,
                            "geo_point"     : kvideo_geo_point_right,
                            "low_res_url"   : value.value(forKey: "videoRightUrlLowRes") as! String] as NSDictionary
                
                self.directionVideoURLArr.append(dict as NSDictionary)
            }
            
            if value.value(forKey: "videoBackUrl") as! String != ""
            {
                let dict = ["name" : "Back View",
                            "high_res_url"  : value.value(forKey: "videoBackUrl") as! String,
                            "geo_point"     : kvideo_geo_point_back,
                            "low_res_url"   : value.value(forKey: "videoBackUrlLowRes") as! String] as NSDictionary
                
                self.directionVideoURLArr.append(dict as NSDictionary)
            }
            
            if value.value(forKey: "videoNightUrl") as! String != ""
            {
                let dict = ["name" : "Night View",
                            "high_res_url"  : value.value(forKey: "videoNightUrl") as! String,
                            "low_res_url"   : value.value(forKey: "videoLeftUrlLowRes") as! String] as NSDictionary
                
                self.directionVideoURLArr.append(dict as NSDictionary)
            }
            
        })
    }
    
    
    //MARK: GET VIDEO POINTS
    func getVideoGeoPoints() {
        
        var directionStr: String!
        
        if (directionIndex == 0)
        {
            directionStr = "a"
        }
        else
        {
            directionStr = "b"
        }
        
        let code = "\(self.selectViewRoute.code!)"
        
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
        
        
        self.videoGeoPointsArr.removeAll()
        
        let departureGeoPoints = VideoGeoPoints(lat: departureStops.lat, lng: departureStops.lng)
        self.videoGeoPointsArr.append(departureGeoPoints)
        
        self.ref.child("route-details").child(code).child(directionStr!).child("videoGeoPoints").queryOrderedByKey().queryStarting(atValue: startSec).queryEnding(atValue: endSec).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            if snapshot.childrenCount > 0 {
                
                for geoPoint in snapshot.children.allObjects as! [DataSnapshot] {
                    //getting values
                    
                    let geoPointObj = geoPoint.value as? [String: AnyObject]
                    
                    let lat  = geoPointObj?["lat"]
                    let lng  = geoPointObj?["lng"]
                    
                    let videoGeoPointObj = VideoGeoPoints(lat: lat as? Double, lng: (lng as! Double))
                    self.videoGeoPointsArr.append(videoGeoPointObj)
                }
            }
            let destinationGeoPoints = VideoGeoPoints(lat: self.destinationStops.lat, lng: self.destinationStops.lng)
            self.videoGeoPointsArr.append(destinationGeoPoints)
            
            // print(self.videoGeoPointsArr.count)
            SVProgressHUD.dismiss()
            
            if self.txtRoutes.text != "" && self.txtDirection.text != "" && (self.txtDeparture.text != nil) && self.txtDestination.text != ""
            {
                self.performSegue(withIdentifier: "viewRoutesSegue", sender: nil)
            }
        })
    }
    
    func setupBorderView() {
        
        for i in 0..<6
        {
            let outterBorderView = self.view.viewWithTag(i+100)
            outterBorderView?.layer.cornerRadius = (outterBorderView?.height)! / 2.0
            outterBorderView?.dropShadow(scale: true, radius: (outterBorderView?.height)! / 2.0)
        }
        
        for i in 0..<6
        {
            let innerBorderView = self.view.viewWithTag(i+200)
            innerBorderView?.layer.borderColor = UIColor.black.cgColor
            innerBorderView?.layer.borderWidth = 1.0
            innerBorderView?.layer.cornerRadius = (innerBorderView?.height)! / 2.0
        }
    }
    
    
    // GET CURRENT LOCATION
    
    // Print out the location to the console
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print(location.coordinate)
            locationManager.stopUpdatingLocation()
            self.getRoutesDetailFromFireBase(isUserLocation: true)
        }
    }
    
    // If we have been deined access give the user the option to change it
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if(status == CLAuthorizationStatus.denied) {
            showLocationDisabledPopUp()
        }
    }
    
    // Show the popup to the user if we have been deined access
    func showLocationDisabledPopUp() {
        let alertController = UIAlertController(title: "Background Location Access Disabled",
                                                message: "If you find nearest route we need your location",
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
            if let url = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(openAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func onSetDefaultColorOnSelectField() {
        
        for i in 0..<6 { // Clear Select Field Bottom Line
            let lbl = self.view.viewWithTag(i+400) as! UILabel
            lbl.backgroundColor = UIColor.black
        }
        
        for i in 0..<6 { // Clear Select Field Label Text Color
            let lbl = self.view.viewWithTag(i+500) as! UILabel
            lbl.textColor = UIColor.black
        }
    }
    
    func clearSelection() {
        selectViewRoute = nil
        routesDestinationArr.removeAll()
        routesDepartureArr.removeAll()
        routesDirectionArr.removeAll()
        
        txtDeparture.text = ""
        txtRoutes.text = ""
        txtDirection.text = ""
        txtDestination.text = ""
        
        departureIndex = -1
        destinationIndex = -1
        directionIndex = -1
        
        routesDropDown.dataSource = routesNameArr as [String]
        
        txtNearByDirection.text = ""
        txtNearByRoutes.text = ""
    }
    
    
    func getNearestStopsAccordingRoutes() {
        
        if selectRoutesStopsArr.count > 0 {
            
            let stops = selectRoutesStopsArr
            
            stops.sorted(by: { (s1, s2) -> Bool in
                (s1.location?.distance(from: locationManager.location!))! < (s2.location?.distance(from: locationManager.location!))!
            })
            arrNearMeStops = Array(stops[0..<3])
        }
    }
    
}

extension UIView {
    
    func dropShadow(scale: Bool = true, radius: CGFloat = 1) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0.0, height: -0.5)
        layer.shadowRadius = radius
    }
}

extension ViewController: NetworkStatusListener {
    
    func networkStatusDidChange(status: Reachability.Connection) {
        
        switch status {
        case .none:
            debugPrint("ViewController: Network became unreachable")
            
            
        case .wifi:
            debugPrint("ViewController: Network reachable through WiFi")
            
            if directionIndex == -1 {
                return
            }
            
            var directionStr: NSString!
            if (directionIndex == 0)
            {
                directionStr = "a"
            }
            else
            {
                directionStr = "b"
            }
            
            self.directionVideoURLArr.removeAll()
            
            self.ref.child("route-details").child((self.selectViewRoute.code)!).child(directionStr as String).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                let value = snapshot.value as! NSDictionary
                //  print(value)
                
                self.selectVideoURL = value.value(forKey: "videoUrl") as! NSString
            })
            
            
        case .cellular:
            debugPrint("ViewController: Network reachable through Cellular Data")
            
            if directionIndex == -1 {
                return
            }
            
            var directionStr: NSString!
            if (directionIndex == 0)
            {
                directionStr = "a"
            }
            else
            {
                directionStr = "b"
            }
            
            self.directionVideoURLArr.removeAll()
            self.ref.child("route-details").child((self.selectViewRoute.code)!).child(directionStr as String).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                let value = snapshot.value as! NSDictionary
                //  print(value)
                
                if let lowResURl = value.value(forKey: "videoUrlLowRes")
                {
                    self.selectVideoURL = lowResURl as! NSString
                }
                else
                {
                    self.selectVideoURL = value.value(forKey: "videoUrl") as! NSString
                }
            })
        }
    }
}


