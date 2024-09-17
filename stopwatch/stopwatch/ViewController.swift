//
//  ViewController.swift
//  stopwatch
//
//  Created by BAN367115 on 01/09/24.
//

import UIKit
import Foundation
import UserNotifications

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var msLabel: UILabel!
    @IBOutlet weak var startPauseBtn: UIButton!
    @IBOutlet weak var resetBtn: UIButton!
    @IBOutlet weak var precisionSpinner: UIPickerView!
    
    let notificationCenter = UNUserNotificationCenter.current()
    let identifier = UUID().uuidString
    
    var timer = Timer()
    var timerBG = Timer()
    var precisionValues = ["Seconds", "Milliseconds"]
    var setPrecision = "Seconds"
    var hours = 0
    var minutes = 0
    var seconds = 0
    var milliseconds = 0
    var isCounting = false
    var startTime: Date?
    var stopTime: Date?
    
    let userDefaults = UserDefaults.standard
    let START_KEY = "startTime"
    let STOP_KEY = "stopTime"
    let COUNTING_KEY = "countingKey"
    
    override func viewWillAppear(_ animated: Bool) {
        if isCounting {
            isCounting = false
            setTimerCounting(val: isCounting)
        }
        timerLabel.text = "00:00:00"
        msLabel.isHidden = true
        msLabel.text = ".000"
        startPauseBtn.setTitle("Start", for: .normal)
        resetBtn.setTitle("Reset", for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Stopwatch"
        self.precisionSpinner.delegate = self
        self.precisionSpinner.dataSource = self
        
        startTime = userDefaults.object(forKey: START_KEY) as? Date
        stopTime = userDefaults.object(forKey: STOP_KEY) as? Date
        isCounting = userDefaults.bool(forKey: COUNTING_KEY)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return precisionValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return precisionValues[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        setPrecision = precisionValues[row]
        
        if setPrecision == "Seconds" {
            msLabel.isHidden = true
        } else {
            msLabel.isHidden = false
        }
    }
    
    func setStartTime(date: Date?) {
        startTime = date
        userDefaults.setValue(startTime, forKey: START_KEY)
    }
    
    func setStopTime(date: Date?) {
        stopTime = date
        userDefaults.setValue(stopTime, forKey: STOP_KEY)
    }
    
    func setTimerCounting(val: Bool) {
        isCounting = val
        userDefaults.setValue(isCounting, forKey: COUNTING_KEY)
    }
    
    @IBAction func startPauseTapped(_ sender: Any) {
        if (isCounting) {
            isCounting = false
            timer.invalidate()
            startPauseBtn.setTitle("Start", for: .normal)
            setTimerCounting(val: isCounting)
        } else {
            isCounting = true
            startPauseBtn.setTitle("Pause", for: .normal)
            timer = Timer.scheduledTimer(timeInterval: 0.002, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
            setTimerCounting(val: isCounting)
        }
    }
    
    @IBAction func resetTapped(_ sender: UIButton?) {
        if (isCounting) {
            isCounting = false
            timer.invalidate()
            startPauseBtn.setTitle("Start", for: .normal)
            timerLabel.text = "00:00:00"
            msLabel.text = ".000"
            hours = 0
            minutes = 0
            seconds = 0
            milliseconds = 0
            precisionSpinner.selectedRow(inComponent: 0)
            setTimerCounting(val: isCounting)
        } else {
            timer.invalidate()
            timerLabel.text = "00:00:00"
            msLabel.text = ".000"
            hours = 0
            minutes = 0
            seconds = 0
            milliseconds = 0
            precisionSpinner.selectedRow(inComponent: 0)
        }
    }
    
    @objc func timerCounter() {
        timerLabel.text = timeCount().0
        msLabel.text = timeCount().1
    }
    
    @objc func appMovedToBackground() {
        if isCounting {
            setStopTime(date: Date())
            dispatchNotification(body: "App is Running in Background", interval: 1, identifier: "appInBG", categoryId: "CUSTOM")
            dispatchNotification(body: "The app is in background for 10 Minute. Timer will reset after 5 more Minutes", interval: 600, identifier: "10min", categoryId: "STANDARD")
        }
    }
    
    @objc func appMovedToForeground() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        if isCounting {
            setStartTime(date: Date())
            let diff = startTime?.timeIntervalSince(stopTime!)
            let roundedDiff = String(round(diff! * 1000)/1000.0)
            let splitDiff = roundedDiff.split(separator: ".")
            if (Int(splitDiff[0])! % 3600)/60 >= 15 {
                resetTapped(nil)
            } else {
                refreshValue()
            }
        }
    }
    
    func refreshValue() {
        let diff = startTime?.timeIntervalSince(stopTime!)
        let roundedDiff = String(round(diff! * 1000)/1000.0)
        let splitDiff = roundedDiff.split(separator: ".")
        let ms = milliseconds + Int(splitDiff[1])!
        if ms >= 999 {
            milliseconds = ms - 999
            seconds += 1
        } else {
            milliseconds += ms
        }
        let sec = seconds + (Int(splitDiff[0])! % 3600)%60
        if sec >= 60 {
            seconds = sec - 60
            minutes += 1
        } else {
            seconds += sec
        }
        let min = minutes + (Int(splitDiff[0])! % 3600)/60
        if min >= 60 {
            minutes = min - 60
            hours += 1
        } else {
            minutes += min
        }
        hours += Int(splitDiff[0])!/3600
    }
    
    func timeCount() -> (String, String) {
        var timeString = ""
        var msString = ""
        
        self.milliseconds += 1
        
        if milliseconds > 999 {
            seconds += 1
            self.milliseconds = 0
        }
        
        if seconds == 60 {
            minutes += 1
            seconds = 0
        }
        
        if minutes == 60 {
            hours += 1
            minutes = 0
        }
    
        timeString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        if milliseconds < 100 {
            msString = String(".0\(milliseconds)")
        } else {
            msString = String(".\(milliseconds)")
        }
        
        return (timeString, msString)
    }
        
    func dispatchNotification(body: String, interval: Double, identifier: String, categoryId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Stopwatch"
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryId
        //content.userInfo = ["value":"Trial"]
        let dateComp = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date().addingTimeInterval(TimeInterval(interval)))
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComp, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        self.notificationCenter.add(request) { (error) in
            if (error != nil) {
                print(error.debugDescription)
                return
            }
        }
    }
}

