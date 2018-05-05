//
//  HomeScreenViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 3/12/18.
//  Copyright © 2018 paradigm-performance. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer

class HomeScreenViewController: UIViewController {

	static let presentPlayerViewControllerSegueID = "PresentPlayerViewControllerSegueIdentifier"
	static let defaultTrackTitle = "KEBF/KZSR"
	static let defaultTrackArtist = "97.3 / 107.9 The Rock Radio"
	static let defaultAlbumArtwork: UIImage = #imageLiteral(resourceName: "RockLogo")
	
	fileprivate var playerViewController: AVPlayerViewController?
	
	// UI in the player window
	var songLabel: UILabel!
	var currentTrackTitle = HomeScreenViewController.defaultTrackTitle
	var currentTrackArtist = HomeScreenViewController.defaultTrackArtist
	var albumArtwork: UIImageView!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		// Set AssetListTableViewController as the delegate for AssetPlaybackManager to recieve playback information.
		AssetPlaybackManager.sharedManager.delegate = self
		NotificationCenter.default.addObserver(self, selector: #selector(HomeScreenViewController.handleNotification), name: NSNotification.Name(rawValue: "ObservedObjectSongName"), object: nil)
		// handle interruptions
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self,
									   selector: #selector(handleInterruption),
									   name: .AVAudioSessionInterruption,
									   object: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)		
	}

	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override var prefersStatusBarHidden: Bool {
		return false
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		
		if segue.identifier == HomeScreenViewController.presentPlayerViewControllerSegueID {
			guard let seguePlayerViewController = segue.destination as? AVPlayerViewController else { return }
			
			/*
			Grab a reference for the destinationViewController to use in later delegate callbacks from
			AssetPlaybackManager.
			*/
			playerViewController = seguePlayerViewController
			
			// Load the new Asset to playback into AssetPlaybackManager.
			let urlAsset = AVURLAsset.init(url: URL.init(string: "https://streaming.radio.co/s96fbbec3a/listen")!)
			let stream = StreamListManager.shared.streams.first
			let asset = Asset.init(stream: stream!, urlAsset: urlAsset)
			AssetPlaybackManager.sharedManager.setAssetForPlayback(asset)
		}
	}
	
	@objc func handleNotification(notification: NSNotification) {
		getStationPlaylistInfo()
	}
	
	func getStationPlaylistInfo() {
		let radioURL = URL.init(string: "https://public.radio.co/stations/s96fbbec3a/status")
		let task = URLSession.shared.dataTask(with: radioURL!) { data, response, error in
			if let error = error {
				self.handleClientError(error)
				return
			}
			guard let httpResponse = response as? HTTPURLResponse,
				(200...299).contains(httpResponse.statusCode) else {
					self.handleServerError(response)
					return
			}
			if let mimeType = httpResponse.mimeType, mimeType == "application/json",
				let data = data {
				do {
					let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
					self.processJSON(jsonData)
				}
				catch {
					print(error)
				}
			}
		}
		task.resume()
	}
	
	func processJSON(_ jsonData: [String : Any]) {
		for dict in jsonData {
			if dict.key == "current_track" {
				guard let currentTrackDict = dict.value as? [String : Any] else { return }
				if let title = currentTrackDict["title"] as? String {
					
					// rework this to make it better and not crash
					let tempString = title
//					let tempString = "Rock 2"
					if tempString.contains("-") {
						let separator = tempString.index(of: "-")!
						let artistSlice = tempString[..<separator]
						let afterSeparator = tempString.index(after: separator)
						let next = tempString.index(after: afterSeparator)
						let titleSlice = tempString.suffix(from: next)
						currentTrackTitle = String(titleSlice)
						currentTrackTitle = currentTrackTitle + "\n"
						currentTrackArtist = String(artistSlice)
					}
					else {
						currentTrackTitle = tempString
						currentTrackArtist = HomeScreenViewController.defaultTrackArtist
					}
				}
				else {
					currentTrackTitle = HomeScreenViewController.defaultTrackTitle
					currentTrackArtist = HomeScreenViewController.defaultTrackArtist
				}
				
//				let start_time = currentTrackDict["start_time"] as! String
				if currentTrackTitle == "Unknown" {
					currentTrackTitle = HomeScreenViewController.defaultTrackTitle
					currentTrackArtist = HomeScreenViewController.defaultTrackArtist
				}

				let titleAttributes: [NSAttributedStringKey : Any] = [
					NSAttributedStringKey.foregroundColor : UIColor.black,
					NSAttributedStringKey.font : UIFont(name: "SanFrancisco", size: CGFloat(30.0)) ?? UIFont.systemFont(ofSize: 30)
				]
				let displayString = NSMutableAttributedString.init(string: currentTrackTitle, attributes: titleAttributes)
				let artistAttributes = [
					NSAttributedStringKey.foregroundColor : UIColor.red,
					NSAttributedStringKey.font : UIFont(name: "SanFrancisco", size: CGFloat(20.0)) ?? UIFont.systemFont(ofSize: 20)
				]
				displayString.append(NSAttributedString.init(string: currentTrackArtist, attributes: artistAttributes))
				
				DispatchQueue.main.async {
					self.songLabel.attributedText = displayString
				}
				updateNowPlaying()
				
				if let artwork_url = currentTrackDict["artwork_url"] as? String,
					let artworkURL = URL.init(string: artwork_url) {
					let task = URLSession.shared.dataTask(with: artworkURL) { data, response, error in
						if let error = error {
							self.handleClientError(error)
							return
						}
						guard let httpResponse = response as? HTTPURLResponse,
							(200...299).contains(httpResponse.statusCode) else {
								self.handleServerError(response)
								return
						}
						
						if let data = data {
							let dataImage = UIImage.init(data: data)
							DispatchQueue.main.async {
								self.albumArtwork.image = dataImage
							}
						}
					}
					task.resume()
				}
				else {
					DispatchQueue.main.async {
						self.albumArtwork.image = HomeScreenViewController.defaultAlbumArtwork
					}
				}
			}
			else if dict.key == "history" {
//				let historyArray = dict.value as! [Any]
//				var songArray: [[String: Any]] = [[:]]
//				for track in historyArray {
////					print(track)
//					let x = track as! [String : Any]
//					let song = x["title"] as? String
//					print(song)
//					songArray.append(x)
//				}
//				print("test")
//				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "History"), object: nil, userInfo: dict.value as? [AnyHashable : Any])
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "History"), object: nil, userInfo: jsonData)
			}
		}
	}
	
	func updateNowPlaying() {
		// Set Metadata to be Displayed in Now Playing Info Center
		let playerRate = playerViewController?.player?.rate ?? 0.0
//		print("playerRate = \(String(describing: playerRate))")
		let infoCenter = MPNowPlayingInfoCenter.default()
		infoCenter.nowPlayingInfo = [MPMediaItemPropertyTitle: currentTrackTitle,
									 MPMediaItemPropertyArtist: currentTrackArtist,
									 MPNowPlayingInfoPropertyDefaultPlaybackRate: 1,
									 MPNowPlayingInfoPropertyPlaybackRate: playerRate
//									 MPMediaItemPropertyPersistentID: ???
//									 MPMediaItemPropertyAlbumTitle: "",
//									 MPMediaItemPropertyGenre: "",
//									 MPMediaItemPropertyReleaseDate: "",
//									 MPMediaItemPropertyPlaybackDuration: 231,
//									 MPMediaItemPropertyArtwork: mediaItemArtwork,
//									 MPNowPlayingInfoPropertyElapsedPlayback: 53,
//									 MPNowPlayingInfoPropertyPlaybackQueueCount: 13,
//									 MPNowPlayingInfoPropertyPlaybackQueueIndex: 3
		]
	}
	
	func handleClientError(_ error: Error) {
	}

	func handleServerError(_ response: URLResponse?) {
	}

	@objc func handleInterruption(notification: Notification) {
		guard let userInfo = notification.userInfo,
			let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
			let type = AVAudioSessionInterruptionType(rawValue: typeValue) else {
				return
		}
		guard let playerViewController = playerViewController else { return }
		if type == .began {
			// Interruption began, take appropriate actions
			if playerViewController.player?.rate == 1.0 {
				playerViewController.player?.pause()
			}
		}
		else if type == .ended {
			if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
				let options = AVAudioSessionInterruptionOptions(rawValue: optionsValue)
				if options.contains(.shouldResume) {
					// Interruption Ended - playback should resume
					if playerViewController.player?.rate == 0.0 {
						playerViewController.player?.play()
					}
				} else {
					// Interruption Ended - playback should NOT resume
				}
			}
		}
		updateNowPlaying()
	}
}

