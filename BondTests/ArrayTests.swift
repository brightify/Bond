//
//  ArrayTests.swift
//  Bond
//
//  Created by Srdan Rasic on 13/03/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import XCTest

func ==<T: Equatable>(dynamicArray: ObservableArray<T>, array: [T]) -> Bool {
  if dynamicArray.count == array.count {
    for i in 0..<array.count {
      if dynamicArray[i] != array[i] {
        return false
      }
    }
    
    return true
  } else {
    return false
  }
}

class ArrayTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testArrayOperations() {
    let array = DynamicArray<Int>([])
    
    XCTAssert(array.count == 0)
    
    array.append(1)
    XCTAssert(array.count == 1)
    XCTAssert(array[0] == 1)
    
    array.append(2)
    XCTAssert(array.count == 2)
    XCTAssert(array.value == [1, 2])
  
    array.insert(3, atIndex: 0)
    XCTAssert(array.count == 3)
    XCTAssert(array.value == [3, 1, 2])
    
    array.append([4, 5])
    XCTAssert(array.count == 5)
    XCTAssert(array.value == [3, 1, 2, 4, 5])
    
    let last = array.removeLast()
    XCTAssert(array.count == 4)
    XCTAssert(array.value == [3, 1, 2, 4])
    XCTAssert(last == 5)
    
    let element = array.removeAtIndex(1)
    XCTAssert(array.count == 3)
    XCTAssert(array.value == [3, 2, 4])
    XCTAssert(element == 1)
    
    array.insertContentsOf([8, 9], atIndex: 1)
    XCTAssert(array.count == 5)
    XCTAssert(array.value == [3, 8, 9, 2, 4])
    
    array[0] = 0
    XCTAssert(array.count == 5)
    XCTAssert(array.value == [0, 8, 9, 2, 4])

    array.removeAll(true)
    XCTAssert(array.count == 0)
    XCTAssert(array.value == [])
  }
  
  func testArrayBond() {
    let array = DynamicArray<Int>([])
    let bond = ArrayBond<Int>()
    
    var indices: [Int] = []
    var objects: [Int] = []
    
    bond.didInsertListener = { a, r in
      indices = Array(r)
    }
    
    bond.willRemoveListener = { a, r in
      indices = Array(r)
      objects = r.map { a[$0] }
    }
    
    bond.willUpdateListener = { a, r in
      indices = Array(r)
      objects = r.map { a[$0] }
    }
    
    array.bindTo(bond)
    
    XCTAssert(array.count == 0)
    
    array.append(1)
    XCTAssertEqual(indices, [0])
    
    array.append(2)
    XCTAssertEqual(indices, [1])
    
    array.insert(3, atIndex: 0)
    XCTAssertEqual(indices, [0])
    
    array.append([4, 5])
    XCTAssertEqual(indices, [3, 4])
    
    array.removeLast()
    XCTAssertEqual(indices, [4])
    XCTAssertEqual(objects, [5])
    
    array.removeAtIndex(1)
    XCTAssertEqual(indices, [1])
    XCTAssert(objects == [1])
    
    array.insertContentsOf([8, 9], atIndex: 1)
    XCTAssertEqual(indices, [1, 2])
    
    array[0] = 0
    XCTAssertEqual(indices, [0])
    XCTAssertEqual(objects, [3])
    
    array.removeAll(true)
    XCTAssertEqual(indices, [0, 1, 2, 3, 4])
  }
  
