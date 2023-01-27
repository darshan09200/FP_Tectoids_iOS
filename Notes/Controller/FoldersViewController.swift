    //
    //  ViewController.swift
    //  Notes
    //
    //  Created by Darshan Jain on 2023-01-17.
    //

    import UIKit

    class FoldersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
        
        private let searchController = UISearchController()
        
        @IBOutlet weak var addButton: UIBarButtonItem!
        
        @IBOutlet weak var sortMenu: UIBarButtonItem!
        
        @IBOutlet weak var folderTable: UITableView!
        //sort menu
        let menu = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: "Sort By Date",
                     image: UIImage(systemName: "calendar")) { action in
                         // Perform action
                     },
            UIAction(title: "Sort By Title",
                     image: UIImage(systemName: "a.square.fill")) { action in
                         // Perform action
                     }
            
        ])
        private var isSearchBarEmpty: Bool {
            return searchController.searchBar.text?.isEmpty ?? true
        }
        private var allFolders: [Folder] = [] {
            didSet {
                filteredFolders = allFolders
            }
        }
        private var filteredFolders: [Folder] = []
        
        override func viewWillAppear(_ animated: Bool) {
            allFolders = Database.getInstance().folders
            folderTable.reloadData()
        }
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if isSearchBarEmpty {
                    return allFolders.count
            } else {
                    return filteredFolders.count
            }
            //return Database.getInstance().folders.count
        }
        
        func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
        {
            
            let deleteAction = UIContextualAction(style: .destructive, title:  "",
                                                  handler: { [self] (ac:UIContextualAction, view:UIView, success:(Bool)
                                                                     -> Void) in
                print("Delete Action Tapped")
             
                let alert = UIAlertController(title: "Do you want to delete the folder?",message: "",preferredStyle: .alert)
                let folder = Database.getInstance().folders[indexPath.row]
                alert.addAction(UIAlertAction(title: "No", style: .destructive, handler: {
                    (alertAction: UIAlertAction!) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {
                    (alertAction: UIAlertAction!) in
                    Folder.context.delete(folder)
                    Database.getInstance().saveData()
                    allFolders = Database.getInstance().folders
                    self.folderTable.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                    
                }))
                
                alert.view.tintColor = UIColor.black  // change text color of the buttons
                alert.view.layer.cornerRadius = 25   // change corner radius
                present(alert, animated: true, completion: nil)
                
                success(true)
            })
                
                
                deleteAction.image = UIImage(systemName: "trash")?.withTintColor(.red)
                deleteAction.backgroundColor = .red
                
                let editAction = UIContextualAction(style: .normal, title:  "",
                                                    handler: { [self] (ac:UIContextualAction, view:UIView, success:(Bool)
                                                                       -> Void) in
                    let folder = Database.getInstance().folders[indexPath.row]
                    // AlertView with Textfield for enter text
                    let alert = UIAlertController(title: "Do you want to edit the folder?",message: "",preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "No", style: .destructive, handler: {
                        (alertAction: UIAlertAction!) in
                        alert.dismiss(animated: true, completion: nil)
                    }))
                    
                    alert.addTextField { (textField) in
                        textField.text = folder.name!
                    }
                    
                    alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {
                        (alertAction: UIAlertAction!) in
                        let textField = alert.textFields![0] // Force unwrapping because we know it exists.
                        folder.name = textField.text!
                        Database.getInstance().saveData()
                        self.folderTable.reloadRows(at: [indexPath], with: .automatic)
                    }))
                    
                    alert.view.tintColor = UIColor.black  // change text color of the buttons
                    alert.view.layer.cornerRadius = 25   // change corner radius
                    present(alert, animated: true, completion: nil)
                    
                    success(true)
                })
                
                editAction.image = UIImage(systemName: "square.and.pencil")?.withTintColor(.orange)
                editAction.backgroundColor = .orange
                let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
                return configuration
                
            
        }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
    //        let folder = Database.getInstance().folders[indexPath.row]
    //        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    //
    //        cell.textLabel?.text = folder.name
    //        cell.imageView?.image = UIImage(systemName: "folder")
    //        cell.imageView?.tintColor = .systemBlue
    //        cell.selectionStyle = .none
    //        return cell;
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                var folder: Folder
            
                if isSearchBarEmpty {
                   // folder = allFolders[indexPath.row]
                    folder = Database.getInstance().folders[indexPath.row]
                } else {
                    folder = filteredFolders[indexPath.row]
                }
                cell.textLabel?.text = folder.name
                cell.imageView?.image = UIImage(systemName: "folder")
                cell.imageView?.tintColor = .systemBlue
                cell.selectionStyle = .none
                return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: NotesViewController.identifier) as! NotesViewController
            //        controller.note = note
            //        controller.delegate = self
            navigationController?.pushViewController(controller, animated: true)
            
        }
        override func viewDidLoad() {
            super.viewDidLoad()
            folderTable.delegate = self
            folderTable.dataSource = self
            self.sortMenu.menu = menu
            // self.sortMenu.showsMenuAsPrimaryAction = true
            //Database.getInstance()
            configureSearchBar()
        }
        
        @IBAction func addButton(_ sender: Any) {
            var textField = UITextField()
            let alert = UIAlertController(title: "Add New Folder", message: "", preferredStyle: .alert)
            
            let addAction = UIAlertAction(title: "Add", style: .default) { (action) in
                let folder = Folder()
                folder.name = textField.text!
                Database.getInstance().saveData()
                print(Database.getInstance().folders)
                self.allFolders = Database.getInstance().folders
                self.folderTable.insertRows(at: [IndexPath(row: self.allFolders.count - 1, section: 0)], with: .automatic)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
            alert.addAction(addAction)
            alert.addAction(cancelAction)
            alert.addTextField { (field) in
                textField = field
                textField.placeholder = "folder name"
            }
            
            self.present(alert, animated: true, completion: nil)
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
            filteredFolders = allFolders.filter { (folder: Folder) -> Bool in
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
                filteredFolders = allFolders.filter { $0.name!.lowercased().contains(query.lowercased()) }
            } else{
                filteredFolders = allFolders
            }
            
            folderTable.reloadData()
        }
    }
