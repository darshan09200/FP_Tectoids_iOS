//
//  NotesTableViewCell.swift
//  Notes
//
//  Created by PAVIT KALRA on 2023-01-23.
//

import UIKit

class NotesTableViewCell: UITableViewCell {

    
    @IBOutlet weak var noteTitle: UILabel!
    @IBOutlet weak var noteDate: UILabel!
    
    @IBOutlet weak var noteImage: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
