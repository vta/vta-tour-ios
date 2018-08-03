//
//  ViewPOIsDetails.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 18/06/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit
import Alamofire
import SDWebImage

class ViewPOIsDetails: UIViewController
{
    @IBOutlet var imgMain: UIImageView!
    @IBOutlet var btnWalk: UIButton!
    @IBOutlet var btnCall: UIButton!
    @IBOutlet var btnWebsite: UIButton!
    
    @IBOutlet var lblName: UILabel!
    @IBOutlet var lblDesc: UILabel!
    @IBOutlet var lblOpen: UILabel!
    @IBOutlet var lblLandmark: UILabel!
    @IBOutlet var lblPhone: UILabel!
    @IBOutlet var lblWebsite: UILabel!
    @IBOutlet var starVw : CosmosView!
    
    var sourceLat_Lon: String!
    var destinationLat_Lon: String!
    var dictDetails = NSMutableDictionary()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        lblName.text = dictDetails.value(forKey: "name") as? String
        starVw.rating = (dictDetails.value(forKey: "rating") as! NSNumber).doubleValue
        
        let strURL = dictDetails.value(forKey: "image") as? String
        imgMain.sd_setImage(with: URL(string: strURL!))
        
        let strPlaceID = dictDetails.value(forKey: "place_id") as? String
        
        sourceLat_Lon = dictDetails.value(forKey: "lat_lon") as? String
        
        getPlaceDetails(placeID: strPlaceID!)
    }
    
    func getPlaceDetails(placeID : String)
    {
        let strURL = "https://maps.googleapis.com/maps/api/place/details/json?placeid=" + placeID + "&fields=name,rating,formatted_phone_number,website,geometry,formatted_address,international_phone_number,opening_hours&key=\(API_KEY.GetPOI)"
        
        Alamofire.request(strURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
            
            if let json = response.result.value
            {
                
                let data = json as! NSDictionary
                if data.value(forKey: "status") as! String  == "REQUEST_DENIED" || data.value(forKey: "status") as! String  == "ZERO_RESULTS" {
                    return
                }
                print(data)
                
                if (data.value(forKeyPath: "result.opening_hours.open_now") != nil) {
                    if data.value(forKeyPath: "result.opening_hours.open_now") as! NSNumber == 0
                    {
                        self.lblOpen.text = "Close Now"
                    }
                    else
                    {
                        self.lblOpen.text = "Open Now"
                    }
                }
                
                if (data.value(forKeyPath: "result.geometry.location") != nil) {
                    
                    let lat = data.value(forKeyPath: "result.geometry.location.lat") as! NSNumber
                    let lng = data.value(forKeyPath: "result.geometry.location.lng") as! NSNumber
                    
                    self.destinationLat_Lon = String(format:"%f", lat.doubleValue) + "," + String(format:"%f", lng.doubleValue)
                }
                
                
                
                self.lblPhone.text = data.value(forKeyPath: "result.formatted_phone_number") as? String
                //                self.btnCall.setTitle(data.value(forKeyPath: "result.international_phone_number") as? String, for: .normal)
                self.lblWebsite.text = data.value(forKeyPath: "result.website") as? String
                self.lblLandmark.text = data.value(forKeyPath: "result.formatted_address") as? String
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func btnWalk(_sender: UIButton)
    {
        
        let googleMapURL = URL(string: "comgooglemaps-x-callback://?saddr=\(sourceLat_Lon!)&daddr=\(destinationLat_Lon!)&x-success=The-Customer-Factor://?resume=true&x-source=The-Customer-Factor") as URL?
        
        
        if let mapOpenURL = URL(string: "comgooglemapsurl://")
        {
            if UIApplication.shared.canOpenURL(mapOpenURL)
            {
                if #available(iOS 10, *)
                {
                    UIApplication.shared.open(googleMapURL!, options: [:]) { (status) in
                    }
                }
                else
                {
                    UIApplication.shared.openURL(googleMapURL!)
                }
            }
        else {
            let appleMapURL = URL(string: "http://maps.apple.com/?daddr=\(destinationLat_Lon!)&saddr=\(sourceLat_Lon!)")
            UIApplication.shared.open(appleMapURL!, options: [:]) { (status) in
            }
        }
        }
    }
    
    @IBAction func btnWebsite(_sender: UIButton)
    {
        if let webURL = lblWebsite.text {
            UIApplication.shared.open(URL(string : webURL)!, options: [:], completionHandler: { (status) in
            })
        }
    }
    
    @IBAction func btnCall(_sender: UIButton)
    {
        if let str = lblPhone.text {
            let strPhone = str.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if let url = URL(string: "tel://\(strPhone)"), UIApplication.shared.canOpenURL(url)
            {
                if #available(iOS 10, *)
                {
                    UIApplication.shared.open(url)
                }
                else
                {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}