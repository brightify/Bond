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
  
  public typealias Element = T
  
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
    insertContentsOf(array, atIndex: noEventValue.count)
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
  
  public func insertContentsOf(array: Array<T>, atIndex i: Int) {
    if array.count > 0 {
      let indices = Array(i..<i+array.count)
      dispatchWillInsert(indices)
      noEventValue.insertContentsOf(array, at: i)
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
    arrayBond.listener = { [unowned self] in
      self.value = $0
    }
    
    arrayBond.willInsertListener = { [unowned self] array, i in
      self.dispatchWillInsert(i)
    }
    
    arrayBond.didInsertListener = { [unowned self] array, i in
      self.dispatchDidInsert(i)
    }
    
    arrayBond.willRemoveListener = { [unowned self] array, i in
      self.dispatchWillRemove(i)
    }
    
    arrayBond.didRemoveListener = { [unowned self] array, i in
      self.dispatchDidRemove(i)
    }
    
    arrayBond.willUpdateListener = { [unowned self] array, i in
      self.dispatchWillUpdate(i)
    }
    
    arrayBond.didUpdateListener = { [unowned self] array, i in
      self.dispatchDidUpdate(i)
    }
    
    arrayBond.willResetListener = { [unowned self] array in
      self.dispatchWillReset()
    }
    
    arrayBond.didResetListener = { [unowned self] array in
      self.dispatchDidReset()
    }
  }
}

public class LazyObservableArray<U>: ObservableArray<() -> U> {

  override init(_ value: [() -> U]) {
    super.init(value)
  }
  
  public func eager() -> ObservableArray<U> {
    return map { $0() }
  }
  
}

// MARK: Dynamic Array Map Proxy

private class LazyObservableArrayMapProxy<T, U>: LazyObservableArray<U> {
  private let bond: ArrayBond<T>
  
  private init(sourceArray: ObservableArray<T>, mapf: (Int, T) -> U) {
    bond = ArrayBond<T>()
    bond.bind(sourceArray, fire: false)
    
    let lazyArray = LazyObservableArrayMapProxy.createArray(sourceArray, mapf)

    super.init(lazyArray)
    
    bond.listener = { [unowned self] array in
      self.noEventValue = LazyObservableArrayMapProxy.createArray(array, mapf)
      self.tryDispatch(self.noEventValue)
    }
    
    bond.willInsertListener = { [unowned self] array, indices in
      self.dispatchWillInsert(indices)
    }
    
    bond.didInsertListener = { [unowned self] array, indices in
      self.noEventValue = LazyObservableArrayMapProxy.createArray(array, mapf)
      self.dispatchDidInsert(indices)
    }
    
    bond.willRemoveListener = { [unowned self] array, indices in
      self.dispatchWillRemove(indices)
    }
    
    bond.didRemoveListener = { [unowned self] array, indices in
      self.noEventValue = LazyObservableArrayMapProxy.createArray(array, mapf)
      self.dispatchDidRemove(indices)
    }
    
    bond.willUpdateListener = { [unowned self] array, indices in
      self.dispatchWillUpdate(indices)
    }
    
    bond.didUpdateListener = { [unowned self] array, indices in
      self.noEventValue = LazyObservableArrayMapProxy.createArray(array, mapf)
      self.dispatchDidUpdate(indices)
    }
    
    bond.willResetListener = { [unowned self] array in
      self.dispatchWillReset()
    }
    
    bond.didResetListener = { [unowned self] array in
      self.noEventValue = LazyObservableArrayMapProxy.createArray(array, mapf)
      self.dispatchDidReset()
    }
  }
  
  private static func createArray(sourceArray: [T], _ mapf: (Int, T) -> U) -> [() -> U] {
    guard sourceArray.count > 0 else { return [] }
    return (0..<sourceArray.count).map { i in return { mapf(i, sourceArray[i]) } }
  }
  
  private static func createArray(sourceArray: ObservableArray<T>, _ mapf: (Int, T) -> U) -> [() -> U] {
    guard sourceArray.count > 0 else { return [] }
    return (0..<sourceArray.count).map(createItem(sourceArray, mapf)).map(takeFirst)
  }
  
  private static func createItem(sourceArray: ObservableArray<T>, _ mapf: (Int, T) -> U)(_ index: Int) -> (element: () -> U, index: Int) {
    return (element: { [unowned sourceArray] in
        mapf(index, sourceArray[index])
    }, index: index)
  }
  
  
}

private func takeFirst<A, B>(a: A, _ b: B) -> A {
  return a
}

private class ObservableArrayMapProxy<T, U>: ObservableArray<U> {
  private let bond: ArrayBond<T>
  
  private init(sourceArray: ObservableArray<T>, mapf: (Int, T) -> U) {
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)

    let array = sourceArray.value.enumerate().map(mapf)
    super.init(array)
    
    bond.willInsertListener = { [unowned self] array, indices in
      self.dispatchWillInsert(indices)
    }
    
