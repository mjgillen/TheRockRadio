//
//  RockPageViewController.swift
//  TheRockRadio
//
//  Created by Michael Gillen on 4/28/18.
//  Copyright © 2018 On The Move Software. All rights reserved.
//

import UIKit

class RockPageViewController: UIPageViewController {

	private(set) lazy var orderedViewControllers: [UIViewController] = { // Website RecentlyPlayed Logger
		return [
			self.newViewControllerWith(name: "Logger"),
			self.newViewControllerWith(name: "Website"),
			self.newViewControllerWith(name: "RSS"),
			self.newViewControllerWith(name: "RecentlyPlayed")
		]
	}()
	
	private func newViewControllerWith(name: String) -> UIViewController {
		return UIStoryboard(name: "Main", bundle: nil) .
			instantiateViewController(withIdentifier: "\(name)ViewController")
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
		
		if let firstViewController = orderedViewControllers.first {
			setViewControllers([firstViewController],
							   direction: .forward,
							   animated: true,
							   completion: nil)
		}    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: UIPageViewControllerDataSource

extension RockPageViewController: UIPageViewControllerDataSource {
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		
		guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else { return nil }
		
		let previousIndex = viewControllerIndex - 1
		
		guard previousIndex >= 0 else {
			return orderedViewControllers.last
		}
		
		guard orderedViewControllers.count > previousIndex else { return nil }
		
		return orderedViewControllers[previousIndex]
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
			return nil
		}
		
		let nextIndex = viewControllerIndex + 1
		let orderedViewControllersCount = orderedViewControllers.count
		
		guard orderedViewControllersCount != nextIndex else {
			return orderedViewControllers.first
		}
		
		guard orderedViewControllersCount > nextIndex else { return nil }
		
		return orderedViewControllers[nextIndex]
	}
	
	func presentationCount(for pageViewController: UIPageViewController) -> Int {
		return orderedViewControllers.count
	}
	
	func presentationIndex(for pageViewController: UIPageViewController) -> Int {
		guard let firstViewController = viewControllers?.first,
			let firstViewControllerIndex = orderedViewControllers.index(of: firstViewController) else {
				return 0
		}
		return firstViewControllerIndex
	}
}
