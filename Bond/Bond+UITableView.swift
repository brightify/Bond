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

@objc class TableViewDynamicArrayDataSource: NSObject, UITableViewDataSource {
  weak var dynamic: DynamicArray<UITableViewCell>?
  
  init(dynamic: DynamicArray<UITableViewCell>) {
    self.dynamic = dynamic
    super.init()
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.dynamic?.count ?? 0
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    return self.dynamic?[indexPath.item] ?? UITableViewCell()
  }
}

public class UITableViewDataSourceBond<T>: ArrayBond<UITableViewCell> {
  weak var tableView: UITableView?
  var dataSource: TableViewDynamicArrayDataSource?
  
  public init(tableView: UITableView) {
    self.tableView = tableView
    super.init()
    
    self.insertListener = { [weak self] i in
      if let tableView = self?.tableView {
        tableView.beginUpdates()
        tableView.insertRowsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: 0) },
          withRowAnimation: UITableViewRowAnimation.Automatic)
        tableView.endUpdates()
      }
    }
    
    self.removeListener = { [weak self] i, o in
      if let tableView = self?.tableView {
        tableView.beginUpdates()
        tableView.deleteRowsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: 0) },
          withRowAnimation: UITableViewRowAnimation.Automatic)
        tableView.endUpdates()
      }
    }
    
    self.updateListener = { [weak self] i in
      if let tableView = self?.tableView {
        tableView.beginUpdates()
        tableView.reloadRowsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: 0) },
          withRowAnimation: UITableViewRowAnimation.Automatic)
        tableView.endUpdates()
      }
    }
  }
  
  public override func bind(dynamic: Dynamic<Array<UITableViewCell>>, fire: Bool, strongly: Bool) {
    super.bind(dynamic, fire: false, strongly: strongly)
    if let dynamic = dynamic as? DynamicArray {
      dataSource = TableViewDynamicArrayDataSource(dynamic: dynamic)
      tableView?.dataSource = dataSource
      tableView?.reloadData()
    }
  }
  
  deinit {
    self.unbindAll()
    tableView?.dataSource = nil
    self.dataSource = nil
  }
}
