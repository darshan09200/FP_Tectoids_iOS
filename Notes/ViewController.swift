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
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
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

    var folder = [
    "groceries",
    "shopping"
    ]
    @IBOutlet weak var AddButton: UIButton!
    
    @IBOutlet weak var SortMenu: UIButton!
    
    @IBOutlet weak var FolderTable: UITableView!
    
    
    override func viewDidLoad() {
		super.viewDidLoad()
        FolderTable.delegate = self
        FolderTable.dataSource = self
        self.SortMenu.menu = menu
        self.SortMenu.showsMenuAsPrimaryAction = true
		// Do any additional setup after loading the view.
	}
   

}

