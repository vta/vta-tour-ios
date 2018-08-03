//
//  CustomPOI.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 27/06/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit

class CustomPOI: NSObject {

    var address: String?
    var code: String?
    var icon: String?
    var latitude: String?
    var longitude: String?
    var name: String?
    var vicinity: String?
    var web_link: String?
    
    init(address: String?, code: String?, icon: String?, latitude: String?, longitude: String?, name: String?, vicinity: String?,web_link: String?)
    {
        self.address = address
        self.code = code
        self.icon = icon
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.vicinity = vicinity
        self.web_link = web_link
    }
    
}
