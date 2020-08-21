//
//  AsyncFetcher.swift
//  pokedex
//
//  Created by Cristina De Rito on 12/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation
import CoreData

class AsyncFetcher {
    // MARK: Types

    private let network: Network
    private let managedObjectContext: NSManagedObjectContext

    /// A serial `OperationQueue` to lock access to the `fetchQueue` and `completionHandlers` properties.
    private let serialAccessQueue = OperationQueue()

    /// An `OperationQueue` that contains `AsyncFetcherOperation`s for requested data.
    private let fetchQueue = OperationQueue()

    /// A dictionary of arrays of closures to call when an object has been fetched for an id.
    private var completionHandlers = [String: [(PokemonSpeciesResponse?) -> Void]]()
    private var imageCompletionHandlers = [String: [(Data?) -> Void]]()

    /// An `NSCache` used to store fetched objects.
    private var cache = NSCache<NSString, PokemonSpeciesResponse>()
    private var imageCache = NSCache<NSString, NSData>()
    private var varietiesIdentifiers = [String: Set<String>]()

    // MARK: Initialization

    init(network: Network, managedObjectContext: NSManagedObjectContext) {
        self.network = network
        self.managedObjectContext = managedObjectContext
        serialAccessQueue.maxConcurrentOperationCount = 1
        fetchQueue.maxConcurrentOperationCount = 4
    }

    // MARK: Object fetching

    /**
     Asynchronously fetches data for a specified `UUID`.

     - Parameters:
         - identifier: The `UUID` to fetch data for.
         - completion: An optional called when the data has been fetched.
    */
    func fetchAsync(_ identifier: String, pokemonName: String, completion: ((PokemonSpeciesResponse?) -> Void)? = nil) {
        // Use the serial queue while we access the fetch queue and completion handlers.
        serialAccessQueue.addOperation {
            // If a completion block has been provided, store it.
            if let completion = completion {
                let handlers = self.completionHandlers[identifier, default: []]
                self.completionHandlers[identifier] = handlers + [completion]
            }

            self.fetchData(for: identifier, pokemonName: pokemonName)
        }
    }

    func fetchAsyncImage(_ identifier: String, pokemonName: String, id: GalleryID, completion: ((Data?) -> Void)? = nil) {
        // Use the serial queue while we access the fetch queue and completion handlers.
        serialAccessQueue.addOperation {
            // If a completion block has been provided, store it.
            if let completion = completion {
                let handlers = self.imageCompletionHandlers[identifier, default: []]
                self.imageCompletionHandlers[identifier] = handlers + [completion]
            }

            self.fetchImage(for: identifier, pokemonName: pokemonName, id: id)
        }
    }

    /**
     Returns the previously fetched data for a specified `UUID`.

     - Parameter identifier: The `UUID` of the object to return.
     - Returns: The 'DisplayData' that has previously been fetched or nil.
     */
    func fetchedData(for identifier: String) -> PokemonSpeciesResponse? {
        return cache.object(forKey: identifier as NSString)
    }

    func fetchedImage(for identifier: String) -> Data? {
        return imageCache.object(forKey: identifier as NSString) as Data?
    }

    /**
     Cancels any enqueued asychronous fetches for a specified `UUID`. Completion
     handlers are not called if a fetch is canceled.

     - Parameter identifier: The `UUID` to cancel fetches for.
     */
    func cancelFetch(_ identifier: String) {
        serialAccessQueue.addOperation {
            self.fetchQueue.isSuspended = true
            defer {
                self.fetchQueue.isSuspended = false
            }

            self.operation(for: identifier)?.cancel()
            NSLog("Canceled operation %@", identifier)
            self.varietiesIdentifiers[identifier]?.forEach { varietyIdentifier in
                self.cancelFetch(varietyIdentifier)
            }
            self.completionHandlers[identifier] = nil
            self.imageCompletionHandlers[identifier] = nil
        }
    }

    // MARK: Convenience

