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
import SVProgressHUD


class ViewPOIs: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate
{
    @IBOutlet var tablePOIs: UITableView!
    @IBOutlet var btnFilter: UIButton!
    @IBOutlet var txtChooseType: UITextField!
    
    var arrPlaces = NSMutableArray()
    
    var arrTypes = [String]()
    
    var arrPOI_Type = [String]()
    
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
        
        arrPOI_Type = ["accounting","airport","amusement_park","aquarium","art_gallery","atm","bakery","bank","bar","beauty_salon","bicycle_store","book_store","bowling_alley","bus_station","cafe","campground","car_dealer","car_rental","car_repair","car_wash","casino","cemetery","church","city_hall","clothing_store","convenience_store","courthouse","dentist","department_store","doctor","electrician","electronics_store","embassy","fire_station","florist","funeral_home","furniture_store","gas_station","gym","hair_care","hardware_store","hindu_temple","home_goods_store","hospital","insurance_agency","jewelry_store","laundry","lawyer","library","liquor_store","local_government_office","locksmith","lodging","meal_delivery","meal_takeaway","mosque","movie_rental","movie_theater","moving_company","museum","night_club","painter","park","parking","pet_store","pharmacy","physiotherapist","plumber","police","post_office","real_estate_agency","restaurant","roofing_contractor","rv_park","school","shoe_store","shopping_mall","spa","stadium","storage","store","subway_station","supermarket","synagogue","taxi_stand","train_station","transit_station","travel_agency","veterinary_care","zoo"]
        
        arrPOI_Type = arrPOI_Type.map({ $0.replacingOccurrences(of: "_", with: " ").capitalized})
        
        
        tablePOIs.rowHeight = UITableView.automaticDimension
        tablePOIs.estimatedRowHeight = 100
        
//        strType = "bank"
//
//        self.getPOIs(latLong: strLatLong, type: strType)
        self.btnFilter(_sender: btnFilter)
        self.setupBorderView()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
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
        self.setupViewsDropDown(views: arrPOI_Type)
        
        self.dropDowns.forEach { $0.dismissMode = .onTap }
        self.dropDowns.forEach { $0.direction = .any }
       // viewsDropDown.show()
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
            self?.txtChooseType.resignFirstResponder()
            self?.getPOIs(latLong: (self?.strLatLong)!, type: strType)
        }
    }
    
    func getPOIs(latLong : String, type: String)
    {
        let strURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=" + latLong + "&radius=500&type=" + type + "&key=\(API_KEY.GetPOI)"
        SVProgressHUD.show()
        Alamofire.request(strURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
            
            let header = (response.response?.allHeaderFields)! as NSDictionary
            
            print(header)
            print(response)
            SVProgressHUD.dismiss()
            if let json = response.result.value
            {
                self.arrPlaces.removeAllObjects()
                let data = json as! NSDictionary
                if data.value(forKey: "status") as! String  == "REQUEST_DENIED" || data.value(forKey: "status") as! String  == "ZERO_RESULTS"
                {
                    self.tablePOIs.reloadData()
                    return
                }
                
                if (data.value(forKey: "next_page_token") != nil) {
                    self.strNextPageToken = data.value(forKey: "next_page_token") as! String
                    print(self.strNextPageToken)
                }
                
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
    func getPOIsPagination(latLong : String, type: String)
    {
        let strURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=" + latLong + "&radius=500&type=" + type + "&key=\(API_KEY.GetPOI)" + "&pagetoken=\(strNextPageToken)"
        
        SVProgressHUD.show()
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
                
                if (data.value(forKey: "next_page_token") != nil)
                {
                    self.strNextPageToken = data.value(forKey: "next_page_token") as! String
                    print(self.strNextPageToken)
                }
                
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
        
        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: .none, queue: OperationQueue.main) { [weak self] _ in
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
        if (indexPath.item + 1 == arrPlaces.count) && ((indexPath.item + 1) % 20 == 0) {
            
            self.getPOIsPagination(latLong: strLatLong, type: strType)
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
        
        if txtChooseType.isEditing {
            txtChooseType.resignFirstResponder()
        }
        
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
    
    //MARK : UITEXTFIELD DELEGATE
    
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        viewsDropDown.show()
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? "") as NSString
        let searchTextStr = textFieldText.replacingCharacters(in: range, with: string)
        
        let searchRoutes = arrPOI_Type.filter { routeName in
            return routeName.localizedCaseInsensitiveContains(searchTextStr)
        }
        // print(searchRoutes)
        viewsDropDown.dataSource = searchRoutes as [String]
        
        if viewsDropDown.isHidden
        {
            viewsDropDown.show()
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        viewsDropDown.dataSource = arrPOI_Type as [String]
        if viewsDropDown.isHidden
        {
            viewsDropDown.show()
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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


