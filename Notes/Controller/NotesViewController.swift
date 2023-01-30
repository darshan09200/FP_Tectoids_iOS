//
//  NotesViewController.swift
//  Notes
//
//  Created by PAVIT KALRA on 2023-01-23.
//

import UIKit

enum Interval: String{
	case today = "Today"
	case yesterday = "Yesterday"
	case previous7 = "Previous 7 Days"
	case previous30 = "Previous 30 Days"
}

struct GroupedNotes{
	var headerText: String
	var date: Date
	var children = [Note]()
}

struct GroupedTaskList{
	var headerText: String
	var date: Date
	var children = [TaskList]()
}

enum SortNotes: Int, CaseIterable{
	case title
	case date
}

class NotesViewController: UIViewController {
	
	@IBOutlet weak var segmentControl: UISegmentedControl!
	private let searchController = UISearchController()
	static let identifier = "NotesVC"
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var countLbl: UILabel!
	
	@IBOutlet weak var sortMenu: UIBarButtonItem!
	
	var selectedFolder: Folder?
	private var notes = [GroupedNotes]()
	private var filteredNotes: [Note] = []

	private var taskList = [GroupedTaskList]()
	private var filteredTaskList: [TaskList] = []
	
	private var isFiltering: Bool {
		return !(searchController.searchBar.text?.isEmpty ?? true)
	}
	
	lazy var titleAction = UIAction(title: "Title") { action in
		self.onSortChange(.title)
	}
	
	lazy var dateAction = UIAction(title: "Created Date") { action in
		self.onSortChange(.date)
	}
	
	lazy var menu = UIMenu(title: "", options: .singleSelection, children: [
		titleAction,
		dateAction
	])
	
	override func viewDidLoad() {
		super.viewDidLoad()
		loadData()
		
		setActionState()
		self.sortMenu.menu = menu
		
		configureSearchBar()
		
	}
	
	@IBAction func segmentValueChanged(_ sender: UISegmentedControl) {
		// Handle the value changed event here
		
		if(sender.selectedSegmentIndex == 1){
			navigationItem.title = "Tasks"
		} else {
			navigationItem.title = "Notes"
		}
		tableView.reloadData()
		
		refreshCount()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		loadData()
	}
	
	func getCurrentSort() -> SortNotes?{
		let sortValue = UserDefaults.standard.integer(forKey: "sortNotes")
		return SortNotes(rawValue: sortValue)
	}
	
	func onSortChange(_ sort: SortNotes){
		UserDefaults.standard.set(sort.rawValue, forKey: "sortNotes")
		setActionState()
		loadData()
	}
	
	func setActionState(){
		let currentSort = getCurrentSort()
		switch currentSort{
			case .title:
				titleAction.state = .on
			case .date: fallthrough
			case .none:
				dateAction.state = .on
		}
	}
	
	func getIntervals () -> [(String, Date)] {
		var intervals = [(String, Date)]()
		let currentDate = Date.now
		intervals.append((Interval.today.rawValue, currentDate))
		if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: currentDate){
			intervals.append((Interval.yesterday.rawValue, yesterday))
		}
		if let previous7 = Calendar.current.date(byAdding: .day, value: -7, to: currentDate){
			intervals.append((Interval.previous7.rawValue, previous7))
		}
		if let previous30 = Calendar.current.date(byAdding: .day, value: -30, to: currentDate){
			intervals.append((Interval.previous30.rawValue, previous30))
		}
		
