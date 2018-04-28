//
//  InfoViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 3/17/18.
//  Copyright © 2018 paradigm-performance. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

	@IBOutlet weak var titleHistory: UILabel!
	//	@IBOutlet weak var titleLabel: UILabel!
	override func viewDidLoad() {
        super.viewDidLoad()

        self.view.layer.borderWidth = 1.0
		NotificationCenter.default.addObserver(self, selector: #selector(InfoViewController.handleNotification), name: NSNotification.Name(rawValue: "History"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@objc func handleNotification(notification: NSNotification) {
		guard let historyDict = notification.userInfo as? [String: Any] else { return }

		var titleAttributes: [NSAttributedStringKey : Any] = [
			NSAttributedStringKey.foregroundColor : UIColor.black,
			NSAttributedStringKey.font : UIFont(name: "SanFrancisco", size: CGFloat(25.0)) ?? UIFont.systemFont(ofSize: 25)
		]
		let playlist = NSMutableAttributedString.init(string: "Recently Played\n", attributes: titleAttributes)
		titleAttributes[NSAttributedStringKey.font] = UIFont(name: "SanFrancisco", size: CGFloat(18.0)) ?? UIFont.systemFont(ofSize: 18)
		titleAttributes[NSAttributedStringKey.foregroundColor] = UIColor.blue
		for dict in historyDict {
			if dict.key == "history" {
				let historyArray = dict.value as! [Any]
				for track in historyArray {
					let x = track as! [String : Any]
					var song = x["title"] as! String
					if !song.contains("KEBF") {
						song = song + "\n"
						playlist.append(NSAttributedString.init(string: song, attributes: titleAttributes))
					}
				}
			}
		}
		DispatchQueue.main.async {
			self.titleHistory.attributedText = playlist
		}
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
