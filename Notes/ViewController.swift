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
    

