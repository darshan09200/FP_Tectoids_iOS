//
//  AttachmentTransformer.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-27.
//

import Foundation

class AttachmentTransformer: NSSecureUnarchiveFromDataTransformer {
	override static var allowedTopLevelClasses: [AnyClass] {
		[Attachments.self]
	}
	
	static func register() {
		let className = String(describing: AttachmentTransformer.self)
		let name = NSValueTransformerName(className)
		let transformer = AttachmentTransformer()
		
		ValueTransformer.setValueTransformer(transformer, forName: name)
	}
}
