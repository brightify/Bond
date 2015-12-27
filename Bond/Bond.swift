//
//  Bond.swift
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

// MARK: Helpers

import Foundation

public class BondBox<T> {
    weak var bond: Bond<T>?
    internal var _hash: Int
    public init(_ b: Bond<T>) { bond = b; _hash = b.hashValue }
    public func get() -> Bond<T>? { return bond }
}

// MARK: - Scalar Dynamic

// MARK: Bond
public class Bond<T>: CustomDebugStringConvertible {
    public typealias Listener = T -> Void
    
    public let sourceLocation: SourceLocation
    
    public var listener: Listener?
    public var bound: Bool {
        return boundObservable != nil
    }
    public var debugDescription: String {
        return "\(self.dynamicType) from \(sourceLocation)"
    }
    
    internal weak var boundObservable: Observable<T>?
    internal var retainedObservable: Observable<T>?
    
    public init(file: String = __FILE__, line: UInt = __LINE__) {
        sourceLocation = SourceLocation(file: file, line: line)
    }
    
    public init(file: String = __FILE__, line: UInt = __LINE__, _ listener: Listener) {
        sourceLocation = SourceLocation(file: file, line: line)
        self.listener = listener
    }
    
    public func bind(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__) {
        bind(observable, fire: true, strongly: true, file: file, line: line)
    }
    
    public func bind(observable: Observable<T>, fire: Bool, file: String = __FILE__, line: UInt = __LINE__) {
        bind(observable, fire: fire, strongly: true, file: file, line: line)
    }
    
    public func bind(observable: Observable<T>, fire: Bool, strongly: Bool, file: String = __FILE__, line: UInt = __LINE__) {
        unbind(file: file, line: line)
        
        observable.bonds.insert(BondBox(self))
        
        boundObservable = observable
        if strongly {
            retainedObservable = observable
        }
        
        if fire && observable.valid {
            fireListenerInternally(observable)
        }
    }
    
    public func unbind(twoWayUnbindIntentional twoWayUnbindIntentional: Bool = false, file: String = __FILE__, line: UInt = __LINE__) {
        let boxedSelf = BondBox(self)
        boundObservable?.bonds.remove(boxedSelf)
        
        // We need to keep the reference and then set the properties to nil to avoid infinite recursion
        let boundDynamic = boundObservable as? Dynamic
        boundObservable = nil
        retainedObservable = nil
        
        // If the boundObservable was a Dynamic and if it was bound to a dynamic where the bond was equal to `self`
        if let
            boundDynamic = boundDynamic,
            otherBoundDynamic = boundDynamic.valueBond.boundObservable as? Dynamic where
            otherBoundDynamic.valueBond === self
        {
            if !twoWayUnbindIntentional {
                print("WARNING: A two-way binding between \n\t\(boundDynamic)\n\t\(otherBoundDynamic) was unbound unintentionally at \(file):\(line)!")
            }
            boundDynamic.valueBond.unbind()
        }
    }
    
    internal func fireListenerInternally(observable: Observable<T>) {
        listener?(observable.value)
    }
}

public class Observable<T>: CustomDebugStringConvertible {
    private var dispatchInProgress: Bool = false
    internal var bonds: Set<BondBox<T>> = Set()
    
    public let sourceLocation: SourceLocation
    
    public var backingValue: T?
    public var noEventValue: T {
        get {
            if let value = backingValue {
                return value
            } else {
                fatalError("\(self) has no value defined at the moment!")
            }
        }
        set {
            backingValue = newValue
        }
    }
    public var value: T {
        get {
            return noEventValue
        }
        set {
            objc_sync_enter(self)
            noEventValue = newValue
            dispatch(newValue)
            objc_sync_exit(self)
        }
    }
    
    public var valid: Bool {
        get {
            return backingValue != nil
        }
    }
    
    public var numberOfBoundBonds: Int {
        return bonds.count
    }
    
    public var debugDescription: String {
        return "\(self.dynamicType) from \(sourceLocation)"
    }
    
    internal init(file: String = __FILE__, line: UInt = __LINE__) {
        backingValue = nil
        sourceLocation = SourceLocation(file: file, line: line)
    }
    
    public init(_ value: T, file: String = __FILE__, line: UInt = __LINE__) {
        backingValue = value
        sourceLocation = SourceLocation(file: file, line: line)
    }
    