    /**
     Begins fetching data for the provided `identifier` invoking the associated
     completion handler when complete.

     - Parameter identifier: The `UUID` to fetch data for.
     */
    private func fetchData(for speciesIdentifier: String, pokemonName: String) {
        // If a request has already been made for the object, do nothing more.
        guard operation(for: speciesIdentifier) == nil else { return }

        if let data = fetchedData(for: speciesIdentifier) {
            // The object has already been cached; call the completion handler with that object.
            invokeCompletionHandlers(for: speciesIdentifier, with: data)
        } else {
            // Enqueue a request for the object.
            let speciesOperation = PokemonOperation(identifier: speciesIdentifier, pokemonName: pokemonName, network: network, managedObjectContext: managedObjectContext)

            // Set the operation's completion block to cache the fetched object and call the associated completion blocks.
            speciesOperation.completionBlock = { [weak speciesOperation] in
                guard let fetchedData = speciesOperation?.fetchedData else { return }
                self.cache.setObject(fetchedData, forKey: speciesIdentifier as NSString)

                for variety in fetchedData.varieties {
                    let varietyoperation = VarietyOperation(identifier: variety.pokemon.url, pokemonName: variety.pokemon.name, network: self.network, managedObjectContext: self.managedObjectContext)

                    varietyoperation.completionBlock = { [weak varietyoperation] in
                        guard let pokemon = varietyoperation?.fetchedData, variety.isDefault, let frontDefaultUrl = pokemon.sprites?.frontDefault else { return }

                        let defaultImageOperation = ImageOperation(identifier: frontDefaultUrl, pokemonName: pokemon.name, id: .frontDefault, network: self.network, managedObjectContext: self.managedObjectContext)

                        defaultImageOperation.completionBlock = { [weak defaultImageOperation] in
                            guard let image = defaultImageOperation?.fetchedData else { return }
                            self.imageCache.setObject(image as NSData, forKey: frontDefaultUrl as NSString)

                            self.serialAccessQueue.addOperation {
                                self.invokeCompletionHandlers(for: frontDefaultUrl, with: fetchedData)
                            }
                        }

                        self.fetchQueue.addOperation(defaultImageOperation)
                        NSLog("Added operation image %@", variety.pokemon.name)
                    }

                    self.varietiesIdentifiers[speciesIdentifier, default: []].insert(variety.pokemon.url)
                    self.fetchQueue.addOperation(varietyoperation)
                    NSLog("Added operation variety %@", variety.pokemon.name)
                }

                self.serialAccessQueue.addOperation {
                    self.invokeCompletionHandlers(for: speciesIdentifier, with: fetchedData)
                }
            }

            fetchQueue.addOperation(speciesOperation)
            NSLog("Added operation species %@", pokemonName)
        }
    }

    private func fetchImage(for identifier: String, pokemonName: String, id: GalleryID) {
        guard operation(for: identifier) == nil else { return }

        if let data = fetchedImage(for: identifier) {
            // The object has already been cached; call the completion handler with that object.
            invokeCompletionHandlers(for: identifier, with: data)
        } else {
            // Enqueue a request for the object.
            let operation = ImageOperation(identifier: identifier, pokemonName: pokemonName, id: id, network: self.network, managedObjectContext: self.managedObjectContext)

            operation.completionBlock = { [weak operation] in
                guard let fetchedData = operation?.fetchedData else { return }
                self.imageCache.setObject(fetchedData as NSData, forKey: identifier as NSString)

                self.serialAccessQueue.addOperation {
                    self.invokeCompletionHandlers(for: identifier, with: fetchedData)
                }
            }

            self.fetchQueue.addOperation(operation)
            NSLog("Added operation image %@", identifier)
        }
    }

    /**
     Returns any enqueued `ObjectFetcherOperation` for a specified `UUID`.

     - Parameter identifier: The `UUID` of the operation to return.
     - Returns: The enqueued `ObjectFetcherOperation` or nil.
     */
    private func operation(for identifier: String) -> PokemonRelatedOperation? {
        for case let fetchOperation as PokemonRelatedOperation in fetchQueue.operations
            where !fetchOperation.isCancelled && fetchOperation.identifier == identifier {
            return fetchOperation
        }

        return nil
    }

    /**
     Invokes any completion handlers for a specified `UUID`. Once called,
     the stored array of completion handlers for the `UUID` is cleared.

     - Parameters:
     - identifier: The `UUID` of the completion handlers to call.
     - object: The fetched object to pass when calling a completion handler.
     */
    private func invokeCompletionHandlers(for identifier: String, with fetchedData: PokemonSpeciesResponse) {
        let completionHandlers = self.completionHandlers[identifier, default: []]
        self.completionHandlers[identifier] = nil

        for completionHandler in completionHandlers {
            completionHandler(fetchedData)
        }
    }

    private func invokeCompletionHandlers(for identifier: String, with fetchedData: Data) {
        let completionHandlers = self.imageCompletionHandlers[identifier, default: []]
        self.imageCompletionHandlers[identifier] = nil

        for completionHandler in completionHandlers {
            completionHandler(fetchedData)
        }
    }
}
