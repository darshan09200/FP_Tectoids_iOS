//
//  NotesViewController.swift
//  Notes
//
//  Created by PAVIT KALRA on 2023-01-23.
//

import UIKit

class NotesViewController: UIViewController {
	
	private let searchController = UISearchController()
	static let identifier = "NotesVC"
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var countLbl: UILabel!
	
	@IBOutlet weak var addButton: UIButton!
	let segmentControl = UISegmentedControl(items: ["Notes", "Tasks"])
	var notes = [Note]()
	var tasks = [TaskList]()
	var selectedFolder: Folder?
	//    lazy var addMenu = UIMenu(title: "", options: .displayInline, children: [
	//        UIAction(title: "Add Task",
	//               image: UIImage(systemName: "calendar.badge.plus")) { action in
	//               // Perform action
	//               },
	//        UIAction(title: "Add Note",
	//               image: UIImage(systemName: "note.text.badge.plus")) { action in
	//				   let controller = UIStoryboard(name: "Main", bundle: nil)
	//					   .instantiateViewController(identifier: "NoteViewController") as! NoteViewController
	//				   controller.parentFolder = self.selectedFolder
	//				   self.navigationController?.pushViewController(controller, animated: true)
	//               }
	//
	//    ])
	
	private var isSearchBarEmpty: Bool {
		if navigationItem.searchController != nil {
			return searchController.searchBar.text?.isEmpty ?? true
		}
		return true
	}
	private var allNotes: [Note] = [] {
		didSet {
			filteredNotes = allNotes
		}
	}
	private var filteredNotes: [Note] = []
	override func viewDidLoad() {
		super.viewDidLoad()
		loadData()
		//addButton.showsMenuAsPrimaryAction = true
		
		//ddButton.menu = addMenu
		// Do any additional setup after loading the view.
		configureSearchBar()
		tableView.sectionHeaderTopPadding = 0
		
		segmentControl.selectedSegmentIndex = 0
		segmentControl.addTarget(self, action: #selector(segmentValueChanged(_:)), for: .valueChanged)
		segmentControl.sizeToFit()
		tableView.tableHeaderView = segmentControl
		
	}
	
	@objc func segmentValueChanged(_ sender: UISegmentedControl) {
		// Handle the value changed event here
		print("Selected index: \(sender.selectedSegmentIndex)")
		
		if(sender.selectedSegmentIndex == 1){
			navigationItem.title = "Tasks"
			navigationItem.searchController = nil
		} else {
			navigationItem.searchController = searchController
			navigationItem.title = "Notes"
		}
		tableView.reloadData()
		
		refreshCount()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		allNotes = Database.getInstance().notes
		tableView.reloadData()
		loadData()
	}
	
	func loadData(){
		var filterNotesPredicate: NSPredicate?
		var filterFolderPredicate: NSPredicate?
		if let selectedFolder = selectedFolder{
			filterNotesPredicate = NSPredicate(format: "parentFolder.name == %@", selectedFolder.name!)
			filterFolderPredicate = NSPredicate(format: "parentFolder.name == %@", selectedFolder.name!)
		}
		let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
		if let data = Note.getData(for: filterNotesPredicate, with: [sortDescriptor]) as? [Note]{
			notes = data
		}
		if let data = TaskList.getData(for: filterFolderPredicate, with: [sortDescriptor]) as? [TaskList]{
			tasks = data
		}
		refreshCount()
		tableView.reloadData()
	}
	
	func refreshCount(){
		if segmentControl.selectedSegmentIndex == 0 {
			if isSearchBarEmpty{
				countLbl.text = "\(notes.count) Notes"
			} else {
				countLbl.text = "\(filteredNotes.count) Notes"
			}
		} else {
			countLbl.text = "\(tasks.count) Tasks"
		}
	}
	
	@IBAction func addButton(_ sender: Any) {
		addButtonClick()
	}
	
	func addButtonClick(){
		switch  segmentControl.selectedSegmentIndex {
			case 0:
				let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "NoteViewController") as! NoteViewController
				controller.parentFolder = self.selectedFolder
				self.navigationController?.pushViewController(controller, animated: true)
				break
			case 1:
				let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "TaskViewController") as! TaskViewController
				let taskList = TaskList()
				taskList.listId = UUID()
				taskList.title = ""
				taskList.updatedAt = Date.now
				taskList.parentFolder = selectedFolder
				controller.currentTaskList = taskList
				self.navigationController?.pushViewController(controller, animated: true)
				break
			default:
				break
		}
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
		search("")
	}
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		guard let query = searchBar.text, !query.isEmpty else { return }
		//searchNotesFromStorage(query)
	}
	
	func search(_ query: String) {
		if segmentControl.selectedSegmentIndex == 0{
			if query.count >= 1 {
				filteredNotes = notes.filter {
					note in
					if let content = note.content{
						let searchString = NSAttributedString.loadFromHtml(content: content)?.string
						return searchString?.lowercased().contains(query.lowercased()) ?? false
					}
					return false
				}
			} else{
				filteredNotes = notes
			}
		}
		
		refreshCount()
		tableView.reloadData()
	}
	
	func getCurrentLine (attributedText: NSAttributedString) -> NSRange{
		let attributedText = NSMutableAttributedString(attributedString: attributedText)
		let actualString = attributedText.string
		if actualString.count == 0 {
			return NSRange(location: 0, length: 1)
		}
		let cursorPosition = 0
		let previousString = actualString.prefix(cursorPosition)
		let startIndex = previousString.lastIndex{ $0.isNewline }
		
		let postString = actualString[actualString.index(actualString.startIndex, offsetBy: cursorPosition)...]
		let endIndex = postString.firstIndex{ $0.isNewline }
		
		var startLocation = 0
		var endLocation = actualString.count
		
		if let startIndex = startIndex{
			startLocation = previousString.distance(from: previousString.startIndex, to: startIndex) + 1
		}
		if let endIndex = endIndex{
			endLocation = cursorPosition + postString.distance(from: postString.startIndex, to: endIndex)
		}
		startLocation = min(max(actualString.count - 1, 0), startLocation)
		endLocation = min(actualString.count, endLocation)
		
		return NSRange(location: startLocation, length: endLocation - startLocation)
	}
}