    internal func dispatch(value: T) {
        guard dispatchInProgress == false else { return }
        
        // lock
        self.dispatchInProgress = true
        
        var emptyBoxes = [BondBox<T>]()
        
        // dispatch change notifications
        for bondBox in self.bonds {
            if let bond = bondBox.bond {
                bond.listener?(value)
            }
            else {
                emptyBoxes.append(bondBox)
            }
        }
        
        self.bonds.subtractInPlace(emptyBoxes)
        
        // unlock
        self.dispatchInProgress = false
    }
    
    public func bindTo(bond: Bond<T>, file: String = __FILE__, line: UInt = __LINE__) {
        bond.bind(self, fire: true, strongly: true, file: file, line: line)
    }
    
    public func bindTo(bond: Bond<T>, fire: Bool, file: String = __FILE__, line: UInt = __LINE__) {
        bond.bind(self, fire: fire, strongly: true, file: file, line: line)
    }
    
    public func bindTo(bond: Bond<T>, fire: Bool, strongly: Bool, file: String = __FILE__, line: UInt = __LINE__) {
        bond.bind(self, fire: fire, strongly: strongly, file: file, line: line)
    }
    
}

// MARK: Dynamic

public class Dynamic<T>: Observable<T> {
    
    public let valueBond: Bond<T>
    
    private override init(file: String = __FILE__, line: UInt = __LINE__) {
        valueBond = Bond(file: file, line: line)
        super.init(file: file, line: line)
        valueBond.listener = { [unowned self] in self.value = $0 }
    }
    
    public override init(_ value: T, file: String = __FILE__, line: UInt = __LINE__) {
        valueBond = Bond(file: file, line: line)
        super.init(value, file: file, line: line)
        valueBond.listener = { [unowned self] in self.value = $0 }
    }
    
}

public class InternalDynamic<T>: Dynamic<T> {
    
    public override init(file: String = __FILE__, line: UInt = __LINE__) {
        super.init(file: file, line: line)
    }
    
    public override init(_ value: T, file: String = __FILE__, line: UInt = __LINE__) {
        super.init(value, file: file, line: line)
    }
    
    public init(file: String = __FILE__, line: UInt = __LINE__, listener: T -> ()) {
        super.init(file: file, line: line)
        let bond = Bond(file: file, line: line, listener)
        bond.bind(self, fire: false, strongly: false)
        retain(bond)
    }
    
    public init(_ value: T, fire: Bool = false, file: String = __FILE__, line: UInt = __LINE__, listener: T -> ()) {
        super.init(value, file: file, line: line)
        let bond = Bond(file: file, line: line, listener)
        bond.bind(self, fire: fire, strongly: false)
        retain(bond)
    }
    
    public var updatingFromSelf: Bool = false
    public var retainedObjects: [AnyObject] = []
    public func retain(object: AnyObject) {
        retainedObjects.append(object)
    }
}

public class InternalDynamicArray<T>: DynamicArray<T> {
    
    public init(file: String = __FILE__, line: UInt = __LINE__) {
        super.init([], file: file, line: line)
    }
    
    public override init(_ value: [T], file: String = __FILE__, line: UInt = __LINE__) {
        super.init(value, file: file, line: line)
    }
    
    public init(file: String = __FILE__, line: UInt = __LINE__, listener: [T] -> ()) {
        super.init([], file: file, line: line)
        let bond = Bond(file: file, line: line, listener)
        bond.bind(self, fire: false, strongly: false)
        retain(bond)
    }
    
    public init(_ value: [T], fire: Bool = false, file: String = __FILE__, line: UInt = __LINE__, listener: [T] -> ()) {
        super.init(value)
        let bond = Bond(file: file, line: line, listener)
        bond.bind(self, fire: fire, strongly: false)
        retain(bond)
    }
    
    public var updatingFromSelf: Bool = false
    public var retainedObjects: [AnyObject] = []
    public func retain(object: AnyObject) {
        retainedObjects.append(object)
    }
}

// MARK: Protocols
public protocol ObservableType {
    typealias ObservableType
    var designatedObservable: Observable<ObservableType> { get }
}

public protocol Dynamical {
    typealias DynamicType
    var designatedDynamic: Dynamic<DynamicType> { get }
}

public protocol Bondable {
    typealias BondType
    var designatedBond: Bond<BondType> { get }
}

extension Dynamic: Bondable {
    public var designatedBond: Bond<T> {
        return self.valueBond
    }
}

// MARK: Functional additions

public extension Observable
{
    public func map<U>(file file: String = __FILE__, line: UInt = __LINE__, _ f: T -> U) -> Observable<U> {
        return _map(self, file: file, line: line, f)
    }
    
