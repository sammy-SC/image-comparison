//
//  ViewController.swift
//  SimularImagesSearch
//
//  Created by samuel susla on 12/8/15.
//  Copyright © 2015 samuel susla. All rights reserved.
//

import UIKit
import Photos
import JTSImageViewController
import SVProgressHUD

final class ViewController: UIViewController {
	private let manager = PHImageManager.defaultManager()
	private let cachingImageManager = PHCachingImageManager()
	private let pixelDensity = UIScreen.mainScreen().scale

	private let cellRequestOptions: PHImageRequestOptions = {
		let request = PHImageRequestOptions()
		request.synchronous = true
		request.resizeMode = .None
		request.deliveryMode = .HighQualityFormat
		return request
	}()

	private let viewerRequestOptions: PHImageRequestOptions = {
		let request = PHImageRequestOptions()
		request.synchronous = true
		request.deliveryMode = .HighQualityFormat
		request.networkAccessAllowed = true

		request.progressHandler = { progress, error, _, _ in
			if let error = error {
				SVProgressHUD.showErrorWithStatus("Failed to load the image")
			} else {
				SVProgressHUD.showProgress(Float(progress), maskType: SVProgressHUDMaskType.Gradient)
			}
		}

		return request
	}()

    private lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        return imagePicker
    }()

	private var assets = [PHAsset]()
	private var images = [(asset: PHAsset, similarity: Double)]()
	private weak var collectionView: UICollectionView!
	private var headerView: ImageSearchHeaderView?

	override func viewDidLoad() {
		super.viewDidLoad()

		let results = PHAsset.fetchAssetsWithMediaType(.Image, options: nil)

		results.enumerateObjectsUsingBlock { object, _, _ in
			if let asset = object as? PHAsset {
				self.assets.append(asset)
			}
		}

		cachingImageManager.startCachingImagesForAssets(assets,
			targetSize: PHImageManagerMaximumSize,
			contentMode: .AspectFit,
			options: nil
		)
	}

	override func loadView() {
		super.loadView()
		let baseView = SimularImageSearcherView()
        baseView.collectionView.delegate = self
        baseView.collectionView.dataSource = self
		collectionView = baseView.collectionView
		view = baseView
	}

	private func presentImagePicker() {
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { _ in }
		controller.addAction(cancelAction)

		let libraryAction = UIAlertAction(title: "Photo Library", style: .Default) { _ in
			self.imagePicker.sourceType = .PhotoLibrary
			self.presentViewController(self.imagePicker, animated: true, completion: nil)
		}
		controller.addAction(libraryAction)

		let cameraAction = UIAlertAction(title: "Camera", style: .Default) { _ in
			self.imagePicker.sourceType = .Camera
			self.presentViewController(self.imagePicker, animated: true, completion: nil)
		}
		controller.addAction(cameraAction)
		presentViewController(controller, animated: true, completion: nil)
	}
}

// MARK: - UIImagePickerControllerDelegate Methods

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
		self.headerView?.imageView.image = image

		self.headerView?.label.text = "0 / \(assets.count)"
		self.images.removeAll()
		self.collectionView.reloadData()

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			var counter = 0
			var failedToResizeCounter = 0
			var failedToLoadCounter = 0
			for asset in self.assets {
				self.manager.requestImageForAsset(asset,
					targetSize: CGSizeMake(100,100),
					contentMode: .AspectFit,
					options: self.cellRequestOptions) { finalResult, _ in
						dispatch_async(dispatch_get_main_queue()) {
							self.headerView?.label.text = "\(++counter) / \(self.assets.count)"
							if counter == self.assets.count {
								SVProgressHUD.showInfoWithStatus("Done")
							}
						}

						guard let otherImage = finalResult else {
							print("failed to load: \(++failedToLoadCounter)")
							return
						}
						if let result = image.compareToImage(otherImage, withPrecision: 100) {
							var newIndex = self.images.isEmpty ? 0 : self.images.count - 1
							for index in 0 ..< self.images.count {
								if result < self.images[index].similarity {
									newIndex = index
									break
								}
							}

							dispatch_async(dispatch_get_main_queue()) {
								self.collectionView.performBatchUpdates({
									self.images.insert((asset: asset, similarity: result), atIndex: newIndex)
									self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: newIndex, inSection: 0)])
									}, completion: nil)
							}
						} else {
							print("failed to resize: \(++failedToResizeCounter)")
						}
				}
			}
		}
//		let otherImage = images.first!
//		imageView.image = otherImage

//		image.compareToImage(otherImage)

        dismissViewControllerAnimated(true, completion: nil)
    }
}


// MARK: - UICollectionViewDelegate & data source methods

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return images.count
	}

	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ImageCell.cellIdentifier, forIndexPath: indexPath) as! ImageCell
		let size = CGSizeMake(CGRectGetWidth(cell.frame) * pixelDensity, CGRectGetHeight(cell.frame) * pixelDensity)
		manager.requestImageForAsset(images[indexPath.item].asset,
			targetSize: size,
			contentMode: .AspectFit,
			options: cellRequestOptions) { finalResult, _ in
				guard let image = finalResult else { return }
				cell.imageView.image = image
		}
		return cell
	}

	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		collectionView.deselectItemAtIndexPath(indexPath, animated: true)
		let cell = collectionView.cellForItemAtIndexPath(indexPath)! as! ImageCell

		let imageInfo = JTSImageInfo()
		imageInfo.image = cell.imageView.image!
		imageInfo.referenceRect = cell.frame
		imageInfo.referenceView = collectionView
		let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: .Image, backgroundStyle: .Blurred)
		imageViewer.showFromViewController(self, transition: .FromOriginalPosition)


//		manager.requestImageForAsset(assets[indexPath.item],
//			targetSize: PHImageManagerMaximumSize,
//			contentMode: .AspectFill,
//			options: viewerRequestOptions) { finalResult, tmp in
//				print(tmp)
//				guard let image = finalResult else { return }
//				let imageInfo = JTSImageInfo()
//				imageInfo.image = image
//				imageInfo.referenceRect = cell.frame
//				imageInfo.referenceView = collectionView
//				let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: .Image, backgroundStyle: .Blurred)
//				imageViewer.showFromViewController(self, transition: .FromOriginalPosition)
//		}
	}

	func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
		let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "header", forIndexPath: indexPath) as! ImageSearchHeaderView
		headerView.imageTapAction = {[unowned self] in
			self.presentImagePicker()
		}

		self.headerView = headerView
		return headerView
	}



	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		let width = (CGRectGetWidth(collectionView.bounds) - Constants.size.galleryMargin * 3) / 3
		return CGSizeMake(width, width)
	}

	func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}
}
