//
//  Bond+Arrays.swift
//  Bond
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

// MARK: - Vector Dynamic

// MARK: Array Bond

public class ArrayBond<T>: Bond<Array<T>> {
  public var willInsertListener: ((ObservableArray<T>, [Int]) -> Void)?
  public var didInsertListener: ((ObservableArray<T>, [Int]) -> Void)?
  
  public var willRemoveListener: ((ObservableArray<T>, [Int]) -> Void)?
  public var didRemoveListener: ((ObservableArray<T>, [Int]) -> Void)?
  
  public var willUpdateListener: ((ObservableArray<T>, [Int]) -> Void)?
  public var didUpdateListener: ((ObservableArray<T>, [Int]) -> Void)?

  public var willResetListener: (ObservableArray<T> -> Void)?
  public var didResetListener: (ObservableArray<T> -> Void)?
  
  public override init() {
    super.init()
  }
}

public struct ObservableArrayGenerator<T>: GeneratorType {
  private var index = -1
  private let array: ObservableArray<T>
  
  init(array: ObservableArray<T>) {
    self.array = array
  }
  
  typealias Element = T
  
  public mutating func next() -> T? {
    index++
    return index < array.count ? array[index] : nil
  }
}

// MARK: Observable array

public class ObservableArray<T>: Observable<Array<T>>, SequenceType {
  public let observableCount: Observable<Int> = Observable(0)
  
  public override var value: Array<T> {
    willSet {
      dispatchWillReset()
    }
    didSet {
      dispatchDidReset()
    }
  }
  
  public var count: Int {
    return noEventValue.count
  }
  
  public var capacity: Int {
    return noEventValue.capacity
  }
  
  public var isEmpty: Bool {
    return noEventValue.isEmpty
  }
  
  public var first: T? {
    return noEventValue.first
  }
  
  public var last: T? {
    return noEventValue.last
  }
  
  public convenience init() {
    self.init([])
  }
  
  public override init(_ value: Array<T>) {
    super.init(value)
    observableCount.value = count
  }
  
  public subscript(index: Int) -> T {
    get {
      return noEventValue[index]
    }
  }
  
  public func generate() -> ObservableArrayGenerator<T> {
    return ObservableArrayGenerator<T>(array: self)
  }
  
  private func dispatchWillReset() {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willResetListener?(self)
      }
    }
  }
  
  private func dispatchDidReset() {
    observableCount.value = self.count
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didResetListener?(self)
      }
    }
  }
  
  private func dispatchWillInsert(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willInsertListener?(self, indices)
      }
    }
  }
  
  private func dispatchDidInsert(indices: [Int]) {
    if !indices.isEmpty {
      observableCount.value = count
    }
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didInsertListener?(self, indices)
      }
    }
  }
  
  private func dispatchWillRemove(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willRemoveListener?(self, indices)
      }
    }
  }
  
  private func dispatchDidRemove(indices: [Int]) {
    if !indices.isEmpty {
      observableCount.value = count
    }
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didRemoveListener?(self, indices)
      }
    }
  }
  
  private func dispatchWillUpdate(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willUpdateListener?(self, indices)
      }
    }
  }
  
  private func dispatchDidUpdate(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didUpdateListener?(self, indices)
      }
    }
  }
}

public class MutableObservableArray<T>: ObservableArray<T> {
  
  public convenience init() {
    self.init([])
  }
  
  public override init(_ value: Array<T>) {
    super.init(value)
  }
  
  public func append(newElement: T) {
    dispatchWillInsert([noEventValue.count])
    noEventValue.append(newElement)
    dispatchDidInsert([noEventValue.count-1])
  }
  
  public func append(array: Array<T>) {
    splice(array, atIndex: noEventValue.count)
  }
  
  public func removeLast() -> T {
    if count > 0 {
      dispatchWillRemove([noEventValue.count-1])
      let last = noEventValue.removeLast()
      dispatchDidRemove([noEventValue.count])
      return last
    }
    
    fatalError("Cannot removeLast() as there are no elements in the array!")
  }
  
  public func insert(newElement: T, atIndex i: Int) {
    dispatchWillInsert([i])
    noEventValue.insert(newElement, atIndex: i)
    dispatchDidInsert([i])
  }
  
