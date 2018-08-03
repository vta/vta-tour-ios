//
//  NavigationVC.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 14/06/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire

class NavigationVC: UIViewController, GMSMapViewDelegate {
    
    var navigationRouteName: String! = nil
    
    @IBOutlet var lblRouteName : UILabel!
    @IBOutlet var txtDirection: UITextView!
    
    var departureStops: Stops! = nil
    var destinationStops: Stops! = nil
    
    @IBOutlet weak var routeMapView: GMSMapView!
    var stopsMarker: GMSMarker?
    var carMarker: GMSMarker?
    
    var videoGeoPointsArr = [VideoGeoPoints]()
    var videoGeoCoordinatesArr = [CLLocation]()
    var routeRangeStopsArr = [Stops]()
    
    var directionIndex: Int! = 0
    var directionAttStr = NSMutableAttributedString()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lblRouteName.text = navigationRouteName as String?
        self.perform(#selector(setupGoogleMapView), with: nil, afterDelay: 0.4)
        
        //        let strOrigin: String! = String(format:"%f,%f", departureStops.lat!,departureStops.lng!)
        //        let strDestination: String! = String(format:"%f,%f", destinationStops.lat!,destinationStops.lng!)
        
        self.processGetNavigationDirection()
        self.setupCarMarker()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    // MARK: SET UP GOOGLE MAP ACCORDING USER SELECT ROUTE
    
    @objc func setupGoogleMapView()
    {
        //Set up Google Map
        
        let camera = GMSCameraPosition.camera(withLatitude: departureStops.lat! ,
                                              longitude: departureStops.lng!,
                                              zoom: 12.6)
        routeMapView.camera = camera
        routeMapView.mapType = .normal
        routeMapView.delegate = self
        
        
        for stops in routeRangeStopsArr {
            let position = CLLocationCoordinate2D(latitude: stops.lat!, longitude: stops.lng!)
            let marker = GMSMarker(position: position)
            marker.title = stops.name
            marker.iconView = UIImageView.init(image: #imageLiteral(resourceName: "map_Stop"))
            marker.tracksViewChanges = true
            marker.map = routeMapView
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
        self.findClosestDistance(lat: coordinate.latitude, lon: coordinate.longitude)
        
    }
    
    func drawRouteLine(){
        /* create the path */
        let path = GMSMutablePath()
        
        for geoPoint in videoGeoPointsArr {
            path.add(CLLocationCoordinate2D(latitude: geoPoint.lat!, longitude: geoPoint.lng!))
        }
        
        /* show what you have drawn */
        let routeLine = GMSPolyline(path: path)
        routeLine.strokeColor = UIColor.init(red: 60.0/255.0, green: 180/255.0, blue: 229.0/255.0, alpha: 1.0)
        routeLine.strokeWidth = 2.0
        routeLine.map = routeMapView
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
    
    @IBAction func onFullScreenBtn(_ sender: UIButton) {
        
        if txtDirection.isHidden {
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.navigationBar.isTranslucent = false
            
            UIView.animate(withDuration: 0.3) {
                self.txtDirection.isHidden = false
            }
        }
        else
        {
            self.navigationController?.navigationBar.isHidden = true
            self.navigationController?.navigationBar.isTranslucent = true
            UIView.animate(withDuration: 0.3) {
                self.txtDirection.isHidden = true
            }
        }
    }
    
    //MARK:- SHOW NAVIGATION DIRECTION

    
    func findClosestDistance(lat: Double, lon: Double) {
        
        if videoGeoCoordinatesArr.count == 0 {
            for geo in videoGeoPointsArr
            {
                let coordinates = CLLocation(latitude: geo.lat!, longitude: geo.lng!)
                videoGeoCoordinatesArr.append(coordinates)
            }
        }
        
        let userLocation = CLLocation(latitude: lat, longitude: lon)
        let closest = videoGeoCoordinatesArr.min(by:{ $0.distance(from: userLocation) < $1.distance(from: userLocation) }) as CLLocation?
        
        carMarker?.position = CLLocationCoordinate2D(latitude: (closest?.coordinate.latitude)!, longitude: (closest?.coordinate.longitude)!)
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
    
    
    func processGetNavigationDirection() {
        
        if directionIndex < (routeRangeStopsArr.count-1) {
            
            let thisStops = routeRangeStopsArr[directionIndex]
            let nextStops = routeRangeStopsArr[directionIndex+1]
            directionIndex = directionIndex + 1
            self.getDirectionData(startStops: thisStops, endStops: nextStops)
        }
    }
    
    
    func getDirectionData(startStops: Stops, endStops: Stops) -> String {
        
        let thisLat:String = String(format:"%f", startStops.lat!)
        let thisLng: String = String(format:"%f",startStops.lng!)
        let thisLatLng = thisLat + "," + thisLng
        
        let nextLat:String = String(format:"%f", endStops.lat!)
        let nextLng: String = String(format:"%f",endStops.lng!)
        let nextLatLng = nextLat + "," + nextLng
        
        let strURL = "https://maps.googleapis.com/maps/api/directions/json?origin=" + thisLatLng + "&destination=" + nextLatLng + "&key=\(API_KEY.GetPOI)"
        
        print("str URL ===\(strURL)")
        
        Alamofire.request(strURL,method: .get, parameters: nil, encoding: URLEncoding.default, headers:nil) .responseJSON { response in
            
            if let json = response.result.value
            {
                //  print(json)
                let directionDict = json as! NSDictionary
                
                let routes = directionDict.value(forKey: "routes") as! NSArray
                
                DispatchQueue.main.async {
                    
                    if routes.count > 0 {
                        
                        let arr = routes.value(forKeyPath: "legs.steps") as! NSArray
                        let steps = (arr.firstObject as! NSArray).firstObject as! NSArray
                        let directionArr = steps.value(forKey: "html_instructions") as! NSArray
                        print("Direction ===> \(directionArr)")
                        
                        
                        var directionStr = directionArr.componentsJoined(by: "<br><br>")
                        
                        //Remove Extra html style
                        directionStr = directionStr.replacingOccurrences(of: "<div style=\"font-size:0.9em\">", with: "<br><br>")
                        directionStr = directionStr.replacingOccurrences(of: "</div>", with: "")
                        directionStr = directionStr.replacingOccurrences(of: "Destination will be on the right", with: "") // Remove Destination Text
                        directionStr = directionStr.replacingOccurrences(of: "Destination will be on the left", with: "")
                        

                        
                        // ADD STOPS NAME
                        let stopsName = startStops.name! + " - " + endStops.name! + "\n\n"
                        
                        let stopsAttributes = [ NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15.0, weight: .regular) ]
                        let att = NSAttributedString(string: stopsName, attributes: stopsAttributes)

                        self.directionAttStr.append(att)
                        
                       // let attr = try? NSAttributedString(htmlString: directionStr, font: UIFont.systemFont(ofSize: 12.0, weight: .regular), useDocumentFontSize: false)

                        let attribute = directionStr.htmlAttributed(using: UIFont.systemFont(ofSize: 13.0))
                        self.directionAttStr.append(attribute!)
                        
                        self.txtDirection.attributedText = self.directionAttStr
                        
                        self.processGetNavigationDirection()
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
                self.processGetNavigationDirection()
            }
        }
        return ""
    }
    
}



