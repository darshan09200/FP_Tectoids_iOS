//
//  MoveFolderViewController.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-30.
//

import UIKit

class MoveFolderViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	var selectedNote: Note?
	var selectedTask: TaskList?
	
	var success: (()->Void) = {}
	
    override func viewDidLoad() {
        super.viewDidLoad()        
    }
	
	func getFolders()->[Folder]{
		return Database.getInstance().folders.filter{
			$0.folderId != selectedNote?.parentFolder?.folderId &&
			$0.folderId != selectedTask?.parentFolder?.folderId
		}
	}

	@IBAction func onCancelPress(_ sender: Any) {
		self.dismiss(animated: true)
	}
}

extension MoveFolderViewController: UITableViewDelegate, UITableViewDataSource{
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return getFolders().count
	}
	
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FolderCell
		let folder = self.getFolders()[indexPath.row]
		cell.titleLabel.text = folder.name
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let folder = self.getFolders()[indexPath.row]
		selectedTask?.parentFolder = folder
		selectedNote?.parentFolder = folder
		Database.getInstance().saveData()
		success()
		self.dismiss(animated: true)
		
	}
}
