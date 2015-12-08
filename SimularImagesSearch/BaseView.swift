//
//  File.swift
//  SimularImagesSearch
//
//  Created by samuel susla on 12/8/15.
//  Copyright © 2015 samuel susla. All rights reserved.
//

import UIKit



final class SimularImageSearcherView: UIView {
	let collectionView: UICollectionView
	init() {

		let headerView = ImageSearchHeaderView(frame: CGRectZero)
		headerView.layoutIfNeeded()
		let size = headerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = Constants.size.galleryMargin
        flowLayout.minimumLineSpacing = Constants.size.galleryMargin
		flowLayout.headerReferenceSize = size

		collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: flowLayout)
        collectionView.registerClass(ImageCell.self, forCellWithReuseIdentifier: ImageCell.cellIdentifier)
		collectionView.registerClass(ImageSearchHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "header")
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.showsVerticalScrollIndicator = false
		collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInset = UIEdgeInsetsMake(Constants.size.galleryMargin , 0, Constants.size.galleryMargin, 0)

		super.init(frame: CGRectZero)
		backgroundColor = UIColor.whiteColor()

        addSubview(collectionView)
		addConstraints([
			collectionView.topAnchor.constraintEqualToAnchor(topAnchor),
			collectionView.leftAnchor.constraintEqualToAnchor(leftAnchor, constant: Constants.size.galleryMargin),
			collectionView.rightAnchor.constraintEqualToAnchor(rightAnchor, constant: -Constants.size.galleryMargin),
			collectionView.bottomAnchor.constraintEqualToAnchor(bottomAnchor),
			])
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}
