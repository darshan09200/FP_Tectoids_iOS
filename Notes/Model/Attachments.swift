//
//  Attachments.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-27.
//

import Foundation

public class Attachments: NSObject, NSSecureCoding{
	
	public static var supportsSecureCoding = true
	
	var isSmall: Bool
	var attachments: [Attachment]
	
	public init(attachments: [Attachment], isSmall: Bool) {
		self.attachments = attachments
		self.isSmall = isSmall
	}
	
	
	required convenience public init?(coder decoder: NSCoder) {
		guard let attachments = decoder.decodeObject(of: [NSArray.self, Attachment.self], forKey: "attachments") as? [Attachment]
		else {return nil}
		let isSmall = decoder.decodeBool(forKey: "isSmall")
		self.init(attachments: attachments, isSmall: isSmall)
	}
	
	public func encode(with coder: NSCoder) {
		coder.encode(attachments, forKey: "attachments")
		coder.encode(isSmall, forKey: "isSmall")
	}
	
	public override var description: String{
		return "attaachments: \(attachments.map{$0.description}.joined(separator: ", ")) isSmall: \(isSmall)"
	}
}
