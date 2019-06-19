//
//  TrendsViewController.swift
//  Cardiologic
//  Displays static graphs of past week's heart rate data
//
//  Created by Ben Zimring on 7/25/18.
//  Copyright © 2018 pulseApp. All rights reserved.
//

import UIKit
import HealthKit
import Charts
import DropDown

class TrendsViewController: UIViewController, ChartViewDelegate {

    let hkm = HealthKitManager()
    
    @IBOutlet weak var rhrBarChart: BarChartView!
    let rhrChartData = BarChartData()
    
    @IBOutlet weak var variabilityBarChart: BarChartView!
    let variabilityChartData = BarChartData()
    @IBOutlet weak var aboutVariabilityButton: UIButton!
    
    @IBOutlet weak var workoutBarChart: BarChartView!
    let workoutChartData = BarChartData()
    
    @IBOutlet weak var stepBarChart: BarChartView!
    let stepChartData = BarChartData()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureCharts()
        graphRestingHeartRateBar()
        graphVariabilityBar()
        graphWorkoutTimeBar()
        graphDailyStepsBar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func graphRestingHeartRateBar() {
        print("graphRHRBar")
        // select range of 7 days
        let calendar = Calendar.current
        let startDay = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))
        
        hkm.restingHeartRate(from: startDay!, to: Date()) { samples in
            if samples.isEmpty {
                print("graphRestingHeartRate: not enough data")
                DispatchQueue.main.async {
                    self.rhrBarChart.data = nil
                    self.rhrBarChart.notifyDataSetChanged()
                }
                return
            }
            
            // create chart entries for each data point
            var entries = [BarChartDataEntry]()
            for sample in samples {
                let exactDate = sample.startDate
                let day = calendar.startOfDay(for: exactDate)
                let x = Double(Int(day.timeIntervalSinceNow/86400))
                let y = sample.quantity.doubleValue(for: .heartRateUnit)
                entries.append(BarChartDataEntry(x: x, y: y))
            }
            
            let dataSet = BarChartDataSet()
            for entry in entries {
                let _ = dataSet.addEntry(entry)
            }
            
            dataSet.colors = [.red]
            dataSet.valueFont = UIFont(descriptor: .init(name: "Avenir Book", size: 12), size: 12)
            dataSet.valueFormatter = DigitValueFormatter()
            self.rhrChartData.addDataSet(dataSet)
            DispatchQueue.main.async {
                self.rhrBarChart.notifyDataSetChanged()
            }
            
        }
    }
    
    func graphVariabilityBar() {
        let calendar = Calendar.current
        let startDay = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))
        
        hkm.variability(from: startDay!, to: Date()) { (samples) in
            if samples.isEmpty {
                print("graphVariability: not enough data")
                DispatchQueue.main.async {
                    self.variabilityBarChart.data = nil
                    self.variabilityBarChart.notifyDataSetChanged()
                }
                return
            }
            
            var results = [Double: (Double, Int)]()
            for sample in samples {
                let exactDate = sample.startDate
                let day = calendar.startOfDay(for: exactDate)
                let x = Double(Int(day.timeIntervalSinceNow/86400))
                let y = sample.quantity.doubleValue(for: .variabilityUnit)
                if results[x] == nil {
                    results[x] = (y, 1)
                } else {
                    results[x]!.0 += y
                    results[x]!.1 += 1
                }
            }
            
            let dataSet = BarChartDataSet()
            for i in -7...0 {
                if let result = results[Double(i)] {
                    let x = Double(i)
                    let y = result.0/Double(result.1)
                    let entry = BarChartDataEntry(x: x, y: y)
                    let _ = dataSet.addEntry(entry)
                }
            }
            
            // dataset settings
            dataSet.colors = [.purple]
            dataSet.valueFont = UIFont(descriptor: .init(name: "Avenir Book", size: 12), size: 12)
            dataSet.valueFormatter = VariabilityValueFormatter()
            self.variabilityChartData.addDataSet(dataSet)
            DispatchQueue.main.async {
                self.variabilityBarChart.notifyDataSetChanged()
            }
            
        }
    }
    
    func graphWorkoutTimeBar() {
        let calendar = Calendar.current
        let startDay = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))
        
        hkm.workouts(from: startDay!, to: Date()) { (samples) in
            if samples.isEmpty {
                print("graphWorkoutTime: not enough data")
                DispatchQueue.main.async {
                    self.workoutBarChart.data = nil
                    self.workoutBarChart.notifyDataSetChanged()
                }
                return
            }
            
            var results = [Double: (Double, Int)]()
            for sample in samples {
                let exactDate = sample.startDate
                let day = calendar.startOfDay(for: exactDate)
                let x = Double(Int(day.timeIntervalSinceNow/86400))
                let y = sample.duration/60
                if results[x] == nil {
                    results[x] = (y, 1)
                } else {
                    results[x]!.0 += y
                    results[x]!.1 += 1
                }
            }
            
            let dataSet = BarChartDataSet()
            for i in -7...0 {
                if let result = results[Double(i)] {
                    let x = Double(i)
                    let y = result.0/Double(result.1)
                    let entry = BarChartDataEntry(x: x, y: y)
                    let _ = dataSet.addEntry(entry)
                }
            }
            
            // dataset settings
            dataSet.colors = [.steelBlue]
            dataSet.valueFont = UIFont(descriptor: .init(name: "Avenir Book", size: 12), size: 12)
            dataSet.valueFormatter = WorkoutValueFormatter()
            self.workoutChartData.addDataSet(dataSet)
            DispatchQueue.main.async {
                self.workoutBarChart.notifyDataSetChanged()
            }
        }
    }
    
    func graphDailyStepsBar() {
        
        hkm.dailySteps { (results) in
            let calendar = Calendar.current
            let startDay = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))
            
            let dataSet = BarChartDataSet()
            
            // enumerate daily step data
            results.enumerateStatistics(from: startDay!, to: Date()) { statistics, stop in
                if let quantity = statistics.sumQuantity() {
                    let exactDate = statistics.startDate
                    let day = calendar.startOfDay(for: exactDate)
                    let x = Double(Int(day.timeIntervalSinceNow/86400))
                    let y = quantity.doubleValue(for: .count())
                    let entry = BarChartDataEntry(x: x, y: y)
                    let _ = dataSet.addEntry(entry)
                }
            }
            
            if dataSet.entryCount == 0 {
                print("graphDailySteps: not enough data")
                DispatchQueue.main.async {
                    self.stepBarChart.data = nil
                    self.stepBarChart.notifyDataSetChanged()
                }
                return
            }
            
            // dataset settings
            dataSet.colors = [.darkGreen]
            dataSet.valueFont = UIFont(descriptor: .init(name: "Avenir Book", size: 12), size: 12)
            dataSet.valueFormatter = DigitValueFormatter()
            self.stepChartData.addDataSet(dataSet)
            DispatchQueue.main.async {
                self.stepBarChart.notifyDataSetChanged()
            }
        }
    }

    // master chart settings
    func configureCharts() {
        rhrBarChart.data = rhrChartData
        rhrBarChart.delegate = self
        
        variabilityBarChart.data = variabilityChartData
        variabilityBarChart.delegate = self
        
        workoutBarChart.data = workoutChartData
        workoutBarChart.delegate = self
        
        stepBarChart.data = stepChartData
        stepBarChart.delegate = self
        
        let axisPadding = 0.5
        let charts = [rhrBarChart, variabilityBarChart, workoutBarChart, stepBarChart]
        for chart in charts {
            chart?.legend.enabled = false
            chart?.chartDescription = nil
            chart?.backgroundColor = .clear
            chart?.setViewPortOffsets(left: 15, top: 15, right: 15, bottom: 15)
            chart?.noDataText = "Not enough data"
            chart?.noDataTextColor = .black
            chart?.noDataFont = UIFont(descriptor: .init(name: "Avenir Book", size: 17), size: 17)

            chart?.xAxis.drawGridLinesEnabled = false
            chart?.xAxis.labelPosition = .bottom
            chart?.xAxis.labelTextColor = .black
            chart?.xAxis.granularityEnabled = true
            chart?.xAxis.granularity = 1
            chart?.xAxis.axisMinimum = -7 - axisPadding
            chart?.xAxis.axisMaximum = 0 + axisPadding
            chart?.xAxis.valueFormatter = DayValueFormatter()

            chart?.rightAxis.drawGridLinesEnabled = false
            chart?.rightAxis.drawAxisLineEnabled = false
            chart?.rightAxis.drawLabelsEnabled = false

            chart?.leftAxis.drawAxisLineEnabled = false
            chart?.leftAxis.drawGridLinesEnabled = false
            chart?.leftAxis.drawLabelsEnabled = false
            chart?.leftAxis.labelTextColor = .black
        }
    }
}

/* misc */
extension TrendsViewController {
    @IBAction func didTouchAboutVariability(_ sender: Any) {
        let dropDown = DropDown()
        dropDown.anchorView = variabilityBarChart
        dropDown.dataSource = [""]
        dropDown.width = 320
        dropDown.cellHeight = 70
        dropDown.direction = .bottom
        dropDown.cellNib = UINib(nibName: "VariabilityInfo", bundle: nil)
        dropDown.show()
    }
}
