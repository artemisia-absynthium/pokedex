//
//  PokemonViewModel.swift
//  pokedex
//
//  Created by Cristina De Rito on 11/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation

class PokemonViewModel {

    private let network: Network
    private let limit = 500

    var pokemonList = [Pokemon]()
    var delegate: PokemonViewModelDelegate?
    var pokemonResponse: PokemonListResponse?

    private var completionHandlers = [String: [() -> Void]]()

    lazy private var completion: (Result<PokemonListResponse, Error>) -> Void = { result in
        switch result {
        case .success(let pokemonResponse):
            self.pokemonResponse = pokemonResponse
            self.pokemonList.append(contentsOf: pokemonResponse.results)
        case .failure(let error):
            NSLog("PokemonList request failed with error \(error)")
            self.delegate?.error(error: error)
        }
    }

    init(network: Network) {
        self.network = network
    }

    func nextPage(completion: @escaping () -> Void) {
        let next = pokemonResponse?.next ?? "https://pokeapi.co/api/v2/pokemon?limit=\(limit)"
        guard completionHandlers[next] == nil else {
            completionHandlers[next]?.append(completion)
            return
        }
        completionHandlers[next] = [completion]
        network.pokemonList(urlString: next) { result in
            self.completion(result)
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

protocol PokemonViewModelDelegate {
    func error(error: Error)
}
