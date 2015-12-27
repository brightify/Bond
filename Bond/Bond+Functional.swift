//
//  Bond+Functional.swift
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

import QuartzCore

// MARK: Map

public func map<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> U) -> Observable<U> {
  return _map(observable, file: file, line: line, f)
}

public func map<S: Dynamical, T, U where S.DynamicType == T>(dynamical: S, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> U) -> Observable<U> {
  return _map(dynamical.designatedDynamic, file: file, line: line, f)
}

internal func _map<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> U) -> Observable<U> {
  let dyn = InternalDynamic<U>(file: file, line: line)
  
  if let value = observable.backingValue {
    dyn.value = f(value)
  }
  
  let bond = Bond<T>(file: file, line: line) { [unowned dyn] t in
    dyn.value = f(t)
  }
  
  dyn.retain(bond)
  observable.bindTo(bond, fire: false, file: file, line: line)
  
  return dyn
}

// MARK: Flat map

public func flatMap<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Observable<U>) -> Observable<U> {
  return _flatMap(observable, file: file, line: line, f)
}

public func flatMap<S: Dynamical, T, U where S.DynamicType == T>(dynamical: S, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Observable<U>) -> Observable<U> {
  return _flatMap(dynamical.designatedDynamic, file: file, line: line, f)
}

internal func _flatMap<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Observable<U>) -> Observable<U> {
  let dyn = InternalDynamic<U>(file: file, line: line)
  
  if let value = observable.backingValue {
    f(value) ->> dyn
  }
  
  let bond = Bond<T>(file: file, line: line) { [unowned dyn] t in
    f(t) ->> dyn
  }
  dyn.retain(bond)
  observable.bindTo(bond, fire: false, file: file, line: line)
  
  return dyn
}

internal func _flatMap<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Observable<U>?) -> Observable<U?> {
  let dyn = InternalDynamic<U?>(file: file, line: line)
  if let value = observable.backingValue {
    if let transformed = f(value) {
      transformed.map { Optional($0) } ->> dyn
    } else {
      Observable(nil, file: file, line: line) ->> dyn
    }
  }
  
  let bond = Bond<T>(file: file, line: line) { [unowned dyn] t in
    if let transformed = f(t) {
      transformed.map { Optional($0) } ->> dyn
    } else {
      Observable(nil, file: file, line: line) ->> dyn
    }
  }
  dyn.retain(bond)
  observable.bindTo(bond, fire: false, file: file, line: line)
  
  return dyn
}

public func flatMap<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> ObservableArray<U>) -> ObservableArray<U> {
  return _flatMap(observable, file: file, line: line, f)
}

public func flatMap<S: Dynamical, T, U where S.DynamicType == T>(dynamical: S, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> ObservableArray<U>) -> ObservableArray<U> {
  return _flatMap(dynamical.designatedDynamic, file: file, line: line, f)
}

internal func _flatMap<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> ObservableArray<U>) -> ObservableArray<U> {
  let dyn = InternalDynamicArray<U>(file: file, line: line)
  
  if let value = observable.backingValue {
    f(value) ->> dyn
  }
  
  let bond = Bond<T>(file: file, line: line) { [unowned dyn] t in
    f(t) ->> dyn
  }
  dyn.retain(bond)
  observable.bindTo(bond, file: file, line: line)
  
  return dyn
}

internal func _flatMap<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> ObservableArray<U>?) -> ObservableArray<U> {
  let dyn = InternalDynamicArray<U>(file: file, line: line)
  
  if let value = observable.backingValue {
    if let transformed = f(value) {
      transformed ->> dyn
    } else {
      ObservableArray(file: file, line: line) ->> dyn
    }
  }
  
  let bond = Bond<T>(file: file, line: line) { [unowned dyn] t in
    if let transformed = f(t) {
      transformed ->> dyn
    } else {
      ObservableArray(file: file, line: line) ->> dyn
    }
  }
  dyn.retain(bond)
  observable.bindTo(bond, file: file, line: line)
  
  return dyn
}

public func flatMapTwoWay<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Dynamic<U>) -> Dynamic<U> {
  return _flatMapTwoWay(observable, file: file, line: line, f)
}

public func flatMapTwoWay<S: Dynamical, T, U where S.DynamicType == T>(dynamical: S, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Dynamic<U>) -> Dynamic<U> {
  return _flatMapTwoWay(dynamical.designatedDynamic, file: file, line: line, f)
}

