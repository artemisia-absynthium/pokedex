//
//  PokemonOperation.swift
//  pokedex
//
//  Created by Cristina De Rito on 12/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation
import UIKit

class PokemonOperation: Operation {
    // MARK: Properties

    /// The `String` pokemon URL that the operation is fetching data for.
    let identifier: String
    let network: Network

    /// The `Pokemon` that has been fetched by this operation.
    private(set) var fetchedData: PokemonSpeciesResponse?

    // MARK: Initialization

    init(identifier: String, network: Network) {
        self.identifier = identifier
        self.network = network
    }

    // MARK: Operation overrides

    override func main() {
        let semaphore = DispatchSemaphore(value: 0)
        network.pokemonSpecies(urlString: identifier) { result in
            guard !self.isCancelled else { return }
            switch result {
            case .success(let pokemonSpeciesResponse):
                self.fetchedData = pokemonSpeciesResponse
                semaphore.signal()
            case .failure:
                self.fetchedData = nil
                semaphore.signal()
            }
        }
        _ = semaphore.wait(timeout: .distantFuture)
    }
}
