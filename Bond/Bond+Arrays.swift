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
        insertContentsOf(array, at: noEventValue.count)
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
    
    public func insertContentsOf<C : CollectionType where C.Generator.Element == T, C.Index.Distance == Int>(newElements: C, at i: Int) {
        guard newElements.count > 0 else { return }
        newElements.count
        let range = i ..< i.advancedBy(newElements.count)
        dispatchWillInsert(noEventValue, range)
        noEventValue.insertContentsOf(newElements, at: i)
        dispatchDidInsert(noEventValue, range)
    }
    
    public func removeAtIndex(index: Int) -> T {
        let range = index ..< index.successor()
        dispatchWillRemove(noEventValue, range)
        let object = noEventValue.removeAtIndex(index)
        dispatchDidRemove(noEventValue, range)
        return object
    }
    
    public func removeRange(subRange: Range<Int>) {
        dispatchWillRemove(noEventValue, subRange)
        noEventValue.removeRange(subRange)
        dispatchDidRemove(noEventValue, subRange)
    }
    
    public func removeAll(keepCapacity: Bool) {
        let range = 0 ..< noEventValue.count
        dispatchWillRemove(noEventValue, range)
        noEventValue.removeAll(keepCapacity: keepCapacity)
        dispatchDidRemove(noEventValue, range)
    }
    
    public func replaceRange<C: CollectionType where C.Generator.Element == T, C.Index == Int>(subRange: Range<Int>, with newElements: C) {
        // Check if the backing value contains the subRange
        if subRange.count == newElements.count {
            dispatchWillUpdate(noEventValue, subRange)
            subRange.enumerate().forEach {
                self.noEventValue[$1] = newElements[$0]
            }
            dispatchDidUpdate(noEventValue, subRange)
        } else {
            removeRange(subRange)
            insertContentsOf(newElements, at: subRange.startIndex)
        }
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
        arrayBond.listener = { [weak self] in
            guard let s = self else { return }
            s.noEventValue = $0
            s.dispatch($0)
        }
        
        arrayBond.willInsertListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillInsert(s.noEventValue, range)
        }
        
        arrayBond.didInsertListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidInsert(s.noEventValue, range)
        }
        
        arrayBond.willRemoveListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillRemove(s.noEventValue, range)
        }
        
        arrayBond.didRemoveListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidRemove(s.noEventValue, range)
        }
        
        arrayBond.willUpdateListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillUpdate(s.noEventValue, range)
        }
        
        arrayBond.didUpdateListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidUpdate(s.noEventValue, range)
        }
        
        arrayBond.willResetListener = { [weak self] array in
            guard let s = self else { return }
            s.dispatchWillReset(s.noEventValue)
        }
        
        arrayBond.didResetListener = { [weak self] array in
            guard let s = self else { return }
            s.dispatchDidReset(s.noEventValue)
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
        
        bond.listener = { [weak self] array in
            guard let s = self else { return }
            s.noEventValue = LazyObservableArrayMapProxy.createArray(array, mapf)
            s.dispatch(s.noEventValue)
        }
        
        bond.willInsertListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillInsert(s.noEventValue, range)
        }
        
        bond.didInsertListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidInsert(s.noEventValue, range)
        }
        
        bond.willRemoveListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillRemove(s.noEventValue, range)
        }
        
        bond.didRemoveListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidRemove(s.noEventValue, range)
        }
        
        bond.willUpdateListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillUpdate(s.noEventValue, range)
        }
        
        bond.didUpdateListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidUpdate(s.noEventValue, range)
        }
        
        bond.willResetListener = { [weak self] array in
            guard let s = self else { return }
            s.dispatchWillReset(s.noEventValue)
        }
        
        bond.didResetListener = { [weak self] array in
            guard let s = self else { return }
            s.dispatchDidReset(s.noEventValue)
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

private class FlatMapContainer<T> {
    private let bond: ArrayBond<T> = .init()
    private let previous: FlatMapContainer<T>?
    private let target: ObservableArray<T>
    
    private var count: Int = 0

    private init(previous: FlatMapContainer<T>?, parent: MutableObservableArray<T>, target: ObservableArray<T>) {
        self.previous = previous
        self.target = target
        self.count = target.count
        bond.bind(target, fire: false)
        
        bond.didInsertListener = { [weak self, weak parent] array, range in
            guard let s = self, parent = parent else { return }
            parent.insertContentsOf(array[range], at: s.absoluteIndex(range.startIndex))
            s.count = array.count
        }
        
        bond.didRemoveListener = { [weak self, weak parent] array, range in
            guard let s = self, parent = parent else { return }
            parent.removeRange(s.absoluteRange(range))
            s.count = array.count
        }
        
        bond.didUpdateListener = { [weak self, weak parent] array, range in
            guard let s = self, parent = parent else { return }
            parent.replaceRange(s.absoluteRange(range), with: array[range])
        }
        
        bond.didResetListener = { [weak self, weak parent] array in
            guard let s = self, parent = parent else { return }
            parent.replaceRange(s.range, with: array)
            s.count = array.count
        }
    }
    
    private var range: Range<Int> {
        let startIndex = previous?.range.endIndex ?? 0
        return startIndex ..< startIndex + count
    }
    
    private func absoluteIndex(relativeIndex: Int) -> Int {
        return range.startIndex + relativeIndex
    }
    
    private func absoluteRange(relativeRange: Range<Int>) -> Range<Int> {
        let startIndex = range.startIndex
        return (startIndex + relativeRange.startIndex) ..< (startIndex + relativeRange.endIndex)
    }
    
}

private class ObservableArrayFlatMapProxy<T, U>: MutableObservableArray<U> {
    private let bond: ArrayBond<T> = .init()

    private var lastSubarrayLink: FlatMapContainer<U>?
    
    private init(sourceArray: ObservableArray<T>, mapf: (Int, T) -> ObservableArray<U>) {
        bond.bind(sourceArray, fire: false)
        
        super.init([])
        noEventValue = sourceArray.value.enumerate().map(mapf)
            .reduce([], combine: ObservableArrayFlatMapProxy.bindSubarrays(&lastSubarrayLink, parent: self))
        
        bond.listener = { [weak self] array in
            guard let s = self else { return }
            s.lastSubarrayLink = nil
            s.noEventValue = sourceArray.value.enumerate().map(mapf)
                .reduce([], combine: ObservableArrayFlatMapProxy.bindSubarrays(&s.lastSubarrayLink, parent: s))
            s.dispatch(s.noEventValue)
        }
        
        bond.willInsertListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillInsert(s.noEventValue, range)
        }
        
        bond.didInsertListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidInsert(s.noEventValue, range)
        }
        
        bond.willRemoveListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillRemove(s.noEventValue, range)
        }
        
        bond.didRemoveListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidRemove(s.noEventValue, range)
        }
        
        bond.willUpdateListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillUpdate(s.noEventValue, range)
        }
        
        bond.didUpdateListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidUpdate(s.noEventValue, range)
        }
        
        bond.willResetListener = { [weak self] array in
            guard let s = self else { return }
            s.dispatchWillReset(s.noEventValue)
        }
        
        bond.didResetListener = { [weak self] array in
            guard let s = self else { return }
            s.dispatchDidReset(s.noEventValue)
        }
    }
    
    private static func bindSubarrays(inout lastSubarrayLink: FlatMapContainer<U>?, parent: MutableObservableArray<U>)(accumulator: [U], array: ObservableArray<U>) -> [U] {
        lastSubarrayLink = FlatMapContainer<U>(previous: lastSubarrayLink, parent: parent, target: array)
        return accumulator + array.value
    }
}

