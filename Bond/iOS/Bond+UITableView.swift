//
//  Bond+UITableView.swift
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

import UIKit

extension NSIndexSet {
  convenience init(array: [Int]) {
    let set = NSMutableIndexSet()
    for index in array {
      set.addIndex(index)
    }
    self.init(indexSet: set)
  }
}

@objc class TableViewDynamicArrayDataSource: NSObject, UITableViewDataSource {
  weak var observable: ObservableArray<LazyObservableArray<UITableViewCell>>?
  @objc weak var nextDataSource: UITableViewDataSource?
  
  init(observable: ObservableArray<LazyObservableArray<UITableViewCell>>) {
    self.observable = observable
    super.init()
  }
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return observable?.count ?? 0
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return observable?[section].count ?? 0
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    return observable?[indexPath.section][indexPath.item]() ?? UITableViewCell()
  }
  
  // Forwards
  
  func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if let ds = self.nextDataSource {
      return ds.tableView?(tableView, titleForHeaderInSection: section)
    } else {
      return nil
    }
  }
  
  func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    if let ds = self.nextDataSource {
      return ds.tableView?(tableView, titleForFooterInSection: section)
    } else {
      return nil
    }
  }
  
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    if let ds = self.nextDataSource {
      return ds.tableView?(tableView, canEditRowAtIndexPath: indexPath) ?? false
    } else {
      return false
    }
  }
  
  func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    if let ds = self.nextDataSource {
      return ds.tableView?(tableView, canMoveRowAtIndexPath: indexPath) ?? false
    } else {
      return false
    }
  }
  
  func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
    return self.nextDataSource?.sectionIndexTitlesForTableView?(tableView) ?? []
  }
  
  func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
    if let ds = self.nextDataSource {
      return ds.tableView?(tableView, sectionForSectionIndexTitle: title, atIndex: index) ?? index
    } else {
      return index
    }
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if let ds = self.nextDataSource {
      ds.tableView?(tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
    }
  }
  
  func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
    if let ds = self.nextDataSource {
      ds.tableView?(tableView, moveRowAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
    }
  }
}

private class UITableViewDataSourceSectionBond: ArrayBond<() -> UITableViewCell> {
  weak var tableView: UITableView?
  var section: Int
  init(tableView: UITableView?, section: Int, disableAnimation: Bool = false) {
    self.tableView = tableView
    self.section = section
    super.init()
    
    self.didInsertListener = { [unowned self] a, i in
      if let tableView: UITableView = self.tableView {
        perform(animated: !disableAnimation) {
          tableView.beginUpdates()
          tableView.insertRowsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: self.section) }, withRowAnimation: UITableViewRowAnimation.Automatic)
          tableView.endUpdates()
        }
      }
    }
    
    self.didRemoveListener = { [unowned self] a, i in
      if let tableView = self.tableView {
        perform(animated: !disableAnimation) {
          tableView.beginUpdates()
          tableView.deleteRowsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: self.section) }, withRowAnimation: UITableViewRowAnimation.Automatic)
          tableView.endUpdates()
        }
      }
    }
    
    self.didUpdateListener = { [unowned self] a, i in
      if let tableView = self.tableView {
        perform(animated: !disableAnimation) {
          tableView.beginUpdates()
          tableView.reloadRowsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: self.section) }, withRowAnimation: UITableViewRowAnimation.Automatic)
          tableView.endUpdates()
        }
      }
    }
    
    self.didResetListener = { [weak self] array in
      if let tableView = self?.tableView {
        tableView.reloadData()
      }
    }
  }
  
  deinit {
    unbind()
  }
}

public class UITableViewDataSourceBond: ArrayBond<LazyObservableArray<UITableViewCell>> {
  weak var tableView: UITableView?
  private var dataSource: TableViewDynamicArrayDataSource?
  private var sectionBonds: [UITableViewDataSourceSectionBond] = []
  public let disableAnimation: Bool
  public weak var nextDataSource: UITableViewDataSource? {
    willSet(newValue) {
      dataSource?.nextDataSource = newValue
    }
  }
  
