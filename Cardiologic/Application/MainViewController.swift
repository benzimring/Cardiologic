//
//  MainViewController.swift
//  Cardiologic
//  Dashboard of live heart rate and today's stats
//
//  Created by Ben Zimring on 6/20/18.
//  Copyright © 2018 pulseApp. All rights reserved.
//

import UIKit
import HealthKit
import Lottie

class MainViewController: UIViewController {
    
    let hkm = HealthKitManager()
    
    // outlets
    @IBOutlet weak var watchWarningLabel: UILabel!
    @IBOutlet weak var liveHeart: UIImageView!
    @IBOutlet weak var liveHeartRateLabel: AnimatedLabel!
    @IBOutlet weak var timeSinceLiveHRLabel: UILabel!
    @IBOutlet weak var maxHRLabel: UILabel!
    @IBOutlet weak var minHRLabel: UILabel!
    @IBOutlet weak var avgHRLabel: UILabel!
    @IBOutlet weak var restHRLabel: UILabel!
    @IBOutlet weak var hasWorkedOutLabel: UILabel!
    @IBOutlet weak var numStepsLabel: UILabel!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var refreshAnimationView: LOTAnimationView!
    @IBOutlet weak var explosionAnimationView: LOTAnimationView!
    
    var heartRate = -1
    var mostRecentTime: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if hkm.isHealthDataAvailable() {
            requestAuthorization()
        }
        updateDateLabel()
        setGreetingLabel()
        liveHeartRateLabel.alpha = 0
        watchWarningLabel.alpha = 0
        refreshAnimationView.setAnimation(named: "refresh_animation")
        refreshAnimationView.play()
        
        explosionAnimationView.setAnimation(named: "explosion_animation")
        explosionAnimationView.animationSpeed = 0.4
        
        // refresh to get most recent data
        if hkm.isHealthDataAvailable() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.requestAuthorization()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if liveHeartRateLabel.alpha == 0 { return }
        
        if self.heartRate != -1 {
            // delayed refresh to gather most recent data
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.requestAuthorization()
            }
            self.animateHeart()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    func updateDateLabel() {
        if mostRecentTime != nil {
            DispatchQueue.main.async {
                UIView.transition(with: self.timeSinceLiveHRLabel, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    self.timeSinceLiveHRLabel.text = self.strTimeSince(self.mostRecentTime!)
                })
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.updateDateLabel()
        }
    }
    
    @IBAction func didTouchRefreshButton(_ sender: Any) {
        refreshAnimationView.play()
        requestAuthorization()
    }

    @IBAction func didTouchWorkoutButton(_ sender: Any) {
//        if let workoutsViewController = storyboard?.instantiateViewController(withIdentifier: "WorkoutsViewController") {
//            present(workoutsViewController, animated: true)
//        }
    }
}

// MARK: - HealthKit functions
extension MainViewController {
    
