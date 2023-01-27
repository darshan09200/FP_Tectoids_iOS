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
    
    
    var folder = [
    "groceries",
    "shopping"
    ]
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var sortMenu: UIButton!
    
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
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
       {
           let pinnedAction = UIContextualAction(style: .destructive, title: "pin") { (action, view, handler) in
               print("Pin Action Tapped")
           }
           pinnedAction.image = UIImage(systemName: "pin")?.withTintColor(.orange)
           pinnedAction.backgroundColor = .orange
           let configuration = UISwipeActionsConfiguration(actions: [pinnedAction])
           return configuration
       }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
        {
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, handler) in
                print("Delete Action Tapped")
            }
            deleteAction.image = UIImage(systemName: "trash")?.withTintColor(.red)
            deleteAction.backgroundColor = .red
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
        }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let categories = folder[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = folder[indexPath.row]
        cell.textLabel?.textColor = .lightGray
        cell.detailTextLabel?.textColor = .lightGray
        cell.imageView?.image = UIImage(systemName: "folder")
        cell.imageView?.tintColor = .orange
        cell.selectionStyle = .none
        return cell;
    }
    override func viewDidLoad() {
		super.viewDidLoad()
        folderTable.delegate = self
        folderTable.dataSource = self
        self.sortMenu.menu = menu
        self.sortMenu.showsMenuAsPrimaryAction = true
		Database.getInstance()
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
    }
    

