//
//  RSSDetailsViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 6/2/18.
//  Copyright © 2018 On The Move Software. All rights reserved.
//

import UIKit
import WebKit

class RSSDetailsViewController: UIViewController {

	@IBOutlet weak var rssWebView: WKWebView!
	
	var rssData = rssCell()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.title = rssData.title
		
		let urlString = rssData.link.replacingOccurrences(of: " |\n", with: "", options: .regularExpression)
		guard let rssURL = URL(string: urlString) else { return }
		let request = URLRequest(url: rssURL)
		rssWebView.allowsBackForwardNavigationGestures = true
		rssWebView.load(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
