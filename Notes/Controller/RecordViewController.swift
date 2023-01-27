//
//  RecordViewController.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-27.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController {

	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var recordButton: UIButton!
	
	var recorderDelegate: RecorderDelegate?
	
	var recordingSession: AVAudioSession?
	var audioRecorder: AVAudioRecorder?
	
	var recordingTime = 0
	var timer: Timer?
	var path = ""
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		recordButton.imageView?.contentMode = .scaleAspectFit
		recordButton.largeContentImageInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		reset()
		
		super.viewWillDisappear(animated)
	}
	
	@IBAction func onRecordPress() {
		record()
	}
	
	func reset(){
		audioRecorder?.stop()
		audioRecorder = nil
		recordButton.setImage(UIImage(systemName: "mic"), for: .normal)
		timer?.invalidate()
		self.timeLabel.text = "00:00"
	}
	
	func record(){
		if(audioRecorder == nil){
			let recordingSession = AVAudioSession.sharedInstance()
			
			do {
				try recordingSession.setCategory(.playAndRecord, mode: .default)
				try recordingSession.setActive(true)
				
			} catch {
				print("error: \(error.localizedDescription)")
			}
			
			if let directory = FileHandling.getDirectory(){
				let filePath = directory.appendingPathComponent("\(UUID().uuidString).m4a")
				let settings = [
					AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
					AVSampleRateKey: 12000,
					AVNumberOfChannelsKey: 1,
					AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
				]
				do
				{
					audioRecorder = try AVAudioRecorder(url: filePath, settings: settings)
					audioRecorder?.delegate = self
					audioRecorder?.record()
					self.path = filePath.path(percentEncoded: false)
					recordButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
					startTimer()
				} catch {
					print("Error: \(error.localizedDescription)")
				}
			}
		}
		else{
			reset()
		}
	}
	
	func startTimer(){
		recordingTime = 0
		self.timeLabel.text = "00:00"
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
			self.recordingTime += 1
			UIView.animate(withDuration: 0.5){
				self.timeLabel.text = TimeInterval(self.recordingTime).asTime()
			}
		}
	}
}

extension RecordViewController: AVAudioRecorderDelegate{
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		dismiss(animated: true)
		if flag{
			recorderDelegate?.onAudioRecordComplete(path)
		}
	}
	
	func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
		reset()
	}
}


protocol RecorderDelegate{
	func onAudioRecordComplete(_ path: String?)
}
