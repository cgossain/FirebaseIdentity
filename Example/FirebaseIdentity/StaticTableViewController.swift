//
//  StaticTableViewController.swift
//  FirebaseIdentity_Example
//
//  Created by Christian Gossain on 2019-07-29.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Static

class StaticTableViewController: UITableViewController {
    /// The table view data source.
    var dataSource = DataSource() {
        willSet {
            dataSource.tableView = nil
        }
        didSet {
            dataSource.tableView = tableView
        }
    }
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource.tableView = tableView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearSelectionsIfNeeded(animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.flashScrollIndicators()
    }
}

fileprivate extension StaticTableViewController {
    func clearSelectionsIfNeeded(animated: Bool) {
        guard let selectedIndexPaths = tableView.indexPathsForSelectedRows, clearsSelectionOnViewWillAppear else {
            return
        }
        
        guard let coordinator = transitionCoordinator else {
            deselectRows(at: selectedIndexPaths, animated: animated)
            return
        }
        
        let animation: (UIViewControllerTransitionCoordinatorContext) -> Void = { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.deselectRows(at: selectedIndexPaths, animated: animated)
        }
        
        let completion: (UIViewControllerTransitionCoordinatorContext) -> Void = { [weak self] context in
            guard let strongSelf = self, context.isCancelled else {
                return
            }
            strongSelf.selectRows(at: selectedIndexPaths, animated: animated)
        }
        
        coordinator.animate(alongsideTransition: animation, completion: completion)
    }
    
    private func selectRows(at indexPaths: [IndexPath], animated: Bool) {
        indexPaths.forEach { tableView.selectRow(at: $0, animated: animated, scrollPosition: .none) }
    }
    
    private func deselectRows(at indexPaths: [IndexPath], animated: Bool) {
        indexPaths.forEach { tableView.deselectRow(at: $0, animated: animated) }
    }
}
