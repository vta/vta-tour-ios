//
//  AmenitiesFields.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 05/07/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit

class AmenitiesFields: NSObject {

    var enabled: Bool?
    var amenitiesKey: String?
    var amenitiesValue: String?
    
    
    init(isEnable: Bool?, key: String?, value: String?)
    {
        self.enabled = isEnable 
        self.amenitiesKey = key ?? ""
        self.amenitiesValue = value ?? ""
    }
}
