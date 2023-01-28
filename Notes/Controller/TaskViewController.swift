//
//  TaskViewController.swift
//  Text Editor
//
//  Created by Darshan Jain on 2023-01-22.
//

import UIKit
import UserNotifications

class TaskViewController: UIViewController {
	
	@IBOutlet weak var tableView: UITableView!
	
	var currentTask: Tasks?
	var tasks = [Tasks]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
//		if currentTask == nil {
//			currentTask = Tasks()
//
//			currentTask?.taskId = UUID()
//			currentTask?.title = "Test"
//			currentTask?.updatedAt = Date.now
//		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		reloadData()
	}
	
	func reloadData(){
		if let currentTask = currentTask{
			tasks = Database.getInstance().tasks.filter{ task in
				if let taskId = task.taskId{
					return taskId.uuidString == currentTask.taskId!.uuidString
				}
				return false
			}
		} else{
			tasks = Database.getInstance().tasks
		}
		print(tasks)
		tableView.reloadData()
	}
	
	
	@objc func keyboardWillShow(notification: NSNotification) {
		guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
		else {
			// if keyboard size is not available for some reason, dont do anything
			return
		}
		
		let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height , right: 0.0)
		tableView.contentInset = contentInsets
		tableView.scrollIndicatorInsets = contentInsets
	}
	
	@objc func keyboardWillHide(notification: NSNotification) {
		let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
		
		
		// reset back the content inset to zero after keyboard is gone
		tableView.contentInset = contentInsets
		tableView.scrollIndicatorInsets = contentInsets
	}
	@IBAction func addNewTask(_ sender: Any) {
		let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddTask") as! AddTaskViewController
		controller.parentTask = currentTask
		controller.reloadData = self.reloadData
		self.present(controller, animated: true)
	}
}

extension TaskViewController: UITextViewDelegate{
	func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
		var additionalActions: [UIMenuElement] = []
		if range.length > 0 {
			let highlightAction = UIAction(title: "Highlight", image: UIImage(systemName: "highlighter")) { action in
				// The highlight action.
			}
			additionalActions.append(highlightAction)
		}
		let addBookmarkAction = UIAction(title: "Add Bookmark", image: UIImage(systemName: "bookmark")) { action in
			// The bookmark action.
		}
		additionalActions.append(addBookmarkAction)
		return UIMenu(children:  suggestedActions+additionalActions)
	}
}

extension TaskViewController: UITableViewDelegate, UITableViewDataSource{
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tasks.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "task", for: indexPath) as! TaskCell
		let task = tasks[indexPath.row]
		cell.delegate = self
		cell.textView.text = task.title
		cell.id = task.taskId?.uuidString
		cell.isChecked = task.isCompleted
		cell.indentationLevel = task.parentTask != nil ? 1 : 0
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		print("called this")
		let task = tasks[indexPath.row]
		let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddTask") as! AddTaskViewController
		controller.currentTask = task
		controller.parentTask = currentTask
		controller.reloadData = self.reloadData
		self.present(controller, animated: true)
	}
	
	func getTaskData(taskId: String)->(Tasks?, Int){
		for (index, task) in tasks.enumerated(){
			if task.taskId?.uuidString == taskId{
				return (task, index)
			}
		}
		return (nil, -1)
	}
	
}


extension TaskViewController: TaskDelegate{
	
	func reloadTable(){
		self.reloadData()
	}
	
	func toggleChecked(cell: TaskCell) {
		let (task, index) = getTaskData(taskId: cell.id!)
		if let task = task, tasks.indices.contains(index){
			if task.isCompleted{
				let alert = UIAlertController(title: "Oops", message: "Task is already completed", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
				self.present(alert, animated: true, completion: nil)
			}else{
				let nextIndex = index + 1
				var canCheck = true
				if nextIndex < tasks.endIndex{
					for i in nextIndex...tasks.endIndex-1{
						let childTask = tasks[i]
						if childTask.parentTask!.uuidString == task.taskId!.uuidString{
							canCheck = canCheck && childTask.isCompleted
						}
						if !canCheck{
							break
						}
					}
				}
				if !canCheck{
					let alert = UIAlertController(title: "Oops", message: "Some child tasks are still pending. Complete them first", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
					self.present(alert, animated: true, completion: nil)
				} else {
					task.isCompleted = true
				}
				Database.getInstance().saveData()
				tableView.reloadData()
			}
		}
	}
	
	func convertToChild(cell: TaskCell) {
		let (task, index) = getTaskData(taskId: cell.id!)
		print(index)
		if tasks.indices.contains(index){
			if tasks.indices.contains(index - 1){
				let previousTask = tasks[index - 1]
				task?.parentTask = previousTask.taskId
				Database.getInstance().saveData()
				tableView.reloadData()
			} else {
				print("No parent available")
			}
		}
	}
	
	func convertToParent(cell: TaskCell) {
		let (task, index) = getTaskData(taskId: cell.id!)
		if let task = task, tasks.indices.contains(index){
			var nextSiblingTasks = [Tasks]()
			let nextIndex = index + 1
			if nextIndex < tasks.endIndex{
				for i in nextIndex...tasks.endIndex{
					let siblingTask = tasks[i]
					if siblingTask.taskId!.uuidString == task.taskId!.uuidString{
						nextSiblingTasks.append(siblingTask)
					}else{
						break
					}
				}
			}
			task.parentTask = currentTask?.taskId
			nextSiblingTasks.forEach{siblingTask in
				siblingTask.parentTask = task.taskId
			}
			Database.getInstance().saveData()
			tableView.reloadData()
		}
	}
}
