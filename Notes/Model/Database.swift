//
//  Database.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-23.
//
import UIKit
import CoreData

class Database {
	static let instance = Database()
	
	let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	var folders = [Folder]()
	var notes = [Note]()
	
	private init(){
		loadData()
	}
	
	static func getInstance()->Database{
		return instance;
	}
	
	func loadData(){
		loadFolders()
		loadNotes()
	}
	
	func loadFolders(){
		if let folders = Folder.getData() as? [Folder]{
			self.folders = folders
		}
	}
	
	func loadNotes(){
		if let notes = Note.getData() as? [Note]{
			self.notes = notes
		}
	}
	
	func saveData() {
		do {
			try context.save()
            loadData()
		} catch {
			print("Error saving data \(error.localizedDescription)")
		}
	}
	
}

protocol Fetchable {
	associatedtype EntityType: NSManagedObject = Self
}

extension NSManagedObject: Fetchable {
	class var entityName : String {
		return String(describing: self)
	}
	
	class var context : NSManagedObjectContext {
		return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	}
	
	class func getData(for predicate: NSPredicate? = nil,
					   with sortDescriptors: [NSSortDescriptor]? = nil) -> [EntityType]?
	{
		let request = fetchRequest()
		request.predicate = predicate
		request.sortDescriptors = sortDescriptors
		do {
			return try context.fetch(request) as? [EntityType]
		} catch {
			print("Error saving data \(error.localizedDescription)")
			return nil
		}
	}
	public override convenience init() {
		self.init(context: NSManagedObject.context)
	}
}
