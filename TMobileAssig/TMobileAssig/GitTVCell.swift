//
//  GitTVCell.swift
//  TMobileAssig
//
//  Created by sai kumar madasu on 4/10/20.
//  Copyright © 2020 sai kumar madasu. All rights reserved.
//

import UIKit

class GitTVCell: UITableViewCell {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var userRepoCountLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userImage.layer.cornerRadius = userImage.frame.size.height/2.0
        userImage.layer.masksToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
