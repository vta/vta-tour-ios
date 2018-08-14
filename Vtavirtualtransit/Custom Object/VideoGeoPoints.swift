//
//  VideoGeoPoints.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 05/06/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit

class VideoGeoPoints: NSObject {
    var lat: Double?
    var lng: Double?
    
    init(lat: Double?, lng: Double?)
    {
        self.lat = lat
        self.lng = lng
    }
}
