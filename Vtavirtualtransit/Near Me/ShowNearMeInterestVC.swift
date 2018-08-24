//
//  ShowNearMeInterestVC.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 15/07/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import Alamofire

class ShowNearMeInterestVC: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    
    var cellType: String! = "label"
    var type: String!
    var selectStops: Stops!
    var strNextPageToken = String()
    
    var ref: DatabaseReference!         // FIREBASE REFERENCE
    
    var arrData = [Dictionary<String, Any>]()
    @IBOutlet weak var tbleVwShowData: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        // Do any additional setup after loading the view.
        tbleVwShowData.rowHeight = UITableViewAutomaticDimension
        tbleVwShowData.estimatedRowHeight = 100
        
        self.title = type
        
        self.getPoiInfo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(forName: .UIContentSizeCategoryDidChange, object: .none, queue: OperationQueue.main) { [weak self] _ in
            self?.tbleVwShowData.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
     // MARK: - Navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showNearMePOIDetailSegue" {
            
            if let destinationVC = segue.destination as? ViewPOIsDetails {
                destinationVC.dictDetails = sender as! NSMutableDictionary
            }
            
        }
        
     }
    
    //MARK:- UITABLEVIEW DATA SOURCE
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if cellType == "label" {
            let lblCell = tableView.dequeueReusableCell(withIdentifier: "poi_Label_Cell", for: indexPath) as! PoiLabelCell
            
            let dict = arrData[indexPath.row]
            lblCell.lblName.text = dict["title"] as? String
            
            return lblCell
        }
        else if cellType == "image" {
            let imgCell = tableView.dequeueReusableCell(withIdentifier: "poi_custom_Cell", for: indexPath) as! PoiCustomCell
            
            let dict = arrData[indexPath.row]
            imgCell.lblName.text = dict["title"] as? String
            
            if dict["image"] is String {
                imgCell.imgVwPoi?.image = UIImage.init(named: dict["image"] as! String)
            }
            else {
                imgCell.imgVwPoi?.image = dict["image"] as? UIImage
            }
            
            imgCell.lblSubTitle.text = dict["subTitle"] as? String
            
            return imgCell
        }
        else {
            
           let poiCell = tableView.dequeueReusableCell(withIdentifier: "cell_pois", for: indexPath) as! PoiCell
            
            let dictDetails = arrData[indexPath.row]
            poiCell.lblPoiTitle.text = dictDetails["name"] as? String
            
            if dictDetails["photos"] != nil
            {
                let arrPhotos = dictDetails["photos"] as! NSArray
                let strPhotoRef = (arrPhotos.object(at: 0) as! NSDictionary).value(forKey: "photo_reference") as! String
                
                let strURL = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=" + strPhotoRef + "&key=\(API_KEY.GetPOI)"
                
                poiCell.imgVwPoi.sd_setImage(with: URL(string: strURL))
            }
            else {
                poiCell.imgVwPoi.image = nil
            }
            
            if dictDetails["rating"] != nil
            {
                poiCell.starRate.isHidden = false
                let rating = dictDetails["rating"] as! NSNumber
                poiCell.starRate.rating = rating.doubleValue
            }
            else
            {
                poiCell.starRate.isHidden = true
            }
            return poiCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        
        if cellType == "POI" {
            
            let dictDetails = arrData[indexPath.row] as NSDictionary
            
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
            let lat:String = String(format:"%f",selectStops.lat!)
            let lng: String = String(format:"%f",selectStops.lng!)
            let strLatLong = lat + "," + lng
            
            dictNew.setValue(strLatLong, forKey: "lat_lon")
            
            self.performSegue(withIdentifier: "showNearMePOIDetailSegue", sender: dictNew)
        }
        else if cellType == "image" {
            
            if type == "Social Gathering" {
                let dictDetails = arrData[indexPath.row] as NSDictionary
                if let meetupURL = dictDetails.value(forKey: "meetupURL") {
                    UIApplication.shared.open(URL(string : meetupURL as! String)!, options: [:], completionHandler: { (status) in
                    })
                }
            }
            else if type == "Custom POI" {
                
                let dictDetails = arrData[indexPath.row] as NSDictionary
                if let connection = dictDetails.value(forKey: "web_link") {
                    
                    UIApplication.shared.open(URL(string : connection as! String)!, options: [:], completionHandler: { (status) in
                    })
                }
            }
        }
        else if cellType == "label" {
            if type == "Transit Connections" {
                
                let dictDetails = arrData[indexPath.row] as NSDictionary
                if let connection = dictDetails.value(forKey: "title") {
                    
                    let connectionURL = "http://www.vta.org/routes/rt\(connection)"
                    UIApplication.shared.open(URL(string : connectionURL)!, options: [:], completionHandler: { (status) in
                    })
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if cellType == "label"{
            return 40.0
        }
        else if cellType == "image"
        {
            return 65.0
        }
        else {
            return 80.0
        }
    }
    
    func getPoiInfo()
    {
        if type == "Amenities" {
            self.loadAmenities()
        }
        else if type == "Transit Connections" {
            self.loadConnection()
        }
        else if type == "Social Gathering" {
            let lat:String = String(format:"%f",selectStops.lat!)
            let lng: String = String(format:"%f",selectStops.lng!)
            
            self.loadSocialGethering(lat: lat, lon: lng)
        }
        else if type == "Custom POI" {
            self.loadCustomePOI()
        }
        else { // Load POI Category
//            let lat:String = String(format:"%f",selectStops.lat!)
//            let lng: String = String(format:"%f",selectStops.lng!)
//
//            let strLatLng = lat + "," + lng
//
//            self.loadPoi(latLong: strLatLng, type: type.lowercased() )
            tbleVwShowData.reloadData()
            
        }
    }
    
    func loadAmenities() {
        
        //        var tempStr = "\nConnections: \(String(selectStops.route_list!))\nAmenities: " as String
        
        self.ref.child("amenities").child((selectStops.code)!).observeSingleEvent(of: DataEventType.childAdded, with: { (snapshot) in
            
            if snapshot.childrenCount > 0 {
                for snapShotObj in snapshot.children.allObjects as! [DataSnapshot] {
                    print(snapShotObj)
                    
                    let amenitiesObj = snapShotObj.value as? [String: AnyObject]
                    
                    let enable  = amenitiesObj?["enabled"]
                    let key  = amenitiesObj?["key"]
                    let value  = amenitiesObj? ["value"]
                    
                    
                    let amiobj = AmenitiesFields(isEnable: enable as? Bool, key: key as? String, value: value as? String )
                    
                    if (amiobj.enabled == true && !(amiobj.amenitiesValue == "0") && !((amiobj.amenitiesValue?.isEmpty)!) && !(amiobj.amenitiesKey == "stop_id"))
                    {
                        var tempStr = ""
                        if (amiobj.amenitiesValue == "1"){
                            tempStr = amiobj.amenitiesKey!
                        }
                        else {
                            tempStr = amiobj.amenitiesKey! + ": " + amiobj.amenitiesValue!
                        }
                        let dict : [String:Any] = ["title": tempStr]
                        self.arrData.append(dict)
                    }
                }
                self.tbleVwShowData.reloadData()
            }
        })
    }
    
    func loadConnection() {
        
        if !(selectStops.route_list?.isEmpty)! {
            
            let arr = selectStops.route_list!.components(separatedBy: ",")
            
            for str in arr {
                let dict : [String:Any] = ["title":str]
                self.arrData.append(dict)
            }           
        }
        self.tbleVwShowData.reloadData()
    }
    
    func loadSocialGethering(lat: String?, lon: String?) {
        
        let strURL = "https://api.meetup.com/2/groups/?lat=" + lat! + "&lon=" + lon! + "&key=\(API_KEY.MeetUp)&radius=5"
        
        print(" Str URL ==\(strURL)")
        Alamofire.request(strURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
            
            if let json = response.result.value
            {
                let dataDict = json as! NSDictionary
                
                if (dataDict != nil && dataDict.count > 0)
                {
                    let resultArr = dataDict.value(forKey: "results") as! NSArray
                    
                    for dict in resultArr {
                        
                        let strName = (dict as! NSDictionary).value(forKey: "name") as! String
                        let meetupURL = (dict as! NSDictionary).value(forKey: "link") as! String
                        let member = (dict as! NSDictionary).value(forKey: "members") as! Int
                        let dict : [String:Any] = ["title": strName, "meetupURL" : meetupURL, "subTitle": "Member: \(member)", "image": #imageLiteral(resourceName: "ic_meetup_poi")]
                        self.arrData.append(dict)
                    }
                    self.tbleVwShowData.reloadData()
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
    
    
    func loadCustomePOI() {
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
                    
                    if customPOIs.icon != nil && customPOIs.icon != "" && !(customPOIs.icon?.isEmpty)!
                    {
                        var str = customPOIs.icon ?? ""
                        str = str.replacingOccurrences(of: "data:image/png;base64,", with: "")
                        str = str.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                        
                        let dataDecoded:NSData = NSData(base64Encoded: str, options: NSData.Base64DecodingOptions(rawValue: 0))!
                        
                        let decodedimage:UIImage = UIImage(data: dataDecoded as Data)!
                        
                        let dict : [String:Any] = ["title": customPOIs.name ?? "", "subTitle": customPOIs.address ?? "", "image": decodedimage, "web_link": customPOIs.web_link ?? ""]
                        self.arrData.append(dict)
                    }
                    else {
                        let dict : [String:Any] = ["title": customPOIs.name ?? "", "subTitle": customPOIs.address ?? "", "image": "", "web_link": customPOIs.web_link ?? ""]
                        self.arrData.append(dict)
                    }
                }
                self.tbleVwShowData.reloadData()
            }
        })
    }
    
    func loadPoi(latLong : String, type: String) {
        
        let strURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=" + latLong + "&radius=500&type=" + type + "&key=\(API_KEY.GetPOI)"
        
        Alamofire.request(strURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
            
            let header = (response.response?.allHeaderFields)! as NSDictionary
            
            print(response.request)
            print(response)
            
            if let json = response.result.value
            {
                let data = json as! NSDictionary
                if data.value(forKey: "status") as! String  == "REQUEST_DENIED" || data.value(forKey: "status") as! String  == "ZERO_RESULTS" {
                    return
                }
                
               // self.strNextPageToken = data.value(forKey: "next_page_token") as! String
                print(self.strNextPageToken)
                self.arrData = data.value(forKey: "results") as! [Dictionary<String, Any>]
                self.tbleVwShowData.reloadData()
                
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
