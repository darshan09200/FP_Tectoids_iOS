//
//  NoteViewController.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-26.
//

import UIKit

class NoteViewController: UIViewController {
	
	var note: Note?
	
	var parentFolder: Folder?
	
	@IBOutlet weak var textView: SubviewAttachingTextView!
	
	private lazy var maxImageWidth = textView.frame.width
	
	private var isSmall = false
	
	private let defaultStyle: [NSAttributedString.Key : Any] = [
		.font: UIFont.preferredFont(forTextStyle: .body),
		.foregroundColor: UIColor.label
	]
	
	private lazy var newLine = NSAttributedString("\n").addingAttributes(defaultStyle)
	
	let titleStyle: UIFont = .preferredFont(forTextStyle: .largeTitle)
	let headingStyle: UIFont = .preferredFont(forTextStyle: .title1)
	let subHeadingStyle: UIFont = .preferredFont(forTextStyle: .title2)
	let bodyStyle: UIFont = .preferredFont(forTextStyle: .body)
	
	lazy var titleButton = UIAction(title: "Title", handler: onResizePress)
	lazy var headingButton = UIAction(title: "Heading", handler: onResizePress)
	lazy var subHeadingButton = UIAction(title: "Subheading", handler: onResizePress)
	lazy var bodyButton = UIAction(title: "Body", handler: onResizePress)
	lazy var menuItems =  [
		bodyButton,
		subHeadingButton,
		headingButton,
		titleButton,
	]
	
	lazy var resizeMenu = UIMenu(options: .singleSelection, children: menuItems)
	
	lazy var textSizeButton = UIBarButtonItem(title: "Resize",
											  image: UIImage(systemName: "textformat.size"),
											  menu: resizeMenu)
	
	lazy var boldButton = UIBarButtonItem(title: "Bold",
										  style: .plain,
										  target: self,
										  action: #selector(onBoldPress))
	
	lazy var italicButton = UIBarButtonItem(title: "Italic",
											style: .plain,
											target: self,
											action: #selector(onItalicPress))
	
	lazy var addImageButton = UIBarButtonItem(title: "Done",
											  style: .plain,
											  target: self,
											  action: #selector(addImagePress))
	
	lazy var alignmentButton = UIBarButtonItem(title: "Alignment", style: .plain, target: self, action: #selector(onAlignmentPress))
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Initialization code
		
		textView.textDragInteraction?.isEnabled = false
		textView.delegate = self
		
		textView.typingAttributes = defaultStyle
		
		textView.font = defaultStyle[.font] as? UIFont
		
		if let content = note?.content{
			DispatchQueue.main.async {
				
				let htmlData = NSString(string: content).data(using: String.Encoding.unicode.rawValue)
				print(htmlData)
				
				let options = [NSAttributedString.DocumentReadingOptionKey.documentType:
								NSAttributedString.DocumentType.html]
				let attributedText = try? NSMutableAttributedString(data: htmlData ?? Data(),
																	options: options,
																	documentAttributes: nil)
				print(attributedText)
				self.textView.attributedText = attributedText
			}
		}
		
		let optionsToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 64))
		optionsToolbar.barStyle = .default
		
		textSizeButton.tintColor = .label
		
		boldButton.image = UIImage(systemName: "bold")
		boldButton.tintColor = .label
		
		italicButton.image = UIImage(systemName: "italic")
		italicButton.tintColor = .label
		
		addImageButton.image = UIImage(systemName: "photo")
		addImageButton.tintColor = .label
		
		alignmentButton.image = UIImage(systemName: "text.alignleft")
		alignmentButton.tintColor = .label
		
		optionsToolbar.items = [
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
			textSizeButton,
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
			boldButton,
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
			italicButton,
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
			alignmentButton,
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
			addImageButton,
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
		]
		optionsToolbar.sizeToFit()
		textView.inputAccessoryView = optionsToolbar
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
		
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		maxImageWidth = UIScreen.main.bounds.width - textView.layoutMargins.left - textView.layoutMargins.right
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		if note == nil{
			note = Note()
			print("created")
			note!.noteId = UUID()
			note!.createdAt = Date.now
			note!.updatedAt = Date.now
		}
		
		if let parentFolder = parentFolder{
			note!.parentFolder = parentFolder
		}
		
		let attributedText = textView.attributedText!
		let documentAttributes = [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.html]
		do {
			let htmlData = try attributedText.data(from: NSMakeRange(0, attributedText.length), documentAttributes:documentAttributes)
			if let content = String(data:htmlData,
									encoding:String.Encoding(rawValue: NSUTF8StringEncoding)) {
				note!.content = content
				note!.updatedAt = Date.now
				
				print("saved")
			}
		}
		catch {
			print("error creating HTML from Attributed String")
		}
		
		
		Database.getInstance().saveData()
		
		super.viewWillDisappear(animated)
		
	}
	@objc func keyboardWillShow(notification: NSNotification) {
		guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
		else {
			// if keyboard size is not available for some reason, dont do anything
			return
		}
		
		let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height , right: 0.0)
		textView.contentInset = contentInsets
		textView.scrollIndicatorInsets = contentInsets
	}
	
