//
//  NowPlayingManager.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 6/26/18.
//  Copyright © 2018 paradigm-performance. All rights reserved.
//

import UIKit
import MediaPlayer

class NowPlayingManager: NSObject {

	var trackTitle = Common.defaultTrackTitle
	var trackArtist = Common.defaultTrackArtist
	var albumArtwork: MPMediaItemArtwork?
	var playerRate = 0.0
	
	override init() {
		super.init()
		NotificationCenter.default.addObserver(self, selector: #selector(updateNowPlaying), name: NSNotification.Name("MediaItemArtworkCompleted"), object: nil)
	}

	func updateNowPlayingWith(title: String, artist: String, artWork: UIImage, rate: Double = 0.0) {
		trackTitle = title
		trackArtist = artist
		playerRate = rate
		albumArtwork = MPMediaItemArtwork.init(boundsSize: artWork.size, requestHandler: { (size) -> UIImage in
			
			let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
			UIGraphicsBeginImageContext(size)
			Common.defaultAlbumArtwork.draw(in: rect)
			let newImage = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			NotificationCenter.default.post(name: NSNotification.Name("MediaItemArtworkCompleted"), object: self, userInfo: ["image" : newImage!])
			return newImage!
		})
	}
	
	// Set Metadata to be Displayed in Now Playing Info Center
	@objc func updateNowPlaying(notification: NSNotification) {
//		loggingText = loggingText.add(string: "updateNowPlaying")
		let albumArtwork = notification.userInfo!["image"] as! UIImage
		let nowPlayingInfo: [String: Any] = [MPMediaItemPropertyTitle: trackTitle,
											 MPMediaItemPropertyArtist: trackArtist,
											 MPNowPlayingInfoPropertyPlaybackRate: playerRate,
											 MPMediaItemPropertyArtwork: albumArtwork,
											 ]
		MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
	}
}
