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

private let maxValue = 255
private let binCount = 16

extension UIImage {
	var colorHistogram: (r: [UInt], g: [UInt], b: [UInt]) {
		let imageRef = CGImage

		let inProvider = CGImageGetDataProvider(imageRef)
		let inBitmapData = CGDataProviderCopyData(inProvider)

		var inBuffer = vImage_Buffer(data: UnsafeMutablePointer(CFDataGetBytePtr(inBitmapData)), height: UInt(CGImageGetHeight(imageRef)), width: UInt(CGImageGetWidth(imageRef)), rowBytes: CGImageGetBytesPerRow(imageRef))

		let first = [UInt](count: 256, repeatedValue: 0)
		let second = [UInt](count: 256, repeatedValue: 0)
		let third = [UInt](count: 256, repeatedValue: 0)
		let fourth = [UInt](count: 256, repeatedValue: 0)

		let alphaPtr = UnsafeMutablePointer<vImagePixelCount>(first)
		let redPtr = UnsafeMutablePointer<vImagePixelCount>(second)
		let greenPtr = UnsafeMutablePointer<vImagePixelCount>(fourth)
		let bluePtr = UnsafeMutablePointer<vImagePixelCount>(fourth)

		let rgba = [redPtr, greenPtr, bluePtr, alphaPtr]

		let histogram = UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>>(rgba)

		_ = vImageHistogramCalculation_ARGB8888(&inBuffer, histogram, UInt32(kvImageNoFlags))

		let bitMapInfo = CGImageGetBitmapInfo(CGImage)
		
		if CGImageGetAlphaInfo(CGImage) == .NoneSkipFirst {
			if bitMapInfo.rawValue & CGBitmapInfo.ByteOrder32Little.rawValue > 0 {
				return (r: fourth, g: third, b: second)
			} else if bitMapInfo.rawValue & (CGBitmapInfo.ByteOrder32Big.rawValue | CGBitmapInfo.AlphaInfoMask.rawValue) > 0  {
				return (r: third, g: fourth, b: first)
			} else {
			fatalError("not defined image format")
			}
		} else if CGImageGetAlphaInfo(CGImage) == .NoneSkipLast {
			return (r: second, g: third, b: fourth)
		} else {
			fatalError("not defined image format")
		}
	}

	var normalisedHistogramVectors: [HistogramVector] {
		let histogram = colorHistogram

		var result = [HistogramVector]()
		var max = 0.0

		for index in 0 ..< histogram.r.count {
			max += Double(histogram.r[index] + histogram.g[index] + histogram.b[index])
		}

		for index in 0 ..< histogram.r.count {
			let normalizedRed = Double(histogram.r[index]) / max
			let normalizedGreen = Double(histogram.g[index]) / max
			let normalizedBlue = Double(histogram.b[index]) / max
			result.append(HistogramVector(red: normalizedRed, blue: normalizedBlue, green: normalizedGreen))
		}

		return result
	}

	var normalized1DArray: [Double] {
		let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(CGImage))
		let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
		var histogram = Array<Double>(count: binCount * binCount * binCount, repeatedValue: 0)
		var total: Double = 0

		let bitMapInfo = CGImageGetBitmapInfo(CGImage)

		for var i = 0; i < CGImageGetWidth(CGImage) * CGImageGetHeight(CGImage) * 4; i += 4 {
			var r: UInt8 = 0
			var g: UInt8 = 0
			var b: UInt8 = 0

			if CGImageGetAlphaInfo(CGImage) == .NoneSkipFirst {
				if bitMapInfo.rawValue & CGBitmapInfo.ByteOrder32Little.rawValue > 0 {
					r = data[i+2]
					g = data[i+1]
					b = data[i]
				} else if bitMapInfo.rawValue & (CGBitmapInfo.ByteOrder32Big.rawValue | CGBitmapInfo.AlphaInfoMask.rawValue) > 0  {
					r = data[i+1]
					g = data[i+2]
					b = data[i+3]
				} else {
					assertionFailure("not defined alpha handling")
				}
			} else if CGImageGetAlphaInfo(CGImage) == .NoneSkipLast {
				r = data[i]
				g = data[i+1]
				b = data[i+2]
			} else {
				assertionFailure("not defined alpha handling")
			}

			let index = getSingleBinIndex(r, g: g, b: b)
			histogram[index] += 1
			total++
		}

		return histogram.map { $0 / total }
	}

	private func getSingleBinIndex(r: UInt8, g: UInt8, b: UInt8) -> Int {
		let i1 = getBinIndex(r)
		let i2 = getBinIndex(g)
		let i3 = getBinIndex(b)
		return i1 + i2 * binCount + i3 * binCount * binCount
	}

	private func getBinIndex(value: UInt8) -> Int {
		var index = Int(value) * binCount / maxValue
		if index >= binCount {
			index = binCount - 1
		}
		return index
	}
}
