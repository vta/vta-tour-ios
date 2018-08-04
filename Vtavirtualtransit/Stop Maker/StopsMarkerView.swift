//
//  StopsMarkerView.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 06/07/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit

protocol StopsMarkerDelegate: class {
    func dismissStopsMarkerView()
}

class StopsMarkerView: UIView {
    
    @IBOutlet weak var snippet: UILabel!
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var btnClose: UIButton!
    
    weak var delegate: StopsMarkerDelegate?
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "StopsMarkerView", bundle: nil).instantiate(withOwner: self, options: nil).first as! UIView
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: x, height: y)
    }
    
    @IBAction func onCloseBtn() {
        self.delegate?.dismissStopsMarkerView()
    }
    
}
