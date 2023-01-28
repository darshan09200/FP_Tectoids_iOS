//
//  TaskCell.swift
//  Text Editor
//
//  Created by Darshan Jain on 2023-01-17.
//

import UIKit

class TaskCell: UITableViewCell {

	override var indentationLevel: Int{
		didSet{
			leftConstraint.constant = CGFloat(indentationLevel) * indentationWidth
		}
	}
	
	@IBOutlet weak var checkButton: UIButton!
	@IBOutlet weak var textView: UITextView!
	
	@IBOutlet weak var leftConstraint: NSLayoutConstraint!

	var delegate: TaskDelegate?
	var firstLayout = true
	
	var isChecked = false
	var id: String?
	
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		textView.font = .preferredFont(forTextStyle: .body)
		
		let swipeRightRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(didRecognizeSwipe))
		swipeRightRecognizer.numberOfTouchesRequired = 1
		swipeRightRecognizer.direction = .right
		addGestureRecognizer(swipeRightRecognizer)
		
		let swipeLeftRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(didRecognizeSwipe))
		swipeLeftRecognizer.numberOfTouchesRequired = 1
		swipeLeftRecognizer.direction = .left
		addGestureRecognizer(swipeLeftRecognizer)
    }
	
	func refreshImages(){
		if isChecked{
			checkButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
		}else{
			checkButton.setImage(UIImage(systemName: "circle"), for: .normal)
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		refreshImages()
	}
	
	@IBAction func toggleChecked() {
		delegate?.toggleChecked(cell: self)
	}
	
	@objc func didRecognizeSwipe(recognizer: UISwipeGestureRecognizer){
		if recognizer.state == .ended{
			if recognizer.direction == .right{
				delegate?.convertToChild(cell: self)
			} else{
				delegate?.convertToParent(cell: self)
			}
		}
	}

}

protocol TaskDelegate{
	func convertToParent(cell: TaskCell)
	func convertToChild(cell: TaskCell)
	func toggleChecked(cell: TaskCell)
}