//  func testArrayFilter() {
//    let array = DynamicArray<Int>([])
//    let filtered: ObservableArray<Int> = array.filter { $0 > 5 }
//    let bond = ArrayBond<Int>()
//    
//    var indices: [Int] = []
//    var removedObjects: [Int] = []
//    var updatedObjects: [Int] = []
//    
//    let resetState = { () -> () in
//      indices = []
//      removedObjects = []
//      updatedObjects = []
//    }
//    
//    bond.didInsertListener = { a, i in
//      indices = i
//    }
//    
//    bond.willRemoveListener = { a, i in
//      indices = i
//      removedObjects = []; for idx in i { removedObjects.append(a[idx]) }
//    }
//    
//    bond.willUpdateListener = { a, i in
//      indices = i
//      updatedObjects = []; for idx in i { updatedObjects.append(a[idx]) }
//    }
//    
//    filtered.bindTo(bond)
//    
//    XCTAssert(array.count == 0)
//    XCTAssert(filtered == [])
//    resetState()
//    
//    array.append(1)   // [1]
//    XCTAssert(indices == [])
//    XCTAssert(filtered == [])
//    resetState()
//    
//    array.append(6)   // [1, 6]
//    XCTAssert(indices == [0])
//    XCTAssert(filtered == [6])
//    resetState()
//    
//    array.insert(3, atIndex: 0)   // [3, 1, 6]
//    XCTAssert(indices == [])
//    XCTAssert(filtered == [6])
//    resetState()
//    
//    array.insert(8, atIndex: 1)   // [3, 8, 1, 6]
//    XCTAssert(indices == [0])
//    XCTAssert(filtered == [8, 6])
//    resetState()
//
//    array.append([4, 7])  // [3, 8, 1, 6, 4, 7]
//    XCTAssert(indices == [2])
//    XCTAssert(filtered == [8, 6, 7])
//    resetState()
//
//    let last = array.removeLast()  // [3, 8, 1, 6, 4]
//    XCTAssert(indices == [2])
//    XCTAssert(removedObjects == [last])
//    XCTAssert(removedObjects == [7])
//    XCTAssert(filtered == [8, 6])
//    resetState()
//
//    let element = array.removeAtIndex(1)   // [3, 1, 6, 4]
//    XCTAssert(array.value == [3, 1, 6, 4])
//    XCTAssert(indices == [0])
//    XCTAssert(removedObjects == [element])
//    XCTAssert(removedObjects == [8])
//    XCTAssert(filtered == [6])
//    resetState()
//    
//    array.insertContentsOf([8, 9, 3], atIndex: 1)   // [3, 8, 9, 3, 1, 6, 4]
//    XCTAssert(array.value == [3, 8, 9, 3, 1, 6, 4])
//    XCTAssert(indices == [0, 1])
//    XCTAssert(filtered == [8, 9, 6])
//    resetState()
//
//    array[0] = 0     // [0, 8, 9, 3, 1, 6, 4]
//    XCTAssert(indices == [])
//    XCTAssert(removedObjects == [])
//    XCTAssert(filtered == [8, 9, 6])
//    resetState()
//    
//    array[0] = 10     // [10, 8, 9, 3, 1, 6, 4]
//    XCTAssert(indices == [0])
//    XCTAssert(filtered == [10, 8, 9, 6])
//    resetState()
//    
//    array[0] = 9     // [9, 8, 9, 3, 1, 6, 4]
//    XCTAssert(indices == [0])
//    XCTAssert(filtered == [9, 8, 9, 6])
//    resetState()
//    
//    array[0] = 3     // [3, 8, 9, 3, 1, 6, 4]
//    XCTAssert(indices == [0])
//    XCTAssert(filtered == [8, 9, 6])
//    resetState()
//    
//    array.removeAll(true)
//    XCTAssert(indices == [0, 1, 2])
//    XCTAssert(removedObjects == [8, 9, 6])
//  }
  
  func testArrayMap() {
    let array = DynamicArray<Int>([])
    let mapped = array.map { i, e in e * 2 }
    
    XCTAssertEqual(array.count, 0)
    XCTAssertEqual(mapped.count, 0)
    
    array.append(1)
    XCTAssertEqual(mapped.count, 1)
    XCTAssertEqual(mapped.observableCount.value, 1)
    XCTAssertEqual(mapped[0], 2)
    
    array.insert(2, atIndex: 0)
    XCTAssertEqual(mapped.count, 2)
    XCTAssertEqual(mapped.observableCount.value, 2)
    XCTAssertEqual(mapped[0], 4)
    XCTAssertEqual(mapped[1], 2)
    
    array.insertContentsOf([3, 4], atIndex: 1)
    XCTAssertEqual(mapped.count, 4)
    XCTAssertEqual(mapped.observableCount.value, 4)
    XCTAssertEqual(mapped[0], 4)
    XCTAssertEqual(mapped[1], 6)
    XCTAssertEqual(mapped[2], 8)
    XCTAssertEqual(mapped[3], 2)
    
    array.removeLast()
    XCTAssertEqual(mapped.count, 3)
    XCTAssertEqual(mapped.observableCount.value, 3)
    XCTAssertEqual(mapped[0], 4)
    XCTAssertEqual(mapped[1], 6)
    XCTAssertEqual(mapped[2], 8)
    
    array.removeAtIndex(1)
    XCTAssertEqual(mapped.count, 2)
    XCTAssertEqual(mapped.observableCount.value, 2)
    XCTAssertEqual(mapped[0], 4)
    XCTAssertEqual(mapped[1], 8)
    
    array.removeAll(true)
    XCTAssertEqual(mapped.count, 0)
  }
  
  func testArrayMapCallCount() {
    class Test {
      var value: Int
      init(_ value: Int) { self.value = value }
    }
    
    var callCount: Int = 0
    let array = DynamicArray<Int>([])
    let mapped = array.lazyMap { i, e -> Test in
      callCount++
      return Test(e)
    }
    
    XCTAssertEqual(mapped.count, 0)
    XCTAssertEqual(callCount, 0)
    
    array.append(1)
    XCTAssertEqual(callCount, 0)
    XCTAssertEqual(mapped.count, 1)
    
    XCTAssertEqual(mapped[0]().value, 1)
    XCTAssertEqual(callCount, 1, "Should call")
    
    XCTAssertEqual(mapped[0]().value, 1)
    XCTAssertEqual(callCount, 2, "Should call")
    
    array.insert(2, atIndex: 0)
    XCTAssertEqual(mapped.count, 2)
    XCTAssertEqual(callCount, 2)
    
    XCTAssertEqual(mapped[1]().value, 1)
    XCTAssertEqual(callCount, 3, "Should call")
    
    XCTAssertEqual(mapped[0]().value, 2)
    XCTAssertEqual(callCount, 4, "Should call")
    
    XCTAssertEqual(mapped[0]().value, 2)
    XCTAssertEqual(callCount, 5, "Should call")
    
    array.removeAtIndex(0)
    XCTAssertEqual(mapped.count, 1)
    XCTAssertEqual(callCount, 5)
    
    XCTAssertEqual(mapped[0]().value, 1)
    XCTAssertEqual(callCount, 6, "Should call")
    
    array.removeLast()
    XCTAssertEqual(mapped.count, 0)
    XCTAssertEqual(callCount, 6)
    
    array.insertContentsOf([1, 2, 3, 4], atIndex: 0)
    XCTAssertEqual(mapped.count, 4)
    XCTAssertEqual(callCount, 6)
    
    XCTAssertEqual(mapped[1]().value, 2)
    XCTAssertEqual(callCount, 7, "Should call")
    
    array.removeAtIndex(1)
    XCTAssertEqual(mapped.count, 3)
    XCTAssertEqual(callCount, 7)
    
    XCTAssertEqual(mapped[1]().value, 3)
    XCTAssertEqual(callCount, 8, "Should call")
    
    array.insert(2, atIndex: 1)
    XCTAssertEqual(mapped.count, 4)
    XCTAssertEqual(callCount, 8)
    
    XCTAssertEqual(mapped[2]().value, 3)
    XCTAssertEqual(callCount, 9, "Should call")
    
    XCTAssertEqual(mapped[1]().value, 2)
    XCTAssertEqual(callCount, 10, "Should call")
    
    XCTAssertEqual(mapped.last!().value, 4)
    XCTAssertEqual(callCount, 11, "Should call")
    
    XCTAssertEqual(mapped.last!().value, 4)
    XCTAssertEqual(callCount, 12, "Should call")
    
    XCTAssertEqual(mapped.first!().value, 1)
    XCTAssertEqual(callCount, 13, "Should call")
    
    XCTAssertEqual(mapped.first!().value, 1)
    XCTAssertEqual(callCount, 14, "Should call")
    
    array.removeAll(true)
    XCTAssertEqual(mapped.count, 0)
    XCTAssertEqual(callCount, 14)
  }
  
