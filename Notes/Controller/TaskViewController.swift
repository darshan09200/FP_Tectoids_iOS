//
//  TaskViewController.swift
//  Text Editor
//
//  Created by Darshan Jain on 2023-01-22.
//

import UIKit
import UserNotifications

struct GroupedTasks{
	var header: Task
	var children = [Task]()
}

class TaskViewController: UIViewController {
	
	@IBOutlet weak var tableView: UITableView!
	
	var currentTaskList: TaskList?
	var tasks = [GroupedTasks]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let taskList = currentTaskList{
			navigationItem.title = taskList.title
		}
		
		tableView.setEditing(true, animated: true)
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		reloadData()
		
		if tasks.count == 0 {
			navigateToNewTask()
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if tasks.count == 0, let currentTaskList = currentTaskList{
			TaskList.context.delete(currentTaskList)
			Database.getInstance().saveData()
		}
	}
	
	func refreshData(){
		var newTasks = [GroupedTasks]()
		if let currentTaskList = currentTaskList{
			let normalTasks = Database.getInstance().tasks.filter{ task in
				if let list = task.list{
					return list.listId == currentTaskList.listId
				}
				return false
			}
			
			let parentTasks = normalTasks.filter{$0.parentTask == nil}
			let childTasks = normalTasks.filter{!parentTasks.contains($0)}
			parentTasks.forEach{task in
				newTasks.append(GroupedTasks(header: task))
			}
			
			childTasks.forEach{task in
				if let parentTaskId = task.parentTask,
				   let index = newTasks.firstIndex(where: {$0.header.taskId == parentTaskId}){
					newTasks[index].children.append(task)
				}
			}
			newTasks = newTasks.sorted{$0.header.rowNo < $1.header.rowNo}
			for index in newTasks.indices{
				newTasks[index].children = newTasks[index].children.sorted{$0.rowNo < $1.rowNo}
			}
		}
		self.tasks = newTasks
	}
	
	func reloadData(){
		refreshData()
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
	
	func navigateToNewTask(){
		let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddTask") as! AddTaskViewController
		let task = Task()
		task.taskId = UUID()
		task.title = ""
		task.list = currentTaskList
		task.updatedAt = Date.now
		task.rowNo = Int32(tasks.count)
		controller.currentTask = task
		controller.reloadData = self.reloadData
		self.present(controller, animated: true)
	}
	
	@IBAction func addNewTask(_ sender: Any) {
		navigateToNewTask()
	}
	
	func getTaskData(taskId: String)->IndexPath{
		for (index, task) in tasks.enumerated(){
			let header = task.header
			let children = task.children
			if header.taskId?.uuidString == taskId{
				return IndexPath(row: -1, section: index)
			} else if children.count>0{
				for (childIndex, childTask) in children.enumerated(){
					if childTask.taskId?.uuidString == taskId{
						return IndexPath(row: childIndex, section: index)
					}
				}
			}
		}
		return IndexPath(row: -1, section: -1)
	}
	
	func refreshCheckedStatusFor(section index: Int, shouldReload: Bool = false){
		let groupTask = tasks[index]
		if groupTask.header.isCompleted{
			var areAllCompleted = true
			
			groupTask.children.forEach{areAllCompleted = areAllCompleted && $0.isCompleted}
			
			if !areAllCompleted{
				groupTask.header.isCompleted = false
				Database.getInstance().saveData()
			}
		}
		reloadData()
	}
}

extension TaskViewController: UITableViewDelegate, UITableViewDataSource{
	
	func cell(for task: Task, rowAt indexPath: IndexPath? = nil, sectionAt section: Int = -1)->UITableViewCell{
		let cell: TaskCell
		if let indexPath = indexPath{
			cell = tableView.dequeueReusableCell(withIdentifier: "task", for: indexPath) as! TaskCell
		} else  {
			cell = tableView.dequeueReusableCell(withIdentifier: "header") as! TaskCell
			let tapRecognizer = HeaderTapGestureRecognizer(target: self, action: #selector(onHeaderTap))
			tapRecognizer.indexPath = IndexPath(row: -1, section: section)
			cell.addGestureRecognizer(tapRecognizer)
		}
		cell.delegate = self
		cell.textView.text = task.title
		cell.id = task.taskId?.uuidString
		cell.isCompleted = task.isCompleted
		cell.indentationLevel = task.parentTask != nil ? 1 : 0
		return cell
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .none
	}
	
	func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return tasks.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tasks[section].children.count
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let task = tasks[section].header
		return cell(for: task, sectionAt: section)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let task = tasks[indexPath.section].children[indexPath.row]
		return cell(for: task, rowAt: indexPath)
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let task: Task
		if indexPath.row > -1{
			tableView.deselectRow(at: indexPath, animated: true)
			task = tasks[indexPath.section].children[indexPath.row]
		} else{
			task = tasks[indexPath.section].header
		}
		let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddTask") as! AddTaskViewController
		controller.currentTask = task
		controller.reloadData = self.reloadData
		self.present(controller, animated: true)
	}
	
