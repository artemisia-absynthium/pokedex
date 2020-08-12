//
//  PokemonDetailsOperation.swift
//  pokedex
//
//  Created by Cristina De Rito on 12/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation
import UIKit

class PokemonDetailsOperation: Operation {
    // MARK: Properties

    /// The `String` pokemon URL that the operation is fetching data for.
    let identifier: String
    let network: Network

    /// The `PokemonDetails` that has been fetched by this operation.
    private(set) var fetchedData: PokemonDetails?

    // MARK: Initialization

    init(identifier: String, network: Network) {
        self.identifier = identifier
        self.network = network
    }

    // MARK: Operation overrides

    override func main() {
        let semaphore = DispatchSemaphore(value: 0)
        network.pokemonDetails(urlString: identifier) { result in
            guard !self.isCancelled else { return }
            switch result {
            case .success(let pokemonDetails):
                self.fetchedData = pokemonDetails
                if let thumb = pokemonDetails.sprites?.frontDefault {
                    self.network.fetchImage(urlString: thumb) { result in
                        switch result {
                        case .success(let image):
                            self.fetchedData?.sprites?.frontDefaultImage = image
                            semaphore.signal()
                        case .failure:
                            semaphore.signal()
                        }
                    }
                } else {
                    self.fetchedData?.sprites?.frontDefaultImage = UIImage(named: "slash.circle")
                    semaphore.signal()
                }
            case .failure:
                self.fetchedData = nil
                semaphore.signal()
            }
        }
        _ = semaphore.wait(timeout: .distantFuture)
    }
}
