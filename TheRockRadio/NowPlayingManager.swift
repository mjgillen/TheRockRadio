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

//	override init() {
//		super.init()
//		NotificationCenter.default.addObserver(self, selector: #selector(updateNowPlaying), name: NSNotification.Name("MediaItemArtworkCompleted"), object: nil)
//	}

	func updateNowPlayingWith(title: String = Common.defaultTrackTitle, artist: String = Common.defaultTrackArtist, artWork: UIImage = Common.defaultNowPlayingAlbumArtwork, rate: Double = 0.0) {
		let albumArtwork = MPMediaItemArtwork.init(boundsSize: artWork.size, requestHandler: { (size) -> UIImage in
			loggingText = loggingText.add(string: "MPMediaItemArtwork requested size = \(size)")
			return artWork
		})
		
		let center = MPNowPlayingInfoCenter.default()
		center.nowPlayingInfo = [
			MPMediaItemPropertyTitle: title,
			MPMediaItemPropertyArtist: artist,
			MPNowPlayingInfoPropertyPlaybackRate: rate,
			MPMediaItemPropertyArtwork: albumArtwork,
//			MPNowPlayingInfoPropertyIsLiveStream: NSNumber(booleanLiteral: true),
			MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
		]
	}
	
//	// Set Metadata to be Displayed in Now Playing Info Center
//	@objc func updateNowPlaying(notification: NSNotification) {
//		loggingText = loggingText.add(string: "updateNowPlaying")
//		let albumArtwork = notification.userInfo!["image"] as! UIImage
//		let nowPlayingInfo: [String: Any] = [MPMediaItemPropertyTitle: trackTitle,
//											 MPMediaItemPropertyArtist: trackArtist,
//											 MPNowPlayingInfoPropertyPlaybackRate: playerRate,
//											 MPMediaItemPropertyArtwork: albumArtwork,
//											 ]
//		MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
//	}
}
