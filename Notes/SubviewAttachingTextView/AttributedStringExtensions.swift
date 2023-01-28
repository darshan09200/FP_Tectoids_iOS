//
//  AttributedStringExtensions.swift
//  Text Editor
//
//  Created by Darshan Jain on 2023-01-13.
//

import UIKit

public extension NSTextAttachment {
	
	convenience init(image: UIImage, size: CGSize? = nil) {
		self.init(data: nil, ofType: nil)
		
		self.image = image
		if let size = size {
			self.bounds = CGRect(origin: .zero, size: size)
		}
	}
	
}

public extension NSAttributedString {
	
	func insertingAttachment(_ attachment: NSTextAttachment, at index: Int, with paragraphStyle: NSParagraphStyle? = nil) -> NSAttributedString {
		let copy = self.mutableCopy() as! NSMutableAttributedString
		copy.insertAttachment(attachment, at: index, with: paragraphStyle)
		
		return copy.copy() as! NSAttributedString
	}
	
	func addingAttributes(_ attributes: [NSAttributedString.Key : Any]) -> NSAttributedString {
		let copy = self.mutableCopy() as! NSMutableAttributedString
		copy.addAttributes(attributes)
		
		return copy.copy() as! NSAttributedString
	}
	
}

public extension NSMutableAttributedString {
	
	func insertAttachment(_ attachment: NSTextAttachment, at index: Int, with paragraphStyle: NSParagraphStyle? = nil) {
		let plainAttachmentString = NSAttributedString(attachment: attachment)
		
		if let paragraphStyle = paragraphStyle {
			let attachmentString = plainAttachmentString
				.addingAttributes([ .paragraphStyle : paragraphStyle ])
			let separatorString = NSAttributedString(string: .paragraphSeparator)
			
			// Surround the attachment string with paragraph separators, so that the paragraph style is only applied to it
			let insertion = NSMutableAttributedString()
			insertion.append(separatorString)
			insertion.append(attachmentString)
			insertion.append(separatorString)
			self.insert(insertion, at: index)
		} else {
			self.insert(plainAttachmentString, at: index)
		}
	}
	
	func addAttributes(_ attributes: [NSAttributedString.Key : Any]) {
		self.addAttributes(attributes, range: NSRange(location: 0, length: self.length))
	}
	
}

public extension String {
	
	static let paragraphSeparator = "\u{2029}"
	
}

extension NSAttributedString {
	public func attributedStringByTrimmingCharacterSet(charSet: CharacterSet) -> NSAttributedString {
		let modifiedString = NSMutableAttributedString(attributedString: self)
		modifiedString.trimCharactersInSet(charSet: charSet)
		return NSAttributedString(attributedString: modifiedString)
	}
	
	class func loadFromHtml(content: String) -> NSAttributedString? {
		let htmlData = NSString(string: content).data(using: String.Encoding.unicode.rawValue)
		
		let options = [NSAttributedString.DocumentReadingOptionKey.documentType:
						NSAttributedString.DocumentType.html]
		let attributedText = try? NSMutableAttributedString(data: htmlData ?? Data(),
															options: options,
															documentAttributes: nil)
		return attributedText?.attributedStringByTrimmingCharacterSet(charSet: .newlines)
	}
	
	public func getHtml() -> String?{
		let attributedText = self
		let documentAttributes = [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.html]
		do {
			let htmlData = try attributedText.data(from: NSMakeRange(0, attributedText.length), documentAttributes:documentAttributes)
			if let content = String(data:htmlData,
									encoding:String.Encoding(rawValue: NSUTF8StringEncoding)) {
				return content
			}
		}
		catch {
			print("error creating HTML from Attributed String")
		}
		return nil
	}
}

extension NSMutableAttributedString {
	public func trimCharactersInSet(charSet: CharacterSet) {
		var range = (string as NSString).rangeOfCharacter(from: charSet as CharacterSet)
		
		// Trim leading characters from character set.
		while range.length != 0 && range.location == 0 {
			replaceCharacters(in: range, with: "")
			range = (string as NSString).rangeOfCharacter(from: charSet)
		}
		
		// Trim trailing characters from character set.
		range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
		while range.length != 0 && NSMaxRange(range) == length {
			replaceCharacters(in: range, with: "")
			range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
		}
	}
}
