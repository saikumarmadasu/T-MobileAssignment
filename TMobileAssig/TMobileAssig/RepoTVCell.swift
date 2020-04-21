//
//  RepoTVCell.swift
//  TMobileAssig
//
//  Created by sai kumar madasu on 4/10/20.
//  Copyright © 2020 sai kumar madasu. All rights reserved.
//

import UIKit

class RepoTVCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var forksLabel: UILabel!
    @IBOutlet weak var starsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