internal func _flatMapTwoWay<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Dynamic<U>) -> Dynamic<U> {
  let inputBridge = InternalDynamic<U>(file: file, line: line)
  let outputBridge = InternalDynamic<U>(file: file, line: line)
  
  let inputBond = Bond<U>(file: file, line: line) { [weak outputBridge] input in
    outputBridge?.value = input
  }
  let outputBond = Bond<U>(file: file, line: line) { [weak inputBridge] output in
    inputBridge?.value = output
  }
  
  inputBridge.bindTo(inputBond, fire: false, strongly: false, file: file, line: line)
  inputBridge.retain(inputBond)
  
  outputBridge.bindTo(outputBond, fire: false, strongly: false, file: file, line: line)
  outputBridge.retain(outputBond)
  
  outputBridge.retain(inputBridge)
  
  if let value = observable.backingValue {
    // Otherwise we would get a warning in the console every time
    inputBridge.valueBond.unbind(twoWayUnbindIntentional: true, file: file, line: line)
    f(value) <->> inputBridge
  }
  
  let bond = Bond<T>(file: file, line: line) { [unowned inputBridge] t in
    // Otherwise we would get a warning in the console every time
    inputBridge.valueBond.unbind(twoWayUnbindIntentional: true, file: file, line: line)
    f(t) <->> inputBridge
  }
  outputBridge.retain(bond)
  observable.bindTo(bond, fire: false, file: file, line: line)
  
  return outputBridge
}


public func asyncMap<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: (T, U -> ()) -> ()) -> Observable<U> {
  return _asyncMap(observable, file: file, line: line, f)
}
  

public func asyncMap<S: Dynamical, T, U where S.DynamicType == T>(dynamical: S, file: String = __FILE__, line: UInt = __LINE__, _ f: (T, U -> ()) -> ()) -> Observable<U> {
  return _asyncMap(dynamical.designatedDynamic, file: file, line: line, f)
}

internal func _asyncMap<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: (T, U -> ()) -> ()) -> Observable<U> {
  let proxy = AsyncMapProxyObservable<T, U>(file: file, line: line, f)
  observable ->> proxy
  return proxy
}

internal func _asyncMap<T, U>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: (T, [U] -> ()) -> ()) -> ObservableArray<U> {
  let proxy = AsyncMapProxyObservableArray<T, U>(file: file, line: line, f)
  observable ->> proxy
  return proxy
}

// MARK: Filter

public func filter<T>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Bool) -> Observable<T> {
  return _filter(observable, file: file, line: line, f)
}

public func filter<T>(observable: Observable<T>, _ f: (T, T) -> Bool, _ v: T, file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
  return _filter(observable, file: file, line: line) { f($0, v) }
}

public func filter<S: Dynamical, T where S.DynamicType == T>(dynamical: S, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Bool) -> Observable<T> {
  return _filter(dynamical.designatedDynamic, file: file, line: line, f)
}

internal func _filter<T>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__, _ f: T -> Bool) -> Observable<T> {
  let dyn = InternalDynamic<T>(file: file, line: line)
  
  if let value = observable.backingValue {
    if f(value) {
      dyn.value = value
    }
  }
  
  let bond = Bond<T>(file: file, line: line) { [unowned dyn] t in
    if f(t) {
      dyn.value = t
    }
  }
  
  dyn.retain(bond)
  observable.bindTo(bond, fire: false, file: file, line: line)
  
  return dyn
}

// MARK: Reduce

public func reduce<A, B, T>(oA: Observable<A>, _ oB: Observable<B>, file: String = __FILE__, line: UInt = __LINE__, _ f: (A, B) -> T) -> Observable<T> {
  return _reduce(oA, oB, file: file, line: line, f)
}

public func reduce<A, B, C, T>(oA: Observable<A>, _ oB: Observable<B>, _ oC: Observable<C>, file: String = __FILE__, line: UInt = __LINE__, _ f: (A, B, C) -> T) -> Observable<T> {
  return _reduce(oA, oB, oC, file: file, line: line, f)
}

public func _reduce<A, B, T>(oA: Observable<A>, _ oB: Observable<B>, file: String = __FILE__, line: UInt = __LINE__, _ f: (A, B) -> T) -> Observable<T> {
  let dyn = InternalDynamic<T>(file: file, line: line)
  
  if let vA = oA.backingValue, let vB = oB.backingValue {
    dyn.value = f(vA, vB)
  }
  
  let bA = Bond<A>(file: file, line: line) { [unowned dyn, weak oB] in
    if let vB = oB?.backingValue {
      dyn.value = f($0, vB)
    }
  }
  
  let bB = Bond<B>(file: file, line: line) { [unowned dyn, weak oA] in
    if let vA = oA?.backingValue {
      dyn.value = f(vA, $0)
    }
  }
  
  oA.bindTo(bA, fire: false, file: file, line: line)
  oB.bindTo(bB, fire: false, file: file, line: line)
  
  dyn.retain(bA)
  dyn.retain(bB)
  
  return dyn
}

