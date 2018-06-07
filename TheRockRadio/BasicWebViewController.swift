//
//  BasicWebViewController.swift
//

import Foundation
import WebKit
import MessageUI

open class BasicWebViewController: UIViewController, WKNavigationDelegate {
    let webView = WKWebView()
//    let toolbar = UIToolbar()
    let progressSpinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
//    var webBack: UIBarButtonItem!
//    var webForward: UIBarButtonItem!
	
    open var hasNavBtns: Bool = false
    open var webTitle: String?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
//        self.tabBarController?.tabBar.isHidden = true
//        self.navigationController?.navigationBar.isTranslucent = false
		
        // Web View
        self.webView.frame = CGRect(x: 0,
                                    y: 0,
                                    width: view.frame.width,
                                    height: view.frame.height) // - 40
        self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.webView.navigationDelegate = self
//        self.webView.evaluateJavaScript("document.body.style.webkitTouchCallout='none';", completionHandler: nil)
		
        // Toolbar Progress spinner
        progressSpinner.frame = CGRect(x: 0,
                                       y: 0,
                                       width: 30,
                                       height: 30)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: progressSpinner)
        
        // Toolbar btns
//        self.webBack = UIBarButtonItem(barButtonSystemItem: .rewind, target: self, action: #selector(self.webBackBtnPressed(sender:)))
//        self.webForward = UIBarButtonItem(barButtonSystemItem: .fastForward, target: self, action: #selector(self.webForwardBtnPressed(sender:)))
		
        // Toolbar
//        toolbar.frame = CGRect(x: 0,
//                               y: view.frame.height - 44,
//                               width: view.frame.width,
//                               height: 44)
//        toolbar.autoresizingMask = [.flexibleTopMargin,
//                                    .flexibleRightMargin,
//                                    .flexibleWidth]
//        toolbar.items = [self.webBack, self.webForward]
		
        
        // Add all Views
        view.backgroundColor = UIColor.white
        view.addSubview(webView)
//        if hasNavBtns {
//            view.addSubview(toolbar)
//        }
		
        self.title = webTitle
//        self.navigationItem.title = webTitle
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
//        self.tabBarController?.tabBar.isHidden = false
    }
    
//    override open var prefersStatusBarHidden: Bool {
//        return false
//    }
	
    @objc func webBackBtnPressed(sender: UIBarButtonItem) {
        self.webView.goBack()
    }
    
    @objc func webForwardBtnPressed(sender: UIBarButtonItem) {
        self.webView.goForward()
    }
    
//    func updateWebNavButtons() {
//        if self.webView.canGoBack {
//            self.webBack.tintColor = UIColor.black
//        } else {
//            self.webBack.tintColor = UIColor.clear
//        }
//
//        if self.webView.canGoForward {
//            self.webForward.tintColor = UIColor.black
//        } else {
//            self.webForward.tintColor = UIColor.clear
//        }
//    }
//
//    func addDoneButton() {
//        let backItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.doneButtonAction))
//        self.navigationItem.leftBarButtonItem = backItem
//    }
//
//    @objc func doneButtonAction() {
//        self.dismiss(animated: true, completion: nil)
//    }
	
    // MARK: Web Loading and Delegates
    open func loadURL(url: String) {
        guard let webUrl = URL(string: url) else { return }
        self.webView.load(URLRequest(url: webUrl))
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        progressSpinner.startAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        progressSpinner.stopAnimating()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
//        webView.evaluateJavaScript("document.body.style.webkitTouchCallout='none';", completionHandler: nil)
//        webView.evaluateJavaScript("document.body.style.webkitUserSelect='none';", completionHandler: nil)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
        progressSpinner.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard
            let scheme = navigationAction.request.url?.scheme,
            let url = navigationAction.request.url,
            UIApplication.shared.canOpenURL(url) else {
                decisionHandler(.allow)
                return
        }
        
        switch scheme {
        case "tel",
             "mailto":
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        default:
            decisionHandler(.allow)
        }
    }
}