	@objc func keyboardWillHide(notification: NSNotification) {
		let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
		
		
		// reset back the content inset to zero after keyboard is gone
		textView.contentInset = contentInsets
		textView.scrollIndicatorInsets = contentInsets
	}
	
	func onResizePress(action: UIAction){
		let style: UIFont.TextStyle
		if action.title == "Title" {
			style = .largeTitle
		} else if action.title == "Heading"{
			style = .title1
		} else if action.title == "Subheading"{
			style = .title2
		} else {
			style = .body
		}
		guard let text = textView.attributedText?.mutableCopy() as? NSMutableAttributedString else { return }
		let currentLine = getCurrentLine()
		let cursorPosition = currentLine.location
		let attributes = textView.attributedText.attributes(at: cursorPosition, effectiveRange: nil)
		var newFont: UIFont = .preferredFont(forTextStyle: style)
		if let font = attributes[.font] as? UIFont{
			newFont = .preferredFont(forTextStyle: style).with(font.fontDescriptor.symbolicTraits)
		}
		
		let newCursorPosition = NSRange(location: textView.selectedRange.location + textView.selectedRange.length, length: 0)
		text.addAttributes([.font: newFont], range: currentLine)
		textView.attributedText = text
		textView.selectedRange = newCursorPosition
		textView.typingAttributes = attributes.merging([.font: newFont]){(_, new) in new}
		setTextResizeMenu(font: newFont)
	}
	
	func updateStyle(_ trait:  UIFontDescriptor.SymbolicTraits){
		var cursorPosition = textView.selectedRange.location
		if cursorPosition >= textView.attributedText.length || textView.selectedRange.length == 0{
			cursorPosition -= 1
		}
		var attributes = textView.attributedText.attributes(at: cursorPosition, effectiveRange: nil)
		guard let text = textView.attributedText?.mutableCopy() as? NSMutableAttributedString else { return }
		if let font = attributes[.font] as? UIFont{
			if !font.familyName.contains("Apple"){
				attributes = attributes.merging(defaultStyle) {(_, new) in new}
			}
			if font.fontDescriptor.symbolicTraits.contains(trait){
				attributes[.font] = font.without(trait)
			} else {
				attributes[.font] = font.with(trait)
			}
			text.addAttributes([.font: attributes[.font]!], range: textView.selectedRange)
			let newCursorPosition = NSRange(location: textView.selectedRange.location + textView.selectedRange.length, length: 0)
			textView.attributedText = text.copy() as? NSAttributedString
			if textView.selectedRange.length == 0 {
				textView.typingAttributes = attributes
			}
			textView.selectedRange = newCursorPosition
			setBoldItalicButton(font: attributes[.font]! as! UIFont)
		}
	}
	
	@objc func onBoldPress(){
		updateStyle(.traitBold)
	}
	
	@objc func onItalicPress(){
		updateStyle(.traitItalic)
	}
	
	@objc func addImagePress(){
		print("added image")
		addImage(image: UIImage(named: "dummy.jpg")!)
	}
	
	@objc func onAlignmentPress(){
		guard let text = textView.attributedText?.mutableCopy() as? NSMutableAttributedString else { return }
		let currentLine = getCurrentLine()
		let cursorPosition = currentLine.location
		let attributes = textView.attributedText.attributes(at: cursorPosition, effectiveRange: nil)
		var currentAlignment: NSTextAlignment = .left
		if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle{
			currentAlignment = paragraphStyle.alignment
		} else if currentLine.length == 1,
				  let paragraphStyle = textView.typingAttributes[.paragraphStyle] as? NSParagraphStyle{
			currentAlignment = paragraphStyle.alignment
		}
		let newParagraphStyle = NSMutableParagraphStyle()
		if currentAlignment == .center{
			newParagraphStyle.alignment = .right
		} else if currentAlignment == .right{
			newParagraphStyle.alignment = .left
		} else {
			newParagraphStyle.alignment = .center
		}
		let newCursorPosition = NSRange(location: textView.selectedRange.location + textView.selectedRange.length, length: 0)
		text.addAttributes([.paragraphStyle: newParagraphStyle], range: currentLine)
		textView.attributedText = text
		textView.selectedRange = newCursorPosition
		textView.typingAttributes = attributes.merging([.paragraphStyle: newParagraphStyle]){(_, new) in new}
		setAlignmentButton(paragraphStyle: newParagraphStyle)
	}
	