private class ObservableArrayValueFlatMapProxy<T, U>: MutableObservableArray<U> {
    private let bond: ArrayBond<T> = .init()
    
    private var valueBonds: [Bond<U>] = []
    
    private init(sourceArray: ObservableArray<T>, mapf: (Int, T) -> Observable<U>) {
        bond.bind(sourceArray, fire: false)
        
        super.init([])
        noEventValue = sourceArray.value.enumerate().map(mapf).enumerate()
            .map(ObservableArrayValueFlatMapProxy.bindValues(&valueBonds, parent: self))
        
        bond.listener = { [weak self] array in
            guard let s = self else { return }
            s.valueBonds = []
            s.noEventValue = sourceArray.value.enumerate().map(mapf).enumerate()
                .map(ObservableArrayValueFlatMapProxy.bindValues(&s.valueBonds, parent: s))
            s.dispatch(s.noEventValue)
        }
        
        bond.willInsertListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillInsert(s.noEventValue, range)
        }
        
        bond.didInsertListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidInsert(s.noEventValue, range)
        }
        
        bond.willRemoveListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillRemove(s.noEventValue, range)
        }
        
        bond.didRemoveListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidRemove(s.noEventValue, range)
        }
        
        bond.willUpdateListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillUpdate(s.noEventValue, range)
        }
        
        bond.didUpdateListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidUpdate(s.noEventValue, range)
        }
        
        bond.willResetListener = { [weak self] array in
            guard let s = self else { return }
            s.dispatchWillReset(s.noEventValue)
        }
        
        bond.didResetListener = { [weak self] array in
            guard let s = self else { return }
            s.dispatchDidReset(s.noEventValue)
        }
    }
    
    private static func bindValues(inout valueBonds: [Bond<U>], parent: MutableObservableArray<U>)(index: Int, value: Observable<U>) -> U {
        let bond = Bond<U> { [unowned parent] in
            parent[index] = $0
        }
        bond.bind(value, fire: false)
        valueBonds.append(bond)
        return value.value
    }
}

