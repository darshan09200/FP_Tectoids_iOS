//
//  ViewController.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-17.
//

import UIKit

enum Sort: Int, CaseIterable{
	case title
	case date
	case count
}

class FoldersViewController: UIViewController, UISearchResultsUpdating {
	
	private let searchController = UISearchController()
	
	@IBOutlet weak var addButton: UIBarButtonItem!
	
	@IBOutlet weak var sortMenu: UIBarButtonItem!
	
	@IBOutlet weak var folderTable: UITableView!
	
	lazy var titleAction = UIAction(title: "Title") { action in
		self.onSortChange(.title)
	}
	
	lazy var dateAction = UIAction(title: "Created Date") { action in
		self.onSortChange(.date)
	}
	
	lazy var countAction = UIAction(title: "Count") { action in
		self.onSortChange(.count)
	}
	
	lazy var menu = UIMenu(title: "", options: .singleSelection, children: [
		titleAction,
		dateAction,
		countAction
	])
	
	private var isFiltering: Bool {
		return !(searchController.searchBar.text?.isEmpty ?? true)
	}
	
	private var filteredFolders = [Folder]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		folderTable.delegate = self
		folderTable.dataSource = self
		setActionState()
		self.sortMenu.menu = menu
		configureSearchBar()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		folderTable.reloadData()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		UserDefaults.standard.synchronize()
	}
	
	func getFolders() -> [Folder]{
		var sortPredicate = [NSSortDescriptor]()
		let currentSort = getCurrentSort()
		if currentSort == .title || currentSort == .none{
			sortPredicate.append(NSSortDescriptor(key: "name", ascending: false, selector: #selector(NSString.localizedStandardCompare)))
		} else if currentSort == .date{
			sortPredicate.append(NSSortDescriptor(key: "createdOn", ascending: false))
		}
		var data = [Folder]()
		if let folders = Folder.getData(with: sortPredicate) as? [Folder]{
			if currentSort == .count{
				print("inside count")
				data = folders.sorted{
					(($0.notes?.count ?? 0 ) + ($0.tasks?.count ?? 0)) >
					(($1.notes?.count ?? 0 ) + ($1.tasks?.count ?? 0))
				}
			} else {
				data = folders
			}
		}
		
		return data
	}
	
	func showFolderNameAlert(for indexPath: IndexPath? = nil){
		let alert = UIAlertController(
			title: indexPath == nil ? "Add New Folder": "Rename Folder",
			message: "", preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
		cancelAction.setValue(UIColor.systemRed, forKey: "titleTextColor")
		alert.addAction(cancelAction)
		
		let saveAction = UIAlertAction(
			title: indexPath == nil ? "Add" :"Save",
			style: .default, handler: {
				(alertAction: UIAlertAction!) in
				let textField = alert.textFields![0] // Force unwrapping because we know it exists.
				let folder: Folder
				if let indexPath = indexPath{
					folder = self.getFolders()[indexPath.row]
				} else{
					folder = Folder()
					folder.createdOn = Date.now
				}
				folder.name = textField.text!
				Database.getInstance().saveData()
//				if let indexPath = indexPath{
//					self.folderTable.reloadRows(at: [indexPath], with: .automatic)
//				} else{
//					self.folderTable.insertRows(at: [IndexPath(row: self.getFolders().count - 1, section: 0)], with: .automatic)
//				}
				self.folderTable.reloadData()
			})
		
		
		alert.addTextField { (textField) in
			textField.autocapitalizationType = .words
			textField.placeholder = "Folder Name"
			if let indexPath = indexPath{
				textField.text = self.getFolders()[indexPath.row].name
			}			
			textField.addObserver(for: saveAction)
		}
		
		alert.addAction(saveAction)
		
		self.present(alert, animated: true, completion: nil)
	}
	
	func getCurrentSort() -> Sort?{
		let sortValue = UserDefaults.standard.integer(forKey: "sort")
		return Sort(rawValue: sortValue)
	}
	
	func onSortChange(_ sort: Sort){
		UserDefaults.standard.set(sort.rawValue, forKey: "sort")
		setActionState()
		folderTable.reloadData()
	}
	
	func setActionState(){
		let currentSort = getCurrentSort()
		switch currentSort{
			case .date:
				dateAction.state = .on
			case .count:
				countAction.state = .on
			case .title: fallthrough
			case .none:
				titleAction.state = .on
		}
	}
}

extension FoldersViewController:  UITableViewDelegate, UITableViewDataSource{
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if isFiltering {
			return filteredFolders.count
		} else {
			return getFolders().count
		}
	}
	
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
	{
		
		let deleteAction = UIContextualAction(style: .destructive,
											  title:  "")
		{ (_, _, success) in
			
			let alert = UIAlertController(title: nil, message: "All notes and tasks will be deleted", preferredStyle: .actionSheet)
			let folder = self.getFolders()[indexPath.row]
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
			alert.addAction(UIAlertAction(title: "Delete Folder", style: .destructive){
				_ in
				Folder.context.delete(folder)
				Database.getInstance().saveData()
				self.folderTable.deleteRows(at: [indexPath], with: .automatic)
			})
			
			self.present(alert, animated: true, completion: nil)
			
			success(true)
		}
		
		
		deleteAction.image = UIImage(systemName: "trash")?.withTintColor(.red)
		deleteAction.backgroundColor = .red
		
		let editAction = UIContextualAction(style: .normal, title:  "")
		{ (_, _, success) in
			self.showFolderNameAlert(for: indexPath)
			success(true)
		}
		
		editAction.image = UIImage(systemName: "square.and.pencil")?.withTintColor(.orange)
		editAction.backgroundColor = .orange
		let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
		return configuration
		
		
	}
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FolderCell
		var folder: Folder
		
		if isFiltering {
			folder = filteredFolders[indexPath.row]
		} else {
			folder = self.getFolders()[indexPath.row]
		}
		cell.titleLabel.text = folder.name
		cell.countLabel.text = String((folder.notes?.count ?? 0 ) + (folder.tasks?.count ?? 0))
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: NotesViewController.identifier) as! NotesViewController
		var folder: Folder
		if isFiltering {
			folder = filteredFolders[indexPath.row]
		} else {
			folder = self.getFolders()[indexPath.row]
		}
		controller.selectedFolder = folder
		navigationController?.pushViewController(controller, animated: true)
		
	}
	
	@IBAction func addButton(_ sender: Any) {
		showFolderNameAlert()
	}
	
	private func configureSearchBar() {
		navigationItem.searchController = searchController
		searchController.obscuresBackgroundDuringPresentation = false
		searchController.searchBar.delegate = self
		searchController.delegate = self
		definesPresentationContext = true
		searchController.searchResultsUpdater = self
	}
	func updateSearchResults(for searchController: UISearchController) {
		filterContentForSearchText(searchController.searchBar.text!)
	}
	private func filterContentForSearchText(_ searchText: String) {
		filteredFolders = self.getFolders().filter { (folder: Folder) -> Bool in
			return folder.name!.lowercased().contains(searchText.lowercased())
		}
		folderTable.reloadData()
	}
}

extension FoldersViewController: UISearchControllerDelegate, UISearchBarDelegate {
	
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
		if query.count >= 1 {
			filteredFolders = self.getFolders().filter { $0.name!.lowercased().contains(query.lowercased()) }
		}
		
		folderTable.reloadData()
	}
}