	func getCurrentLine () -> NSRange{
		let cursorPosition = textView.selectedRange.location
		let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
		let actualString = attributedText.string
		
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
		startLocation = min(actualString.count - 1, startLocation)
		endLocation = min(actualString.count, endLocation)
		
		return NSRange(location: startLocation, length: endLocation - startLocation)
	}
	
	func getNewWidthHeight(oldWidth: CGFloat, oldHeight: CGFloat, scaledToWidth: CGFloat)->(CGFloat, CGFloat){
		let scaleFactor = scaledToWidth / oldWidth
		
		let newHeight = oldHeight * scaleFactor
		let newWidth = oldWidth * scaleFactor
		
		return (newWidth, newHeight)
	}
	
	func imageWithImage (sourceImage:UIImage, scaledToWidth: CGFloat) -> UIImage {
		let (newWidth, newHeight) = getNewWidthHeight(oldWidth: sourceImage.size.width, oldHeight: sourceImage.size.height, scaledToWidth: scaledToWidth)
		
		UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
		sourceImage.draw(in: CGRect(x:8, y:8, width:newWidth - CGFloat(16), height:newHeight - CGFloat(16)))
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage!
	}
	
	func addImage(image: UIImage){
		var attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
		
		let resizedImage = imageWithImage(sourceImage: image, scaledToWidth: maxImageWidth)
		let imageView = AttachmentImageView(image: resizedImage, shouldResize: true)
		let (newWidth, newHeight) = getNewWidthHeight(oldWidth: resizedImage.size.width, oldHeight: resizedImage.size.height, scaledToWidth: self.maxImageWidth * (isSmall ? 0.5 : 1))
		
		imageView.frame.size = CGSize(width: newWidth, height: newHeight)
		imageView.isUserInteractionEnabled = true
		
		
		let tapGestureRecognizer = ImageTapGestureRecognizer(target: self, action: #selector(onImageTap(_:)))
		imageView.addGestureRecognizer(tapGestureRecognizer)
		
		let interaction = UIContextMenuInteraction(delegate: self)
		imageView.addInteraction(interaction)
		let imageAttachment = SubviewTextAttachment(view: imageView, size: imageView.frame.size)
		
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = .center
		attributedText = NSMutableAttributedString(attributedString: attributedText
			.insertingAttachment(imageAttachment, at: textView.selectedRange.location))
		
		var newLinePosition = textView.selectedRange.location + 1
		let previousTextRange = NSRange(location: textView.selectedRange.location - 1, length: 1)
		if previousTextRange.location > -1{
			let previousText = attributedText.attributedSubstring(from: previousTextRange)
			if previousText.string != "\n" && !isSmall {
				attributedText.insert(newLine, at: previousTextRange.location + 1)
				newLinePosition += 1
			} else if isSmall{
				let previousImageRange = NSRange(location: previousTextRange.location - 1, length: 1)
				if previousImageRange.location > -1 {
					let previousImage = attributedText.attributedSubstring(from: previousImageRange)
					if isResizableImage(attachment: previousImage){
						attributedText.deleteCharacters(in: previousTextRange)
						newLinePosition -= 1
					}
				}
			}
		}
		
		let postTextRange = NSRange(location: textView.selectedRange.location + textView.selectedRange.length + 1, length: 1)
		if postTextRange.location < attributedText.length{
			let postText = attributedText.attributedSubstring(from: postTextRange)
			if postText.string != "\n"{
				attributedText.insert(newLine, at: newLinePosition)
			}
		} else {
			attributedText.insert(newLine, at: attributedText.length)
		}
		textView.attributedText = attributedText
		
	}
	
	@objc func onImageTap(_ sender: ImageTapGestureRecognizer){
		print("tapped")
	}
	
}


extension NoteViewController: UITextViewDelegate{
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		if text.count == 0{
			var isPostImage = false
			let postRange = NSRange(location: range.location + 1, length: 1)
			if postRange.location < textView.attributedText.length{
				isPostImage = isResizableImage(attachment: textView.attributedText.attributedSubstring(from: postRange))
			}
			if isPostImage{
				var isPreviousImage = false
				let previousRange = NSRange(location: range.location - 2, length: 1)
				if previousRange.location > 0{
					isPreviousImage = isResizableImage(attachment: textView.attributedText.attributedSubstring(from: previousRange))
				}
				if !isPreviousImage{
					textView.selectedRange = NSMakeRange(max(range.location, 0), 0)
					return false
				}
			}
		} else {
			var isPostImage = false
			let postRange = NSRange(location: range.location, length: 1)
			if postRange.location < textView.attributedText.length{
				isPostImage = isResizableImage(attachment: textView.attributedText.attributedSubstring(from: postRange))
			}
			
			var isPreviousImage = false
			let previousRange = NSRange(location: range.location - 1, length: 1)
			if previousRange.location > 0{
				isPreviousImage = isResizableImage(attachment: textView.attributedText.attributedSubstring(from: previousRange))
			}
			if isPreviousImage || isPostImage{
				textView.typingAttributes = defaultStyle
				if !text.first!.isNewline{
					let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
					let newText = NSMutableAttributedString(attributedString:  NSAttributedString(string: text).addingAttributes(defaultStyle))
					var newCursorPosition = textView.selectedRange.location + text.count
					if isPreviousImage{
						newText.insert(newLine, at: 0)
						newCursorPosition += 1
					}
					if isPostImage{
						newText.append(newLine)
					}
					attributedText.insert(newText, at: textView.selectedRange.location)
					let selectedRange = NSRange(location: newCursorPosition, length: 0)
					textView.attributedText = attributedText
					textView.selectedRange = selectedRange
					return false
				}
			}
		}
		return true
	}
	
