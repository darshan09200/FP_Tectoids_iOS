//
//  ViewController.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-17.
//

import UIKit
class folder{
    let title : String
    
    init(title: String) {
        self.title = title
      
    }
}
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let searchController = UISearchController()
    var folder = [
    "groceries",
    "shopping"
    ]
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    @IBOutlet weak var sortMenu: UIBarButtonItem!
    
    @IBOutlet weak var folderTable: UITableView!
    //sort menu
    let menu = UIMenu(title: "", options: .displayInline, children: [
        UIAction(title: "Sort By Date",
               image: UIImage(systemName: "square.and.arrow.up.fill")) { action in
               // Perform action
               },
        UIAction(title: "Sort By Title",
               image: UIImage(systemName: "square.and.arrow.up.fill")) { action in
               // Perform action
               },
        UIAction(title: "Share",
               image: UIImage(systemName: "square.and.arrow.up.fill")) { action in
               // Perform action
             }
    
    ])
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folder.count
    }
   
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, handler) in
            print("Delete Action Tapped")
            self.folder.remove(at: indexPath.row)
            self.folderTable.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            self.folderTable.reloadData()
        }
        deleteAction.image = UIImage(systemName: "trash")?.withTintColor(.red)
        deleteAction.backgroundColor = .red

                let editAction = UIContextualAction(style: .normal, title: "edit") { (action, view, handler) in
                    print("edit Action Tapped")
                    
            }

        editAction.image = UIImage(systemName: "square.and.pencil")?.withTintColor(.orange)
        editAction.backgroundColor = .orange
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
            return configuration
            

        }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let categories = folder[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = folder[indexPath.row]
        cell.imageView?.image = UIImage(systemName: "folder")
        cell.imageView?.tintColor = .systemBlue
        cell.selectionStyle = .none
        return cell;
    }
    override func viewDidLoad() {
		super.viewDidLoad()
        folderTable.delegate = self
        folderTable.dataSource = self
        self.sortMenu.menu = menu
       // self.sortMenu.showsMenuAsPrimaryAction = true
        configureSearchBar()
	}

    @IBAction func addButton(_ sender: Any) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Folder", message: "", preferredStyle: .alert)
        let addAction = UIAlertAction(title: "Add", style: .default) { (action) in
            self.folder.append(textField.text!)
            self.folderTable.reloadData()
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
       }

    
}



extension ViewController: UISearchControllerDelegate, UISearchBarDelegate {
    

}
    

