//
//  Bond+UICollectionView.swift
//  Bond
//
//  Created by Srđan Rašić on 06/03/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit

@objc class CollectionViewDynamicArrayDataSource: NSObject, UICollectionViewDataSource {
    weak var dynamic: ObservableArray<LazyObservableArray<UICollectionViewCell>>?
    @objc weak var nextDataSource: UICollectionViewDataSource?
    
    init(dynamic: ObservableArray<LazyObservableArray<UICollectionViewCell>>) {
        self.dynamic = dynamic
        super.init()
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.dynamic?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dynamic?[section].count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return self.dynamic?[indexPath.section][indexPath.item]() ?? UICollectionViewCell()
    }
    
    // Forwards
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if let result = self.nextDataSource?.collectionView?(collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath) {
            return result
        } else {
            fatalError("Defining Supplementary view either in Storyboard or by registering a class or nib file requires you to implement method collectionView:viewForSupplementaryElementOfKind:indexPath in your data soruce! To provide data source, make a class (usually your view controller) adhere to protocol UICollectionViewDataSource and implement method collectionView:viewForSupplementaryElementOfKind:indexPath. Register instance of your class as next data source with UICollectionViewDataSourceBond object by setting its nextDataSource property. Make sure you set it before binding takes place!")
        }
    }
}

private class UICollectionViewDataSourceSectionBond: ArrayBond<() -> UICollectionViewCell> {
    weak var collectionView: UICollectionView?
    var section: Int
    
    init(collectionView: UICollectionView?, section: Int) {
        self.collectionView = collectionView
        self.section = section
        super.init()
        
        self.didInsertListener = { [unowned self] a, i in
            if let collectionView = self.collectionView {
                collectionView.insertItemsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: self.section) })
            }
        }
        
        self.didRemoveListener = { [unowned self] a, i in
            if let collectionView = self.collectionView {
                collectionView.deleteItemsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: self.section) })
            }
        }
        
        self.didUpdateListener = { [unowned self] a, i in
            if let collectionView = self.collectionView {
                collectionView.reloadItemsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: self.section) })
            }
        }
        
        self.didResetListener = { [weak self] array in
            if let collectionView = self?.collectionView {
                collectionView.reloadData()
            }
        }
    }
    
    deinit {
        self.unbind()
    }
}

public class UICollectionViewDataSourceBond: ArrayBond<LazyObservableArray<UICollectionViewCell>> {
    weak var collectionView: UICollectionView?
    private var dataSource: CollectionViewDynamicArrayDataSource?
    private var sectionBonds: [UICollectionViewDataSourceSectionBond] = []
    
    public weak var nextDataSource: UICollectionViewDataSource? {
        didSet(newValue) {
            dataSource?.nextDataSource = newValue
        }
    }
    
    public init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        
        self.didInsertListener = { [weak self] array, range in
            guard let s = self, let collectionView = s.collectionView else { return }
            
            collectionView.insertSections(NSIndexSet(array: Array(range)))
            
            for section in range {
                let sectionBond = UICollectionViewDataSourceSectionBond(collectionView: collectionView, section: section)
                let sectionDynamic = array[section]
                sectionDynamic.bindTo(sectionBond, fire: false)
                s.sectionBonds.insert(sectionBond, atIndex: section)
                
                for var idx = section + 1; idx < s.sectionBonds.count; idx++ {
                    s.sectionBonds[idx].section += 1
                }
            }
        }
        
        self.didRemoveListener = { [weak self] array, range in
            guard let s = self, let collectionView = s.collectionView else { return }
            
            collectionView.deleteSections(NSIndexSet(array: Array(range)))
            
            for section in range.sort(>) {
                s.sectionBonds[section].unbind()
                s.sectionBonds.removeAtIndex(section)
                
                for var idx = section; idx < s.sectionBonds.count; idx++ {
                    s.sectionBonds[idx].section -= 1
                }
            }
        }
        
        self.didUpdateListener = { [weak self] array, range in
            guard let s = self, let collectionView = s.collectionView else { return }
            
            collectionView.reloadSections(NSIndexSet(array: Array(range)))
            
            for section in range {
                let sectionBond = UICollectionViewDataSourceSectionBond(collectionView: collectionView, section: section)
                let sectionDynamic = array[section]
                sectionDynamic.bindTo(sectionBond, fire: false)
                
                s.sectionBonds[section].unbind()
                s.sectionBonds[section] = sectionBond
            }
            
        }
        
        self.didResetListener = { [weak self] array in
            if let collectionView = self?.collectionView {
                collectionView.reloadData()
            }
        }
    }
    
    public func bind(dynamic: LazyObservableArray<UICollectionViewCell>, fire: Bool = true) {
        bind(ObservableArray([dynamic]), fire: fire)
    }
    
    public override func bind(dynamic: Observable<Array<LazyObservableArray<UICollectionViewCell>>>, fire: Bool, strongly: Bool) {
        super.bind(dynamic, fire: fire, strongly: strongly)
        if let dynamic = dynamic as? ObservableArray<LazyObservableArray<UICollectionViewCell>> {
            for section in 0..<dynamic.count {
                let sectionBond = UICollectionViewDataSourceSectionBond(collectionView: self.collectionView, section: section)
                let sectionDynamic = dynamic[section]
                sectionDynamic.bindTo(sectionBond, fire: false)
                sectionBonds.append(sectionBond)
            }
            
            dataSource = CollectionViewDynamicArrayDataSource(dynamic: dynamic)
            dataSource?.nextDataSource = self.nextDataSource
            collectionView?.dataSource = dataSource
            collectionView?.reloadData()
        }
    }
    
    deinit {
        self.unbind()
        collectionView?.dataSource = nil
        self.dataSource = nil
    }
}


private var bondDynamicHandleUICollectionView: UInt8 = 0

extension UICollectionView /*: Bondable */ {
    public var designatedBond: UICollectionViewDataSourceBond {
        if let d: AnyObject = objc_getAssociatedObject(self, &bondDynamicHandleUICollectionView) {
            return (d as? UICollectionViewDataSourceBond)!
        } else {
            let bond = UICollectionViewDataSourceBond(collectionView: self)
            objc_setAssociatedObject(self, &bondDynamicHandleUICollectionView, bond, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return bond
        }
    }
}

public func ->> (left: LazyObservableArray<UICollectionViewCell>, right: UICollectionViewDataSourceBond) {
    right.bind(left)
}

public func ->| (left: LazyObservableArray<UICollectionViewCell>, right: UICollectionViewDataSourceBond) {
    right.bind(left, fire: false)
}

public func ->> (left: LazyObservableArray<UICollectionViewCell>, right: UICollectionView) {
    left ->> right.designatedBond
}

public func ->| (left: LazyObservableArray<UICollectionViewCell>, right: UICollectionView) {
    left ->| right.designatedBond
}

public func ->> (left: ObservableArray<LazyObservableArray<UICollectionViewCell>>, right: UICollectionView) {
    left ->> right.designatedBond
}

public func ->| (left: ObservableArray<LazyObservableArray<UICollectionViewCell>>, right: UICollectionView) {
    left ->| right.designatedBond
}
