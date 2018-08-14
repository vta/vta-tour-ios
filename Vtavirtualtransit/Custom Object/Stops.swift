//
//  Stops.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 27/05/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit
import CoreLocation

class Stops: NSObject {

    var code: String?
    var lat: Double?
    var lng: Double?
    var name: String?
    var route_list: String?
    var sec: Int?
    var stop_code: String?
    var location: CLLocation?
    
    init(code: String?, lat: Double?, lng: Double?, name: String?, route_list: String?, sec: Int?, stop_code: String?)
    {
        self.code = code ?? ""
        self.lat = lat      
        self.lng = lng
        self.name = name    ?? ""
        self.route_list = route_list    ?? ""
        self.sec = sec
        self.stop_code = stop_code ?? ""
        self.location = CLLocation(latitude: lat!, longitude: lng!)
    }
}
