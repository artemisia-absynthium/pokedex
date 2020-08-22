//
//  PokemonOperation.swift
//  pokedex
//
//  Created by Cristina De Rito on 12/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation
import UIKit
import CoreData

protocol PokemonRelatedOperation: Operation {
    var identifier: String { get }
}

class PokemonOperation: Operation, PokemonRelatedOperation {
    // MARK: Properties

    /// The `String` pokemon species URL that the operation is fetching data for.
    let identifier: String

    /// The `String` pokemon species name that the operation is fetching data for.
    let pokemonName: String

    private let network: Networkable
    private let managedObjectContext: NSManagedObjectContext

    /// The `PokemonSpeciesResponse` that has been fetched by this operation.
    private(set) var fetchedData: PokemonSpeciesResponse?

    // MARK: Initialization

    init(identifier: String, pokemonName: String, network: Networkable, managedObjectContext: NSManagedObjectContext) {
        self.identifier = identifier
        self.pokemonName = pokemonName
        self.network = network
        self.managedObjectContext = managedObjectContext
    }

    // MARK: Operation overrides

    override func main() {
        let semaphore = DispatchSemaphore(value: 0)
        network.pokemonSpecies(urlString: identifier) { result in
            guard !self.isCancelled else { return }
            switch result {
            case .success(let pokemonSpeciesResponse):
                self.fetchedData = pokemonSpeciesResponse
                CoreDataOperations.save(species: pokemonSpeciesResponse, context: self.managedObjectContext)
                semaphore.signal()
            case .failure:
                self.fetchedData = nil
                semaphore.signal()
            }
        }
        _ = semaphore.wait(timeout: .distantFuture)
    }
}

class VarietyOperation: Operation {
    // MARK: Properties

    /// The `String` pokemon URL that the operation is fetching data for.
    let identifier: String

    /// The `String` pokemon name that the operation is fetching data for.
    let pokemonName: String

    let network: Networkable
    let managedObjectContext: NSManagedObjectContext

    /// The `PokemonResponse` that has been fetched by this operation.
    private(set) var fetchedData: PokemonResponse?

    // MARK: Initialization

    init(identifier: String, pokemonName: String, network: Networkable, managedObjectContext: NSManagedObjectContext) {
        self.identifier = identifier
        self.pokemonName = pokemonName
        self.network = network
        self.managedObjectContext = managedObjectContext
    }

    // MARK: Operation overrides

    override func main() {
        let semaphore = DispatchSemaphore(value: 0)
        network.pokemon(urlString: identifier) { result in
            guard !self.isCancelled else { return }
            switch result {
            case .success(let pokemonResponse):
                self.fetchedData = pokemonResponse
                CoreDataOperations.save(pokemon: pokemonResponse, context: self.managedObjectContext)
                semaphore.signal()
            case .failure:
                self.fetchedData = nil
                semaphore.signal()
            }
        }
        _ = semaphore.wait(timeout: .distantFuture)
    }
}

class ImageOperation: Operation {
    // MARK: Properties

    /// The `String` pokemon image URL that the operation is fetching data for.
    let identifier: String

    /// The `String` pokemon name whose image the operation is fetching.
    let pokemonName: String

    /// The `GalleryID` image type that the operation is fetching data for.
    let id: GalleryID

    let network: Networkable
    let managedObjectContext: NSManagedObjectContext

    /// The image `Data` that has been fetched by this operation.
    private(set) var fetchedData: Data?

    // MARK: Initialization

    init(identifier: String, pokemonName: String, id: GalleryID, network: Networkable, managedObjectContext: NSManagedObjectContext) {
        self.identifier = identifier
        self.pokemonName = pokemonName
        self.id = id
        self.network = network
        self.managedObjectContext = managedObjectContext
    }

    // MARK: Operation overrides

    override func main() {
        let semaphore = DispatchSemaphore(value: 0)
        network.fetchImage(urlString: identifier) { result in
            guard !self.isCancelled else { return }
            switch result {
            case .success(let image):
                self.fetchedData = image
                CoreDataOperations.save(image: image, forPokemonName: self.pokemonName, with: self.id, context: self.managedObjectContext)
                semaphore.signal()
            case .failure:
                self.fetchedData = nil
                semaphore.signal()
            }
        }
        _ = semaphore.wait(timeout: .distantFuture)
    }
}