		for i in stride(from: -1, to: -3, by: -1){
			if let yearDate = Calendar.current.date(byAdding: .year, value: i, to: currentDate),
			   let year = Calendar.current.dateComponents([.year], from: yearDate).year{
				intervals.append((String(year), yearDate))
			}
		}
		return intervals
	}
	
	func loadData(){
		var filterNotesPredicate: NSPredicate?
		var filterFolderPredicate: NSPredicate?
		if let selectedFolder = selectedFolder{
			filterNotesPredicate = NSPredicate(format: "parentFolder.folderId == %@", selectedFolder.folderId! as CVarArg)
			filterFolderPredicate = NSPredicate(format: "parentFolder.folderId == %@", selectedFolder.folderId! as CVarArg)
		}
		let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
		let currentSort = getCurrentSort()
		if let data = Note.getData(for: filterNotesPredicate, with: [sortDescriptor]) as? [Note]{
			var groupedData = getIntervals().map{GroupedNotes(headerText: $0.0, date: $0.1)}
			for index in groupedData.indices{
				let item = groupedData[index]
				
				groupedData[index].children = data.filter{
					if let content = $0.content, content.count == 0 { return false }
					if item.headerText == Interval.today.rawValue ||
						item.headerText == Interval.yesterday.rawValue{
						return Calendar.current.isDate($0.updatedAt!, inSameDayAs: item.date)
					} else {
						let compareResult = Calendar.current.compare($0.updatedAt!, to: item.date, toGranularity: .day)
						return compareResult == .orderedAscending || compareResult == .orderedSame
					}
				}
				
				groupedData[index].children = groupedData[index].children.sorted{
					if currentSort == .title {
						return (NSAttributedString.loadFromHtml(
							content: $0.content ?? "")?.getLine()?.string.condenseWhitespace() ?? "") <
								(NSAttributedString.loadFromHtml(
									content: $1.content ?? "")?.getLine()?.string.condenseWhitespace() ?? "")
					} else {
						return $0.updatedAt! > $1.updatedAt!
					}
				}
			}
			self.notes = groupedData.filter{$0.children.count > 0}
		}
		if let data = TaskList.getData(for: filterFolderPredicate, with: [sortDescriptor]) as? [TaskList]{
			var groupedData = getIntervals().map{GroupedTaskList(headerText: $0.0, date: $0.1)}
			for index in groupedData.indices{
				let item = groupedData[index]
				
				groupedData[index].children = data.filter{
					if let tasks = $0.tasks, tasks.count == 0 { return false }
					if item.headerText == Interval.today.rawValue ||
						item.headerText == Interval.yesterday.rawValue{
						return Calendar.current.isDate($0.updatedAt!, inSameDayAs: item.date)
					} else{
						let compareResult = Calendar.current.compare($0.updatedAt!, to: item.date, toGranularity: .day)
						return compareResult == .orderedAscending || compareResult == .orderedSame
					}
				}
				
				groupedData[index].children = groupedData[index].children.sorted{
					if currentSort == .title {
						return (($0.title ?? "") < ($1.title ?? ""))
					} else {
						return $0.updatedAt! > $1.updatedAt!
					}
				}
			}
			self.taskList = groupedData.filter{$0.children.count > 0}
		}
		refreshCount()
		if isFiltering{
			search(searchController.searchBar.text ?? "")
		}
		tableView.reloadData()
	}
	
	func refreshCount(){
		if segmentControl.selectedSegmentIndex == 0 {
			if isFiltering{
				countLbl.text = "\(filteredNotes.count) Notes"
			} else {
				countLbl.text = "\(notes.map{$0.children.count}.reduce(0, +)) Notes"
			}
		} else {
			if isFiltering{
				countLbl.text = "\(filteredTaskList.count) Tasks"
			} else {
				countLbl.text = "\(taskList.map{$0.children.count}.reduce(0, +)) Tasks"
			}
		}
	}
	
	@IBAction func addButton(_ sender: Any) {
		addButtonClick()
	}
	
	func addButtonClick(){
		switch segmentControl.selectedSegmentIndex {
			case 0:
				let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "NoteViewController") as! NoteViewController
				controller.parentFolder = self.selectedFolder
				self.navigationController?.pushViewController(controller, animated: true)
				break
			case 1:
				self.showTaskListNameAlert()
				break
			default:
				break
		}
	}
	
	func showTaskListNameAlert(for indexPath: IndexPath? = nil){
		let alert = UIAlertController(
			title: indexPath == nil ? "Add New Task List": "Rename Task List",
			message: "", preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
		cancelAction.setValue(UIColor.systemRed, forKey: "titleTextColor")
		alert.addAction(cancelAction)
		
		let saveAction = UIAlertAction(
			title: indexPath == nil ? "Add" :"Save",
			style: .default, handler: {
				(alertAction: UIAlertAction!) in
				let textField = alert.textFields![0] // Force unwrapping because we know it exists.
				let taskList: TaskList
				if let indexPath = indexPath{
					taskList = self.taskList[indexPath.section].children[indexPath.row]
				} else{
					taskList = TaskList()
					taskList.listId = UUID()
					taskList.parentFolder = self.selectedFolder
				}
				taskList.title = textField.text!
				taskList.updatedAt = Date.now
				Database.getInstance().saveData()
				self.loadData()
				if indexPath == nil{
					let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "TaskViewController") as! TaskViewController
					controller.currentTaskList = taskList
					self.navigationController?.pushViewController(controller, animated: true)
				}
			})
		
		alert.addTextField { (textField) in
			textField.autocapitalizationType = .words
			textField.placeholder = "Task List Name"
			if let indexPath = indexPath{
				textField.text = self.taskList[indexPath.section].children[indexPath.row].title
			}
			textField.addObserver(for: saveAction)
		}
		alert.addAction(saveAction)
		self.present(alert, animated: true, completion: nil)
	}
	
	private func configureSearchBar() {
		navigationItem.searchController = searchController
		searchController.obscuresBackgroundDuringPresentation = false
		searchController.searchBar.delegate = self
		searchController.delegate = self
		definesPresentationContext = true
	}
	
	@IBAction func createNewNoteClicked(_ sender: UIButton) {
		
	}
	
}

