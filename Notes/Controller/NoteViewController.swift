//
//  NoteViewController.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-26.
//

import UIKit
import CoreLocation

class NoteViewController: UIViewController {
	
	var note: Note?
	
	var parentFolder: Folder?
	
	@IBOutlet weak var textView: SubviewAttachingTextView!
	
	@IBOutlet weak var deleteBtn: UIBarButtonItem!
	
	@IBOutlet weak var infoBtn: UIBarButtonItem!
	
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
	
	lazy var alignmentButton = UIBarButtonItem(title: "Alignment",
											   style: .plain,
											   target: self,
											   action: #selector(onAlignmentPress))
	
	lazy var addImageButton = UIBarButtonItem(title: "Add Image",
											  style: .plain,
											  target: self,
											  action: #selector(addImagePress))
	
	lazy var addAudioButton = UIBarButtonItem(title: "Add Audio",
											  style: .plain,
											  target: self,
											  action: #selector(addAudioPress))
	
	lazy var imagePickerController = ImagePicker(presentationController: self, delegate: self)
	lazy var audioPickerController = AudioPicker(presentationController: self, delegate: self)
	
	let locationManager = CLLocationManager()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Initialization code
		
		if note == nil{
			note = Note()
			note!.noteId = UUID()
			note!.createdAt = Date.now
			note!.updatedAt = Date.now
		}
		
		if let parentFolder = parentFolder{
			note!.parentFolder = parentFolder
		}
		
		loadData()
		
		textView.textDragInteraction?.isEnabled = false
		textView.delegate = self
		
		locationManager.requestWhenInUseAuthorization()
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
		locationManager.startUpdatingLocation()
		
		textView.typingAttributes = defaultStyle
		
		textView.font = defaultStyle[.font] as? UIFont
		
		
		let optionsToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 64))
		optionsToolbar.barStyle = .default
		
		textSizeButton.tintColor = .label
		
		boldButton.image = UIImage(systemName: "bold")
		boldButton.tintColor = .label
		
		italicButton.image = UIImage(systemName: "italic")
		italicButton.tintColor = .label
		
		alignmentButton.image = UIImage(systemName: "text.alignleft")
		alignmentButton.tintColor = .label
		
		addImageButton.image = UIImage(systemName: "photo")
		addImageButton.tintColor = .label
		
		addAudioButton.image = UIImage(systemName: "music.quarternote.3")
		addAudioButton.tintColor = .label
		
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
			addAudioButton,
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
		saveData()
		
		super.viewWillDisappear(animated)
		
	}
	
