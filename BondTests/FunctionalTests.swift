//
//  ReduceTests.swift
//  Bond
//
//  Created by Srdan Rasic on 23/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class ReduceTests: XCTestCase {
  
  func testMap() {
    let d1 = Dynamic<Int>(0)
    let m = d1.map { "\($0)" }
    
    XCTAssert(m.value == "0", "Initial value")
    XCTAssert(m.valid == true, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(m.value == "2", "Value after dynamic change")
  }
  
  func testObservableFlatMap() {
    class A {
      let b = Observable<B>(B())
    }

    class B {
      let c = Observable<String>("hello")
    }
    
    let o1 = Observable<A>(A())
    let fm = o1.flatMap { $0.b }.flatMap { $0.c }
    
    let a2 = A()
    a2.b.value.c.value = "yello"
    o1.value = a2
  
    XCTAssert(fm.value == "yello", "Value after parent observable change")
    
    let b3 = B()
    b3.c.value = "another"
    o1.value.b.value = b3
    
    XCTAssert(fm.value == "another", "Value after child observable change")
    
    let c4 = "yet another"
    o1.value.b.value.c.value = c4
    
    XCTAssert(fm.value == "yet another", "Value after child of child observable change")
  }
  
  func testFlatMap() {
    class A {
      let b = Dynamic<B>(B())
    }
    
    class B {
      var c = Dynamic<String>("hello")
    }
    
    let d1 = Dynamic<A>(A())
    let fm = d1.flatMap { $0.b }.flatMap { $0.c }
    
    XCTAssert(fm.value == "hello", "Initial value")
    XCTAssert(fm.valid == true, "Should not be faulty")
    
    let a2 = A()
    a2.b.value.c.value = "yello"
    d1.value = a2
    
    XCTAssert(fm.value == "yello", "Value after parent dynamic change")
    
    let b3 = B()
    b3.c.value = "another"
    d1.value.b.value = b3
    
    XCTAssert(fm.value == "another", "Value after child dynamic change")
    
    let c4 = "yet another"
    d1.value.b.value.c.value = c4
    
    XCTAssert(fm.value == "yet another", "Value after child of child dynamic change")
  }
  
  func testArrayFlatMap() {
    class A {
      let b = Dynamic<B>(B())
    }
    
    class B {
      var c = DynamicArray<String>(["hello"])
    }
    
    let d1 = Dynamic<A>(A())
    let fm = d1.flatMap { $0.b }.flatMap { $0.c }
    
    XCTAssertEqual(fm[0], "hello")
    XCTAssertEqual(fm.valid, true)
    
    let a2 = A()
    a2.b.value.c[0] = "yello"
    d1.value = a2
    
    XCTAssertEqual(fm[0], "yello")
    
    let b3 = B()
    b3.c[0] = "another"
    d1.value.b.value = b3
    
    XCTAssertEqual(fm[0], "another")
    
    let c4 = ["yet", "another"]
    d1.value.b.value.c.value = c4
    
    XCTAssertEqual(fm[0], "yet")
    XCTAssertEqual(fm[1], "another")
    XCTAssertEqual(fm.observableCount.value, 2)
  }
  
  func testArrayObservableCountFlatMap() {
    class A {
      var strings = ObservableArray<String>(["hello"])
    }
    
    var count: Int = 0
    let bond = Bond<Int> {
      count = $0
    }
    
    let dyn = Dynamic(A())
    let fm = dyn.flatMap { $0.strings }
    fm.observableCount.map { print("count: \($0)"); return $0 } ->> bond
    XCTAssertEqual(dyn.value.strings.observableCount.value, 1)
    XCTAssertEqual(dyn.value.strings.count, 1)
    XCTAssertEqual(count, 1)
    
    dyn.value.strings.value = ["hello", "world"]
    XCTAssertEqual(dyn.value.strings.observableCount.value, 2)
    XCTAssertEqual(dyn.value.strings.count, 2)
    XCTAssertEqual(count, 2)

    let newA = A()
    newA.strings = ObservableArray(["hello", "world", "!"])
    dyn.value = newA
    XCTAssertEqual(dyn.value.strings.observableCount.value, 3)
    XCTAssertEqual(dyn.value.strings.count, 3)
    XCTAssertEqual(count, 3)
    
    
    //model.flatMap { $0.tickets }.observableCount.map { print("ticketcount: \($0)"); return $0 == 0 } ->> ticketsList.dynHidden
  }
  
  func testDynamicFlatMapTwoWayBinding() {
    class A {
      let b = Dynamic<B>(B())
    }

    class B {
      let c = Dynamic<String>("hello")
    }
    
    let d1 = Dynamic<A>(A())
    let fm = d1.flatMap { $0.b }.flatMapTwoWay { $0.c }
  
    XCTAssert(fm.value == "hello", "Initial value")
    XCTAssert(fm.valid == true, "Should not be faulty")
    
    let d2 = Dynamic<String>("yello")

    d2 <->> fm
    
    XCTAssert(fm.value == "yello", "Value in flatMap after a two way bind")
    XCTAssert(d1.value.b.value.c.value == "yello", "Value in real dynamic after a two way bind")

    d2.value = "another"

    XCTAssert(fm.value == "another", "Value in flatMap after bound dynamic change")
    XCTAssert(d1.value.b.value.c.value == "another", "Value in real dynamic after bound dynamic change")

    let c4 = "yet another"
    d1.value.b.value.c.value = c4
    
    XCTAssert(fm.value == "yet another", "Value after child of child dynamic change")
    XCTAssert(d2.value == "yet another", "Value in bound dynamic after a child of child dynamic change")
  }
  
  func testFilter() {
    let d1 = Dynamic<Int>(0)
    let f = d1.filter { $0 > 5 }
    
    var observedValue = -1
    let bond = Bond<Int>() { v in observedValue = v }
    f ->> bond
    
    XCTAssert(f.valid == false, "Should be faulty")
    XCTAssert(observedValue == -1, "Should not update observed value")
    
    d1.value = 10
    XCTAssert(f.value == 10, "Value after dynamic change")
    XCTAssert(f.valid == true, "Should not be faulty")
    XCTAssert(observedValue == 10, "Should update observed value")
    
    d1.value = 2
    XCTAssert(f.value == 10, "Value after dynamic change")
    XCTAssert(f.valid == true, "Should not be faulty")
    XCTAssert(observedValue == 10, "Should update observed value")
  }
  
  func testReduce2() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    
    let r = reduce(d1, d2, *)
    
    XCTAssert(r.value == 2, "Initial value")
    XCTAssert(r.valid == true, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(r.value == 4, "Value after first dynamic change")
    
    d2.value = 3
    XCTAssert(r.value == 6, "Value after second dynamic change")
  }
  
  func testReduce3() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    let d3 = Dynamic<Int>(3)
    
    let r = reduce(d1, d2, d3) { $0 * $1 * $2 }
    
    XCTAssert(r.value == 6, "Initial value")
    XCTAssert(r.valid == true, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(r.value == 12, "Value after first dynamic change")
    
    d2.value = 3
    XCTAssert(r.value == 18, "Value after second dynamic change")
    
    d3.value = 2
    XCTAssert(r.value == 12, "Value after third dynamic change")
  }
  
  func testRewrite() {
    let d1 = Dynamic<Int>(0)
    let r = d1.rewrite("foo")
    
    XCTAssert(r.value == "foo", "Initial value")
    XCTAssert(r.valid == true, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(r.value == "foo", "Value after dynamic change")
  }
  
  func testZip1() {
    let d1 = Dynamic<Int>(0)
    let z = d1.zip("foo")
    
    XCTAssert(z.value.0 == 0 && z.value.1 == "foo", "Initial value")
    XCTAssert(z.valid == true, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(z.value.0 == 2 && z.value.1 == "foo", "Value after dynamic change")
  }
  
  func testZip2() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    
    let z = d1.zip(d2)
    
    XCTAssert(z.value.0 == 1 && z.value.1 == 2, "Initial value")
    XCTAssert(z.valid == true, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(z.value.0 == 2 && z.value.1 == 2, "Value after first dynamic change")
    
    d2.value = 3
    XCTAssert(z.value.0 == 2 && z.value.1 == 3, "Value after second dynamic change")
  }
  
  func testSkip() {
    let d1 = Dynamic<Int>(0)
    let s = d1.skip(1)
    
    var observedValue = -1
    let bond = Bond<Int>() { v in observedValue = v }
    s ->> bond
    
    XCTAssert(s.valid == false, "Should be faulty")
    XCTAssert(observedValue == -1, "Should not update observed value")
    
    d1.value = 1
    XCTAssert(s.valid == false, "Should still be faulty")
    XCTAssert(observedValue == -1, "Should not update observed value")
    
    d1.value = 2
    XCTAssert(s.valid == true, "Should not be faulty")
    XCTAssert(s.value == 2, "Value after dynamic change")
  }
  
  func testAny() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    
    let a = any([d1, d2])
    
    XCTAssert(a.valid == false, "Should be faulty")
    
    d1.value = 2
    XCTAssert(a.value == 2, "Value after first dynamic change")
    XCTAssert(a.valid == true, "Should not be faulty")
    
    d2.value = 3
    XCTAssert(a.value == 3, "Value after second dynamic change")
    XCTAssert(a.valid == true, "Should not be faulty")
  }
  
  func testThrottle() {
    let d1 = Dynamic<Int>(0)
    var dispatchedValues: [Int] = []
    
    let bond = Bond<Int> { value in
      dispatchedValues.append(value)
    }
    
    d1.throttle(0.1) ->> bond
    
    let expectation = expectationWithDescription("Values throttled")
    
    XCTAssertEqual(dispatchedValues, [0])
    for i in 1...50 {
      d1.value = i
    }
    XCTAssertEqual(dispatchedValues, [0])
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
      XCTAssertEqual(dispatchedValues, [0, 50])
      for i in 51...100 {
        d1.value = i
      }
      XCTAssertEqual(dispatchedValues, [0, 50])
      
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
        XCTAssertEqual(dispatchedValues, [0, 50, 100])
        expectation.fulfill()
      }
    }
    
    waitForExpectationsWithTimeout(1, handler: nil)
  }
  
  func testFilterMapChain() {
    var callCount = 0
    let d1 = Dynamic<Int>(0)
    
    let f = d1.filter { $0 > 5 }
    
    let m = f.map { (v: Int) -> String in
      callCount++
      return "\(v)"
    }
    
    XCTAssert(callCount == 0, "Count should be 0 instead of \(callCount)")
    
    var observedValue = ""
    let bond = Bond<String>() { v in observedValue = v }
    m ->> bond
    
    XCTAssert(callCount == 0, "Count should be 0 instead of \(callCount)")
    
    XCTAssert(f.valid == false, "Should be faulty")
    XCTAssert(m.valid == false, "Should be faulty")
    XCTAssert(observedValue == "", "Should not update observed value")
    
    d1.value = 2
    XCTAssert(f.valid == false, "Should still be faulty")
    XCTAssert(m.valid == false, "Should still be faulty")
    XCTAssert(observedValue == "", "Should not update observed value")
    XCTAssert(callCount == 0, "Count should still be 0 instead of \(callCount)")
    
    d1.value = 10
    XCTAssert(f.value == 10, "Value after dynamic change")
    XCTAssert(m.value == "10", "Value after dynamic change")
    XCTAssert(f.valid == true, "Should not be faulty")
    XCTAssert(m.valid == true, "Should not be faulty")
    XCTAssert(observedValue == "10", "Should update observed value")
    XCTAssert(callCount == 1, "Count should be 1 instead of \(callCount)")
  }
  
  func testDeliverOn() {
    let d1 = Dynamic<Int>(0)
    let deliveredOn = deliver(d1, on: dispatch_get_main_queue())
    
    let expectation = expectationWithDescription("Dynamic changed")
    
    let bond = Bond<Int>() { v in
      XCTAssert(v == 10, "Value after dynamic change")
      XCTAssert(NSThread.isMainThread(), "Invalid queue")
      expectation.fulfill()
    }
    
    deliveredOn ->| bond
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      d1.value = 10
    }
    
    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testDistinct() {
    var values = [Int]()
    let d1 = Dynamic<Int>(0)
    let bond = Bond<Int>() { v in values.append(v) }

    let distinctD1 = distinct(d1)

    distinctD1 ->> bond

    d1.value = 1
    d1.value = 2
    d1.value = 2
    d1.value = 3
    d1.value = 3
    d1.value = 3

    XCTAssert(values == [0, 1, 2, 3], "Values should equal [0, 1, 2, 3] instead of \(values)")
  }
}
