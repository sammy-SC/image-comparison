//
//  BCOperation.swift
//  SimularImagesSearch
//
//  Created by samuel susla on 12/10/15.
//  Copyright © 2015 samuel susla. All rights reserved.
//

import UIKit
import Photos

final class BCOperation: Operation {
	private let manager = PHImageManager()
	private let requestOptions: PHImageRequestOptions = {
		let request = PHImageRequestOptions()
		request.synchronous = true
		request.resizeMode = .None
		request.deliveryMode = .HighQualityFormat
		return request
	}()

	let asset: PHAsset
	let normalizedColorHistogram: [Double]
	init(asset: PHAsset, histogram: [Double]) {
		self.asset = asset
		normalizedColorHistogram = histogram
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

				let otherHistogram = image.normalized1DArray
				var result = 0.0

				for index in 0 ..< self.normalizedColorHistogram.count {
					let res1 = self.normalizedColorHistogram[index]
					let res2 = otherHistogram[index]
					result += sqrt(res1 * res2)
				}

				if self.cancelled {
					self.finish()
					return
				}

				self.result = result

				self.finish()
				print("finished")
		}
	}

}