  public func splice(array: Array<T>, atIndex i: Int) {
    if array.count > 0 {
      let indices = Array(i..<i+array.count)
      dispatchWillInsert(indices)
      noEventValue.splice(array, atIndex: i)
      dispatchDidInsert(indices)
    }
  }
  
  public func removeAtIndex(index: Int) -> T {
    dispatchWillRemove([index])
    let object = noEventValue.removeAtIndex(index)
    dispatchDidRemove([index])
    return object
  }
  
  public func removeAll(keepCapacity: Bool) {
    let count = noEventValue.count
    let indices = Array(0..<count)
    dispatchWillRemove(indices)
    noEventValue.removeAll(keepCapacity: keepCapacity)
    dispatchDidRemove(indices)
  }
  
  public override subscript(index: Int) -> T {
    get {
      return super[index]
    }
    set(newObject) {
      if index == noEventValue.count {
        dispatchWillInsert([index])
        noEventValue[index] = newObject
        dispatchDidInsert([index])
      } else {
        dispatchWillUpdate([index])
        noEventValue[index] = newObject
        dispatchDidUpdate([index])
      }
    }
  }
}

// MARK: Dynamic array

/**
Note: Directly setting `DynamicArray.value` is not recommended. The array's count will not be updated and no array change notification will be emitted. Call `setArray:` instead.
*/
public class DynamicArray<T>: MutableObservableArray<T>, Bondable {
  public let arrayBond: ArrayBond<T> = ArrayBond()
  
  public var designatedBond: Bond<Array<T>> {
    return arrayBond
  }
  
  public convenience init() {
    self.init([])
  }
  
  public override init(_ array: Array<T>) {
    super.init(array)
    arrayBond.listener = { [unowned self] in self.value = $0 }
  }
}

// MARK: Dynamic Array Map Proxy

private class ObservableArrayMapProxy<T, U>: ObservableArray<U> {
  private unowned var sourceArray: ObservableArray<T>
  private var mapf: (T, Int) -> U
  private let bond: ArrayBond<T>
  
  private init(sourceArray: ObservableArray<T>, mapf: (T, Int) -> U) {
    self.sourceArray = sourceArray
    self.mapf = mapf
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)
    super.init([])
    
    bond.willInsertListener = { [unowned self] array, i in
      self.dispatchWillInsert(i)
    }
    
    bond.didInsertListener = { [unowned self] array, i in
      self.dispatchDidInsert(i)
    }
    
    bond.willRemoveListener = { [unowned self] array, i in
      self.dispatchWillRemove(i)
    }
    
    bond.didRemoveListener = { [unowned self] array, i in
      self.dispatchDidRemove(i)
    }
    
    bond.willUpdateListener = { [unowned self] array, i in
      self.dispatchWillUpdate(i)
    }
    
    bond.didUpdateListener = { [unowned self] array, i in
      self.dispatchDidUpdate(i)
    }
    
    bond.willResetListener = { [unowned self] array in
      self.dispatchWillReset()
    }
    
    bond.didResetListener = { [unowned self] array in
      self.dispatchDidReset()
    }
  }
  
  override var value: [U] {
    get {
      fatalError("Getting proxy array value is not supported!")
    }
    set {
      fatalError("Modifying proxy array is not supported!")
    }
  }
  
  override var count: Int {
    return sourceArray.count
  }
  
  override var capacity: Int {
    return sourceArray.capacity
  }
  
  override var isEmpty: Bool {
    return sourceArray.isEmpty
  }
  
  override var first: U? {
    if let first = sourceArray.first {
      return mapf(first, 0)
    } else {
      return nil
    }
  }
  
  override var last: U? {
    if let last = sourceArray.last {
      return mapf(last, sourceArray.count - 1)
    } else {
      return nil
    }
  }
  
  override subscript(index: Int) -> U {
    get {
        return mapf(sourceArray[index], index)
    }
  }
}

func indexOfFirstEqualOrLargerThan(x: Int, array: [Int]) -> Int {
  var idx: Int = -1
  for (index, element) in enumerate(array) {
    if element < x {
      idx = index
    } else {
      break
    }
  }
  return idx + 1
}

// MARK: Dynamic Array Filter Proxy

