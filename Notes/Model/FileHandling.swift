//
//  FileHandling.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-27.
//

import UIKit

class FileHandling{
	
	class func getDirectory() -> URL?{
		do{
			var directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
			directory = directory.appending(path: "images")
			if !FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)) {
				try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
				
			}
			return directory
		} catch {
			print("error:", error)
			return nil
		}
	}
	
	class func saveToDirectory(_ image: UIImage) -> String?{
		if let documentsDirectory = getDirectory(){
			let fileName = "\(UUID().uuidString).jpg"
			let fileURL = documentsDirectory.appending(path: fileName)
			do {
				if let data = image.jpegData(compressionQuality:  1),
				   !FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) {
					try data.write(to: fileURL)
					return fileURL.path(percentEncoded: false)
				}
			} catch {
				print("error:", error)
			}
		}
		return nil
	}
}
