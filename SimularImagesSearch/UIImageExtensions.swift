//
//  UIImageExtensions.swift
//  SimularImagesSearch
//
//  Created by samuel susla on 12/8/15.
//  Copyright © 2015 samuel susla. All rights reserved.
//

import UIKit
import ImageIO
import Accelerate

extension Int {
	var double: Double {
		return Double(self)
	}
}

struct HistogramVector {
	let red: Int
	let blue: Int
	let green: Int

	func compare(histogram: HistogramVector) -> Double {
		let first = pow((red - histogram.red).double, 2.0)
		let second = pow((blue - histogram.blue).double, 2.0)
		let third = pow((green - histogram.green).double, 2.0)
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


private func compareArrays(array1: [UInt], array2: [UInt]) -> Double {
	var result = 0.0

	for index in 0 ..< array1.count {
		let val1 = Double(array1[index])
		let val2 = Double(array2[index])

		result += (val1 - val2) * (val1 - val2)
	}

	return sqrt(result)
}

extension UIImage {
	var colorHistogram: [HistogramVector] {
		let imageRef = self.CGImage
		
		let inProvider = CGImageGetDataProvider(imageRef)
		let inBitmapData = CGDataProviderCopyData(inProvider)
		
		var inBuffer = vImage_Buffer(data: UnsafeMutablePointer(CFDataGetBytePtr(inBitmapData)), height: UInt(CGImageGetHeight(imageRef)), width: UInt(CGImageGetWidth(imageRef)), rowBytes: CGImageGetBytesPerRow(imageRef))
		
		let alpha = [Int](count: 256, repeatedValue: 0)
		let red = [Int](count: 256, repeatedValue: 0)
		let green = [Int](count: 256, repeatedValue: 0)
		let blue = [Int](count: 256, repeatedValue: 0)
		
		let alphaPtr = UnsafeMutablePointer<vImagePixelCount>(alpha)
		let redPtr = UnsafeMutablePointer<vImagePixelCount>(red)
		let greenPtr = UnsafeMutablePointer<vImagePixelCount>(green)
		let bluePtr = UnsafeMutablePointer<vImagePixelCount>(blue)
		
		let rgba = [redPtr, greenPtr, bluePtr, alphaPtr]
		
		let histogram = UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>>(rgba)
		
		_ = vImageHistogramCalculation_ARGB8888(&inBuffer, histogram, UInt32(kvImageLeaveAlphaUnchanged))

		var result = [HistogramVector]()
		for index in 0 ..< red.count {
			result.append(HistogramVector(red: red[index], blue: blue[index], green: green[index]))
		}
		
		return result
	}
	
	func compareToImage(image: UIImage, withPrecision precision: Double = 20) -> Double? {
		guard let resized1 = resizeImageToWidth(precision), resized2 = image.resizeImageToWidth(precision) else { return nil }
		
		let histogram1 = resized1.colorHistogram
		let histogram2 = resized2.colorHistogram

		let result = HistogramVector.compareArray(histogram1, toArray: histogram2)

		return result
	}


	func resizeImageToWidth(width: Double) -> UIImage? {
		guard let data = UIImageJPEGRepresentation(self, 1.0) else { return nil }
		let imageSource = CGImageSourceCreateWithData(data, nil)!
		let options: [NSString: NSObject] = [
			kCGImageSourceThumbnailMaxPixelSize: width,
			kCGImageSourceCreateThumbnailFromImageAlways: true
		]
		
		let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options).flatMap { UIImage(CGImage: $0) }
		return scaledImage!
	}
}
