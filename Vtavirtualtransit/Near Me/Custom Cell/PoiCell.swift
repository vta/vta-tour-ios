//
//  PoiCell.swift
//  Virtualtour
//
//  Created by Paras Navadiya on 15/07/18.
//  Copyright © 2018 Paras Navadiya. All rights reserved.
//

import UIKit


class PoiCell: UITableViewCell {
    
    @IBOutlet weak var imgVwPoi: UIImageView!
    @IBOutlet weak var lblPoiTitle: UILabel!
    @IBOutlet weak var starRate: CosmosView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
