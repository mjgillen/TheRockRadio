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

//	@IBOutlet weak var rssTitle: UILabel!
//	@IBOutlet weak var rssDate: UILabel!
//	@IBOutlet weak var rssDescription: UILabel!
	
	
	@IBOutlet weak var rssWebView: WKWebView!
	
	var rssData = rssCell()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.title = rssData.title
//		print("\n----------------------------------------------------------------------- >>> \(rssData.link)\n")
		
		let urlString = rssData.link.replacingOccurrences(of: " |\n", with: "", options: .regularExpression)
		guard let rssURL = URL(string: urlString) else { return }
		let request = URLRequest(url: rssURL)
		rssWebView.allowsBackForwardNavigationGestures = true
		rssWebView.load(request)
		
//		rssTitle.text = rssData.title
//		rssDate.text = rssData.pubDate
//		rssDescription.text = rssData.description
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
