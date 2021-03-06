//
//  ViewController.swift
//  SHFEILI
//
//  Created by Nemo on 7/11/18.
//  Copyright © 2018 Sijie Tan. All rights reserved.
//

import UIKit
import UICircularProgressRing


class ViewController: UIViewController {
    
    @IBOutlet weak var progressBar: UICircularProgressRing!
    
    var work = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let isUserLoggedIn = UserDefaults.standard.bool(forKey: "isUserLoggedIn");
        progressBar.innerRingColor = UIColor.brown
        progressBar.outerRingColor = UIColor.purple
        progressBar.maxValue = 100
        if (!isUserLoggedIn) {
            performSegue(withIdentifier: "showLogin", sender: self)
        } 
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        startTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopTimer()
    }
    
    @IBAction func stopProgress(_ sender: Any) {
        NetworkUtils.post(endpoint: "/api/stop_testing/", inputData:[:]) {
            (dictionary) in
            let stopped = dictionary?["stop"] as! Bool
            if (stopped) {
                Utils.displayMessage(title: "Success", userMessage: "Success stop testing", view: self, handler: nil)
            } else {
                Utils.displayMessage(title: "Error", userMessage: "Cannot stop testing, please check admin right and system status", view: self, handler: nil)
            }
        }
    }
    
    @IBAction func logout(_ sender: Any) {
        NetworkUtils.deleteAllCookies()
        let domain = Bundle.main.bundleIdentifier!;
        UserDefaults.standard.removePersistentDomain(forName: domain);
        UserDefaults.standard.synchronize();
        performSegue(withIdentifier: "showLogin", sender: self)
    }
    
    func updateUI(totalScheduled: String, totalTested: String, working: Bool, completionHandler: (() -> Void)? = nil) {
        if (working) {
            if (totalScheduled == "-1") {
                if progressBar.isAnimating {
                    progressBar.pauseProgress()
                }
                progressBar.startProgress(to: UICircularProgressRing.ProgressValue(100), duration: UICircularProgressRing.ProgressDuration(0.1))
            } else {
                let s = Float(totalScheduled)
                let t = Float(totalTested)
                let value = Float(t!/s!)
                if progressBar.isAnimating {
                    progressBar.pauseProgress()
                }
                progressBar.startProgress(to: UICircularProgressRing.ProgressValue(value * 100), duration: UICircularProgressRing.ProgressDuration(0.1))
            }
        } else {
            progressBar.value = 0
        }
        if (completionHandler != nil) {
            completionHandler!()
        }
    }
    
    func loadProgress() {
        if UserDefaults.standard.bool(forKey: "isUserLoggedIn") {
            NetworkUtils.get(endpoint: "/api/system_status_brief/") {
                (dictionary) in
                let working = dictionary?["working"] as! Bool
                if (working) {
                    self.work = true
                    let totalScheduled = dictionary?["totalScheduled"] as! String
                    let totalTested = dictionary?["totalTested"] as! String
                    self.updateUI(totalScheduled: totalScheduled, totalTested: totalTested,
                                  working: true, completionHandler: nil)
                } else {
                    if (self.work) {
                        self.updateUI(totalScheduled: "-1", totalTested: "-1", working: true) {
                            self.work = false
                            Utils.displayMessage(title: "Finished", userMessage: "Running finished",
                                                 view: self, handler: nil)
                        }
                    }
                    self.updateUI(totalScheduled: "0", totalTested: "0", working: false, completionHandler: nil)
                }
            }
        }
    }
    
    var timer: DispatchSourceTimer?
    
    func startTimer() {
        //https://stackoverflow.com/questions/25951980/do-something-every-x-minutes-in-swift
        let queue = DispatchQueue(label: "com.domain.app.timer")  // you can also use `DispatchQueue.main`, if you want
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer!.scheduleRepeating(deadline: .now(), interval: .seconds(2))
        timer!.setEventHandler { [weak self] in
            self?.loadProgress()
        }
        timer!.resume()
    }
    
    func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    deinit {
        self.stopTimer()
    }
    
}

