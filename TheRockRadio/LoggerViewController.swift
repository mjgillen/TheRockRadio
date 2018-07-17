//
//  LoggerViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 5/27/18.
//  Copyright © 2018 Estero Bay Community Radio. All rights reserved.
//

import UIKit

class LoggerViewController: UIViewController {
	
	@IBOutlet weak var scrollView: UIScrollView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
//		self.scrollView.addSubview(loggingLabel)
//		loggingLabel.numberOfLines = 0
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func viewDidLayoutSubviews() {
//		loggingLabel.frame = self.view.frame
		scrollView.contentSize = CGSize(width: self.view.frame.width, height: 10000)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }    
}