private class ObservableArrayFilterProxy<T>: ObservableArray<T> {
  private unowned var sourceArray: ObservableArray<T>
  private var pointers: [Int]
  private var filterf: T -> Bool
  private let bond: ArrayBond<T>
  
  private init(sourceArray: ObservableArray<T>, filterf: T -> Bool) {
    self.sourceArray = sourceArray
    self.filterf = filterf
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)
    
    self.pointers = ObservableArrayFilterProxy.pointersFromSource(sourceArray, filterf: filterf)
    
    super.init([])

    bond.didInsertListener = { [unowned self] array, indices in
      var insertedIndices: [Int] = []
      var pointers = self.pointers
      
      for idx in indices {

        for (index, element) in enumerate(pointers) {
          if element >= idx {
            pointers[index] = element + 1
          }
        }
        
        let element = array[idx]
        if filterf(element) {
          let position = indexOfFirstEqualOrLargerThan(idx, pointers)
          pointers.insert(idx, atIndex: position)
          insertedIndices.append(position)
        }
      }
      
      if insertedIndices.count > 0 {
       self.dispatchWillInsert(insertedIndices)
      }
      
      self.pointers = pointers
      
      if insertedIndices.count > 0 {
        self.dispatchDidInsert(insertedIndices)
      }
    }
    
    bond.willRemoveListener = { [unowned self] array, indices in
      var removedIndices: [Int] = []
      var pointers = self.pointers
      
      for idx in reverse(indices) {
        
        if let idx = find(pointers, idx) {
          pointers.removeAtIndex(idx)
          removedIndices.append(idx)
        }
        
        for (index, element) in enumerate(pointers) {
          if element >= idx {
            pointers[index] = element - 1
          }
        }
      }
      
      if removedIndices.count > 0 {
        self.dispatchWillRemove(reverse(removedIndices))
      }
      
      self.pointers = pointers
      
      if removedIndices.count > 0 {
        self.dispatchDidRemove(reverse(removedIndices))
      }
    }
    
    bond.didUpdateListener = { [unowned self] array, indices in
      
      let idx = indices[0]
      let element = array[idx]

      var insertedIndices: [Int] = []
      var removedIndices: [Int] = []
      var updatedIndices: [Int] = []
      var pointers = self.pointers
      
      if let idx = find(pointers, idx) {
        if filterf(element) {
          // update
          updatedIndices.append(idx)
        } else {
          // remove
          pointers.removeAtIndex(idx)
          removedIndices.append(idx)
        }
      } else {
        if filterf(element) {
          let position = indexOfFirstEqualOrLargerThan(idx, pointers)
          pointers.insert(idx, atIndex: position)
          insertedIndices.append(position)
        } else {
          // nothing
        }
      }

      if insertedIndices.count > 0 {
        self.dispatchWillInsert(insertedIndices)
      }
      
      if removedIndices.count > 0 {
        self.dispatchWillRemove(removedIndices)
      }
      
      if updatedIndices.count > 0 {
        self.dispatchWillUpdate(updatedIndices)
      }
      
      self.pointers = pointers
      
      if updatedIndices.count > 0 {
        self.dispatchDidUpdate(updatedIndices)
      }
      
      if removedIndices.count > 0 {
        self.dispatchDidRemove(removedIndices)
      }
      
      if insertedIndices.count > 0 {
        self.dispatchDidInsert(insertedIndices)
      }
    }

    bond.willResetListener = { [unowned self] array in
      self.dispatchWillReset()
    }
    
    bond.didResetListener = { [unowned self] array in
      self.pointers = ObservableArrayFilterProxy.pointersFromSource(array, filterf: filterf)
      self.dispatchDidReset()
    }
  }
  
  class func pointersFromSource(sourceArray: ObservableArray<T>, filterf: T -> Bool) -> [Int] {
    var pointers = [Int]()
    for (index, element) in enumerate(sourceArray) {
      if filterf(element) {
        pointers.append(index)
      }
    }
    return pointers
  }
  
  override var value: [T] {
    get {
      fatalError("Getting proxy array value is not supported!")
    }
    set(newValue) {
      fatalError("Modifying proxy array is not supported!")
    }
  }
  
  private override var count: Int {
    return pointers.count
  }
  
  private override var capacity: Int {
    return pointers.capacity
  }
  
  private override var isEmpty: Bool {
    return pointers.isEmpty
  }
  
  private override var first: T? {
    if let first = pointers.first {
      return sourceArray[first]
    } else {
      return nil
    }
  }
  
  private override var last: T? {
    if let last = pointers.last {
      return sourceArray[last]
    } else {
      return nil
    }
  }
  
  override private subscript(index: Int) -> T {
    get {
      return sourceArray[pointers[index]]
    }
  }
}

