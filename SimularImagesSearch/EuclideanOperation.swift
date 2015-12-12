//
//  EuclideanOperation.swift
//  SimularImagesSearch
//
//  Created by samuel susla on 12/12/15.
//  Copyright © 2015 samuel susla. All rights reserved.
//

import UIKit
import Photos

final class EuclideanOperation: Operation {
	private let manager = PHImageManager()
	private let requestOptions: PHImageRequestOptions = {
		let request = PHImageRequestOptions()
		request.synchronous = true
		request.resizeMode = .None
		request.deliveryMode = .HighQualityFormat
		return request
	}()

	let asset: PHAsset
	let histogram: [HistogramVector]
	init(asset: PHAsset, histogram: [HistogramVector]) {
		self.asset = asset
		self.histogram = histogram
	}

	override var ready: Bool {
		return true
	}

	override func start() {
		super.start()
		startExecuting()

		if self.cancelled {
			self.finish()
			return
		}

		self.manager.requestImageForAsset(asset,
			targetSize: CGSizeMake(450, 450),
			contentMode: .AspectFit,
			options: self.requestOptions) { finalResult, _ in

				if self.cancelled {
					self.finish()
					return
				}

				guard let image = finalResult else {
					self.finish()
					return
				}

				let otherHistogram = image.normalisedHistogramVectors
				self.result = HistogramVector.compareArray(self.histogram, toArray: otherHistogram)

				if self.cancelled {
					self.finish()
					return
				}

				self.finish()
		}
	}
}