	func setTextResizeMenu(font: UIFont){
		titleButton.state = .off
		headingButton.state = .off
		subHeadingButton.state = .off
		bodyButton.state = .off
		
		switch font.pointSize{
			case titleStyle.pointSize:
				titleButton.state = .on
			case headingStyle.pointSize:
				headingButton.state = .on
			case subHeadingStyle.pointSize:
				subHeadingButton.state = .on
			default:
				bodyButton.state = .on
		}
		
		textSizeButton.menu = resizeMenu
	}
	
	func setBoldItalicButton(font: UIFont){
		if font.fontDescriptor.symbolicTraits.contains(.traitBold){
			boldButton.tintColor = .systemBlue
		} else {
			boldButton.tintColor = .label
		}
		if font.fontDescriptor.symbolicTraits.contains(.traitItalic){
			italicButton.tintColor = .systemBlue
		} else {
			italicButton.tintColor = .label
		}
	}
	
	func setAlignmentButton(paragraphStyle: NSParagraphStyle){
		if paragraphStyle.alignment == .center{
			alignmentButton.image = UIImage(systemName: "text.aligncenter")
		} else if paragraphStyle.alignment == .right{
			alignmentButton.image = UIImage(systemName: "text.alignright")
		}else{
			alignmentButton.image = UIImage(systemName: "text.alignleft")
		}
	}
	
	func textViewDidChangeSelection(_ textView: UITextView) {
		var cursorPosition = textView.selectedRange.location
		if cursorPosition >= textView.attributedText.length || textView.selectedRange.length == 0{
			cursorPosition -= 1
		}
		if cursorPosition < 0 {
			cursorPosition = 0
		}
		let attributes = textView.attributedText.attributes(at: cursorPosition, effectiveRange: nil)
		
		if let font = attributes[.font] as? UIFont{
			setBoldItalicButton(font: font)
			setTextResizeMenu(font: font)
		}
		
		if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle{
			setAlignmentButton(paragraphStyle: paragraphStyle)
		}
	}
	
	func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
		var additionalActions: [UIMenuElement] = []
		if range.length > 0 {
			let highlightAction = UIAction(title: "Highlight", image: UIImage(systemName: "highlighter")) { action in
				// The highlight action.
			}
			additionalActions.append(highlightAction)
		}
		let addBookmarkAction = UIAction(title: "Add Bookmark", image: UIImage(systemName: "bookmark")) { action in
			// The bookmark action.
		}
		additionalActions.append(addBookmarkAction)
		return UIMenu(children:  suggestedActions+additionalActions)
	}
	
	func textViewDidChange(_ textView: UITextView) {
		
	}
}

