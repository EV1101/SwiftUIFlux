//
//  AppState.swift
//  MovieSwift
//
//  Created by Thomas Ricouard on 06/06/2019.
//  Copyright © 2019 Thomas Ricouard. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

public final class Store<StoreState: FluxState>: ObservableObject {
    @Published public var state: StoreState

    private var dispatchFunction: DispatchFunction!
    private let reducer: Reducer<StoreState>
    private let dispatchQueue: DispatchQueue

    public init(
        reducer: @escaping Reducer<StoreState>,
        middleware: [Middleware<StoreState>] = [],
        state: StoreState,
        dispatchQueue: DispatchQueue = .main
    ) {
        self.reducer = reducer
        self.state = state
        self.dispatchQueue = dispatchQueue

        var middleware = middleware
        middleware.append(asyncActionsMiddleware)
        dispatchFunction = middleware
            .reversed()
            .reduce(
                { [unowned self] action in
                    self._dispatchOnMainQueue(action: action)
                },
                { dispatchFunction, middleware in
                    let dispatch: (Action) -> Void = { [weak self] in self?.dispatch(action: $0) }
                    let getState = { [weak self] in self?.state }
                    return middleware(dispatch, getState)(dispatchFunction)
                }
            )
    }

    public func dispatch(action: Action) {
        dispatchQueue.async {
            self.dispatchFunction(action)
        }
    }

    private func _dispatch(action: Action) {
        state = reducer(state, action)
    }

    private func _dispatchOnMainQueue(action: Action) {
        DispatchQueue.main.async {
            self._dispatch(action: action)
        }
    }
}