	func loadData(){
		if let content = note?.content{
			DispatchQueue.main.async {
				
				let htmlData = NSString(string: content).data(using: String.Encoding.unicode.rawValue)
				
				let options = [NSAttributedString.DocumentReadingOptionKey.documentType:
								NSAttributedString.DocumentType.html]
				let attributedText = try? NSMutableAttributedString(data: htmlData ?? Data(),
																	options: options,
																	documentAttributes: nil)
				attributedText?.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: attributedText?.length ?? 0)){
					value, range, _ in
					attributedText?.addAttributes([.foregroundColor: UIColor.label], range: range)
				}
				
				self.textView.attributedText = attributedText?.attributedStringByTrimmingCharacterSet(charSet: .newlines)
				
				if let extras = self.note?.extras{
					self.isSmall = extras.isSmall
					var goBackPosition = 0
					extras.attachments.forEach{ attachment in
						if FileHandling.fileExists(attachment.path){
							let position = min(self.textView.attributedText.length, max(attachment.position - goBackPosition, 0))
							if attachment.type == .image{
								if let image = AttachmentImage.load(fileURL: attachment.path){
									self.textView.selectedRange = NSRange(location: position, length: 0)
									self.addImage(image: image)
								}
							} else if attachment.type == .audio{
								self.textView.selectedRange = NSRange(location: position, length: 0)
								self.addAudio(path: attachment.path)
							}
						}else{
							goBackPosition += 1
						}
					}
				}
				
			}
		}
		
	}
	
	func saveData(){
		let attributedText = textView.attributedText!.attributedStringByTrimmingCharacterSet(charSet: .newlines)
		let documentAttributes = [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.html]
		do {
			let htmlData = try attributedText.data(from: NSMakeRange(0, attributedText.length), documentAttributes:documentAttributes)
			if let content = String(data:htmlData,
									encoding:String.Encoding(rawValue: NSUTF8StringEncoding)) {
				note!.content = content
				note!.updatedAt = Date.now
				
				var extras = [Attachment]()
				
				attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributedText.length)){
					value, range, stopLoop in
					if let attachment = value as? SubviewTextAttachment,
					   let provider = attachment.viewProvider as? DirectTextAttachedViewProvider
					{
						if let imageView = provider.view as? AttachmentImageView{
							if let image = imageView.image as? AttachmentImage, let path = image.path{
								extras.append(Attachment(path: path, type: .image, position: range.location))
							}
						} else if let audioView = provider.view as? AudioPlayer{
							if let path = audioView.path{
								extras.append(Attachment(path: path, type: .audio, position: range.location))
							}
						}
					}
				}
				
				note?.extras = Attachments(attachments: extras, isSmall: isSmall)
				if attributedText.length > 0{
					print("saved")
					Database.getInstance().saveData()
				} else{
					print("deleted")
					Note.context.delete(note!)
				}
			}
		}
		catch {
			print("error creating HTML from Attributed String")
		}
		
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
		var attributes = textView.typingAttributes
		if textView.attributedText.length > 0{
			attributes = textView.attributedText.attributes(at: cursorPosition, effectiveRange: nil)
		}
		var newFont: UIFont = .preferredFont(forTextStyle: style)
		if let font = attributes[.font] as? UIFont{
			newFont = .preferredFont(forTextStyle: style).with(font.fontDescriptor.symbolicTraits)
		}
		
		let newCursorPosition = NSRange(location: textView.selectedRange.location + textView.selectedRange.length, length: 0)
		if text.length > 0{
			text.addAttributes([.font: newFont], range: currentLine)
		}
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
		var attributes = textView.typingAttributes
		if textView.attributedText.length > 0 {
			attributes = textView.attributedText.attributes(at: cursorPosition, effectiveRange: nil)
		}
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
			if text.length > 0{
				text.addAttributes([.font: attributes[.font]!], range: textView.selectedRange)
			}
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
	
	@objc func onAlignmentPress(){
		guard let text = textView.attributedText?.mutableCopy() as? NSMutableAttributedString else { return }
		let currentLine = getCurrentLine()
		let cursorPosition = currentLine.location
		var attributes = defaultStyle
		if text.length > 0 && currentLine.location < text.length{
			attributes = text.attributes(at: cursorPosition, effectiveRange: nil)
		}
		var currentAlignment: NSTextAlignment = .left
		if currentLine.length <= 1,
		   let paragraphStyle = textView.typingAttributes[.paragraphStyle] as? NSParagraphStyle{
			currentAlignment = paragraphStyle.alignment
		} else if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle{
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
		if text.length > 0{
			text.addAttributes([.paragraphStyle: newParagraphStyle], range: currentLine)
		}
		textView.attributedText = text
		textView.selectedRange = newCursorPosition
		textView.typingAttributes = attributes.merging([.paragraphStyle: newParagraphStyle]){(_, new) in new}
		setAlignmentButton(paragraphStyle: newParagraphStyle)
	}
	
	@objc func addImagePress(){
		textView.resignFirstResponder()
		imagePickerController.present()
	}
	
	@objc func addAudioPress(){
		textView.resignFirstResponder()
		audioPickerController.present()
	}
	
	func getCurrentLine () -> NSRange{
		let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
		let actualString = attributedText.string
		if actualString.count == 0 {
			return NSRange(location: 0, length: 1)
		}
		let cursorPosition = textView.selectedRange.location
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
	
	func getNewWidthHeight(oldWidth: CGFloat, oldHeight: CGFloat, scaledToWidth: CGFloat)->(CGFloat, CGFloat){
		let scaleWidthFactor = scaledToWidth / oldWidth
		let scaleHeightFactor = scaledToWidth / oldHeight
		
		let scaleFactor = oldWidth > oldHeight || !isSmall ? scaleWidthFactor : scaleHeightFactor
		
		let newHeight = oldHeight * scaleFactor
		let newWidth = oldWidth * scaleFactor
		
		return (newWidth, newHeight)
	}
	
	func imageWithImage (sourceImage:AttachmentImage, scaledToWidth: CGFloat) -> AttachmentImage {
		let (newWidth, newHeight) = getNewWidthHeight(oldWidth: sourceImage.size.width, oldHeight: sourceImage.size.height, scaledToWidth: scaledToWidth)
		
		UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
		sourceImage.draw(in: CGRect(x:8, y:8, width:newWidth - CGFloat(16), height:newHeight - CGFloat(16)))
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		let image = AttachmentImage(cgImage: newImage!.cgImage!)
		image.path = sourceImage.path
		return image
	}
	
	func addImage(image: AttachmentImage){
		var attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
		
		let resizedImage = imageWithImage(sourceImage: image, scaledToWidth: maxImageWidth)
		let imageView = AttachmentImageView(image: resizedImage, shouldResize: true)
		let (newWidth, newHeight) = getNewWidthHeight(oldWidth: resizedImage.size.width, oldHeight: resizedImage.size.height, scaledToWidth: self.maxImageWidth * (isSmall ? 0.5 : 1))
		
		imageView.frame.size = CGSize(width: newWidth, height: newHeight)
		imageView.isUserInteractionEnabled = true
		
		
		//		let tapGestureRecognizer = ImageTapGestureRecognizer(target: self, action: #selector(onImageTap(_:)))
		//		imageView.addGestureRecognizer(tapGestureRecognizer)
		
		let interaction = MenuInteraction(delegate: self)
		interaction.path = image.path
		interaction.type = .image
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
			//			if previousText.string != "\n" && !isSmall {
			//				attributedText.insert(newLine, at: previousTextRange.location + 1)
			//				newLinePosition += 1
			//			} else if isSmall{
			let previousImageRange = NSRange(location: previousTextRange.location - (previousText.string == "\n" ? 1 : 0), length: 1)
			if previousImageRange.location > -1 {
				let previousImage = attributedText.attributedSubstring(from: previousImageRange)
				if isResizableImage(attachment: previousImage){
					if previousText.string == "\n"{
						attributedText.deleteCharacters(in: previousTextRange)
						newLinePosition -= 1
					}
				} else if previousText.string != "\n" {
					attributedText.insert(newLine, at: previousTextRange.location + 1)
					newLinePosition += 1
				}
			}else if previousText.string != "\n"{
				attributedText.insert(newLine, at: previousTextRange.location + 1)
				newLinePosition += 1
			}
			//			}
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
	
	func addAudio(path: String){
		var attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
		let audioView = AudioPlayer(frame: CGRect(x: 8, y: 8, width: maxImageWidth, height: 64), path: path)
		
		let interaction = MenuInteraction(delegate: self)
		interaction.path = path
		interaction.type = .audio
		audioView.addInteraction(interaction)
		
		let audioAttachment = SubviewTextAttachment(view: audioView, size: audioView.frame.size)
		attributedText = NSMutableAttributedString(attributedString: attributedText
			.insertingAttachment(audioAttachment, at: textView.selectedRange.location))
		attributedText.insert(newLine, at: textView.selectedRange.location+1)
		textView.becomeFirstResponder()
		textView.attributedText = attributedText
	}
	
	@objc func onImageTap(_ sender: ImageTapGestureRecognizer){
		print("tapped")
	}
	
	
	@IBAction func onDeletePress(_ sender: UIBarButtonItem) {
		if let note = note{
			Note.context.delete(note)
		}
	}
	
	@IBAction func onInfoPress(_ sender: UIBarButtonItem) {
		let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NotesInfoVC") as! NotesInfoViewController
		controller.currentNote = note
		self.present(UINavigationController(rootViewController: controller), animated: true)
	}
}


extension NoteViewController: UITextViewDelegate{
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		if textView.attributedText.length > 0{
			if text.count == 0{
				var isPostImage = false
				let postRange = NSRange(location: range.location + 1, length: 1)
				if postRange.location < textView.attributedText.length{
					isPostImage = isResizableImage(attachment: textView.attributedText.attributedSubstring(from: postRange))
				}
				if isPostImage{
					var isPreviousImage = false
					let previousRange = NSRange(location: range.location -
												1
												//												(isSmall ? 1 : 2)
												, length: 1)
					if previousRange.location > -1{
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
				if previousRange.location > -1{
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
						newCursorPosition = max(newCursorPosition, attributedText.length)
						let selectedRange = NSRange(location: newCursorPosition, length: 0)
						textView.attributedText = attributedText
						textView.selectedRange = selectedRange
						return false
					}
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
		alignmentButton.isEnabled = true
		var attributes = textView.typingAttributes
		if textView.attributedText.length > 0{
			attributes = textView.attributedText.attributes(at: cursorPosition, effectiveRange: nil)
			let currentLine = getCurrentLine()
			if textView.attributedText.containsAttachments(in: currentLine){
				alignmentButton.isEnabled = false
			}
		}
		
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
		if textView.attributedText.length == 0{
			textView.typingAttributes = defaultStyle
		}
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
	
	func removeAttachment(for path: String){
		let attributedText: NSMutableAttributedString = self.textView.attributedText.mutableCopy() as! NSMutableAttributedString
		attributedText.enumerateAttribute(
			.attachment,
			in: NSRange(location: 0, length: attributedText.length))
		{ value, range, stopLoop in
			if let attachment = value as? SubviewTextAttachment,
			   let provider = attachment.viewProvider as? DirectTextAttachedViewProvider{
				if let imageView = provider.view as? AttachmentImageView,
					let image = imageView.image as? AttachmentImage,
					image.path == path{
					attributedText.replaceCharacters(in: range, with: "")
					stopLoop.initialize(to: true)
				} else if let audioView = provider.view as? AudioPlayer,
							audioView.path == path{
					attributedText.replaceCharacters(in: range, with: "")
					stopLoop.initialize(to: true)
				}
			}
			
		}
		self.textView.attributedText = attributedText.attributedStringByTrimmingCharacterSet(charSet: .newlines)
	}
	
	func resizeImages(){
		isSmall = !isSmall
		saveData()
		loadData()
	}
	
	func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
			var actions = [UIAction]()
			let shareAction = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { action in
				if let interaction = interaction as? MenuInteraction, let path = interaction.path{
					self.imagePickerController.shareFile(path: path, sourceView: interaction.view)
				}
			}
			
			let resizeAction = UIAction(title: "Resize", image: UIImage(systemName: self.isSmall ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")) { action in
				self.resizeImages()
			}
			
			if let interaction = interaction as? MenuInteraction{
				actions.append(shareAction)
				if interaction.type == .image{
					actions.append(resizeAction)
				}
				if let path = interaction.path{
					let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
						self.removeAttachment(for: path)
					}
					actions.append(deleteAction)
				}
			}
			if actions.count > 0{
				return UIMenu(title: "", children: actions)
			} else {
				return nil
			}
		}
	}
}


extension NoteViewController: ImagePickerDelegate {
	
	func didSelect(image: UIImage?) {
		if let image = image{
			let path = FileHandling.saveToDirectory(image)
			if let path = path{
				let attachmentImage = AttachmentImage(cgImage: image.cgImage!, scale: image.scale, orientation: image.imageOrientation)
				attachmentImage.path = path
				addImage(image: attachmentImage)
			}
		} else{
			print("no image")
		}
		textView.becomeFirstResponder()
	}
}

extension NoteViewController: CLLocationManagerDelegate{
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location: CLLocationCoordinate2D = manager.location?.coordinate else { return }
		print(location)
		note?.latitude = location.latitude
		note?.longitude = location.longitude
	}
}

extension NoteViewController: AudioPickerDelegate{
	func didSelect(path: String?) {
		if let path = path{
			self.addAudio(path: path)
		}
		textView.resignFirstResponder()
	}
}


internal class ImageTapGestureRecognizer: UITapGestureRecognizer{
	var image: String?;
}

internal class AttachmentImageView: UIImageView{
	var shouldResize = false
	
	init(image: AttachmentImage?, shouldResize: Bool = false) {
		super.init(image: image)
		self.shouldResize = shouldResize
		layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
	}
	
	required init?(coder: NSCoder) {
		fatalError("not implemented")
	}
}

