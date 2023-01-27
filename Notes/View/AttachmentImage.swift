//
//  AttachmentImage.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-27.
//

import UIKit

class AttachmentImage: UIImage{
	var path: String?
	
	func clone() -> AttachmentImage? {
		guard let originalCgImage = self.cgImage, let newCgImage = originalCgImage.copy() else {
			return nil
		}
		
		let image = AttachmentImage(cgImage: newCgImage, scale: self.scale, orientation: self.imageOrientation)
		image.path = path
		
		return image
	}
	
	class func load(fileURL: String) -> AttachmentImage? {
		let url = URL(fileURLWithPath: fileURL, isDirectory: false)
		
		print("inside url")
		do {
			let imageData = try Data(contentsOf: url)
			let image = AttachmentImage(data: imageData)
			image?.path = fileURL
			return image
		} catch {
			print("Error loading image : \(error.localizedDescription)")
		}
		
		return nil
	}
}

public extension UIImage{
	convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
		let rect = CGRect(origin: .zero, size: size)
		UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
		color.setFill()
		UIRectFill(rect)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		guard let cgImage = image?.cgImage else { return nil }
		self.init(cgImage: cgImage)
	}
}