//  func testFilterMapChain() {
//    let array = DynamicArray<Int>([])
//    let filtered = array.filter { e in e > 2 }
//    let mapped = filtered.map { i, e in e * 2 }
//    
//    XCTAssert(array.count == 0)
//    XCTAssert(mapped.count == 0)
//    
//    array.append(1)
//    XCTAssert(mapped == [])
//    
//    array.insert(3, atIndex: 0)
//    XCTAssert(mapped == [6])
//    
//    array.insertContentsOf([1, 4], atIndex: 1)
//    XCTAssert(mapped == [6, 8])
//    
//    array.removeLast()
//    XCTAssert(mapped == [6, 8])
//    
//    array.removeAtIndex(2)
//    XCTAssert(mapped == [6])
//    
//    array.removeAll(true)
//    XCTAssert(mapped.count == 0)
//  }
  
  func testBasicDynCount() {
    let array = DynamicArray<Int>([])
    let updatedCount = Dynamic(0)
    array.observableCount ->| updatedCount
    
    XCTAssert(array.count == 0)
    
    array.append(1)
    XCTAssert(updatedCount.value == 1)
    XCTAssert(array.count == 1)
    
    array.value = [1, 2, 3, 4, 5]
    XCTAssert(updatedCount.value == 5)
    XCTAssert(array.count == 5)
    
    array.removeAtIndex(2)
    XCTAssert(updatedCount.value == 4)
    XCTAssert(array.count == 4)
  }
  
