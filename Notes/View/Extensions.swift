//
//  Extensions.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-27.
//

import UIKit

public extension UIFont {
	var bold: UIFont {
		return with(.traitBold)
	}
	
	var italic: UIFont {
		return with(.traitItalic)
	}
	
	var boldItalic: UIFont {
		return with([.traitBold, .traitItalic])
	}
	
	func with(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
		guard let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits).union(self.fontDescriptor.symbolicTraits)) else {
			return self
		}
		return UIFont(descriptor: descriptor, size: pointSize)
	}
	
	func without(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
		guard let descriptor = self.fontDescriptor.withSymbolicTraits(self.fontDescriptor.symbolicTraits.subtracting(UIFontDescriptor.SymbolicTraits(traits))) else {
			return self
		}
		return UIFont(descriptor: descriptor, size: pointSize)
	}
}

public extension TimeInterval{
	func asTime() -> String{
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.minute, .second]
		formatter.unitsStyle = .positional
		formatter.zeroFormattingBehavior = .pad
		let formattedString = formatter.string(from: TimeInterval(self))!
		return formattedString
	}
	
}

extension Date{
	func fullDate() -> String {
		let dateFormatterGet = DateFormatter()
		dateFormatterGet.dateFormat = "MMM dd, yyyy hh:mm a"
	
		return dateFormatterGet.string(from: self)
	}
	
	func format() -> String{
		let dateFormatterGet = DateFormatter()
		let currentDate = Date.now
		if Calendar.current.isDate(self, inSameDayAs: currentDate){
			dateFormatterGet.dateFormat = "hh:mm a"
		} else if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: currentDate),
					Calendar.current.isDate(self, inSameDayAs: yesterday) {
			return "Yesterday"
		} else if let nexWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate), self < nexWeek{
			dateFormatterGet.dateFormat = "EEEE"
		} else {
			dateFormatterGet.dateFormat = "MMM dd, yyyy"
		}
		
		return dateFormatterGet.string(from: self)
	}
}

extension UITextField{
	func addObserver(for action: UIAlertAction){
		action.isEnabled = self.text?.count ?? 0 > 0
		NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: self, queue: OperationQueue.main)
		{_ in
			
			let textCount = self.text?.trimmingCharacters(in: .whitespacesAndNewlines).count ?? 0
			let textIsNotEmpty = textCount > 0
			
			action.isEnabled = textIsNotEmpty
		}
	}
}
