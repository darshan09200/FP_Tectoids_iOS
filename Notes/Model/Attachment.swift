//
//  Attachment.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-27.
//

import Foundation

enum FileType: Int{
	case image
	case audio
}
public class Attachment: NSObject, NSSecureCoding {
	
	public static var supportsSecureCoding = true
	
	var path: String
	var type: FileType
	var position: Int
	
	init(path: String, type: FileType, position: Int) {
		self.path = path
		self.type = type
		self.position = position
	}
	
	
	required convenience public init?(coder decoder: NSCoder) {
		let rawType = decoder.decodeInteger(forKey: "type")
		guard let path = decoder.decodeObject(of: NSString.self, forKey: "path") as? String,
			  let type = FileType(rawValue: rawType)
		else {return nil}
		let position = decoder.decodeInteger(forKey: "position") as Int
		
		self.init(path: path, type: type, position: position)
	}
	
	public func encode(with coder: NSCoder) {
		coder.encode(path, forKey: "path")
		coder.encode(type.rawValue, forKey: "type")
		coder.encode(position, forKey: "position")
	}
	
	public override var description: String{
		return "\(path) \(type.rawValue) \(position)"
	}
}
