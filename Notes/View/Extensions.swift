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
	func format() -> String{
		let dateFormatterGet = DateFormatter()
		dateFormatterGet.dateFormat = "MMM dd yyyy, HH:mm:ss"
		
		return dateFormatterGet.string(from: self)
	}
}