extension NotesViewController: UITableViewDelegate, UITableViewDataSource{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if isSearchBarEmpty {
			if segmentControl.selectedSegmentIndex == 0{
				return allNotes.count
			} else {
				return tasks.count
			}
		} else {
			return filteredNotes.count
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "note", for: indexPath) as! NotesTableViewCell
		if segmentControl.selectedSegmentIndex == 0{
			var note = notes[indexPath.row]
			if !isSearchBarEmpty{
				note = filteredNotes[indexPath.row]
			}
			if let content = note.content{
				let searchString = NSAttributedString.loadFromHtml(content: content)
				if let searchString = searchString{
					let currentLine = getCurrentLine(attributedText: searchString)
					let title = searchString.attributedSubstring(from: currentLine).string
					cell.noteTitle?.text = title
					cell.noteDate.text = note.updatedAt?.format()
				}
			}
		} else{
			let task = tasks[indexPath.row]
			cell.noteTitle?.text = task.title
			cell.noteDate.text = task.updatedAt?.format()
		}
		return cell
	}
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		if segmentControl.selectedSegmentIndex == 0{
			let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "NoteViewController") as! NoteViewController
			var note = notes[indexPath.row]
			if !isSearchBarEmpty{
				note = filteredNotes[indexPath.row]
			}
			controller.parentFolder = selectedFolder
			controller.note = note
			navigationController?.pushViewController(controller, animated: true)
		}else{
			let task = self.tasks[indexPath.row]
			let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "TaskViewController") as! TaskViewController
			controller.currentTaskList = task
			self.navigationController?.pushViewController(controller, animated: true)
		}
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let moveToCategory = UIContextualAction(style: .normal, title: "Move to Category") { (action, view, completion) in
			// code to move the note to another category
		}
		moveToCategory.backgroundColor = .blue
		moveToCategory.image = UIImage(systemName: "folder")
		
		let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
			if self.segmentControl.selectedSegmentIndex == 0{
				var note = self.notes[indexPath.row]
				if !self.isSearchBarEmpty{
					note = self.filteredNotes[indexPath.row]
				}
				Note.context.delete(note)
			}else{
				let task = self.tasks[indexPath.row]
				TaskList.context.delete(task)
			}
			
			Database.getInstance().saveData()
			self.loadData()
			// Delete the note from your data source (e.g. an array of notes)
			tableView.deleteRows(at: [indexPath], with: .fade)
			completion(true)
		}
		delete.image = UIImage(systemName: "trash")
		let swipeActions = UISwipeActionsConfiguration(actions: [moveToCategory, delete])
		return swipeActions
	}
}