    /* query HealthKit for today's HR data */
    func getDayHR() {
        print("getDayHeartRate")
        let calendar = Calendar.current
        
        // create 1-day range
        let today = calendar.startOfDay(for: Date())
        hkm.heartRate(from: today, to: Date()) { (results) in
            if results.isEmpty {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 4, animations: {
                        self.watchWarningLabel.alpha = 1
                    })
                }
            } else {
                self.processDayHR(results)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 120, execute: {
            self.getDayHR()
        })
    }
    
    func processDayHR(_ results: [HKQuantitySample]) {       
        // average
        var total = 0.0
        var max = 0.0
        var min = 230.0
        for result in results {
            let hr = result.quantity.doubleValue(for: .heartRateUnit)
            if hr > max { max = hr }
            if hr < min { min = hr }
            total += result.quantity.doubleValue(for: .heartRateUnit)
        }
        let average = Int(total)/results.count
        
        // most recent
        let lastIndex = results.count - 1
        let lastMeasurement = results[lastIndex]
        let newHeartRate = Int(lastMeasurement.quantity.doubleValue(for: .heartRateUnit))
        DispatchQueue.main.async {
            if self.watchWarningLabel.alpha == 1 {
                UIView.animate(withDuration: 0.2, animations: {
                    self.watchWarningLabel.alpha = 0
                })
            }
            
            if self.heartRate == -1 {
                // just opened, animate from low
                self.heartRate = 30
                UIView.animate(withDuration: 1, animations: {
                    self.liveHeartRateLabel.alpha = 1
                })
            }
            
            if self.heartRate == newHeartRate {
                // no explosion if HR didn't change
                self.liveHeartRateLabel.completion = nil
            } else {
                self.liveHeartRateLabel.completion = {
                    self.explosionAnimationView.play()
                }
            }
            
            self.maxHRLabel.text = String(Int(max))
            self.minHRLabel.text = String(Int(min))
            self.avgHRLabel.text = String(average)
            
            self.liveHeartRateLabel.countingMethod = .easeOut
            self.liveHeartRateLabel.count(from: Float(self.heartRate), to: Float(newHeartRate))
            self.timeSinceLiveHRLabel.text = self.strTimeSince(lastMeasurement.startDate)
            self.heartRate = newHeartRate
            self.mostRecentTime = lastMeasurement.startDate
            self.animateHeart()
        }
    }
    
    /* query HealthKit for resting HR data */
    func getDayRHR() {
        print("getDayRHR")
        
        // samples from today
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: Date())
        hkm.restingHeartRate(from: startDay, to: Date()) { (results) in
            if results.isEmpty {
                NSLog("no RHR samples")
                DispatchQueue.main.async {
                    self.restHRLabel.text = "--"
                }
                return
            } else {
                // found sample(s)
                DispatchQueue.main.async {
                    self.processDayRHR(results)
                }
            }
        }
        
    }
    
    func processDayRHR(_ results: [HKQuantitySample]) {
        let idx = results.count-1
        let RHR = results[idx].quantity.doubleValue(for: .heartRateUnit)
        restHRLabel.text = "\(Int(RHR))"
    }
    
    /* query HealthKit for workout data */
    func getDayWorkouts() {
        
        // workouts from today
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: Date())
        
        hkm.workouts(from: startDay, to: Date()) { (results) in
            DispatchQueue.main.async {
                self.processDayWorkouts(results)
            }
        }
    }
    
    func processDayWorkouts(_ results: [HKWorkout]) {
        switch results.count {
        case 0:
            self.hasWorkedOutLabel.text = "You haven't logged\nany workouts yet."
        case 1:
            self.hasWorkedOutLabel.text = "You have 1 workout\nlogged today."
        default:
            self.hasWorkedOutLabel.text = "You have \(results.count) workouts\nlogged today."
        }
    }
    
    /* query HealthKit for step data */
    func getDaySteps() {
        // steps from today
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        
        // HealthKit query
        hkm.dailySteps { (results) in
            results.enumerateStatistics(from: startDate, to: Date()) { statistics, stop in
                if let sum = statistics.sumQuantity() {
                    DispatchQueue.main.async {
                        self.processDaySteps(sum.doubleValue(for: .count()))
                    }
                } else {
                    DispatchQueue.main.async {
                        self.processDaySteps(0)
                    }
                }
            }
        }
    }
    
    func processDaySteps(_ sum: Double) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        let steps = NSNumber(value: Int(sum))
        switch steps {
        case 0:
            self.numStepsLabel.text = "You haven't taken\nany steps yet today."
        default:
            self.numStepsLabel.text = "You've taken\n\(formatter.string(from: steps)!) steps today."
        }
    }
    
    /* HealthKit auth */
    func requestAuthorization() {
        let readingTypes:Set<HKObjectType> = [.heartRateType,
                                              .restingHeartRateType,
                                              .workoutType,
                                              .stepsType,
                                              .variabilityType,
                                              .genderType,
                                              .weightType,
                                              .heightType,
                                              .dateOfBirthType]
        
        // auth request
        hkm.requestAuthorization(readingTypes: readingTypes, writingTypes: nil) {
            DispatchQueue.main.async {
                self.getDayHR()
                self.getDayRHR()
                self.getDayWorkouts()
                self.getDaySteps()
                self.setGreetingLabel()
            }
            print("auth success")
        }
    }
}

// MARK: - misc functions
extension MainViewController {
    /* time-based greeting label */
    func setGreetingLabel() {
        if let name = UserDefaults.standard.string(forKey: "userName") {
            let hour = Calendar.current.component(.hour, from: Date())
            DispatchQueue.main.async {
                switch hour {
                case 0..<12:
                    self.greetingLabel.text = "Good morning, \(name)!"
                case 12..<17:
                    self.greetingLabel.text = "Good afternoon, \(name)!"
                default:
                    self.greetingLabel.text = "Good evening, \(name)!"
                }
            }
        }
    }
    
    /* heart animation settings */
    func animateHeart() {
        if heartRate == -1 { return }
        liveHeart.layer.removeAnimation(forKey: "pulse")
        liveHeartRateLabel.layer.removeAnimation(forKey: "pulse")
        liveHeart.tintColor = UIColor.heartColor
        
        let pulse1 = CASpringAnimation(keyPath: "transform.scale")
        pulse1.duration = 0.1
        pulse1.fromValue = 1.0
        pulse1.toValue = 0.95
        pulse1.autoreverses = true
        pulse1.repeatCount = 1
        pulse1.initialVelocity = 1
        pulse1.damping = 1
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = 60.0/Double(heartRate)
        animationGroup.repeatCount = Float(Int.max)
        animationGroup.animations = [pulse1]
        
        liveHeart.layer.add(animationGroup, forKey: "pulse")
        liveHeartRateLabel.layer.add(animationGroup, forKey: "pulse")
    }
    
    /* pretty print time since last HR measurement */
    func strTimeSince(_ date: Date) -> String {
        let interval = DateInterval(start: date, end: Date())
        switch interval.duration {
        case 0..<60:
            if Int(interval.duration) == 0 {
                return "just now"
            } else if interval.duration < 2 {
                // display seconds
                return "\(Int(interval.duration)) second ago"
            } else {
                return "\(Int(interval.duration)) seconds ago"
            }
        case 60..<3600:
            if interval.duration < 120 {
                return "\(Int(interval.duration/60)) minute ago"
            } else {
                return "\(Int(interval.duration/60)) minutes ago"
            }
        default:
            // display hours
            if interval.duration < 7200 {
                return "\(Int(interval.duration/3600)) hour ago"
            } else {
                return "\(Int(interval.duration/3600)) hours ago"
            }
        }
    }
    
    
}
