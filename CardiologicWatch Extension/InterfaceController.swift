//
//  InterfaceController.swift
//  watch Extension
//
//  Created by Ben Zimring on 5/14/18.
//  Copyright © 2018 pulseApp. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation
import HealthKit


class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {

    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    @IBOutlet var ecgImage: WKInterfaceImage!
    @IBOutlet var button: WKInterfaceButton!
    
    let healthStore = HKHealthStore()
    let heartRateUnit = HKUnit(from: "count/min")
    let heartRateSampleType = HKObjectType.quantityType(forIdentifier: .heartRate)
    let workoutConfiguration = HKWorkoutConfiguration()
    
    var workoutActive = false
    var session: HKWorkoutSession?
    var currentQuery: HKQuery?
    var heartRate: Double = -1
    
    override init() {
        // This method runs FIRST at runtime
        print("interfaceController: init")
        super.init()
        let wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
        
        workoutConfiguration.activityType = .mixedCardio
        workoutConfiguration.locationType = .indoor
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        heartRateLabel.setText("--")
        ecgImage.setImageNamed("ecg_red-")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        guard HKHealthStore.isHealthDataAvailable() == true else { return }
        print("health data avail")
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        print("quantityType init")
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) in
            if !success { print("healthStore auth req error") }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running: workoutDidStart()
        case .ended: workoutDidEnd()
        default: print("unexpected workout state change")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workoutSession failure")
    }
    
    func workoutDidStart() {
        print("workoutDidStart")
        // if query in progress, stop
        if currentQuery != nil {
            healthStore.stop(currentQuery!)
        }
        
        // new query
        currentQuery = HKObserverQuery(sampleType: heartRateSampleType!, predicate: nil) { (_, _, error) in
            if let error = error {
                print("currentQuery error: \(error.localizedDescription)")
                return
            }
            
            self.fetchLatestHeartRateSample() { (sample) in
                DispatchQueue.main.async {
                    let heartRate = sample.quantity.doubleValue(for: self.heartRateUnit)
                    print("Heart Rate Sample: \(heartRate)")
                    if self.workoutActive {
                        self.updateHeartRate(value: heartRate)
                    }
                }
            }
        }
        
        currentQuery != nil ? healthStore.execute(currentQuery!) : print("error: currentQuery nil")
    }
    
    func workoutDidEnd() {
        print("workoutDidEnd")
        heartRateLabel.setText("--")
        heartRate = -1
    }
    
    func fetchLatestHeartRateSample(completionHandler: @escaping (_ sample: HKQuantitySample) -> Void) {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (_, results, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            if (results?.isEmpty)! { print("empty results array"); return }
            completionHandler(results?[0] as! HKQuantitySample)
            
        }
        healthStore.execute(query)
    }
    
    func updateHeartRate(value: Double) {
        self.heartRateLabel.setText(String(Int(value)))
        
        // update animation if HR moves outside of current bounds
        let hrRange = heartRate - 3...heartRate + 3
        if !hrRange.contains(value) {
            heartRate = value
            ecgAnimation()
        }
    }
    
    func ecgAnimation() {
        print("animating")
        if 30...210 ~= heartRate {
            // new animation with updated HR
            ecgImage.stopAnimating()
            ecgImage.startAnimatingWithImages(in: NSMakeRange(1, 130), duration: 60.0/heartRate, repeatCount: 0)
        } else {
            ecgImage.stopAnimating()
        }
    }
    
    @IBAction func didTouchStartButton() {
        if self.workoutActive {
            // finish the current session
            workoutActive = false
            button.setTitle("Start")
            heartRateLabel.setText("--")
            ecgImage.stopAnimating()
            session?.stopActivity(with: Date())
            session?.end()
        } else {
            // start a new session
            workoutActive = true
            button.setTitle("Stop")
            // Configure the workout session.
            
            do {
                session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
                session?.delegate = self
            } catch {
                fatalError("Failed to create a workout session object")
            }
            session?.startActivity(with: Date())
        }
    }
}

/* watch delegation */
extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            print("wcSession: activated")
        } else {
            guard let error = error else { return }
            print("wcSession: activation error - \(error.localizedDescription)")
        }
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("wcSession: message received")
        if let _ = message["startWorkout"] {
            print("starting workout")
            didTouchStartButton()
        } else { print("unknown message") }
    }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("wcSession: userInfo received")
        print(userInfo)
    }
}
