//
//  AudioPicker.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-27.
//

import UIKit

open class AudioPicker: NSObject {
	private let pickerController: UIDocumentPickerViewController
	private weak var presentationController: UIViewController?
	private weak var delegate: AudioPickerDelegate?
	
	public init(presentationController: UIViewController, delegate: AudioPickerDelegate) {
		self.pickerController = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
		
		super.init()
		
		self.presentationController = presentationController
		self.delegate = delegate
		
		self.pickerController.delegate = self
		self.pickerController.modalPresentationStyle = .fullScreen
	}
	
	func openPicker(){
		presentationController?.present(pickerController, animated: true, completion: nil)
	}
	
	func openRecord(){
		let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RecordViewController") as! RecordViewController
		controller.recorderDelegate = self
		if let sheet = controller.sheetPresentationController{
			let smallDetentId = UISheetPresentationController.Detent.Identifier("small")
			let smallDetent = UISheetPresentationController.Detent.custom(identifier: smallDetentId) { context in
				return UIScreen.main.bounds.height * 0.25
			}
			
			let detents = [ smallDetent]
			
			sheet.prefersGrabberVisible = true
			sheet.prefersEdgeAttachedInCompactHeight = true
			sheet.detents = detents
			sheet.selectedDetentIdentifier = smallDetentId
		}
		presentationController?.present(controller, animated: true)
	}
	
	public func present() {
		
		let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		let recordAction = UIAlertAction(title: "Record Audio", style: .default) { _ in
			self.openRecord()
		}
		alertController.addAction(recordAction)
		
		let chooseAction = UIAlertAction(title: "Choose Audio", style: .default) { _ in
			self.openPicker()
		}
		alertController.addAction(chooseAction)
		
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		
		self.presentationController?.present(alertController, animated: true)
	}
}

extension AudioPicker: UIDocumentPickerDelegate{
	public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		controller.dismiss(animated: true)
		if let url = urls.first{
			if url.startAccessingSecurityScopedResource() {
				NSFileCoordinator().coordinate(readingItemAt: url, error: nil) { (url) in
					let newPath = FileHandling.saveToDirectory(url.path(percentEncoded: false))
					delegate?.didSelect(path: newPath)
					url.stopAccessingSecurityScopedResource()
				}
			}
		}
	}
	
	public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		controller.dismiss(animated: true)
		delegate?.didSelect(path: nil)
	}
}


extension AudioPicker: RecorderDelegate{
	func onAudioRecordComplete(_ path: String?) {
		delegate?.didSelect(path: path)
	}
}


public protocol AudioPickerDelegate: AnyObject{
	func didSelect(path: String?)
}