//  func testFilterDynCount() {
//    let array = DynamicArray<Int>([1, 2, 3, 4, 5])
//    let filtered = array.filter { e in e > 2 }
//    
//    let updatedCount = Dynamic(0)
//    filtered.observableCount ->> updatedCount
//    
//    XCTAssertEqual(updatedCount.value, 3)
//    
//    array.append([6, 1])
//    XCTAssertEqual(updatedCount.value, 4)
//    
//    array.removeAll(false)
//    XCTAssertEqual(updatedCount.value, 0)
//  }
  
  func testResetEventBasic() {
    let expectedBefore = [1, 2, 3], expectedAfter = [4, 5, 6]
    let array = DynamicArray(expectedBefore)
    let bond = ArrayBond<Int>()
    var testCount = 0
    bond.willResetListener = { array in
      testCount++
      XCTAssertEqual(array, expectedBefore, "before arrays don't match (\(array) vs \(expectedBefore))")
    }
    bond.didResetListener = { array in
      testCount++
      XCTAssertEqual(array, expectedAfter, "after arrays don't match (\(array) vs \(expectedAfter))")
    }
    array ->| bond
    
    array.value = expectedAfter
    
    XCTAssertEqual(testCount, 2, "reset events did not fire")
  }
  
  func testResetEventMapped() {
    let sourceBefore = [1, 2, 3], sourceAfter = [4, 5, 6]
    let expectedBefore = [2, 4, 6], expectedAfter = [8, 10, 12]
    let source = DynamicArray(sourceBefore)
    let array = source.map { $0 * 2 }
    let bond = ArrayBond<Int>()
    var testCount = 0
    bond.willResetListener = { array in
      testCount++
      XCTAssert(array == expectedBefore, "before arrays don't match (\(array) vs \(expectedBefore))")
    }
    bond.didResetListener = { array in
      testCount++
      XCTAssert(array == expectedAfter, "after arrays don't match (\(array) vs \(expectedAfter))")
    }
    array ->| bond
    
    source.value = sourceAfter
    
    XCTAssertEqual(testCount, 2, "reset events did not fire")
  }

//  func testResetEventFiltered() {
//    let sourceBefore = [1, 2, 3, 4], sourceAfter = [4, 5, 6, 7]
//    let expectedBefore = [2, 4], expectedAfter = [4, 6]
//    let source = DynamicArray(sourceBefore)
//    let array = source.filter { $0 % 2 == 0  }
//    let bond = ArrayBond<Int>()
//    var testCount = 0
//    bond.willResetListener = { array in
//      testCount++
//      XCTAssert(array == expectedBefore, "before arrays don't match (\(array) vs \(expectedBefore))")
//    }
//    bond.didResetListener = { array in
//      testCount++
//      XCTAssert(array == expectedAfter, "after arrays don't match (\(array) vs \(expectedAfter))")
//    }
//    array ->> bond
//    
//    source.value = sourceAfter
//    
//    XCTAssertEqual(testCount, 2, "reset events did not fire")
//  }

//  func testArrayDeliverOn() {
//    let array = DynamicArray<Int>([1, 2, 3])
//    let deliveredOn: ObservableArray<Int> = deliver(array, on: dispatch_get_main_queue())
//    let bond = ArrayBond<Int>()
//    
//    let e1 = expectationWithDescription("Insert")
//    let e2 = expectationWithDescription("Remove")
//    let e3 = expectationWithDescription("Update")
//    
//    bond.didInsertListener = { a, i in
//      XCTAssert(NSThread.isMainThread(), "Invalid queue")
//      e1.fulfill()
//    }
//    
//    bond.willRemoveListener = { a, i in
//      XCTAssert(NSThread.isMainThread(), "Invalid queue")
//      e2.fulfill()
//    }
//    
//    bond.willUpdateListener = { a, i in
//      XCTAssert(NSThread.isMainThread(), "Invalid queue")
//      e3.fulfill()
//    }
//        
//    deliveredOn ->| bond
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
//      array.append(10)
//    }
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
//      array.removeAtIndex(0)
//    }
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
//      array[0] = 2
//    }
//    
//    waitForExpectationsWithTimeout(1, handler: nil)
//  }
}