  public init(tableView: UITableView, disableAnimation: Bool = false) {
    self.disableAnimation = disableAnimation
    self.tableView = tableView
    super.init()
    
    self.didInsertListener = { [weak self] array, i in
      if let s = self {
        if let tableView: UITableView = self?.tableView {
          perform(animated: !disableAnimation) {
            tableView.beginUpdates()
            tableView.insertSections(NSIndexSet(array: i), withRowAnimation: UITableViewRowAnimation.Automatic)
            
            for section in i.sort(<) {
              let sectionBond = UITableViewDataSourceSectionBond(tableView: tableView, section: section, disableAnimation: disableAnimation)
              let sectionObservable = array[section]
              sectionObservable.bindTo(sectionBond)
              s.sectionBonds.insert(sectionBond, atIndex: section)
              
              for var idx = section + 1; idx < s.sectionBonds.count; idx++ {
                s.sectionBonds[idx].section += 1
              }
            }
            
            tableView.endUpdates()
          }
        }
      }
    }
    
    self.didRemoveListener = { [weak self] array, i in
      if let s = self {
        if let tableView = s.tableView {
          perform(animated: !disableAnimation) {
            tableView.beginUpdates()
            tableView.deleteSections(NSIndexSet(array: i), withRowAnimation: UITableViewRowAnimation.Automatic)
            for section in i.sort(>) {
              s.sectionBonds[section].unbind()
              s.sectionBonds.removeAtIndex(section)
              
              for var idx = section; idx < s.sectionBonds.count; idx++ {
                s.sectionBonds[idx].section -= 1
              }
            }
            
            tableView.endUpdates()
          }
        }
      }
    }
  
    self.didUpdateListener = { [weak self] array, i in
      if let s = self {
        if let tableView = s.tableView {
          perform(animated: !disableAnimation) {
            tableView.beginUpdates()
            tableView.reloadSections(NSIndexSet(array: i), withRowAnimation: UITableViewRowAnimation.Automatic)

            for section in i {
              let sectionBond = UITableViewDataSourceSectionBond(tableView: tableView, section: section, disableAnimation: disableAnimation)
              let sectionObservable = array[section]
              sectionObservable.bindTo(sectionBond)
              
              self?.sectionBonds[section].unbind()
              self?.sectionBonds[section] = sectionBond
            }
            
            tableView.endUpdates()
          }
        }
      }
    }
    
    self.didResetListener = { [weak self] array in
      if let tableView = self?.tableView {
        tableView.reloadData()
      }
    }
  }
  
  public func bind(observable: LazyObservableArray<UITableViewCell>) {
    bind(ObservableArray([observable]))
  }
  
  public override func bind(observable: Observable<Array<LazyObservableArray<UITableViewCell>>>, fire: Bool, strongly: Bool) {
    super.bind(observable, fire: false, strongly: strongly)
    if let observable = observable as? ObservableArray<LazyObservableArray<UITableViewCell>> {
      for section in 0..<observable.count {
        let sectionBond = UITableViewDataSourceSectionBond(tableView: self.tableView, section: section, disableAnimation: disableAnimation)
        let sectionObservable = observable[section]
        sectionObservable.bindTo(sectionBond)
        sectionBonds.append(sectionBond)
      }
      
      dataSource = TableViewDynamicArrayDataSource(observable: observable)
      dataSource?.nextDataSource = nextDataSource
      tableView?.dataSource = dataSource
      tableView?.reloadData()
    }
  }
  
  deinit {
    self.unbind()
    tableView?.dataSource = nil
    dataSource = nil
  }
}

private var bondDynamicHandleUITableView: UInt8 = 0

extension UITableView /*: Bondable */ {
  public var designatedBond: UITableViewDataSourceBond {
    if let d: AnyObject = objc_getAssociatedObject(self, &bondDynamicHandleUITableView) {
      return (d as? UITableViewDataSourceBond)!
    } else {
      let bond = UITableViewDataSourceBond(tableView: self, disableAnimation: false)
      objc_setAssociatedObject(self, &bondDynamicHandleUITableView, bond, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return bond
    }
  }
}

private func perform(animated animated: Bool, block: () -> Void) {
  if !animated {
    UIView.performWithoutAnimation(block)
  } else {
    block()
  }
}

//public func ->> <T>(left: DynamicArray<UITableViewCell>, right: UITableViewDataSourceBond) {
//  right.bind(left)
//}

public func ->> (left: LazyObservableArray<UITableViewCell>, right: UITableViewDataSourceBond) {
  right.bind(left)
}

public func ->> (left: LazyObservableArray<UITableViewCell>, right: UITableView) {
  left ->> right.designatedBond
}

public func ->> (left: ObservableArray<LazyObservableArray<UITableViewCell>>, right: UITableView) {
  left ->> right.designatedBond
}
