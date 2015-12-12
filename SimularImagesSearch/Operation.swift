//
//  Operation.swift
//  SimularImagesSearch
//
//  Created by samuel susla on 12/12/15.
//  Copyright © 2015 samuel susla. All rights reserved.
//

import Foundation


class Operation: NSOperation {
	var result: Double?
	// keep track of executing and finished states
	private var _executing = false
	private var _finished = false
	
	override var executing: Bool {
		return _executing
	}

	override var finished: Bool {
		return _finished
	}

	func startExecuting() {
		willChangeValueForKey("isExecuting")
		_executing = true
		didChangeValueForKey("isExecuting")
	}

	func finish() {
		willChangeValueForKey("isExecuting")
		willChangeValueForKey("isFinished")
		_executing = false
		_finished = true
		didChangeValueForKey("isExecuting")
		didChangeValueForKey("isFinished")
	}

}