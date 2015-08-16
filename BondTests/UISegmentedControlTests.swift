//
//  UISegmentedControlTests.swift
//  Bond
//
//  Created by Austin Cooley on 6/23/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UISegmentedControlTests: XCTestCase {
  
  func testUISegmentedControlDynamic() {
    let segmentedControl = UISegmentedControl()
    
    var observedValue = UIControlEvents.AllEvents
    let bond = Bond<UIControlEvents>() { v in observedValue = v }
    
    XCTAssert(segmentedControl.dynEvent.valid == false, "Should be faulty initially")
    
    segmentedControl.dynEvent.filter(==, .ValueChanged) ->> bond
    XCTAssert(observedValue == UIControlEvents.AllEvents, "Value after binding should not be changed")
    
    segmentedControl.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
    XCTAssert(observedValue == UIControlEvents.AllEvents, "Dynamic change does not pass test - should not update observedValue")
    
    segmentedControl.sendActionsForControlEvents(.ValueChanged)
    XCTAssert(observedValue == UIControlEvents.ValueChanged, "Dynamic change passes test - should update observedValue")
  }
  
  func testUISegmentedControlSelectedIndexDynamic() {
    let segmentedControl = UISegmentedControl(items: ["One", "Two", "Three"])
    
    var observedValue = -1000
    let bond = Bond<Int>() { observedValue = $0 }
    
    XCTAssert(segmentedControl.dynSelectedSegmentIndex.valid == true, "Should be valid initially")
    
    segmentedControl.dynSelectedSegmentIndex ->> bond
    XCTAssert(observedValue == -1, "Value after binding should be changed")
    
    segmentedControl.selectedSegmentIndex = 0
    segmentedControl.sendActionsForControlEvents(UIControlEvents.ValueChanged)
    XCTAssert(observedValue == 0, "Dynamic changes when an event is sent")
    
    let observable = Observable(1)
    observable ->> segmentedControl.dynSelectedSegmentIndex
    XCTAssert(observedValue == 1, "Binding an observable to the segmented control dynamic should fire the observing bond")
    XCTAssert(segmentedControl.selectedSegmentIndex == 1, "Binding an observable to the segmented control dynamic should change the selected segment index")
    
    observable.value = 2
    XCTAssert(observedValue == 2, "Changing the bound observable value should fire the bound bond.")
    XCTAssert(segmentedControl.selectedSegmentIndex == 2, "Changing the bound observable value should change the selected segment index")
  }
}

