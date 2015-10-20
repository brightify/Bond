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

private func cast<T, U>(type: T.Type)(_ object: U) -> T? {
    return object as? T
}

private func takeFirst<A, B>(a: A, _ b: B) -> A {
    return a
}

// MARK: Array Bond

public class ArrayBond<T>: Bond<Array<T>> {
    public var willInsertListener: (([T], Range<Int>) -> Void)?
    public var didInsertListener: (([T], Range<Int>) -> Void)?
    
    public var willRemoveListener: (([T], Range<Int>) -> Void)?
    public var didRemoveListener: (([T], Range<Int>) -> Void)?
    
    public var willUpdateListener: (([T], Range<Int>) -> Void)?
    public var didUpdateListener: (([T], Range<Int>) -> Void)?
    
    public var willResetListener: ([T] -> Void)?
    public var didResetListener: ([T] -> Void)?
    
    public override init() {
        super.init()
    }
    
    override func fireListenerInternally(observable: Observable<[T]>) {
        willResetListener?(observable.value)
        super.fireListenerInternally(observable)
        didResetListener?(observable.value)
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
    public var observableCount: Observable<Int> {
        return map { $0.count }
    }
    
    public override var value: Array<T> {
        willSet {
            dispatchWillReset(noEventValue)
        }
        didSet {
            dispatchDidReset(noEventValue, callDispatch: false)
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
    
    public convenience override init() {
        self.init([])
    }
    
    public override init(_ value: Array<T>) {
        super.init(value)
    }
    
    public subscript(index: Int) -> T {
        get {
            return noEventValue[index]
        }
    }
    
    public func generate() -> ObservableArrayGenerator<T> {
        return ObservableArrayGenerator<T>(array: self)
    }
    
    private func dispatchWillReset(array: [T]) {
        bonds.map { $0.bond as? ArrayBond }.forEach { $0?.willResetListener?(array) }
    }
    
    private func dispatchDidReset(array: [T], callDispatch: Bool = true) {
        if callDispatch {
            dispatch(array)
        }
        bonds.map { $0.bond as? ArrayBond }.forEach { $0?.didResetListener?(array) }
    }
    
    private func dispatchWillInsert(array: [T], _ range: Range<Int>) {
        bonds.map { $0.bond as? ArrayBond }.forEach { $0?.willInsertListener?(array, range) }
    }
    
    private func dispatchDidInsert(array: [T], _ range: Range<Int>) {
        if !range.isEmpty {
            dispatch(array)
        }
        bonds.map { $0.bond as? ArrayBond }.forEach { $0?.didInsertListener?(array, range) }
    }
    
    private func dispatchWillRemove(array: [T], _ range: Range<Int>) {
        bonds.map { $0.bond as? ArrayBond }.forEach { $0?.willRemoveListener?(array, range) }
    }
    
    private func dispatchDidRemove(array: [T], _ range: Range<Int>) {
        if !range.isEmpty {
            dispatch(array)
        }
        
        bonds.map { $0.bond as? ArrayBond }.forEach { $0?.didRemoveListener?(array, range) }
    }
    
    private func dispatchWillUpdate(array: [T], _ range: Range<Int>) {
        bonds.map { $0.bond as? ArrayBond }.forEach { $0?.willUpdateListener?(array, range) }
    }
    
    private func dispatchDidUpdate(array: [T], _ range: Range<Int>) {
        if !range.isEmpty {
            dispatch(array)
        }
        bonds.map { $0.bond as? ArrayBond }.forEach { $0?.didUpdateListener?(array, range) }
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
        let range = noEventValue.endIndex ..< noEventValue.endIndex.successor()
        dispatchWillInsert(noEventValue, range)
        noEventValue.append(newElement)
        dispatchDidInsert(noEventValue, range)
    }
    
    public func append(array: Array<T>) {
        insertContentsOf(array, atIndex: noEventValue.count)
    }
    
    public func removeLast() -> T {
        guard count > 0 else { fatalError("Cannot removeLast() as there are no elements in the array!") }
        return removeAtIndex(noEventValue.endIndex - 1)
    }
    
    public func insert(newElement: T, atIndex i: Int) {
        let range = i ..< (i + 1)
        dispatchWillInsert(noEventValue, range)
        noEventValue.insert(newElement, atIndex: i)
        dispatchDidInsert(noEventValue, range)
    }
    
    public func insertContentsOf(array: Array<T>, atIndex i: Int) {
        guard array.count > 0 else { return }
        
        let range = i ..< i.advancedBy(array.count)
        dispatchWillInsert(noEventValue, range)
        noEventValue.insertContentsOf(array, at: i)
        dispatchDidInsert(noEventValue, range)
    }
    
    public func removeAtIndex(index: Int) -> T {
        let range = index ..< index.successor()
        dispatchWillRemove(noEventValue, range)
        let object = noEventValue.removeAtIndex(index)
        dispatchDidRemove(noEventValue, range)
        return object
    }
    
    public func removeAll(keepCapacity: Bool) {
        let range = 0 ..< noEventValue.count
        dispatchWillRemove(noEventValue, range)
        noEventValue.removeAll(keepCapacity: keepCapacity)
        dispatchDidRemove(noEventValue, range)
    }
    
    public override subscript(index: Int) -> T {
        get {
            return super[index]
        }
        set {
            if index == noEventValue.count {
                append(newValue)
            } else {
                let range = index ..< index.successor()
                dispatchWillUpdate(noEventValue, range)
                noEventValue[index] = newValue
                dispatchDidUpdate(noEventValue, range)
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
            self.noEventValue = $0
            self.dispatch($0)
        }
        
        arrayBond.willInsertListener = { [unowned self] array, range in
            self.dispatchWillInsert(self.noEventValue, range)
        }
        
        arrayBond.didInsertListener = { [unowned self] array, range in
            self.dispatchDidInsert(self.noEventValue, range)
        }
        
        arrayBond.willRemoveListener = { [unowned self] array, range in
            self.dispatchWillRemove(self.noEventValue, range)
        }
        
        arrayBond.didRemoveListener = { [unowned self] array, range in
            self.dispatchDidRemove(self.noEventValue, range)
        }
        
        arrayBond.willUpdateListener = { [unowned self] array, range in
            self.dispatchWillUpdate(self.noEventValue, range)
        }
        
        arrayBond.didUpdateListener = { [unowned self] array, range in
            self.dispatchDidUpdate(self.noEventValue, range)
        }
        
        arrayBond.willResetListener = { [unowned self] array in
            self.dispatchWillReset(self.noEventValue)
        }
        
        arrayBond.didResetListener = { [unowned self] array in
            self.dispatchDidReset(self.noEventValue)
        }
    }
}

public class LazyObservableArray<T>: ObservableArray<() -> T> {
    
    public override init(_ value: [() -> T]) {
        super.init(value)
    }
    
    public func eager() -> ObservableArray<T> {
        return map { $0() }
    }
    
    public func eager(range: Range<Int>) -> [T] {
        return noEventValue[range].map { $0() }
    }
    
    public func eager(index: Int) -> T {
        return noEventValue[index]()
    }
    
}

// MARK: Dynamic Array Map Proxy

private class LazyObservableArrayMapProxy<T, U>: LazyObservableArray<U> {
    private let bond: ArrayBond<T>
    
    private init(sourceArray: ObservableArray<T>, mapf: (Int, T) -> U) {
        bond = ArrayBond<T>()
        bond.bind(sourceArray, fire: false)
        
        let lazyArray = LazyObservableArrayMapProxy.createArray(sourceArray.noEventValue, mapf)
        
        super.init(lazyArray)
        
        bond.listener = { [unowned self] array in
            self.noEventValue = LazyObservableArrayMapProxy.createArray(array, mapf)
            self.dispatch(self.noEventValue)
        }
        
        bond.willInsertListener = { [unowned self] array, range in
            self.dispatchWillInsert(self.noEventValue, range)
        }
        
        bond.didInsertListener = { [unowned self] array, range in
            self.dispatchDidInsert(self.noEventValue, range)
        }
        
        bond.willRemoveListener = { [unowned self] array, range in
            self.dispatchWillRemove(self.noEventValue, range)
        }
        
        bond.didRemoveListener = { [unowned self] array, range in
            self.dispatchDidRemove(self.noEventValue, range)
        }
        
        bond.willUpdateListener = { [unowned self] array, range in
            self.dispatchWillUpdate(self.noEventValue, range)
        }
        
        bond.didUpdateListener = { [unowned self] array, range in
            self.dispatchDidUpdate(self.noEventValue, range)
        }
        
        bond.willResetListener = { [unowned self] array in
            self.dispatchWillReset(self.noEventValue)
        }
        
        bond.didResetListener = { [unowned self] array in
            self.dispatchDidReset(self.noEventValue)
        }
    }
    
    private static func createArray(sourceArray: [T], _ mapf: (Int, T) -> U) -> [() -> U] {
        guard sourceArray.count > 0 else { return [] }
        return (0..<sourceArray.count).map(createItem(sourceArray, mapf))
    }
    
    private static func createItem(sourceArray: [T], _ mapf: (Int, T) -> U)(_ index: Int)() -> U {
        return mapf(index, sourceArray[index])
    }
    
    
}

private class ObservableArrayMapProxy<T, U>: ObservableArray<U> {
    private let bond: ArrayBond<T>
    
    private init(sourceArray: ObservableArray<T>, mapf: (Int, T) -> U) {
        self.bond = ArrayBond<T>()
        self.bond.bind(sourceArray, fire: false)
        
        let array = sourceArray.value.enumerate().map(mapf)
        super.init(array)
        
        bond.listener = { [unowned self] array in
            self.noEventValue = array.enumerate().map(mapf)
            self.dispatch(self.noEventValue)
        }
        
        bond.willInsertListener = { [unowned self] array, range in
            self.dispatchWillInsert(self.noEventValue, range)
        }
        
        bond.didInsertListener = { [unowned self] array, range in
            self.dispatchDidInsert(self.noEventValue, range)
        }
        
        bond.willRemoveListener = { [unowned self] array, range in
            self.dispatchWillRemove(self.noEventValue, range)
        }
        
        bond.didRemoveListener = { [unowned self] array, range in
            self.dispatchDidRemove(self.noEventValue, range)
        }
        
        bond.willUpdateListener = { [unowned self] array, range in
            self.dispatchWillUpdate(self.noEventValue, range)
        }
        
        bond.didUpdateListener = { [unowned self] array, range in
            self.dispatchDidUpdate(self.noEventValue, range)
        }
        
        bond.willResetListener = { [unowned self] array in
            self.dispatchWillReset(self.noEventValue)
        }
        
        bond.didResetListener = { [unowned self] array in
            self.dispatchDidReset(self.noEventValue)
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
    private let filterf: T -> Bool
    private let bond: ArrayBond<T>
    
    private init(sourceArray: ObservableArray<T>, filterf: T -> Bool) {
        self.sourceArray = sourceArray
        self.filterf = filterf
        self.bond = ArrayBond<T>()
        self.bond.bind(sourceArray, fire: false)
        var pointers: [Int] = []
        let array = self.dynamicType.filteredArray(sourceArray.noEventValue, withPointers: &pointers, filterUsing: filterf)
        self.pointers = pointers
        
        super.init(array)
        
        bond.didInsertListener = { [unowned self] array, range in
            var pointers: [Int] = []
            let filtered = self.dynamicType.filteredArray(array[range], withPointers: &pointers, filterUsing: filterf)
            guard let firstPointer = pointers.first else { return }
            
            let startIndex = self.pointers.indexOfFirstEqualOrLargerThan(firstPointer)
            let insertedRange = startIndex ..< startIndex.advancedBy(filtered.count)

            self.dispatchWillInsert(self.noEventValue, insertedRange)
            
            self.noEventValue.insertContentsOf(filtered, at: startIndex)
            self.pointers.insertContentsOf(pointers, at: startIndex)
            
            self.dispatchDidInsert(self.noEventValue, insertedRange)
        }
        
        bond.willRemoveListener = { [unowned self] array, range in
            var pointers: [Int] = []
            let filtered = self.dynamicType.filteredArray(array[range], withPointers: &pointers, filterUsing: filterf)
            guard let firstPointer = pointers.first, let startIndex = self.pointers.indexOf(firstPointer) else { return }
            
            let removedRange = startIndex ..< startIndex.advancedBy(filtered.count)
            
            self.dispatchWillRemove(self.noEventValue, removedRange)
            
            self.noEventValue.removeRange(removedRange)
            self.pointers.removeRange(removedRange)
            
            self.dispatchDidRemove(self.noEventValue, removedRange)
        }
        
        bond.didUpdateListener = { [unowned self] array, range in
            
            //let idx = range.startIndex
            //let element = array[idx]
            
            var insertedIndices: [Int] = []
            var removedIndices: [Int] = []
            var updatedIndices: [Int] = []
            let pointers = self.pointers
            
            for i in range {
                let keep = filterf(array[i])
                let exists = pointers.contains(i)
                
                if exists && keep {
                    updatedIndices.append(i)
                } else if exists && !keep {
                    removedIndices.append(i)
                } else if keep {
                    insertedIndices.append(i)
                }
            }
            
            insertedIndices.map { (pointers.indexOfFirstEqualOrLargerThan($0 - 1), $0) }.forEach {
                print("inserted", $0, $1, array[$1])
                let insertedRange = $0...$0
                self.dispatchWillInsert(self.noEventValue, insertedRange)
                self.noEventValue.insert(array[$1], atIndex: $0)
                self.pointers.insert($1, atIndex: $0)
                self.dispatchDidInsert(self.noEventValue, insertedRange)
            }
            
            removedIndices.map(pointers.indexOf).forEach {
                guard let localIndex = $0 else { return }
                print("removed", localIndex, self.noEventValue[localIndex])
                let removedRange = localIndex...localIndex
                self.dispatchWillRemove(self.noEventValue, removedRange)
                self.noEventValue.removeAtIndex(localIndex)
                self.pointers.removeAtIndex(localIndex)
                self.dispatchDidRemove(self.noEventValue, removedRange)
            }
            
            updatedIndices.map { (pointers.indexOf($0), $0) }.forEach {
                guard let localIndex = $0 else { return }
                print("updated", localIndex, self.noEventValue[localIndex], $1, array[$1])
                let updatedRange = localIndex...localIndex
                self.dispatchWillUpdate(self.noEventValue, updatedRange)
                self.noEventValue[localIndex] = array[$1]
                self.dispatchDidUpdate(self.noEventValue, updatedRange)
            }
            
//            if let idx = pointers.indexOf(idx) {
//                if filterf(element) {
//                    // update
//                    updatedIndices.append(idx)
//                } else {
//                    // remove
//                    pointers.removeAtIndex(idx)
//                    removedIndices.append(idx)
//                }
//            } else {
//                if filterf(element) {
//                    let position = pointers.indexOfFirstEqualOrLargerThan(idx)
//                    pointers.insert(idx, atIndex: position)
//                    insertedIndices.append(position)
//                } else {
//                    // nothing
//                }
//            }
//            
//            if insertedIndices.count > 0 {
//                self.dispatchWillInsert(insertedIndices)
//            }
//            
//            if removedIndices.count > 0 {
//                self.dispatchWillRemove(removedIndices)
//            }
//            
//            if updatedIndices.count > 0 {
//                self.dispatchWillUpdate(updatedIndices)
//            }
//            
//            self.pointers = pointers
//            
//            if updatedIndices.count > 0 {
//                self.dispatchDidUpdate(updatedIndices)
//            }
//            
//            if removedIndices.count > 0 {
//                self.dispatchDidRemove(removedIndices)
//            }
//            
//            if insertedIndices.count > 0 {
//                self.dispatchDidInsert(insertedIndices)
//            }
        }
        
        bond.willResetListener = { [unowned self] array in
            self.dispatchWillReset(self.noEventValue)
        }
        
        bond.didResetListener = { [unowned self] array in
            self.noEventValue = self.dynamicType.filteredArray(array, withPointers: &self.pointers, filterUsing: filterf)
            self.dispatchDidReset(self.noEventValue)
        }
    }
    
    class func filteredArray<C: CollectionType where C.Generator.Element == T, C.Index == Int>(sourceArray: C, inout withPointers pointers: [Int], filterUsing filterf: T -> Bool) -> [T] {
        let filtered = sourceArray.enumerate().filter { filterf($0.element) }
        pointers = filtered.map { sourceArray.startIndex + $0.index }
        return filtered.map { $0.element }
    }
    
    class func rangesFromPointers(pointers: [Int]) -> [Range<Int>] {
        var insertedRanges: [Range<Int>] = []
        var currentRange: Range<Int>?
        for i in pointers {
            if let range = currentRange {
                if i == range.endIndex {
                    currentRange = range.startIndex...range.endIndex
                    continue
                } else {
                    insertedRanges.append(range)
                }
            }
            currentRange = i...i
        }
        if let range = currentRange {
            insertedRanges.append(range)
        }
        return insertedRanges
    }
//
//    override var value: [T] {
//        get {
//            return sourceArray.lazy.filter(filterf)
//        }
//        set(newValue) {
//            fatalError("Modifying proxy array is not supported!")
//        }
//    }
//    
//    private override var count: Int {
//        return pointers.count
//    }
//    
//    private override var capacity: Int {
//        return pointers.capacity
//    }
//    
//    private override var isEmpty: Bool {
//        return pointers.isEmpty
//    }
//    
//    private override var first: T? {
//        if let first = pointers.first {
//            return sourceArray[first]
//        } else {
//            return nil
//        }
//    }
//    
//    private override var last: T? {
//        if let last = pointers.last {
//            return sourceArray[last]
//        } else {
//            return nil
//        }
//    }
//    
//    override private subscript(index: Int) -> T {
//        get {
//            return sourceArray[pointers[index]]
//        }
//    }
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
        
        bond.willInsertListener = { [unowned self] array, range in
            dispatch_async(queue) { [weak self] in
                self?.dispatchWillInsert(array, range)
            }
        }
        
        bond.didInsertListener = { [unowned self] array, range in
            dispatch_async(queue) { [weak self] in
                self?.dispatchDidInsert(array, range)
            }
        }
        
        bond.willRemoveListener = { [unowned self] array, range in
            dispatch_async(queue) { [weak self] in
                self?.dispatchWillRemove(array, range)
            }
        }
        
        bond.didRemoveListener = { [unowned self] array, range in
            dispatch_async(queue) { [weak self] in
                self?.dispatchDidRemove(array, range)
            }
        }
        
        bond.willUpdateListener = { [unowned self] array, range in
            dispatch_async(queue) { [weak self] in
                self?.dispatchWillUpdate(array, range)
            }
        }
        
        bond.didUpdateListener = { [unowned self] array, range in
            dispatch_async(queue) { [weak self] in
                self?.dispatchDidUpdate(array, range)
            }
        }
        
        bond.willResetListener = { [unowned self] array in
            dispatch_async(queue) { [weak self] in
                self?.dispatchWillReset(array)
            }
        }
        
        bond.didResetListener = { [unowned self] array in
            dispatch_async(queue) { [weak self] in
                self?.dispatchDidReset(array)
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
