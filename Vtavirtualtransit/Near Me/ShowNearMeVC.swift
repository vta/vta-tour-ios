//
//  ShowNearMeVC.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 15/07/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit
import DropDown
import Firebase
import Alamofire
import CoreLocation
import SVProgressHUD

struct Post: Hashable, Equatable {
    let id: String
    var hashValue: Int { get { return id.hashValue } }
}

func ==(left:Post, right:Post) -> Bool {
    return left.id == right.id
}

class ShowNearMeVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var ref: DatabaseReference!         // FIREBASE REFERENCE
    
    var mainArr = [String]()
    var arrNearMeStops = [Stops]()
    var amenitiesArr = [String]()
    var selectIndex: Int! = -1
    var selectStops: Stops!
    var arrCategory = [String]()
    var category_Index : Int! = 0
    var isLoadMore: Bool! = false
    var arrValidCategory = [String]()
    var selectStopIndex: Int! = 0
    
    // var currentLocation: CLLocation!
    
    var poiCategoryDataArr = [Dictionary<String, Any>]()
    
    @IBOutlet weak var tableVwAnimities: UITableView!
    @IBOutlet weak var lblNearBySelection: UILabel!
    
    let nearMeStopsDropDown = DropDown()
    
    var strNextPageToken = String()
    
    
    lazy var dropDowns: [DropDown] = {  // DROP DOWN ARRAY
        return [
            self.nearMeStopsDropDown,
            ]
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        
        // Do any additional setup after loading the view.
        DropDown.appearance().textAlignment = NSTextAlignment.center
        
        selectStops = arrNearMeStops.first
        self.title = selectStops.name
        
        mainArr = ["Amenities", "Connections", "Social Gathering", "Custom POI"]
        
        let lat:String = String(format:"%f", selectStops.lat!)
        let lng: String = String(format:"%f",selectStops.lng!)
        
        let crrentLatLng = lat + "," + lng
        
        // self.getPOIs(latLong: crrentLatLng, type: "all")
        
        arrCategory = ["accounting","airport","amusement_park","aquarium","art_gallery","atm","bakery","bank","bar","beauty_salon","bicycle_store","book_store","bowling_alley","bus_station","cafe","campground","car_dealer","car_rental","car_repair","car_wash","casino","cemetery","church","city_hall","clothing_store","convenience_store","courthouse","dentist","department_store","doctor","electrician","electronics_store","embassy","fire_station","florist","funeral_home","furniture_store","gas_station","gym","hair_care","hardware_store","hindu_temple","home_goods_store","hospital","insurance_agency","jewelry_store","laundry","lawyer","library","liquor_store","local_government_office","locksmith","lodging","meal_delivery","meal_takeaway","mosque","movie_rental","movie_theater","moving_company","museum","night_club","painter","park","parking","pet_store","pharmacy","physiotherapist","plumber","police","post_office","real_estate_agency","restaurant","roofing_contractor","rv_park","school","shoe_store","shopping_mall","spa","stadium","storage","store","subway_station","supermarket","synagogue","taxi_stand","train_station","transit_station","travel_agency","veterinary_care","zoo"]
        
        arrValidCategory.removeAll()
        self.recursiveMethodGetCategoryAccordingNearBy()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.isTranslucent = false
        self.title = selectStops.name
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.title = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK:- UITABLEVIEW DATA SOURCE
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return amenitiesArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "animities_Cell", for: indexPath)
        let lblName = cell.viewWithTag(10) as! UILabel
        lblName.text = amenitiesArr[indexPath.row]
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectIndex = indexPath.row
        
        
        if selectIndex > 3 && amenitiesArr[indexPath.row] != "Load More" {
            
            let lat:String = String(format:"%f",selectStops.lat!)
            let lng: String = String(format:"%f",selectStops.lng!)
            
            let strLatLng = lat + "," + lng
            
            let typeStr = amenitiesArr[indexPath.row].replacingOccurrences(of: " ", with: "_").lowercased()
            
            self.loadPoiCategory(latLong: strLatLng, type: typeStr)
        }
        else if selectIndex <= 3 {
            self.performSegue(withIdentifier: "nearme_poi_segue", sender: nil)
        }
        else if selectIndex > 3 && amenitiesArr[indexPath.row] == "Load More" {
            isLoadMore = true
            
            if let index = amenitiesArr.index(of: "Load More") {
                amenitiesArr.remove(at: index)
            }
            arrValidCategory.removeAll()
            self.recursiveMethodGetCategoryAccordingNearBy()
        }
    }
    
    
    
    //MARK:- IBACTION METHOD
    
    @IBAction func onStopsSelectionBtn(_ sender: UIButton) {
        
        let stopsName = arrNearMeStops.map({$0.name})
        
        self.setupViewsDropDown(views: stopsName as! [String])
        
        self.dropDowns.forEach { $0.dismissMode = .onTap }
        self.dropDowns.forEach { $0.direction = .any }
        nearMeStopsDropDown.show()
        
    }
    
    //MARK: - Drop Down Setup
    func setupViewsDropDown(views: [String]) { // Setup Routes
        nearMeStopsDropDown.anchorView = tableVwAnimities
        nearMeStopsDropDown.bottomOffset = CGPoint(x: 0, y: tableVwAnimities.y)
        nearMeStopsDropDown.dataSource = views as [String]
        
        nearMeStopsDropDown.selectionAction = { [weak self] (index, item) in
            
            if self?.selectStopIndex != index {
                self?.selectStopIndex = index
                self?.title = item
                self?.selectStops = self?.arrNearMeStops[index]
               
                self?.category_Index = 0
                self?.isLoadMore = false
                self?.arrValidCategory.removeAll()
                self?.amenitiesArr.removeAll()
                self?.recursiveMethodGetCategoryAccordingNearBy()
            }
        }
    }
    
    
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "nearme_poi_segue" {
            
            if let destinationVC = segue.destination as? ShowNearMeInterestVC {
                
                if (amenitiesArr[selectIndex] == "Amenities") || (amenitiesArr[selectIndex] == "Connections")
                {
                    destinationVC.cellType = "label"
                }
                else if (amenitiesArr[selectIndex]) == "Social Gathering" || (amenitiesArr[selectIndex]) == "Custom POI" {
                    destinationVC.cellType = "image"
                }
                else{
                    destinationVC.cellType = "POI"
                    destinationVC.arrData = poiCategoryDataArr
                }
                destinationVC.type = amenitiesArr[selectIndex]
                destinationVC.selectStops = selectStops
            }
        }
    }
    
    func recursiveMethodGetCategoryAccordingNearBy() {
        
        if category_Index < (isLoadMore ? (arrCategory.count-1) : 10)
        {
            let lat:String = String(format:"%f", selectStops.lat!)
            let lng: String = String(format:"%f",selectStops.lng!)
            
            let crrentLatLng = lat + "," + lng
            let strCate = arrCategory[category_Index]
         //   print("Category call.....\(strCate)")
            self.getPOIs(latLong: crrentLatLng, type: strCate)
        }
        else{
            print("Get All category.....")
            let tempArr = arrValidCategory
            
            var poiTypesArr = [String]()
            for strTypes in tempArr {
                poiTypesArr.append(strTypes.replacingOccurrences(of: "_", with: " ").capitalized)
            }
            
            poiTypesArr = poiTypesArr.sorted(by: { (s1, s2) -> Bool in
                s1 < s2
            })
            self.amenitiesArr.removeAll()
            self.amenitiesArr += self.mainArr
            self.amenitiesArr += poiTypesArr
            
            if !isLoadMore {
                self.amenitiesArr.append("Load More")
            }
            else{
                if let index = amenitiesArr.index(of: "Load More") {
                    amenitiesArr.remove(at: index)
                }
            }
            
            self.tableVwAnimities.reloadData()
            SVProgressHUD.dismiss()
        }
        
    }
    
    func getPOIs(latLong : String, type: String)
    {
        SVProgressHUD.show(withStatus: "Loading...\nPlease wait")
        
        let strURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=" + latLong + "&radius=500&type=" + type + "&key=\(API_KEY.GetPOI)"
        
        Alamofire.request(strURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
            
            // let header = (response.response?.allHeaderFields)! as NSDictionary
            
            //  print(response.request)
            //print(response)
            
            if let json = response.result.value
            {
                let data = json as! NSDictionary
                if data.value(forKey: "status") as! String  == "REQUEST_DENIED" || data.value(forKey: "status") as! String  == "ZERO_RESULTS" {
                    self.category_Index = self.category_Index + 1
                    self.recursiveMethodGetCategoryAccordingNearBy()
                    return
                }
                
                if (data.value(forKey: "next_page_token") != nil) {
                    self.strNextPageToken = data.value(forKey: "next_page_token") as! String
                    print(self.strNextPageToken)
                }
                
                
                let resultArr = data.value(forKey: "results") as! NSArray
               // print("Result Arr ===\(resultArr)")
                
                let types = resultArr.value(forKey: "types") as! NSArray
               // print("TYPES +++++====\(types)")
                
                self.arrValidCategory.append(type)
                self.category_Index = self.category_Index + 1
                self.recursiveMethodGetCategoryAccordingNearBy()
                
                //                var typesArr = [String]()
                //
                //                for innerArr in types {
                //                    for typeStr in (innerArr as! NSArray) {
                //                        if !typesArr.contains(typeStr as! String) {
                //                            typesArr.append(typeStr as! String)
                //                        }
                //                    }
                //                }
                //                self.amenitiesArr.removeAll()
                //
                //                var poiTypesArr = [String]()
                //                for strTypes in typesArr {
                //                    poiTypesArr.append(strTypes.replacingOccurrences(of: "_", with: " ").capitalized)
                //                }
                //
                //                poiTypesArr = poiTypesArr.sorted(by: { (s1, s2) -> Bool in
                //                    s1 < s2
                //                })
                //
                //                self.amenitiesArr += self.mainArr
                //                self.amenitiesArr += poiTypesArr
                //
                //                print("Final Type Arr ===\(typesArr)")
                //                self.tableVwAnimities.reloadData()
                //
                //                SVProgressHUD.dismiss()
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
    
    
    func loadPoiCategory(latLong : String, type: String) {
        SVProgressHUD.show()
        let strURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=" + latLong + "&radius=500&type=" + type + "&key=\(API_KEY.GetPOI)"
        
        Alamofire.request(strURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
            
            let header = (response.response?.allHeaderFields)! as NSDictionary
            
            print(header)
            print(response)
            SVProgressHUD.dismiss()
            if let json = response.result.value
            {
                let data = json as! NSDictionary
                if data.value(forKey: "status") as! String  == "REQUEST_DENIED" || data.value(forKey: "status") as! String  == "ZERO_RESULTS" {
                    return
                }
                
                // self.strNextPageToken = data.value(forKey: "next_page_token") as! String
                print(self.strNextPageToken)
                self.poiCategoryDataArr = data.value(forKey: "results") as! [Dictionary<String, Any>]
                
                
                if self.poiCategoryDataArr.count > 0 {
                    self.performSegue(withIdentifier: "nearme_poi_segue", sender: nil)
                }
                else
                {
                    let alertController = UIAlertController(title: "Virtualtour", message: "No details available" as String, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: { action in})
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
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
}



