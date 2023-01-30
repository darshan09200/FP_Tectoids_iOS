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
	
	private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	private(set) var folders = [Folder]()
	private(set) var notes = [Note]()
	private(set) var taskList = [TaskList]()
	private(set) var tasks = [Task]()
	
	private init(){
		loadData()
	}
	
	static func getInstance()->Database{
		return instance;
	}
	
	func loadData(){
		loadFolders()
		loadNotes()
		loadTasks()
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
	
	func loadTaskList(){
		if let taskList = TaskList.getData() as? [TaskList]{
			self.taskList = taskList
		}
	}
	
	func loadTasks(){
		if let tasks = Task.getData() as? [Task]{
			self.tasks = tasks
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
		let request = NSFetchRequest<EntityType>(entityName: entityName)
		request.predicate = predicate
		request.sortDescriptors = sortDescriptors
		do {
			return try context.fetch(request)
		} catch {
			print("Error saving data \(error.localizedDescription)")
			return nil
		}
	}
	
	@nonobjc
	public override convenience init() {
		self.init(context: NSManagedObject.context)
	}
}
