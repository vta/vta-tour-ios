//
//  ViewPOIs.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 11/06/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit
import Alamofire
import SDWebImage
import DropDown



class ViewPOIs: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet var tablePOIs: UITableView!
    @IBOutlet var btnFilter: UIButton!
    @IBOutlet var txtChooseType: UITextField!
    
    var arrPlaces = NSMutableArray()
    
    var arrTypes = [String]()
    
    var arrPOI_Type = [Dictionary<String, Any>]()
    
    var strLatLong = String()
    var strType = String()
    var strNextPageToken = String()
    
    let viewsDropDown = DropDown()
    
    lazy var dropDowns: [DropDown] = {  // DROP DOWN ARRAY
        return [
            self.viewsDropDown,
            ]
    }()
    
    var counterIndex: Int! = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        DropDown.appearance().textAlignment = NSTextAlignment.center
        
        arrPOI_Type = [["type" : 0,
                        "items": ["*"]],
                       
                       ["type" : 1,
                        "items":["airport","atm","bank","bus_station","car_rental","car_repair","car_wash","fire_station","gas_station","hospital","library","point_of_interestpoint_of_interest","pharmacy","post_office","school","subway_station","taxi_stand","train_station",
                                 "transit_station","shopping_mall","supermarket"]],
                       
                       ["type" : 2,
                        "items" :["amusement_park","aquarium","art_gallery","church","city_hall","embassy","establishment","hindu_temple","local_government_office","mosque","movie_rental","movie_theater","museum","park","point_of_interest","rv_park","stadium","zoo"]],
                       
                       ["type" : 3,
                        "items": ["bakery","bar","cafe","restaurant","casino","convenience_store","department_store",
                                  "home_goods_store","furniture_store","liquor_store","meal_delivery","meal_takeaway","night_club",
                                  "clothing_store","pet_store","shoe_store","spa","store","gym","hair_care","beauty_salon"]],
                       
                       ["type" : 4,
                        "items": ["accounting","book_store","car_dealer","courthouse","dentist","doctor","electrician","florist","lawyer","painter","physiotherapist","plumber","police","roofing_contractor","moving_company","real_estate_agency","travel_agency","insurance_agency"]],
                       
                       ["type" : 5,
                        "items": ["bicycle_store","bowling_alley","campground","cemetery","electronics_store","funeral_home","hardware_store","jewelry_store","laundry","locksmith","lodging","storage","synagogue","veterinary_care"]]]
        
        
        tablePOIs.rowHeight = UITableViewAutomaticDimension
        tablePOIs.estimatedRowHeight = 100
        
        strType = "bank"
        
        self.getPOIs(latLong: strLatLong, type: strType)
        
        self.getPOITypesCategory(latLong: strLatLong)
        self.setupBorderView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = "Place of Interest"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.title = ""
    }
    
    @IBAction func btnFilter(_sender: UIButton)
    {
        // self.setupViewsDropDown(views: ["All", "Bank", "Atm", "Finance", "Point of Interest", "Establishment", "Moving Company"])
        
        self.setupViewsDropDown(views: arrTypes)
        
        self.dropDowns.forEach { $0.dismissMode = .onTap }
        self.dropDowns.forEach { $0.direction = .any }
        viewsDropDown.show()
    }
    
    //MARK: - Setup
    func setupViewsDropDown(views: [String]) { // Setup Routes
        viewsDropDown.anchorView = btnFilter
        viewsDropDown.bottomOffset = CGPoint(x: 0, y: btnFilter.bounds.height + 10)
        
        viewsDropDown.dataSource = views as [String]
        
        viewsDropDown.selectionAction = { [weak self] (index, item) in
            self?.btnFilter.titleLabel?.text = item
            
            var strType = String()
            self?.txtChooseType.text = item
            
            strType = item.replacingOccurrences(of: " ", with: "_").lowercased()
            
            
            
            self?.getPOIs(latLong: (self?.strLatLong)!, type: strType)
        }
    }
    
    func getPOIs(latLong : String, type: String)
    {
        let strURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=" + latLong + "&rankby=distance&type=" + type + "&key=\(API_KEY.GetPOI)"
        
        Alamofire.request(strURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
            
            let header = (response.response?.allHeaderFields)! as NSDictionary
            
            print(header)
            print(response)
            
            if let json = response.result.value
            {
                let data = json as! NSDictionary
                if data.value(forKey: "status") as! String  == "REQUEST_DENIED" || data.value(forKey: "status") as! String  == "ZERO_RESULTS" {
                    return
                }
                
                if (data.value(forKey: "next_page_token") != nil) {
                    self.strNextPageToken = data.value(forKey: "next_page_token") as! String
                    print(self.strNextPageToken)
                }
                
                
                self.arrPlaces.removeAllObjects()
                self.arrPlaces.addObjects(from: data.value(forKey: "results") as! [Any])
                self.tablePOIs.reloadData()
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
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(forName: .UIContentSizeCategoryDidChange, object: .none, queue: OperationQueue.main) { [weak self] _ in
            self?.tablePOIs.reloadData()
        }
    }
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "show_details"
        {
            if let obj = segue.destination as? ViewPOIsDetails
            {
                obj.dictDetails = sender as! NSMutableDictionary
            }
        }
    }
    
    //MARK: - UITABLEVIEW DELEGATE
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return arrPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cell = UITableViewCell()
        
        cell = tableView.dequeueReusableCell(withIdentifier: "cell_pois", for: indexPath)
        
        let dictDetails = arrPlaces.object(at: indexPath.row) as! NSDictionary        
        let lblName = cell.viewWithTag(11) as! UILabel
        let imgMain = cell.viewWithTag(10) as! UIImageView
        let starVw  = cell.viewWithTag(12) as! CosmosView
        
        lblName.text = dictDetails.value(forKey: "name") as? String
        
        if (dictDetails.value(forKey: "photos") != nil)
        {
            let arrPhotos = dictDetails.value(forKey: "photos") as! NSArray
            let strPhotoRef = (arrPhotos.object(at: 0) as! NSDictionary).value(forKey: "photo_reference") as! String
            
            let strURL = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=" + strPhotoRef + "&key=\(API_KEY.GetPOI)"
            
            imgMain.sd_setImage(with: URL(string: strURL))
        }
        else {
            imgMain.image = nil
        }
        
        if (dictDetails.value(forKey: "rating") != nil)
        {
            starVw.isHidden = false
            let rating = dictDetails.value(forKey: "rating") as! NSNumber
            starVw.rating = rating.doubleValue
        }
        else
        {
            starVw.isHidden = true
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let dictDetails = arrPlaces.object(at: indexPath.row) as! NSDictionary
        
        let dictNew = NSMutableDictionary()
        
        dictNew.setValue(dictDetails.value(forKey: "name") as? String, forKey: "name")
        dictNew.setValue(dictDetails.value(forKey: "place_id") as? String, forKey: "place_id")
        
        if (dictDetails.value(forKey: "rating") != nil)
        {
            let rating = dictDetails.value(forKey: "rating") as! NSNumber
            dictNew.setValue(rating, forKey: "rating")
        }
        else
        {
            dictNew.setValue(0, forKey: "rating")
        }
        
        if (dictDetails.value(forKey: "photos") != nil)
        {
            let arrPhotos = dictDetails.value(forKey: "photos") as! NSArray
            let strPhotoRef = (arrPhotos.object(at: 0) as! NSDictionary).value(forKey: "photo_reference") as! String
            
            let strURL = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=" + strPhotoRef + "&key=\(API_KEY.GetPOI)"
            
            dictNew.setValue(strURL, forKey: "image")
        }
        else
        {
            dictNew.setValue("", forKey: "image")
        }
        dictNew.setValue(strLatLong, forKey: "lat_lon")
        
        self.performSegue(withIdentifier: "show_details", sender: dictNew)
    }
    
    func setupBorderView() {
        
        let outterBorderView = self.view.viewWithTag(100)
        outterBorderView?.layer.cornerRadius = (outterBorderView?.height)! / 2.0
        outterBorderView?.dropShadow(scale: true, radius: (outterBorderView?.height)! / 2.0)
        
        let innerBorderView = self.view.viewWithTag(200)
        innerBorderView?.layer.borderColor = UIColor.black.cgColor
        innerBorderView?.layer.borderWidth = 1.0
        innerBorderView?.layer.cornerRadius = (innerBorderView?.height)! / 2.0
    }
    
    func getPOITypesCategory(latLong : String)
    {
        if counterIndex < (arrPOI_Type.count - 1) {
            
            let typeArr = arrPOI_Type[counterIndex]["items"] as! [String]
            
            let type = typeArr.joined(separator: ",")

            
            let strURL = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=" + type + "&fields=types" + "&inputtype=textquery" + "&locationbias=circle:500@" + latLong + "&key=\(API_KEY.GetPOI)"
            
            Alamofire.request(strURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
                
                let header = (response.response?.allHeaderFields)! as NSDictionary
                
                print(header)
                print(response)
                
                if let json = response.result.value
                {
                    let data = json as! NSDictionary
                    if data.value(forKey: "status") as! String  == "REQUEST_DENIED" || data.value(forKey: "status") as! String  == "ZERO_RESULTS" {
                        self.counterIndex = self.counterIndex + 1
                        self.getPOITypesCategory(latLong: self.strLatLong)
                        return
                    }
                    
                    let resultArr = data.value(forKey: "candidates") as! NSArray
                    //  print("Result Arr ===\(resultArr)")
                    let types = resultArr.value(forKey: "types") as! NSArray
                    print("TYPES +++++====\(types)")
                    
                    var typesArr = [String]()
                    
                    for innerArr in types {
                        print("Inner Arrr= = \(innerArr)")
                        for typeStr in (innerArr as! NSArray) {
                            
                            if self.counterIndex == 0 {
                                if !typesArr.contains(typeStr as! String) {
                                    typesArr.append(typeStr as! String)
                                }
                            }
                            else {
                               
                                if !typesArr.contains(typeStr as! String) && (self.arrPOI_Type[self.counterIndex]["items"] as! [String]).contains(typeStr as! String) {
                                    typesArr.append(typeStr as! String)
                                }
                            }
                        }
                    }
                    
                    typesArr = typesArr.sorted(by: { (s1, s2) -> Bool in
                        s1 < s2
                    })
                    
                    for strTypes in typesArr {
                        self.arrTypes.append(strTypes.replacingOccurrences(of: "_", with: " ").capitalized)
                    }
                    self.arrTypes = self.arrTypes.removeDuplicates()
                    
                    self.counterIndex = self.counterIndex + 1
                    self.getPOITypesCategory(latLong: self.strLatLong)
                }
                else
                {
                    print(response)
                    self.counterIndex = self.counterIndex + 1
                    
                    self.getPOITypesCategory(latLong: self.strLatLong)
                    let alertController = UIAlertController(title: "Virtualtour", message: "Could not connect to the server.\n Please try again." as String, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: { action in})
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        else {
            self.arrTypes.insert("All", at: 0   )
            
        }
    }
}

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        
        return result
    }
}

//var getByCategory = function(index){
//    console.log('Index: '+index +' Group length: '+typeGroups.length);
//    if(index<typeGroups.length){
//        var request = {
//            location: location,
//            radius: 500,
//            //rankBy: google.maps.places.RankBy.DISTANCE,
//            types: typeGroups[index].items
//        };
//        var service = new google.maps.places.PlacesService(map);
//        var results;
//
//        var mapCounter = 1;
//
//        service.nearbySearch(request, function(results, status) {
//            console.log('check pois')
//            console.log(results);
//            if(results){
//                results = results.map(function(result) {
//                    result.latitude = result.geometry.location.lat();
//                    result.longitude = result.geometry.location.lng();
//
//                    if (result.photos && result.photos.length > 0) {
//                        result.imageUrl = result.photos[0].getUrl({
//                            'maxWidth': 100,
//                            'maxHeight': 100
//                        });
//                    }
//
//                    // if (mapCounter === results.length) {
//                    //   self.fire('pois-loaded', results);
//                    // }
//
//                    mapCounter++;
//                    if(ids.indexOf(result.id) === -1){
//                        ids.push(result.id);
//                        totalResults.push(result);
//                    }
//
//                });
//                // if(totalResults && totalResults.length){
//                //   //totalResults.push(results);
//                //   self.fire('pois-loaded', totalResults);
//                // }
//            }
//
//            setTimeout(function(){
//                index = index+1;
//                getByCategory(index);
//            }, 100);
//
//        });
//    }else{
//        console.log('Total results');
//        console.log(totalResults);
//        self.fire('pois-loaded', totalResults);
//    }
//}
//getByCategory(0);
//},

