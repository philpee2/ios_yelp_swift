//
//  RadioCell.swift
//  Yelp
//
//  Created by phil_nachum on 8/9/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit

class RadioCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            accessoryType = .Checkmark
        } else {
            accessoryType = .None
        }
        // Configure the view for the selected state
    }

}