internal func _reduce<A, B, C, T>(oA: Observable<A>, _ oB: Observable<B>, _ oC: Observable<C>, file: String = __FILE__, line: UInt = __LINE__, _ f: (A, B, C) -> T) -> Observable<T> {
  let dyn = InternalDynamic<T>(file: file, line: line)
  
  if let vA = oA.backingValue, let vB = oB.backingValue, let vC = oC.backingValue {
    dyn.value = f(vA, vB, vC)
  }
  
  let bA = Bond<A>(file: file, line: line) { [unowned dyn, weak oB, weak oC] in
    if let vB = oB?.backingValue, let vC = oC?.backingValue { dyn.value = f($0, vB, vC) }
  }
  
  let bB = Bond<B>(file: file, line: line) { [unowned dyn, weak oA, weak oC] in
    if let vA = oA?.backingValue, let vC = oC?.backingValue { dyn.value = f(vA, $0, vC) }
  }
  
  let bC = Bond<C>(file: file, line: line) { [unowned dyn, weak oA, weak oB] in
    if let vA = oA?.backingValue, let vB = oB?.backingValue { dyn.value = f(vA, vB, $0) }
  }
  
  oA.bindTo(bA, fire: false, file: file, line: line)
  oB.bindTo(bB, fire: false, file: file, line: line)
  oC.bindTo(bC, fire: false, file: file, line: line)
  
  dyn.retain(bA)
  dyn.retain(bB)
  dyn.retain(bC)
  
  return dyn
}

// MARK: Rewrite

public func rewrite<T, U>(observable: Observable<T>, _ value: U, file: String = __FILE__, line: UInt = __LINE__) -> Observable<U> {
  return _map(observable, file: file, line: line) { _ in value }
}

// MARK: Zip

public func zip<T, U>(observable: Observable<T>, _ value: U, file: String = __FILE__, line: UInt = __LINE__) -> Observable<(T, U)> {
  return _map(observable, file: file, line: line) { ($0, value) }
}

public func zip<T, U>(o1: Observable<T>, _ o2: Observable<U>, file: String = __FILE__, line: UInt = __LINE__) -> Observable<(T, U)> {
  return reduce(o1, o2, file: file, line: line) { ($0, $1) }
}

// MARK: Skip

internal func _skip<T>(observable: Observable<T>, var _ count: Int, file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
  let dyn = InternalDynamic<T>(file: file, line: line)
  
  if count <= 0 {
    dyn.value = observable.value
  }
  
  let bond = Bond<T>(file: file, line: line) { [unowned dyn] t in
    if count <= 0 {
      dyn.value = t
    } else {
      count--
    }
  }
  
  dyn.retain(bond)
  observable.bindTo(bond, fire: false, file: file, line: line)
  
  return dyn
}

public func skip<T>(observable: Observable<T>, _ count: Int, file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
  return _skip(observable, count, file: file, line: line)
}

// MARK: Any

public func any<T>(observables: [Observable<T>], file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
  let dyn = InternalDynamic<T>(file: file, line: line)
  
  for observable in observables {
    let bond = Bond<T>(file: file, line: line) { [unowned dyn] in
      dyn.value = $0
    }
    observable.bindTo(bond, fire: false, file: file, line: line)
    dyn.retain(bond)
  }
  
  return dyn
}

// MARK: Throttle

private func cancellableDispatchAfter(time: dispatch_time_t, _ queue: dispatch_queue_t, _ block: () -> ()) -> () -> () {
  var cancelled: Bool = false
  dispatch_after(time, queue) {
    if cancelled == false {
      block()
    }
  }
  return {
    cancelled = true
  }
}

internal func _throttle<T>(observable: Observable<T>, _ seconds: Double, _ queue: dispatch_queue_t, file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
  let dyn = InternalDynamic<T>(file: file, line: line)
  var cancel: () -> () = { }
  let bond = Bond<T>(file: file, line: line) { value in
    cancel()
    let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    cancel = cancellableDispatchAfter(delay, queue) { [weak dyn] in
      dyn?.value = value
    }
  }
  
  if observable.valid {
    dyn.value = observable.value
  }
  
  dyn.retain(bond)
  observable.bindTo(bond, fire: false, file: file, line: line)
  
  return dyn
}

public func throttle<T>(observable: Observable<T>, _ seconds: Double, _ queue: dispatch_queue_t = dispatch_get_main_queue(), file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
    return _throttle(observable, seconds, queue, file: file, line: line)
}

// MARK: deliverOn

internal func _deliver<T>(observable: Observable<T>, on queue: dispatch_queue_t, file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
  let dyn = InternalDynamic<T>(file: file, line: line)
  
  if let value = observable.backingValue {
    dyn.value = value
  }
  
  let bond = Bond<T>(file: file, line: line) { [weak dyn] t in
    dispatch_async(queue) {
      dyn?.value = t
    }
  }
  
  dyn.retain(bond)
  observable.bindTo(bond, fire: false, file: file, line: line)
  
  return dyn
}

public func deliver<T>(observable: Observable<T>, on queue: dispatch_queue_t, file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
  return _deliver(observable, on: queue, file: file, line: line)
}

// MARK: Distinct

internal func _distinct<T: Equatable>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
  let dyn = InternalDynamic<T>(file: file, line: line)
  dyn.backingValue = observable.backingValue

  let bond = Bond<T>(file: file, line: line) { [weak dyn] v in
    if dyn?.valid == false || v != dyn?.value {
      dyn?.value = v
    }
  }

  dyn.retain(bond)
  observable.bindTo(bond, fire: false, file: file, line: line)

  return dyn
}

public func distinct<T: Equatable>(observable: Observable<T>, file: String = __FILE__, line: UInt = __LINE__) -> Observable<T> {
  return _distinct(observable, file: file, line: line)
}