extension NotesViewController: UISearchControllerDelegate, UISearchBarDelegate {
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		search(searchText)
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		searchBar.text = ""
		tableView.reloadData()
	}
	
	func indexOf(note: Note, for searchText: String = "") -> Int{
		let query: String
		if !searchText.isEmpty{
			query = searchText
		} else {
			query = searchController.searchBar.text ?? ""
		}
		if let content = note.content{
			let searchString = NSAttributedString.loadFromHtml(content: content)?.string.condenseWhitespace().lowercased()
			if let searchString = searchString,
			   let range = searchString.range(of: query.lowercased()){
				return searchString.distance(from: searchString.startIndex, to: range.lowerBound)
			}
		}
		return -1
	}
	
	func indexOf(taskList: TaskList, for searchText: String = "") -> Int{
		let query: String
		if !searchText.isEmpty{
			query = searchText
		} else {
			query = searchController.searchBar.text ?? ""
		}
		if let title = taskList.title,
		   let range = title.lowercased().range(of: query.lowercased()){
			return title.distance(from: title.startIndex, to: range.lowerBound)
		} else if let tasks = taskList.tasks as? Set<Task>{
			let searchString = tasks.map{"\($0.title ?? "") \(NSAttributedString.loadFromHtml(content: $0.content ?? "")?.string ?? "")"}
				.joined(separator: " ").condenseWhitespace()
			if let range = searchString.lowercased().range(of: query.lowercased()){
				return searchString.distance(from: searchString.startIndex, to: range.lowerBound)
			}
		}
		return -1
	}
	
	func search(_ query: String) {
		var filteredNotes = [Note]()
		notes.forEach {
			item in
			item.children.forEach{ note in
				if indexOf(note: note, for: query) > -1{
					filteredNotes.append(note)
				}
			}
		}
		self.filteredNotes = filteredNotes
		
		var filteredTaskList = [TaskList]()
		taskList.forEach {
			item in
			item.children.forEach{ childTask in
				if indexOf(taskList: childTask, for: query) > -1{
					filteredTaskList.append(childTask)
				}
			}
		}
		self.filteredTaskList = filteredTaskList
		
		
		refreshCount()
		tableView.reloadData()
	}
}