extension NoteViewController: UIContextMenuInteractionDelegate {
	
	func isResizableImage(attachment: NSAttributedString) -> Bool{
		var flag = false
		if attachment.length == 1{
			attachment.enumerateAttribute(.attachment, in: NSRange(location: 0, length: 1)){
				value, range, stopLoop in
				if let attachment = value as? SubviewTextAttachment,
				   let provider = attachment.viewProvider as? DirectTextAttachedViewProvider,
				   let imageView = provider.view as? AttachmentImageView {
					flag = imageView.shouldResize
					stopLoop.initialize(to: true)
				}
			}
		}
		return flag
	}
	
	func resizeImages(){
		isSmall = !isSmall
		var attributedText: NSMutableAttributedString = self.textView.attributedText.mutableCopy() as! NSMutableAttributedString
		attributedText.enumerateAttribute(
			NSAttributedString.Key.attachment,
			in: NSRange(location: 0, length: attributedText.length))
		{ value, range, _ in
			if let attachment = value as? SubviewTextAttachment,
			   let provider = attachment.viewProvider as? DirectTextAttachedViewProvider,
			   let oldImageView = provider.view as? AttachmentImageView {
				if(oldImageView.shouldResize){
					let possiblePreviousImageIndex = range.location - (isSmall ? 2 : 1)
					let isPreviousImage = isResizableImage(attachment: attributedText.attributedSubstring(from: NSRange(location: possiblePreviousImageIndex, length: 1)))
					var replaceRange = NSRange(location: range.location, length: range.length)
					var insertRange = NSRange(location: range.location, length: range.length)
					var style: NSParagraphStyle?
					if isPreviousImage {
						if isSmall{
							replaceRange = NSRange(location: possiblePreviousImageIndex + 1, length: range.length + (isSmall ? 1 : 0))
							insertRange = NSRange(location: insertRange.location - (isSmall ? 1 : 0), length: insertRange.length)
						} else {
							if let attachmentStyle =  attributedText.attributes(at: range.location, effectiveRange: nil)[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle{
								style = attachmentStyle
							}
						}
					}
					attributedText.replaceCharacters(in: replaceRange, with: "")
					
					let image = oldImageView.image!.clone()!
					let imageView = AttachmentImageView(image: image, shouldResize: true)
					
					let tapGestureRecognizer = ImageTapGestureRecognizer(target: self, action: #selector(onImageTap(_:)))
					imageView.addGestureRecognizer(tapGestureRecognizer)
					
					let interaction = UIContextMenuInteraction(delegate: self)
					imageView.addInteraction(interaction)
					
					imageView.isUserInteractionEnabled = true
					
					let (newWidth, newHeight) = getNewWidthHeight(oldWidth: image.size.width, oldHeight: image.size.height, scaledToWidth: self.maxImageWidth * (isSmall ? 0.5 : 1))
					imageView.frame.size = CGSize(width: newWidth, height: newHeight)
					
					let updatedAttahment = SubviewTextAttachment(view: imageView, size: imageView.frame.size)
					if let style = style{
						attributedText = NSMutableAttributedString(attributedString: attributedText.insertingAttachment(updatedAttahment, at: insertRange.location, with: style))
					}else{
						attributedText.insertAttachment(updatedAttahment, at: insertRange.location)
					}
				}
			}
			
		}
		self.textView.attributedText = (attributedText.copy() as! NSAttributedString)
	}
	
	func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
			let importAction = UIAction(title: "Import", image: UIImage(systemName: "folder")) { action in }
			let createAction = UIAction(title: "Resize", image: UIImage(systemName: "square.and.pencil")) { action in
				self.resizeImages()
				
			}
			return UIMenu(title: "", children: [importAction, createAction])
		}
	}
}


internal class ImageTapGestureRecognizer: UITapGestureRecognizer{
	var image: String?;
}

internal extension UIImage {
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
	
	func clone() -> UIImage? {
		guard let originalCgImage = self.cgImage, let newCgImage = originalCgImage.copy() else {
			return nil
		}
		
		return UIImage(cgImage: newCgImage, scale: self.scale, orientation: self.imageOrientation)
	}
}

internal class AttachmentImageView: UIImageView{
	var shouldResize = false
	
	init(image: UIImage?, shouldResize: Bool = false) {
		super.init(image: image)
		self.shouldResize = shouldResize
		layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
	}
	
	required init?(coder: NSCoder) {
		fatalError("not implemented")
	}
}


extension UIFont {
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