// MARK: Dynamic Array DeliverOn Proxy

private class ObservableArrayDeliverOnProxy<T>: ObservableArray<T> {
  private unowned var sourceArray: ObservableArray<T>
  private var queue: dispatch_queue_t
  private let bond: ArrayBond<T>
  
  private init(sourceArray: ObservableArray<T>, queue: dispatch_queue_t) {
    self.sourceArray = sourceArray
    self.queue = queue
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)
    super.init([])
    
    bond.willInsertListener = { [unowned self] array, i in
      dispatch_async(queue) { [weak self] in
        self?.dispatchWillInsert(i)
      }
    }
    
    bond.didInsertListener = { [unowned self] array, i in
      dispatch_async(queue) { [weak self] in
        self?.dispatchDidInsert(i)
      }
    }
    
    bond.willRemoveListener = { [unowned self] array, i in
      dispatch_async(queue) { [weak self] in
        self?.dispatchWillRemove(i)
      }
    }
    
    bond.didRemoveListener = { [unowned self] array, i in
      dispatch_async(queue) { [weak self] in
        self?.dispatchDidRemove(i)
      }
    }
    
    bond.willUpdateListener = { [unowned self] array, i in
      dispatch_async(queue) { [weak self] in
        self?.dispatchWillUpdate(i)
      }
    }
    
    bond.didUpdateListener = { [unowned self] array, i in
      dispatch_async(queue) { [weak self] in
        self?.dispatchDidUpdate(i)
      }
    }
    
    bond.willResetListener = { [unowned self] array in
      dispatch_async(queue) { [weak self] in
        self?.dispatchWillReset()
      }
    }
    
    bond.didResetListener = { [unowned self] array in
      dispatch_async(queue) { [weak self] in
        self?.dispatchDidReset()
      }
    }
  }
  
  override var value: [T] {
    get {
      fatalError("Getting proxy array value is not supported!")
    }
    set(newValue) {
      fatalError("Modifying proxy array is not supported!")
    }
  }
  
  override var count: Int {
    return sourceArray.count
  }
  
  override var capacity: Int {
    return sourceArray.capacity
  }
  
  override var isEmpty: Bool {
    return sourceArray.isEmpty
  }
  
  override var first: T? {
    if let first = sourceArray.first {
      return first
    } else {
      return nil
    }
  }
  
  override var last: T? {
    if let last = sourceArray.last {
      return last
    } else {
      return nil
    }
  }
  
  override subscript(index: Int) -> T {
    get {
      return sourceArray[index]
    }
  }
}

// MARK: Dynamic Array additions
public extension ObservableArray
{
  public func map<U>(f: (T, Int) -> U) -> ObservableArray<U> {
    return _map(self, f)
  }
  
  public func map<U>(f: T -> U) -> ObservableArray<U> {
    let mapf = { (o: T, i: Int) -> U in f(o) }
    return _map(self, mapf)
  }
  
  public func filter(f: T -> Bool) -> ObservableArray<T> {
    return _filter(self, f)
  }
}

// MARK: Map

private func _map<T, U>(dynamicArray: ObservableArray<T>, f: (T, Int) -> U) -> ObservableArrayMapProxy<T, U> {
  return ObservableArrayMapProxy(sourceArray: dynamicArray, mapf: f)
}

// MARK: Filter

private func _filter<T>(dynamicArray: ObservableArray<T>, f: T -> Bool) -> ObservableArray<T> {
  return ObservableArrayFilterProxy(sourceArray: dynamicArray, filterf: f)
}

// MARK: DeliverOn

public func deliver<T>(dynamicArray: ObservableArray<T>, on queue: dispatch_queue_t) -> ObservableArray<T> {
  return ObservableArrayDeliverOnProxy(sourceArray: dynamicArray, queue: queue)
}
