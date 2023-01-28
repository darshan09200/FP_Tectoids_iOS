//
//  AddTaskViewController.swift
//  Notes
//
//  Created by PAVIT KALRA on 2023-01-27.
//

import UIKit

class AddTaskViewController: UIViewController {

	@IBOutlet weak var navBar: UINavigationBar!
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var taskTitle: PaddedTextField!
	@IBOutlet weak var taskDescription: UITextView!
	@IBOutlet weak var taskDate: UIDatePicker!
	
	var parentTask: Tasks?
	var currentTask: Tasks?
	
	var reloadData: () -> Void = {}
	
	override func viewDidLoad() {
        super.viewDidLoad()
        
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
		
		if let task = currentTask{
			taskTitle.text = task.title
			if let content = task.content{
				taskDescription.attributedText = NSAttributedString.loadFromHtml(content: content)
			}
			if let date = task.dueDate{
				taskDate.date = date
			}
			if task.isCompleted{
				taskTitle.isEnabled = false
				taskDescription.isEditable = false
				taskDate.isEnabled = false
				navBar.topItem?.title = "View Task"
				
				navBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCloseTap))
			}else{
				navBar.topItem?.title = "Edit Task"
				
				
			}
		}
		
		taskTitle.textInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
		
		taskTitle.clipsToBounds = true;
		taskTitle.layer.cornerRadius = 4.0;
		taskTitle.borderStyle = .none
		
		taskDescription.font = .preferredFont(forTextStyle: .body)
		taskDescription.clipsToBounds = true;
		taskDescription.layer.cornerRadius = 4.0;
		taskDescription.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
		
		taskDate.minimumDate = Date.now
    }
    
	
	@objc func keyboardWillShow(notification: NSNotification) {
		guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
		else {
			// if keyboard size is not available for some reason, dont do anything
			return
		}
		
		let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height , right: 0.0)
		scrollView.contentInset = contentInsets
		scrollView.scrollIndicatorInsets = contentInsets
	}
	
	@objc func keyboardWillHide(notification: NSNotification) {
		let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
		
		
		// reset back the content inset to zero after keyboard is gone
		scrollView.contentInset = contentInsets
		scrollView.scrollIndicatorInsets = contentInsets
	}
	
	@objc func onCloseTap(){
		dismiss(animated: true)
	}
	
	@IBAction func onSaveClick(_ sender: Any) {
		let title = taskTitle.text?.trimmingCharacters(in: .whitespacesAndNewlines)
		if title == nil || title!.isEmpty{
			let alert = UIAlertController(title: "Oops", message: "Title cant be empty", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
			self.present(alert, animated: true, completion: nil)
		}else{
			if currentTask == nil{
				currentTask	= Tasks()
				currentTask?.taskId = UUID()
				currentTask?.parentTask = parentTask?.taskId
			}
			currentTask?.title = title
			currentTask?.content = taskDescription.attributedText.getHtml()
			currentTask?.dueDate = taskDate.date
			currentTask?.updatedAt = Date.now			
			Database.getInstance().saveData()
			reloadData()
			dismiss(animated: true)
		}
	}
	
	@IBAction func onDateChanged(_ sender: UIDatePicker) {
		print(sender.date)
	}
}
