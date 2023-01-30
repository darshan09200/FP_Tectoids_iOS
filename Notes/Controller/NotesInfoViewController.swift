//
//  NotesInfoViewController.swift
//  Notes
//
//  Created by Vijay Bharath Reddy Challa on 2023-01-23.
//

import UIKit
import MapKit

class NotesInfoViewController: UIViewController {

	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subTitleLabel: UILabel!
	
	@IBOutlet weak var mapView: UIView!
	@IBOutlet weak var map: MKMapView!
	
	var currentNote: Note?
	
	override func viewDidLoad() {
        super.viewDidLoad()

		mapView.layer.cornerRadius = 8

		if let note = currentNote{
			titleLabel.text = NSAttributedString.loadFromHtml(content: note.content ?? "")?.getLine()?.string ?? "New Note"
			
			subTitleLabel.text = note.updatedAt?.fullDate()
			
			if note.latitude > -89 && note.latitude < 89 && note.longitude > -179 && note.longitude < 179{
				let annotation = MKPointAnnotation()
				annotation.coordinate = CLLocationCoordinate2D(latitude: note.latitude, longitude: note.longitude)
				map.addAnnotation(annotation)
				
				let camera = MKMapCamera()
				camera.centerCoordinate = annotation.coordinate
				camera.centerCoordinateDistance = 5000
				map.setCamera(camera, animated: false)
			} else{
				mapView.isHidden = true
			}
		}
    }
    
	@IBAction func onDeletePress() {
		if let note = currentNote{
			Note.context.delete(note)
		}
	}
	
	@IBAction func onCancelPress(_ sender: Any) {
		self.dismiss(animated: true)
	}
}
