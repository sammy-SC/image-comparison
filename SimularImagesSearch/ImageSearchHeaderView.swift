//
//  ImageSearchHeaderView.swift
//  SimularImagesSearch
//
//  Created by samuel susla on 12/8/15.
//  Copyright © 2015 samuel susla. All rights reserved.
//

import UIKit

private let euclideanDistanceString = "Euclidean distance"
private let bhattacharyyaCoefficientString = "Bhattacharyya Coefficient"

final class ImageSearchHeaderView: UICollectionReusableView {
	var imageTapAction: (() -> Void)?
	weak var switcher: UISwitch!
	weak var imageView: UIImageView!
	private weak var label: UILabel!

	override init(frame: CGRect) {
		super.init(frame: frame)

		let imageView = UIImageView()
		imageView.layer.borderColor = UIColor.blackColor().CGColor
		imageView.layer.borderWidth = 1.0
		imageView.userInteractionEnabled = true
		imageView.contentMode = .ScaleAspectFit
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "didTapImage"))
		addSubview(imageView)
		self.imageView = imageView

		addConstraints([
			imageView.heightAnchor.constraintEqualToConstant(350),
			imageView.widthAnchor.constraintEqualToAnchor(widthAnchor),
			imageView.topAnchor.constraintEqualToAnchor(topAnchor, constant: 10),
			imageView.centerXAnchor.constraintEqualToAnchor(centerXAnchor)
			])

		let label = UILabel()
		label.text = euclideanDistanceString
		label.textAlignment = .Center
		label.numberOfLines = 0
		label.translatesAutoresizingMaskIntoConstraints = false
		addSubview(label)
		self.label = label

		addConstraints([
			label.topAnchor.constraintEqualToAnchor(imageView.bottomAnchor, constant: 20),
			label.leadingAnchor.constraintEqualToAnchor(self.leadingAnchor),
			label.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor),
			])

		let switcher = UISwitch()
		switcher.translatesAutoresizingMaskIntoConstraints = false
		switcher.addTarget(self, action: "didSwitch:", forControlEvents: .ValueChanged)
		addSubview(switcher)
		self.switcher = switcher

		let bottom = switcher.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -40)
		bottom.priority = UILayoutPriorityFittingSizeLevel + 1
		addConstraints([
			switcher.centerXAnchor.constraintEqualToAnchor(centerXAnchor),
			switcher.topAnchor.constraintEqualToAnchor(label.bottomAnchor, constant: 20),
			bottom,
			])
	}

	func didSwitch(sender: UISwitch) {
		if sender.on {
			label.text = bhattacharyyaCoefficientString
		} else {
			label.text = euclideanDistanceString
		}

	}

	func didTapImage() {
		imageTapAction?()
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}
