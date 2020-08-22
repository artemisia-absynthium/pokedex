//
//  PokemonViewModel.swift
//  pokedex
//
//  Created by Cristina De Rito on 11/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation
import CoreData

class PokemonViewModel {

    private let network: Networkable
    private let managedObjectContext: NSManagedObjectContext
    private let limit = 1000

    var pokemonList = [NamedApiResource]()
    var pokemonResponse: PokemonSpeciesListResponse?

    private var completionHandlers = [String: [() -> Void]]()
    private var runningOperations = [String : Operation]()

    init(network: Networkable, managedObjectContext: NSManagedObjectContext) {
        self.network = network
        self.managedObjectContext = managedObjectContext
    }

    func nextPage(completion: @escaping () -> Void) {
        let next = pokemonResponse?.next ?? "https://pokeapi.co/api/v2/pokemon-species?limit=\(limit)"
        guard completionHandlers[next] == nil else {
            completionHandlers[next]?.append(completion)
            return
        }
        completionHandlers[next] = [completion]
        network.pokemonList(urlString: next) { result in
            switch result {
            case .success(let pokemonResponse):
                self.save(response: pokemonResponse)
                self.pokemonResponse = pokemonResponse
                if let completions = self.completionHandlers[next] {
                    DispatchQueue.main.async {
                        for compl in completions {
                            compl()
                        }
                    }
                }
                self.completionHandlers.removeValue(forKey: next)
            case .failure(let error):
                NSLog("PokemonList request failed with error \(error)")
                if let completions = self.completionHandlers[next] {
                    DispatchQueue.main.async {
                        for compl in completions {
                            compl()
                        }
                    }
                }
                self.completionHandlers.removeValue(forKey: next)
            }
        }
    }

    private func save(response: PokemonSpeciesListResponse) {
        managedObjectContext.perform {
            response.results.enumerated().forEach { offset, result in
                do {
                    let fetchRequest: NSFetchRequest<SpeciesMO> = SpeciesMO.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "index == %@", String(offset))
                    let results = try self.managedObjectContext.fetch(fetchRequest)
                    let speciesMO = results.first ?? SpeciesMO(context: self.managedObjectContext)
                    speciesMO.name = result.name
                    speciesMO.url = result.url
                    speciesMO.index = Int64(offset)
                } catch {
                    NSLog("Error saving downloaded pokemon species")
                }
            }
            do {
                try self.managedObjectContext.save()
            } catch {
                NSLog("Error saving downloaded pokemon species")
            }
        }
    }

}
