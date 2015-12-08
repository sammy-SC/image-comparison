//
//  BackgroundImageCell.swift
//  LikeItLocator
//
//  Created by samuel susla on 8/17/15.
//  Copyright (c) 2015 Ackee s.r.o. All rights reserved.
//

import UIKit


final class ImageCell: UICollectionViewCell {

    weak var imageView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.whiteColor()

        let imageView = UIImageView()
		imageView.clipsToBounds = true
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
		imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        self.imageView = imageView

		contentView.addConstraints([
			imageView.topAnchor.constraintEqualToAnchor(contentView.topAnchor),
			imageView.leftAnchor.constraintEqualToAnchor(contentView.leftAnchor),
			imageView.rightAnchor.constraintEqualToAnchor(contentView.rightAnchor),
			imageView.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor),
			])
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
