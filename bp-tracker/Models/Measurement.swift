
//
//  Measurement 2.swift
//  bp-tracker
//
//  Created by Alexandr Shklyaev on 17.03.2026.
//

import SwiftData
import Foundation

@Model
class Measurement {
    var date: Date
    var systolic: Int
    var diastolic: Int
    var pulse: Int?

    init(systolic: Int, diastolic: Int, pulse: Int? = nil) {
        self.date = Date()
        self.systolic = systolic
        self.diastolic = diastolic
        self.pulse = pulse
    }
}
