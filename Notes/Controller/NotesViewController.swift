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
    @IBOutlet weak var NotesCountLbl: UILabel!
    
    @IBOutlet weak var addButton: UIButton!
    
    var notes = [Note]()
    var selectedFolder: Folder?
    lazy var addMenu = UIMenu(title: "", options: .displayInline, children: [
        UIAction(title: "Add Task",
               image: UIImage(systemName: "calendar.badge.plus")) { action in
               // Perform action
               },
        UIAction(title: "Add Note",
               image: UIImage(systemName: "note.text.badge.plus")) { action in
				   let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "NoteViewController") as! NoteViewController
				   self.navigationController?.pushViewController(controller, animated: true)
               }
    
    ])
    override func viewDidLoad() {
        super.viewDidLoad()

        addButton.showsMenuAsPrimaryAction = true

        addButton.menu = addMenu
        // Do any additional setup after loading the view.
        configureSearchBar()
        
        var filterPredicate: NSPredicate?
        if let selectedFolder = selectedFolder{
            filterPredicate = NSPredicate(format: "parentFolder.id == %@", selectedFolder.name!)
        }
        notes = Note.getData(for: filterPredicate) as! [Note]
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func addButton(_ sender: Any) {
    }
    
    private func configureSearchBar() {
        navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.delegate = self
    }
    
    @IBAction func createNewNoteClicked(_ sender: UIButton) {
        
    }
    
}


extension NotesViewController: UISearchControllerDelegate, UISearchBarDelegate {
    
//
    
}

extension NotesViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "note", for: indexPath)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
		let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "NoteViewController") as! NoteViewController
		navigationController?.pushViewController(controller, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteNote(at: indexPath)
        }
    }
    func deleteNote(at indexPath: IndexPath) {
   
        //notes.remove(at: indexPath.row)
        
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let moveToCategory = UIContextualAction(style: .normal, title: "Move to Category") { (action, view, completion) in
            // code to move the note to another category
        }
        moveToCategory.backgroundColor = .blue
        moveToCategory.image = UIImage(systemName: "folder")

        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
                // Delete the note from your data source (e.g. an array of notes)
                //tableView.deleteRows(at: [indexPath], with: .fade)
                completion(true)
            }
            delete.image = UIImage(systemName: "trash")
        let swipeActions = UISwipeActionsConfiguration(actions: [moveToCategory, delete])
        return swipeActions
    }
}
