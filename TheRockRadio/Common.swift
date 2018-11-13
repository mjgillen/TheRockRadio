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
	
	static let defaultTrackTitle = "c89.5 SEATTLE'S HOME FOR DANCE"
	static let defaultTrackArtist = "KNHC Public Radio"
	static let defaultAlbumArtwork: UIImage = #imageLiteral(resourceName: "c895Logo")
	static let defaultNowPlayingAlbumArtwork: UIImage = #imageLiteral(resourceName: "c895Logo")
	static let streamingURL = "http://streams.c895.org/live.m3u"
	static let playlistURL = "https://public.radio.co/stations/s96fbbec3a/status"

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
