//
//  LoggerViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 5/27/18.
//  Copyright © 2018 paradigm-performance. All rights reserved.
//

import UIKit

class LoggerViewController: UIViewController {
	
	@IBOutlet weak var scrollView: UIScrollView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
//		self.localLogLabel.text = loggingText
//		self.localLogLabel = loggingLabel
//		self.localLogLabel.addObserver(self, forKeyPath: "text", options: [.new], context: nil)
//		loggingLabel.frame = self.view.frame
		self.scrollView.addSubview(loggingLabel)
//		self.scrollView.bringSubview(toFront: loggingLabel)
		loggingLabel.numberOfLines = 0
//		scrollView.contentSize = CGSize(1000)

        // Do any additional setup after loading the view.
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func viewDidLayoutSubviews() {
//		var newFrame = self.view.frame
//		newFrame.size.height = 1000
//		loggingLabel.frame = newFrame
		loggingLabel.frame = self.view.frame
		scrollView.contentSize = CGSize(width: self.view.frame.width, height: 10000)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//
//		if keyPath == "text" {
//			self.localLogLabel.layoutIfNeeded()
//		}
//	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
