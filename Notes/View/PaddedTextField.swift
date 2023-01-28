//
//  PaddedTextField.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-27.
//

import UIKit

open class PaddedTextField: UITextField {
	public var textInsets = UIEdgeInsets.zero {
		didSet {
			setNeedsDisplay()
		}
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	convenience init() {
		self.init(frame: .zero)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	open override func textRect(forBounds bounds: CGRect) -> CGRect {
		return bounds.inset(by: textInsets)
	}
	
	open override func editingRect(forBounds bounds: CGRect) -> CGRect {
		return bounds.inset(by: textInsets)
	}
	
	open override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
		return bounds.inset(by: textInsets)
	}
}