/**
Extend `AssetListTableViewController` to conform to the `AssetPlaybackDelegate` protocol.
*/
extension HomeScreenViewController: AssetPlaybackDelegate {
	func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager, playerReadyToPlay player: AVPlayer) {
		player.play()
		playerViewController?.player = player
		
		// setup properties for the AVPlayerViewController
		playerViewController?.allowsPictureInPicturePlayback = false
		playerViewController?.updatesNowPlayingInfoCenter = true
		playerViewController?.contentOverlayView?.backgroundColor = .white
//		playerViewController?.contentOverlayView?.layer.borderWidth = 1.0
		
		// setup the label
		let pvcWidth = Double((playerViewController?.contentOverlayView?.frame.width)!)
		let pvcHeight = Double((playerViewController?.contentOverlayView?.frame.height)!)
		let offsetX = 10.0
		let offsetY = pvcHeight - 125.0
		var rect = CGRect(x: offsetX, y: offsetY, width: pvcWidth - offsetX, height: 75.0)
		songLabel = UILabel.init(frame: rect)
		songLabel.text = ""
		songLabel.font = UIFont.systemFont(ofSize: 30.0)
		songLabel.numberOfLines = 2
		songLabel.lineBreakMode = .byTruncatingMiddle
		songLabel.textAlignment = .center
//		songLabel.textColor = .white
//		songLabel.backgroundColor = .red
		
		// album artwork image
		rect.origin.x = 0.0
		rect.origin.y = 5.0
		rect.size.width = CGFloat(pvcWidth / 2.0)
		rect.size.height = CGFloat(pvcHeight / 2.0)
		albumArtwork = UIImageView.init(frame: rect)
		albumArtwork.contentMode = .scaleAspectFit
		albumArtwork.center.x = (playerViewController?.contentOverlayView?.center.x)!
		
		playerViewController?.contentOverlayView?.addSubview(albumArtwork)
		playerViewController?.contentOverlayView?.addSubview(songLabel)
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PlayerStartedPlaying"), object: nil)
		
		// setup CarPlay Remote Command Events
		let commandCenter = MPRemoteCommandCenter.shared()
		commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
			if self.playerViewController?.player?.rate == 0.0 {
				self.playerViewController?.player?.play()
			}
			self.updateNowPlaying()
			return MPRemoteCommandHandlerStatus.success
		}
		
		commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
			if self.playerViewController?.player?.rate == 1.0 {
				self.playerViewController?.player?.pause()
			}
			self.updateNowPlaying()
			return MPRemoteCommandHandlerStatus.success
		}
	}
	
	func streamPlaybackManager(_ streamPlaybackManager: AssetPlaybackManager,
							   playerCurrentItemDidChange player: AVPlayer) {
		guard let playerViewController = playerViewController, player.currentItem != nil else { return }
		
		playerViewController.player = player
	}
}

