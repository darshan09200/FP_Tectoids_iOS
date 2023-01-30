//
//  AddTaskViewController.swift
//  Notes
//
//  Created by PAVIT KALRA on 2023-01-27.
//

import UIKit
import UserNotifications

class AddTaskViewController: UIViewController {

	static let MIN_DIFFERENCE = 5
	
	@IBOutlet weak var navBar: UINavigationBar!
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var taskTitle: PaddedTextField!
	@IBOutlet weak var taskDescription: UITextView!
	@IBOutlet weak var taskDate: UIDatePicker!
	
	@IBOutlet weak var deleteTaskBtn: UIButton!
	private var hasAnythingChanged: Bool{
		if let task = currentTask, !task.title!.isEmpty{
			if task.isCompleted {
				return true
			}
			return task.title != taskTitle.text! || task.content != taskDescription.attributedText.getHtml() || task.dueDate! != taskDate.date
		}
		return false
	}
	
	private var isDueDateFuture: Bool {
		if let task = currentTask, !task.title!.isEmpty, let date = task.dueDate{
			print(date)
			return date > Date.now
		}
		return true
	}
	
	var hasAdded = false
	
	var currentTask: Task?
	
	var reloadData: () -> Void = {}
	var deleteTask: (_ task: Task?) -> Void = {_ in }
	
	override func viewDidLoad() {
        super.viewDidLoad()
        
		self.presentationController?.delegate = self
		
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
				deleteTaskBtn.isHidden = true
				navBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCloseTap))
			}else if let title = task.title{
				if title.isEmpty{
					navBar.topItem?.title = "Add Task"
					deleteTaskBtn.isHidden = true
				} else {
					navBar.topItem?.title = "Edit Task"
					deleteTaskBtn.isHidden = false
				}
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
		
		if let task = currentTask, let date = task.dueDate{
			taskDate.date = date
			taskDate.minimumDate = date
		} else {
			taskDate.minimumDate = Calendar.current.date(byAdding: .minute, value: AddTaskViewController.MIN_DIFFERENCE, to: Date.now)
		}
		
		taskTitle.becomeFirstResponder()
    }
    
	override func viewWillDisappear(_ animated: Bool) {
		if !hasAdded, let task = currentTask, task.title!.isEmpty{
			TaskList.context.delete(task)
			Database.getInstance().saveData()
			reloadData()
		}
		super.viewWillDisappear(animated)
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
		} else if let minDate = Calendar.current.date(byAdding: .minute, value: AddTaskViewController.MIN_DIFFERENCE, to: Date.now), taskDate.date < minDate {
			let alert = UIAlertController(title: "Oops", message: "Due date should be atleast \(AddTaskViewController.MIN_DIFFERENCE) minutes from current time", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
			self.present(alert, animated: true, completion: nil)
		} else {
			currentTask?.title = title
			currentTask?.content = taskDescription.attributedText.getHtml()
			currentTask?.dueDate = taskDate.date
			currentTask?.updatedAt = Date.now
			NotificationConfig.instance.setupNotification(task: currentTask!)
			Database.getInstance().saveData()
			hasAdded = true
			dismiss(animated: true)
			reloadData()
		}
	}
	
	@IBAction func onDeletePress() {
		let additionalMsg = currentTask?.parentTask == nil ? "This is a parent task. Deleting this will delete its subtask too." :""
		let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this task? \(additionalMsg)", preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: "Delete Task", style: .destructive) { _ in
			self.dismiss(animated: true){
				self.deleteTask(self.currentTask)
			}
		})
		alert.addAction(UIAlertAction(title: "Keep Task", style: .cancel))
		self.present(alert, animated: true)
				
	}
}

extension AddTaskViewController: UIAdaptivePresentationControllerDelegate {
	
	public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
		return !hasAnythingChanged && isDueDateFuture
	}
	
	public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
		var message = "Are you sure you want to discard changes"
		var actions = [UIAlertAction]()
		var style: UIAlertController.Style = .actionSheet
		if !isDueDateFuture {
			message = "Your due date has already past. Please select a future date"
			actions.append(UIAlertAction(title: "Ok", style: .cancel))
			style = .alert
		} else {
			actions.append(UIAlertAction(title: "Discard Changes", style: .destructive) { _ in
				self.dismiss(animated: true)
			})
			actions.append(UIAlertAction(title: "Keep Editing", style: .cancel))
		}
		let alert = UIAlertController(title: nil, message: message, preferredStyle: style)
		actions.forEach{alert.addAction($0)}
		self.present(alert, animated: true)
	
	}
}
