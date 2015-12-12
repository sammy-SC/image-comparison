//
//  HistogramVector.swift
//  SimularImagesSearch
//
//  Created by samuel susla on 12/10/15.
//  Copyright © 2015 samuel susla. All rights reserved.
//

import Foundation

struct HistogramVector {
	let red: Double
	let blue: Double
	let green: Double

	func compare(histogram: HistogramVector) -> Double {
        //distance
		let first = pow(red - histogram.red, 2.0)
		let second = pow(blue - histogram.blue, 2.0)
		let third = pow(green - histogram.green, 2.0)
		return sqrt(first + second + third)
	}

	static func compareArray(array1: [HistogramVector], toArray array2: [HistogramVector]) -> Double {
		var result = 0.0

		for index in 0 ..< array1.count {
			let vector1 = array1[index]
			let vector2 = array2[index]
			result += vector1.compare(vector2)
		}

		return sqrt(result)
	}
}