extension NotesViewController: UITableViewDelegate, UITableViewDataSource{
	func numberOfSections(in tableView: UITableView) -> Int {
		if isFiltering{
			return 1
		} else if segmentControl.selectedSegmentIndex == 0 {
			return notes.count
		} else {
			return taskList.count
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if segmentControl.selectedSegmentIndex == 0 {
			if isFiltering{
				return filteredNotes.count
			} else {
				return notes[section].children.count
			}
		} else {
			if isFiltering{
				return filteredTaskList.count
			} else {
				return taskList[section].children.count
			}
		}
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if isFiltering{
			return "Search Results"
		} else if segmentControl.selectedSegmentIndex == 0 {
			return notes[section].headerText
		} else {
			return taskList[section].headerText
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "note", for: indexPath) as! NotesTableViewCell
		if segmentControl.selectedSegmentIndex == 0{
			var note = notes[indexPath.section].children[indexPath.row]
			if isFiltering{
				note = filteredNotes[indexPath.row]
			}
			if let content = note.content{
				let searchString = NSAttributedString.loadFromHtml(content: content)
				if let searchString = searchString{
					let subtitle = NSMutableAttributedString(string: note.updatedAt?.format() ?? "")
					let attributes: [NSAttributedString.Key: Any] = [
						.foregroundColor: UIColor.secondaryLabel,
						.font: UIFont.preferredFont(forTextStyle: .caption1)
					]
					let currentLine = searchString.getLineRange()
					if currentLine.location > -1 && currentLine.length > 1{
						let title = searchString.attributedSubstring(from: currentLine).string
						cell.noteTitle?.text = title
						
						let remainingText: NSMutableAttributedString
						let nextStart = currentLine.location + currentLine.length
						if searchString.length - nextStart > -1 {
							let remainingString = searchString.attributedSubstring(
								from: NSRange(location: nextStart, length: searchString.length - nextStart)).string.condenseWhitespace()
							print(remainingString)
							
							remainingText = NSMutableAttributedString(string: "  \(remainingString)", attributes: attributes)
						} else {
							remainingText = NSMutableAttributedString(string: "  No additional text", attributes: attributes)
						}
						subtitle.append(remainingText)
					} else {
						cell.noteTitle.text = "New Note"
						if let count = note.extras?.attachments.count, count > 0{
							subtitle.append(NSMutableAttributedString(string: "  \(count) Attachments", attributes: attributes))
						}
					}
					cell.noteDate.attributedText = subtitle
				}
			}
			if let extras = note.extras, let firstImage = extras.attachments.first(where: {$0.type == .image}), let image = AttachmentImage.load(fileURL: firstImage.path){
				cell.noteImage.isHidden = false
				cell.noteImage.image = image
			} else {
				cell.noteImage.isHidden = true
			}
		} else{
			var task = taskList[indexPath.section].children[indexPath.row]
			if isFiltering{
				task = filteredTaskList[indexPath.row]
			}
			cell.noteTitle?.text = task.title
			cell.noteDate.text = task.updatedAt?.format()			
		}
		return cell
	}
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		if segmentControl.selectedSegmentIndex == 0{
			let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "NoteViewController") as! NoteViewController
			var note = notes[indexPath.section].children[indexPath.row]
			if isFiltering{
				note = filteredNotes[indexPath.row]
			}
			controller.parentFolder = selectedFolder
			controller.note = note
			navigationController?.pushViewController(controller, animated: true)
		}else{
			var task = taskList[indexPath.section].children[indexPath.row]
			if isFiltering {
				task = filteredTaskList[indexPath.row]
			}
			let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "TaskViewController") as! TaskViewController
			controller.currentTaskList = task
			self.navigationController?.pushViewController(controller, animated: true)
		}
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		
		var actions = [UIContextualAction]()
		let editAction = UIContextualAction(style: .normal, title: "Edit Task List"){
			(_, _, completion) in
			self.showTaskListNameAlert(for: indexPath)
			completion(true)
		}
		editAction.image = UIImage(systemName: "square.and.pencil")?.withTintColor(.orange)
		editAction.backgroundColor = .orange
		
		let moveToCategory = UIContextualAction(style: .normal, title: "Move to Folder") { (action, view, completion) in
			let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MoveFolderViewController") as! MoveFolderViewController
			if self.segmentControl.selectedSegmentIndex == 0 {
				controller.selectedNote = self.notes[indexPath.section].children[indexPath.row]
				if self.isFiltering{
					controller.selectedNote = self.filteredNotes[indexPath.row]
				}
			} else {
				controller.selectedTask = self.taskList[indexPath.section].children[indexPath.row]
				if self.isFiltering {
					controller.selectedTask = self.filteredTaskList[indexPath.row]
				}
			}
			controller.success = {
				self.loadData()
			}
			self.present(UINavigationController(rootViewController: controller), animated: true)
			completion(true)
		}
		moveToCategory.backgroundColor = .systemBlue
		moveToCategory.image = UIImage(systemName: "folder")
		
		let delete = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completion) in
			if self.segmentControl.selectedSegmentIndex == 0 {
				var note = self.notes[indexPath.section].children[indexPath.row]
				if self.isFiltering{
					note = self.filteredNotes[indexPath.row]
				}
				Note.context.delete(note)
			}else{
				var task = self.taskList[indexPath.section].children[indexPath.row]
				if self.isFiltering{
					task = self.filteredTaskList[indexPath.row]
				}
				TaskList.context.delete(task)
			}
			completion(true)
			Database.getInstance().saveData()
			self.loadData()
		}
		delete.image = UIImage(systemName: "trash")
		actions.append(delete)
		if Database.getInstance().folders.count > 1{
			actions.append(moveToCategory)
		}
		if segmentControl.selectedSegmentIndex == 1{
			actions.append(editAction)
		}
		let swipeActions = UISwipeActionsConfiguration(actions: actions)
		return swipeActions
	}
}
