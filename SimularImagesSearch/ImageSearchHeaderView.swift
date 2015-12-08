//
//  ImageSearchHeaderView.swift
//  SimularImagesSearch
//
//  Created by samuel susla on 12/8/15.
//  Copyright © 2015 samuel susla. All rights reserved.
//

import UIKit


final class ImageSearchHeaderView: UICollectionReusableView {
	var imageTapAction: (() -> Void)?
	weak var label: UILabel!
	weak var imageView: UIImageView!

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
		label.numberOfLines = 0
		label.textAlignment = .Center
		label.text = "Tap on the space above to pick image"
		label.translatesAutoresizingMaskIntoConstraints = false
		addSubview(label)
		self.label = label

		let bottom = label.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -20)
		let right =  label.rightAnchor.constraintEqualToAnchor(rightAnchor, constant: -20)
		bottom.priority = 900
		right.priority = 900
		addConstraints([
			label.leftAnchor.constraintEqualToAnchor(leftAnchor, constant: 20),
			right,
			label.topAnchor.constraintEqualToAnchor(imageView.bottomAnchor, constant: 20),
			bottom,
			])
	}

	func didTapImage() {
		imageTapAction?()
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}
