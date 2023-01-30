//
//  Notification.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-30.
//

import UIKit
import UserNotifications

struct NotificationTemplate{
	let identifier: String
	let notificationContent: UNMutableNotificationContent
	let date: Date
}

struct NotificationIdentifier{
	struct Category {
		static let task = "task"
		static let taskIncomplete = "taskIncomplete"
	}
	
	struct Action{
		static let markComplete = "markComplete"
	}
}


class NotificationConfig: NSObject{
	static let instance = NotificationConfig()
	
	private override init(){}
	
	func setupNotification(){
		UNUserNotificationCenter.current().delegate = self
		
		UNUserNotificationCenter.current().requestAuthorization(
			options: [.alert, .badge, .sound]) { success, error in
				
				if success{
					let markCompleteAction = UNNotificationAction(identifier: NotificationIdentifier.Action.markComplete, title: "Mark as Complete", options: [])
					
					let taskCategory = UNNotificationCategory(identifier: NotificationIdentifier.Category.task, actions: [markCompleteAction], intentIdentifiers: [], options: [])
					UNUserNotificationCenter.current().setNotificationCategories([taskCategory])
				}
			}
	}
	
	func createNotification(data: NotificationTemplate){
		let notificationContent = data.notificationContent
		
		notificationContent.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
		
		// Add Trigger
		let notificationTrigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: data.date), repeats: false)
		
		// Create Notification Request
		let notificationRequest = UNNotificationRequest(identifier: data.identifier, content: notificationContent, trigger: notificationTrigger)
		
		// Add Request to User Notification Center
		UNUserNotificationCenter.current().add(notificationRequest) { (error) in
			if let error = error {
				print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
			} else{
				print("added")
			}
		}
	}
}

extension NotificationConfig: UNUserNotificationCenterDelegate{
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		completionHandler([.banner, .list, .badge, .sound])
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		let id = String(response.notification.request.identifier.split(separator: "_").first ?? "")
		switch response.actionIdentifier {
			case NotificationIdentifier.Action.markComplete:
				print("mark complete")
				markTaskAsComplete(taskId: id)
			default:
				print("Other Action")
		}
		completionHandler()
		print("received")
	}
	
	func markTaskAsComplete(taskId: String){
		let tasks = Database.getInstance().tasks
		let currentTask = tasks.first(where: {$0.taskId!.uuidString == taskId})
		if let currentTask = currentTask{
			var childTask = [Task]()
			if currentTask.parentTask == nil{
				childTask = tasks.filter{$0.parentTask == currentTask.taskId}
			}
			
			let canCheck = childTask.reduce(true){$0 && $1.isCompleted}
			if canCheck{
				currentTask.isCompleted = true
				Database.getInstance().saveData()
				UIApplication.shared.applicationIconBadgeNumber -= 1
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationIdentifier.Category.task), object: nil)
				UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["\(currentTask.taskId!.uuidString)_incomplete"])
				UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(currentTask.taskId!.uuidString)_incomplete"])
			}
			
		}
	}
}