private class ObservableArrayMapProxy<T, U>: ObservableArray<U> {
    private let bond: ArrayBond<T>
    
    private init(sourceArray: ObservableArray<T>, mapf: (Int, T) -> U) {
        self.bond = ArrayBond<T>()
        self.bond.bind(sourceArray, fire: false)
        
        let array = sourceArray.value.enumerate().map(mapf)
        super.init(array)
        
        bond.listener = { [weak self] array in
            guard let s = self else { return }
            s.noEventValue = array.enumerate().map(mapf)
            s.dispatch(s.noEventValue)
        }
        
        bond.willInsertListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillInsert(s.noEventValue, range)
        }
        
        bond.didInsertListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidInsert(s.noEventValue, range)
        }
        
        bond.willRemoveListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillRemove(s.noEventValue, range)
        }
        
        bond.didRemoveListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidRemove(s.noEventValue, range)
        }
        
        bond.willUpdateListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchWillUpdate(s.noEventValue, range)
        }
        
        bond.didUpdateListener = { [weak self] array, range in
            guard let s = self else { return }
            s.dispatchDidUpdate(s.noEventValue, range)
        }
        
        bond.willResetListener = { [weak self] array in
            guard let s = self else { return }
            s.dispatchWillReset(s.noEventValue)
        }
        
        bond.didResetListener = { [weak self] array in
            guard let s = self else { return }
            s.dispatchDidReset(s.noEventValue)
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
        
        bond.didInsertListener = { [weak self] array, range in
            guard let s = self else { return }
            var pointers: [Int] = []
            let filtered = s.dynamicType.filteredArray(array[range], withPointers: &pointers, filterUsing: filterf)
            guard let firstPointer = pointers.first else { return }
            
            let startIndex = s.pointers.indexOfFirstEqualOrLargerThan(firstPointer)
            let insertedRange = startIndex ..< startIndex.advancedBy(filtered.count)

            s.dispatchWillInsert(s.noEventValue, insertedRange)
            
            s.noEventValue.insertContentsOf(filtered, at: startIndex)
            s.pointers.insertContentsOf(pointers, at: startIndex)
            
            s.dispatchDidInsert(s.noEventValue, insertedRange)
        }
        
        bond.willRemoveListener = { [weak self] array, range in
            guard let s = self else { return }
            var pointers: [Int] = []
            let filtered = s.dynamicType.filteredArray(array[range], withPointers: &pointers, filterUsing: filterf)
            guard let firstPointer = pointers.first, let startIndex = s.pointers.indexOf(firstPointer) else { return }
            
            let removedRange = startIndex ..< startIndex.advancedBy(filtered.count)
            
            s.dispatchWillRemove(s.noEventValue, removedRange)
            
            s.noEventValue.removeRange(removedRange)
            s.pointers.removeRange(removedRange)
            
            s.dispatchDidRemove(s.noEventValue, removedRange)
        }
        
        bond.didUpdateListener = { [weak self] array, range in
            guard let s = self else { return }
            //let idx = range.startIndex
            //let element = array[idx]
            
            var insertedIndices: [Int] = []
            var removedIndices: [Int] = []
            var updatedIndices: [Int] = []
            let pointers = s.pointers
            
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
                let insertedRange = $0...$0
                s.dispatchWillInsert(s.noEventValue, insertedRange)
                s.noEventValue.insert(array[$1], atIndex: $0)
                s.pointers.insert($1, atIndex: $0)
                s.dispatchDidInsert(s.noEventValue, insertedRange)
            }
            
            removedIndices.map(pointers.indexOf).forEach {
                guard let localIndex = $0 else { return }
                let removedRange = localIndex...localIndex
                s.dispatchWillRemove(s.noEventValue, removedRange)
                s.noEventValue.removeAtIndex(localIndex)
                s.pointers.removeAtIndex(localIndex)
                s.dispatchDidRemove(s.noEventValue, removedRange)
            }
            
            updatedIndices.map { (pointers.indexOf($0), $0) }.forEach {
                guard let localIndex = $0 else { return }
                let updatedRange = localIndex...localIndex
                s.dispatchWillUpdate(s.noEventValue, updatedRange)
                s.noEventValue[localIndex] = array[$1]
                s.dispatchDidUpdate(s.noEventValue, updatedRange)
            }
        }
        
        bond.willResetListener = { [weak self] array in
            guard let s = self else { return }
            s.dispatchWillReset(s.noEventValue)
        }
        
        bond.didResetListener = { [weak self] array in
            guard let s = self else { return }
            s.noEventValue = s.dynamicType.filteredArray(array, withPointers: &s.pointers, filterUsing: filterf)
            s.dispatchDidReset(s.noEventValue)
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
        
        bond.willInsertListener = { [weak self] array, range in
            dispatch_async(queue) { [weak self] in
                self?.dispatchWillInsert(array, range)
            }
        }
        
        bond.didInsertListener = { [weak self] array, range in
            dispatch_async(queue) { [weak self] in
                self?.dispatchDidInsert(array, range)
            }
        }
        
        bond.willRemoveListener = { [weak self] array, range in
            dispatch_async(queue) { [weak self] in
                self?.dispatchWillRemove(array, range)
            }
        }
        
        bond.didRemoveListener = { [weak self] array, range in
            dispatch_async(queue) { [weak self] in
                self?.dispatchDidRemove(array, range)
            }
        }
        
        bond.willUpdateListener = { [weak self] array, range in
            dispatch_async(queue) { [weak self] in
                self?.dispatchWillUpdate(array, range)
            }
        }
        
        bond.didUpdateListener = { [weak self] array, range in
            dispatch_async(queue) { [weak self] in
                self?.dispatchDidUpdate(array, range)
            }
        }
        
        bond.willResetListener = { [weak self] array in
            dispatch_async(queue) { [weak self] in
                self?.dispatchWillReset(array)
            }
        }
        
        bond.didResetListener = { [weak self] array in
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
    
    public func flatMap<U>(f: T -> Observable<U>) -> ObservableArray<U> {
        return _flatMap(self) {
            f($1)
        }
    }
    
    public func flatMap<U>(f: (Int, T) -> Observable<U>) -> ObservableArray<U> {
        return _flatMap(self, f)
    }
    
    public func flatMap<U>(f: T -> ObservableArray<U>) -> ObservableArray<U> {
        return _flatMap(self) {
            f($1)
        }
    }
    
    public func flatMap<U>(f: (Int, T) -> ObservableArray<U>) -> ObservableArray<U> {
        return _flatMap(self, f)
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

internal func _flatMap<T, U>(observable: ObservableArray<T>, _ f: (Int, T) -> Observable<U>) -> ObservableArray<U> {
    return ObservableArrayValueFlatMapProxy(sourceArray: observable, mapf: f)
}

internal func _flatMap<T, U>(observable: ObservableArray<T>, _ f: (Int, T) -> ObservableArray<U>) -> ObservableArray<U> {
    return ObservableArrayFlatMapProxy(sourceArray: observable, mapf: f)
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