    public func flatMap<U>(file file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Observable<U>?) -> Observable<U?> {
        return _flatMap(self, file: file, line: line, f)
    }
    
    public func flatMap<U>(file file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Observable<U>) -> Observable<U> {
        return _flatMap(self, file: file, line: line, f)
    }
    
    public func flatMap<U>(file file: String = __FILE__, line: UInt = __LINE__, _ f: T -> ObservableArray<U>?) -> ObservableArray<U> {
        return _flatMap(self, file: file, line: line, f)
    }
    
    public func flatMap<U>(file file: String = __FILE__, line: UInt = __LINE__, _ f: T -> ObservableArray<U>) -> ObservableArray<U> {
        return _flatMap(self, file: file, line: line, f)
    }
    
    public func flatMapTwoWay<U>(file file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Dynamic<U>) -> Dynamic<U> {
        return _flatMapTwoWay(self, file: file, line: line, f)
    }
    
    public func asyncMap<U>(file file: String = __FILE__, line: UInt = __LINE__, _ f: (T, U -> ()) -> ()) -> Observable<U> {
        return _asyncMap(self, file: file, line: line, f)
    }
    
    public func asyncMap<U>(file file: String = __FILE__, line: UInt = __LINE__, _ f: (T, [U] -> ()) -> ()) -> ObservableArray<U> {
        return _asyncMap(self, file: file, line: line, f)
    }
    
    public func filter(file file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Bool) -> Observable<T> {
        return _filter(self, file: file, line: line, f)
    }
    
    public func filter(file file: String = __FILE__, line: UInt = __LINE__, _ f: (T, T) -> Bool, _ v: T) -> Observable<T> {
        return _filter(self, file: file, line: line) { f($0, v) }
    }
    
    public func rewrite<U>(v:  U, file: String = __FILE__, line: UInt = __LINE__) -> Observable<U> {
        return _map(self, file: file, line: line) { _ in return v}
    }
    
    public func zip<U>(v: U, file: String = __FILE__, line: UInt = __LINE__) -> Observable<(T, U)> {
        return _map(self, file: file, line: line) { ($0, v) }
    }
    
    public func zip<U>(d: Observable<U>, file: String = __FILE__, line: UInt = __LINE__) -> Observable<(T, U)> {
        return reduce(self, d, file: file, line: line) { ($0, $1) }
    }
    
    public func skip(count: Int, file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
        return _skip(self, count, file: file, line: line)
    }
    
    public func throttle(seconds: Double, queue: dispatch_queue_t = dispatch_get_main_queue(), file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
        return _throttle(self, seconds, queue, file: file, line: line)
    }
}

public extension Observable where T: Equatable {
    public func distinct(file file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
        return _distinct(self, file: file, line: line)
    }
}

// MARK: Equatable/Hashable

extension Bond: Hashable, Equatable {
    public var hashValue: Int { return unsafeAddressOf(self).hashValue }
}

public func ==<T>(left: Bond<T>, right: Bond<T>) -> Bool {
    return unsafeAddressOf(left) == unsafeAddressOf(right)
}

extension BondBox: Equatable, Hashable {
    public var hashValue: Int { return _hash }
}

public func ==<T>(left: BondBox<T>, right: BondBox<T>) -> Bool {
    return left._hash == right._hash
}

internal class AsyncMapProxyObservable<IN, OUT>: Observable<OUT>, Bondable {
    
    internal let inputBond: Bond<IN>
    
    internal var designatedBond: Bond<IN> {
        return self.inputBond
    }
    
    internal init(file: String = __FILE__, line: UInt = __LINE__, _ action: (IN, (OUT) -> ()) -> ()) {
        inputBond = Bond(file: file, line: line)

        super.init(file: file, line: line)
        
        inputBond.listener = { [unowned self] in
            action($0, self.setOutputValue)
        }
    }
    
    private func setOutputValue(value: OUT) {
        self.value = value
    }
}

internal class AsyncMapProxyObservableArray<IN, OUT>: ObservableArray<OUT>, Bondable {
    
    internal let inputBond: Bond<IN>
    
    internal var designatedBond: Bond<IN> {
        return self.inputBond
    }
    
    internal init(file: String = __FILE__, line: UInt = __LINE__, _ action: (IN, [OUT] -> ()) -> ()) {
        inputBond = Bond(file: file, line: line)

        super.init([], file: file, line: line)
        
        inputBond.listener = { [unowned self] in
            action($0, self.setOutputValue)
        }
    }
    
    private func setOutputValue(value: [OUT]) {
        self.value = value
    }
}