    bond.didInsertListener = { [unowned self] array, indices in
      indices.forEach {
        self.noEventValue.insert(mapf($0, array[$0]), atIndex: $0)
      }
      self.dispatchDidInsert(indices)
    }
    
    bond.willRemoveListener = { [unowned self] array, indices in
      self.dispatchWillRemove(indices)
    }
    
    bond.didRemoveListener = { [unowned self] array, indices in
      indices.sort(>).forEach {
        self.noEventValue.removeAtIndex($0)
      }
      self.dispatchDidRemove(indices)
    }
    
    bond.willUpdateListener = { [unowned self] array, indices in
      self.dispatchWillUpdate(indices)
    }
    
    bond.didUpdateListener = { [unowned self] array, indices in
      indices.forEach {
        self.noEventValue[$0] = mapf($0, array[$0])
      }
      self.dispatchDidUpdate(indices)
    }
    
    bond.willResetListener = { [unowned self] array in
      self.dispatchWillReset()
    }
    
    bond.didResetListener = { [unowned self] array in
      self.noEventValue = array.enumerate().map(mapf)
      self.dispatchDidReset()
    }
  }
  
  override var value: [U] {
    get {
      return super.value
    }
    set {
      fatalError("Modifying proxy array is not supported!")
    }
  }
}

private extension SequenceType where Generator.Element == Int {
  func indexOfFirstEqualOrLargerThan(x: Int) -> Int {
    var idx: Int = -1
    for (index, element) in self.enumerate() {
      if element < x {
        idx = index
      } else {
        break
      }
    }
    return idx + 1
  }
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

        for (index, element) in pointers.enumerate() {
          if element >= idx {
            pointers[index] = element + 1
          }
        }
        
        let element = array[idx]
        if filterf(element) {
          let position = pointers.indexOfFirstEqualOrLargerThan(idx)
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
      
      for idx in indices.reverse() {
        
        if let idx = pointers.indexOf(idx) {
          pointers.removeAtIndex(idx)
          removedIndices.append(idx)
        }
        
        for (index, element) in pointers.enumerate() {
          if element >= idx {
            pointers[index] = element - 1
          }
        }
      }
      
      if removedIndices.count > 0 {
        self.dispatchWillRemove(removedIndices.reverse())
      }
      
      self.pointers = pointers
      
      if removedIndices.count > 0 {
        self.dispatchDidRemove(removedIndices.reverse())
      }
    }
    
    bond.didUpdateListener = { [unowned self] array, indices in
      
      let idx = indices[0]
      let element = array[idx]

      var insertedIndices: [Int] = []
      var removedIndices: [Int] = []
      var updatedIndices: [Int] = []
      var pointers = self.pointers
      
      if let idx = pointers.indexOf(idx) {
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
          let position = pointers.indexOfFirstEqualOrLargerThan(idx)
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
    for (index, element) in sourceArray.enumerate() {
      if filterf(element) {
        pointers.append(index)
      }
    }
    return pointers
  }
  
  override var value: [T] {
    get {
      return sourceArray.lazy.filter(filterf)
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
  public func map<U>(f: (Int, T) -> U) -> ObservableArray<U> {
    return _map(self, f)
  }
  
  public func map<U>(f: T -> U) -> ObservableArray<U> {
    let mapf = { (i: Int, o: T) -> U in f(o) }
    return _map(self, mapf)
  }
  
  public func lazyMap<U>(f: (Int, T) -> U) -> LazyObservableArray<U> {
    return _lazyMap(self, f)
  }
  
  public func lazyMap<U>(f: T -> U) -> LazyObservableArray<U> {
    let mapf = { (i: Int, o: T) -> U in f(o) }
    return _lazyMap(self, mapf)
  }
  
  public func filter(f: T -> Bool) -> ObservableArray<T> {
    return _filter(self, f)
  }
}

// MARK: Map

private func _map<T, U>(dynamicArray: ObservableArray<T>, _ f: (Int, T) -> U) -> ObservableArrayMapProxy<T, U> {
  return ObservableArrayMapProxy(sourceArray: dynamicArray, mapf: f)
}

private func _lazyMap<T, U>(dynamicArray: ObservableArray<T>, _ f: (Int, T) -> U) -> LazyObservableArrayMapProxy<T, U> {
  return LazyObservableArrayMapProxy(sourceArray: dynamicArray, mapf: f)
}

// MARK: Filter

private func _filter<T>(dynamicArray: ObservableArray<T>, _ f: T -> Bool) -> ObservableArray<T> {
  return ObservableArrayFilterProxy(sourceArray: dynamicArray, filterf: f)
}

// MARK: DeliverOn

public func deliver<T>(dynamicArray: ObservableArray<T>, on queue: dispatch_queue_t) -> ObservableArray<T> {
  return ObservableArrayDeliverOnProxy(sourceArray: dynamicArray, queue: queue)
}
