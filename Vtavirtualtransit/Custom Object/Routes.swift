//
//  Routes.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 27/05/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit
import CoreLocation

class Routes: NSObject {

    var code: String?
    var departure: String?
    var destination: String?
    var directionAName: String?
    var directionBName: String?
    var name: String?
    var location: CLLocation?
    
    init(code: String?, departure: String?, destination: String?, directionAName: String?, directionBName: String?, name: String?, lat: Double?, lon: Double?)
    {
        self.code = code
        self.departure = departure
        self.destination = destination
        self.directionAName = directionAName?.capitalized
        self.directionBName = directionBName?.capitalized
        self.name = name
        self.location = CLLocation(latitude: lat!, longitude: lon!)
    }
}

