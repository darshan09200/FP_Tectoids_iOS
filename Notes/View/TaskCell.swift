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
			if indentationLevel > 0 {
				titleLabel.font = .preferredFont(forTextStyle: .title3)
			} else {
				titleLabel.font = .preferredFont(forTextStyle: .title2)
			}
		}
	}
	
	@IBOutlet weak var checkButton: UIButton!
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var leftConstraint: NSLayoutConstraint!

	@IBOutlet weak var moveUp: UIButton?
	@IBOutlet weak var moveDown: UIButton?
	
	var delegate: TaskDelegate?
	var firstLayout = true
	
	var isCompleted = false
	var id: String?
	
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		
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
		if isCompleted{
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

	@IBAction func onMoveUpPress() {
		delegate?.moveUp(cell: self)
	}
	
	@IBAction func onMoveDownPress() {
		delegate?.moveDown(cell: self)
	}
	
}

protocol TaskDelegate{
	func moveUp(cell: TaskCell)
	func moveDown(cell: TaskCell)
	func convertToParent(cell: TaskCell)
	func convertToChild(cell: TaskCell)
	func toggleChecked(cell: TaskCell)
}
