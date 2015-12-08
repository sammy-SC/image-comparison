//
//  UIKitExtensions.swift
//  SimularImagesSearch
//
//  Created by samuel susla on 12/8/15.
//  Copyright © 2015 samuel susla. All rights reserved.
//

import UIKit

extension UICollectionViewCell {
	class var cellIdentifier: String {
		return NSStringFromClass(self)
	}
}
