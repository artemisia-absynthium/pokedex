//
//  TestNetwork.swift
//  pokedexTests
//
//  Created by Cristina De Rito on 22/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation
import UIKit
@testable import Pokédex

class TestNetwork: Networkable {

    func pokemonList(urlString: String, completion: @escaping (Result<PokemonSpeciesListResponse, Error>) -> Void) {
        let fileName = "pokemon-species-list"
        if let filepath = Bundle(for: TestNetwork.self).path(forResource: fileName, ofType: "json") {
            do {
                guard let contents = try String(contentsOfFile: filepath).data(using: .utf8) else {
                    completion(.failure(NSError(domain: "TestPokemonList", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot read from \(fileName) stub response file"])))
                    return
                }
                let response = try JSONDecoder().decode(PokemonSpeciesListResponse.self, from: contents)
                completion(.success(response))
            } catch {
                completion(.failure(NSError(domain: "TestPokemonList", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot load \(fileName) stub response file"])))
            }
        } else {
            completion(.failure(NSError(domain: "TestPokemonList", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot find \(fileName) stub response file"])))
        }
    }

    func pokemonSpecies(urlString: String, completion: @escaping (Result<PokemonSpeciesResponse, Error>) -> Void) {
        let fileName = "pokemon-species"
        if let filepath = Bundle(for: TestNetwork.self).path(forResource: fileName, ofType: "json") {
            do {
                guard let contents = try String(contentsOfFile: filepath).data(using: .utf8) else {
                    completion(.failure(NSError(domain: "TestPokemonSpecies", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot read from \(fileName) stub response file"])))
                    return
                }
                let response = try JSONDecoder().decode(PokemonSpeciesResponse.self, from: contents)
                completion(.success(response))
            } catch {
                completion(.failure(NSError(domain: "TestPokemonSpecies", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot load \(fileName) stub response file"])))
            }
        } else {
            completion(.failure(NSError(domain: "TestPokemonSpecies", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot find \(fileName) stub response file"])))
        }
    }

    func pokemon(urlString: String, completion: @escaping (Result<PokemonResponse, Error>) -> Void) {
        let fileName = "pokemon"
        if let filepath = Bundle(for: TestNetwork.self).path(forResource: fileName, ofType: "json") {
            do {
                guard let contents = try String(contentsOfFile: filepath).data(using: .utf8) else {
                    completion(.failure(NSError(domain: "TestPokemon", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot read from \(fileName) stub response file"])))
                    return
                }
                let response = try JSONDecoder().decode(PokemonResponse.self, from: contents)
                completion(.success(response))
            } catch {
                completion(.failure(NSError(domain: "TestPokemon", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot load \(fileName) stub response file"])))
            }
        } else {
            completion(.failure(NSError(domain: "TestPokemon", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot find \(fileName) stub response file"])))
        }
    }

    func fetchImage(urlString: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let fileName = "3"
        if let filepath = Bundle(for: TestNetwork.self).path(forResource: fileName, ofType: "png") {
            guard let contents = UIImage(contentsOfFile: filepath)?.pngData() else {
                completion(.failure(NSError(domain: "TestPokemon", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot read from \(fileName) stub response file"])))
                return
            }
            completion(.success(contents))
        } else {
            completion(.failure(NSError(domain: "TestPokemon", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot find \(fileName) stub response file"])))
        }
    }

}
