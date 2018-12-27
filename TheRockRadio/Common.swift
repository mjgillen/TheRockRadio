//
//  Common.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 5/28/18.
//  Copyright © 2018 Estero Bay Community Radio. All rights reserved.
//

import UIKit
import MediaPlayer
class Common: NSObject {
	
	static let defaultTrackTitle = "97.3 / 107.9 The Rock"
	static let defaultTrackArtist = "KEBF/KZSR"
	static let defaultAlbumArtwork: UIImage = #imageLiteral(resourceName: "RockLogo")
	static let defaultNowPlayingAlbumArtwork: UIImage = #imageLiteral(resourceName: "NowPlayingIcon")
	static let streamingURL = "https://streaming.radio.co/s96fbbec3a/listen"
	static let playlistURL = "https://public.radio.co/stations/s96fbbec3a/status"
	
	// Google Ads
	static let productionGoogleAdID = "ca-app-pub-6955767719823909~7822178760"
	static let testGoogleAdID = "ca-app-pub-3940256099942544/2934735716"

	class func updateNowPlaying() {
//		loggingText = loggingText.add(string: "updateNowPlaying CALLED")
		let artwork = MPMediaItemArtwork.init(boundsSize: albumArtwork.size, requestHandler: { (size) -> UIImage in
//			loggingText = loggingText.add(string: "updateNowPlaying IN BLOCK")
			return albumArtwork
		})

		let center = MPNowPlayingInfoCenter.default()
		center.nowPlayingInfo = [
			MPMediaItemPropertyTitle: trackTitle,
			MPMediaItemPropertyArtist: trackArtist,
			MPNowPlayingInfoPropertyPlaybackRate: playerRate,
			MPMediaItemPropertyArtwork: artwork,
//			MPNowPlayingInfoPropertyIsLiveStream: NSNumber(booleanLiteral: true),
			MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
		]
	}
}
