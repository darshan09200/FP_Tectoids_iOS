//
//  AudioPlayer.swift
//  Notes
//
//  Created by Darshan Jain on 2023-01-27.
//

import UIKit
import AVFoundation

class AudioPlayer: UIStackView{
	private(set) var path: String?
	
	var audioFileUrl: URL?{
		if let path = path{
			return URL(fileURLWithPath: path)
		}
		return nil
	}
	
	private var hasAdded = false
	
	var audioPlayer: AVAudioPlayer?
	
	var playButton: UIImageView?
	var nameLabel: UILabel?
	var timeLabel: UILabel?
	var timer: Timer?
	
	init(frame: CGRect, path: String) {
		super.init(frame: frame)
		self.path = path
		
		let recordingSession = AVAudioSession.sharedInstance()
		
		do {
			try recordingSession.setCategory(.playback, mode: .default)
			try recordingSession.setActive(true)
			
		} catch {
			print("error: \(error.localizedDescription)")
		}
				
	}
	
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func draw(_ rect: CGRect) {
		loadView()
	}
	
	func loadView(){
		let stackView = self
		stackView.axis = .horizontal
		stackView.alignment = .center
		
		stackView.spacing = UIStackView.spacingUseSystem
		stackView.isLayoutMarginsRelativeArrangement = true
		stackView.layoutMargins = UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 16)
		
		if !hasAdded{
			playButton = UIImageView()
			playButton?.widthAnchor.constraint(equalToConstant: 48).isActive = true
			playButton?.heightAnchor.constraint(equalTo: playButton!.heightAnchor, multiplier: 1).isActive = true
			playButton?.contentMode = .scaleAspectFit
			playButton?.image = UIImage(systemName: "play.fill")
			playButton?.sizeToFit()
			stackView.addArrangedSubview(playButton!)
			
			
			let vertical = UIStackView()
			vertical.axis = .vertical
			
			nameLabel = UILabel()
			nameLabel?.font = .preferredFont(forTextStyle: .subheadline)
			nameLabel?.textColor = .label
			
			
			timeLabel = UILabel()
			timeLabel?.font = .preferredFont(forTextStyle: .footnote)
			timeLabel?.textColor = .label
			
			vertical.addArrangedSubview(nameLabel!)
			vertical.addArrangedSubview(timeLabel!)
			
			vertical.sizeToFit()
			stackView.addArrangedSubview(vertical)
			
			stackView.sizeToFit()
			
			stackView.isUserInteractionEnabled = true
						
			let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onPlayPress))
			stackView.addGestureRecognizer(gestureRecognizer)
			
			if let audioFileUrl = audioFileUrl{
				
				self.audioPlayer = try? AVAudioPlayer(contentsOf: audioFileUrl)
				audioPlayer?.delegate = self
				nameLabel?.text = audioFileUrl.lastPathComponent
				
				let duration = audioPlayer?.duration
				if let duration = duration{
					timeLabel?.text = duration.asTime()
				}
			}
			
			hasAdded = true
		}
		
		stackView.layer.backgroundColor = UIColor.secondarySystemBackground.cgColor
		stackView.layer.cornerRadius = 4
	}
	func resetPlayer(){
		playButton?.image = UIImage(systemName: "play.fill")
		audioPlayer?.stop()
		timer?.invalidate()
	}
	
	@objc func onPlayPress(){
		if let audioPlayer = audioPlayer{
			if audioPlayer.isPlaying{
				resetPlayer()
			} else{
				playButton?.image = UIImage(systemName: "stop.fill")
				audioPlayer.play()
				timeLabel?.text = audioPlayer.currentTime.asTime()
				self.timer = Timer.scheduledTimer(timeInterval: 1,
											 target: self,
											 selector: #selector(self.updateTime),
											 userInfo: nil,
											 repeats: true)
			}
		}
	}
	
	@objc func updateTime(_ sender: Any) {
		if let audioPlayer = audioPlayer{
			let songCurrTime = round(audioPlayer.currentTime)
			timeLabel?.text = songCurrTime.asTime()
		}
	}
}

extension AudioPlayer: AVAudioPlayerDelegate{
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		if flag{
			resetPlayer()
		}
	}
}
