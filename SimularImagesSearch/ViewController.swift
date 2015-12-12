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
	private let operationQueue: NSOperationQueue = {
		let queue = NSOperationQueue()
		queue.qualityOfService = .UserInitiated
		queue.maxConcurrentOperationCount = 1
		return queue
	}()
	private let manager = PHImageManager.defaultManager()
	private let pixelDensity = UIScreen.mainScreen().scale
	private var assets = [PHAsset]()
	private var images = [(asset: PHAsset, similarity: Double)]()
	private weak var collectionView: UICollectionView!
	private var headerView: ImageSearchHeaderView?
	private var cancelButton: UIBarButtonItem!
	private var baseView: SimularImageSearcherView!

	private let cellRequestOptions: PHImageRequestOptions = {
		let request = PHImageRequestOptions()
		request.synchronous = true
		request.resizeMode = .None
		request.deliveryMode = .HighQualityFormat
		return request
	}()

    private lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        return imagePicker
    }()

	private func loadImagesFromLibrary() {
		let options = PHFetchOptions()
		//		options.fetchLimit = 1
		options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		let results = PHAsset.fetchAssetsWithMediaType(.Image, options: options)

		assets.removeAll()
		results.enumerateObjectsUsingBlock { object, _, _ in
			if let asset = object as? PHAsset {
				self.assets.append(asset)
			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()


		PHPhotoLibrary.requestAuthorization { status in
			dispatch_async(dispatch_get_main_queue()) {
				switch status {
				case .Authorized:
					self.loadImagesFromLibrary()
				default:
					SVProgressHUD.showErrorWithStatus("No access")
				}
			}

		}

		cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "didTapCancel")
		cancelButton.enabled = false
		navigationItem.rightBarButtonItem = cancelButton
	}

	override func loadView() {
		super.loadView()
		let baseView = SimularImageSearcherView()
        baseView.collectionView.delegate = self
        baseView.collectionView.dataSource = self
		collectionView = baseView.collectionView
		view = baseView
		self.baseView = baseView
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

	func didTapCancel() {
		self.title = "Cancelled"
		cancelButton.enabled = false
		operationQueue.cancelAllOperations()
	}
}

// MARK: - UIImagePickerControllerDelegate Methods

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {

	private func bcOperationForAsset(asset: PHAsset, compareTo histogram: [Double]) -> Operation {
		let operation = BCOperation(asset: asset, histogram: histogram)
		
		operation.completionBlock = {
			NSOperationQueue.mainQueue().addOperationWithBlock {
				if operation.cancelled { return }
				self.title = "To go: \(self.operationQueue.operationCount)"
				if self.operationQueue.operationCount == 0 {
					self.title = "Done"
					self.cancelButton.enabled = false
					self.headerView?.switcher.enabled = true
				}

				guard let result = operation.result else {
					return
				}

				print(result)
				var newIndex = self.images.isEmpty ? 0 : self.images.count
				for index in 0 ..< self.images.count {
					if result > self.images[index].similarity {
						newIndex = index
						break
					}
				}
				
				self.collectionView.performBatchUpdates({
					self.images.insert((asset: operation.asset, similarity: result), atIndex: newIndex)
					self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: newIndex, inSection: 0)])
					}, completion: nil)
			}
		}

		return operation
	}

	private func euclideanOperationForAsset(asset: PHAsset, compareTo histogram: [HistogramVector]) -> Operation {
		let operation = EuclideanOperation(asset: asset, histogram: histogram)
		
		operation.completionBlock = {
			NSOperationQueue.mainQueue().addOperationWithBlock {
				if operation.cancelled { return }
				self.title = "To go: \(self.operationQueue.operationCount)"
				if self.operationQueue.operationCount == 0 {
					self.title = "Done"
					self.cancelButton.enabled = false
					self.headerView?.switcher.enabled = true
				}

				guard let result = operation.result else {
					return
				}

				print(result)
				var newIndex = self.images.isEmpty ? 0 : self.images.count
				for index in 0 ..< self.images.count {
					if result < self.images[index].similarity {
						newIndex = index
						break
					}
				}
				
				self.collectionView.performBatchUpdates({
					self.images.insert((asset: operation.asset, similarity: result), atIndex: newIndex)
					self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: newIndex, inSection: 0)])
					}, completion: nil)
			}
		}

		return operation
	}

	func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
		headerView?.imageView.image = image

		title = "0 / \(assets.count)"
		cancelButton.enabled = true
		headerView?.switcher.enabled = false

		images.removeAll()
		collectionView.reloadData()

		let dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)

		dispatch_async(dispatchQueue) {
			let operations: [Operation]

			if self.headerView!.switcher.on {
				let originalHistogram = image.normalized1DArray
				operations = self.assets.map { self.bcOperationForAsset($0, compareTo: originalHistogram) }
			} else {
				let originalHistogram = image.normalisedHistogramVectors
				operations = self.assets.map { self.euclideanOperationForAsset($0, compareTo: originalHistogram) }
			}

			dispatch_async(dispatch_get_main_queue()) {
				self.operationQueue.addOperations(operations, waitUntilFinished: false)
			}
		}
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
