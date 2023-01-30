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
	static let lineSeparator = "\u{2028}"
	
	func condenseWhitespace() -> String {
		let components = self
			.replacingOccurrences(of: "\n", with: " ")
			.replacingOccurrences(of: "\r", with: " ")
			.replacingOccurrences(of: String.paragraphSeparator, with: " ")
			.replacingOccurrences(of: String.lineSeparator, with: " ")
			.components(separatedBy: .whitespacesAndNewlines)
		return components.filter { !$0.isEmpty }.joined(separator: " ")
	}
	
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
	
	func getLine(at cursorPosition: Int = 0) -> NSAttributedString?{
		let currentLine = getLineRange()
		if currentLine.location > -1 && currentLine.length > -1 &&
			currentLine.location + currentLine.length < self.length{
			return attributedSubstring(from: currentLine)
		}
		return nil
	}
	
	func getLineRange (at cursorPosition: Int = 0) -> NSRange{
		let attributedText = NSMutableAttributedString(attributedString: self)
		let actualString = attributedText.string
		if actualString.count == 0 {
			return NSRange(location: 0, length: 1)
		}
		let previousString = actualString.prefix(cursorPosition)
		let startIndex = previousString.lastIndex{ $0.isNewline }
		
		let postString = actualString[actualString.index(actualString.startIndex, offsetBy: cursorPosition)...]
		let endIndex = postString.firstIndex{ $0.isNewline }
		
		var startLocation = 0
		var endLocation = actualString.count
		
		if let startIndex = startIndex{
			startLocation = previousString.distance(from: previousString.startIndex, to: startIndex) + 1
		}
		if let endIndex = endIndex{
			endLocation = cursorPosition + postString.distance(from: postString.startIndex, to: endIndex)
		}
		startLocation = min(max(actualString.count - 1, 0), startLocation)
		endLocation = min(actualString.count, endLocation)
		
		return NSRange(location: startLocation, length: endLocation - startLocation)
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