	@objc func onHeaderTap(_ sender: HeaderTapGestureRecognizer){
		if let indexPath = sender.indexPath{
			tableView(tableView, didSelectRowAt: indexPath)
		}
	}
		
	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		var sourceGroupTask = tasks[sourceIndexPath.section]
		let removedElement = sourceGroupTask.children.remove(at: sourceIndexPath.row)

		var destinationGroupTask = tasks[destinationIndexPath.section]
		if destinationIndexPath.section == sourceIndexPath.section{
			destinationGroupTask = sourceGroupTask
		}
		removedElement.parentTask = destinationGroupTask.header.taskId
		removedElement.rowNo = Int32(destinationIndexPath.row)
		destinationGroupTask.children.insert(removedElement, at: destinationIndexPath.row)
		
		for (index, task) in destinationGroupTask.children.enumerated(){
			task.rowNo = Int32(index)
		}
		if sourceIndexPath.section != destinationIndexPath.section{
			for (index, task) in sourceGroupTask.children.enumerated(){
				task.rowNo = Int32(index)
			}
		}
		Database.getInstance().saveData()
		refreshData()
		refreshCheckedStatusFor(section: destinationIndexPath.section)
	}
	
}


extension TaskViewController: TaskDelegate{
	
	func showAlert(_ message: String, actions: [UIAlertAction]? = nil){
		let alert = UIAlertController(title: "Oops", message: message, preferredStyle: .alert)
		if let actions = actions{
			actions.forEach{alert.addAction($0)}
		} else{
			alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
		}
		self.present(alert, animated: true, completion: nil)
	}
	
	func reloadTable(){
		self.reloadData()
	}
	
	func toggleChecked(cell: TaskCell) {
		let indexPath = getTaskData(taskId: cell.id!)
		if indexPath.section > -1 {
			let groupTask = tasks[indexPath.section]
			if indexPath.row > -1 {
				groupTask.children[indexPath.row].isCompleted = !groupTask.children[indexPath.row].isCompleted
			} else {
				if groupTask.header.isCompleted {
					let actions = [
						UIAlertAction(title: "No", style: .destructive),
						UIAlertAction(title: "Yes", style: .default){_ in
							groupTask.header.isCompleted = false
							Database.getInstance().saveData()
							self.reloadData()
							self.reloadData()
						}
					]
					showAlert("Are you sure you want to mark this is pending as all the sub tasks are completed?", actions: actions)
					return
				} else{
					var canCheck = true
					groupTask.children.forEach{canCheck = canCheck && $0.isCompleted}
					if canCheck{
						groupTask.header.isCompleted = true
					} else{
						showAlert("Some child tasks are still pending. Complete them first")
					}
				}
			}
			Database.getInstance().saveData()
			self.reloadData()
		}
	}
	
	func convertToChild(cell: TaskCell) {
		let indexPath = getTaskData(taskId: cell.id!)
		if indexPath.row > -1 || (indexPath.section > -1 && indexPath.section < 1){
			let message = indexPath.row > -1
							? "Task already a subtask"
							: "No task available to make it subtask"
			showAlert(message)
		} else if indexPath.section > -1 {
			let groupTask = tasks[indexPath.section]
			let prevGroupTask = tasks[indexPath.section - 1]
			groupTask.header.parentTask = prevGroupTask.header.taskId
			groupTask.header.rowNo = Int32(prevGroupTask.children.count)
			var rowNo = groupTask.header.rowNo + 1
			groupTask.children.forEach{
				$0.parentTask = prevGroupTask.header.taskId
				$0.rowNo = rowNo
				rowNo += 1
			}
			Database.getInstance().saveData()
			refreshData()
			refreshCheckedStatusFor(section: indexPath.section - 1, shouldReload: true)
		}
	}
	
	func convertToParent(cell: TaskCell) {
		let indexPath = getTaskData(taskId: cell.id!)
		if indexPath.section > -1 && indexPath.row == -1 {
			let message = "Task already a parent task"
			showAlert(message)
		} else if indexPath.section > -1{
			let groupTask = tasks[indexPath.section]
			let newParentTask = groupTask.children[indexPath.row]
			newParentTask.parentTask = nil
			if indexPath.row+1 < groupTask.children.count{
				var rowNo = Int32(0)
				groupTask.children[(indexPath.row+1)...].forEach{
					$0.parentTask = newParentTask.taskId
					$0.rowNo = rowNo
					rowNo += 1
				}
			}
			Database.getInstance().saveData()
			refreshData()
			refreshCheckedStatusFor(section: indexPath.section, shouldReload: true)
		}
	}
}

class HeaderTapGestureRecognizer: UITapGestureRecognizer{
	var indexPath: IndexPath?
}
