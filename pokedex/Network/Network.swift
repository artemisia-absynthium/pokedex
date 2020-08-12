//
//  Network.swift
//  pokedex
//
//  Created by Cristina De Rito on 11/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation
import UIKit

class Network {

    private let pokeApiBaseURL = "https://pokeapi.co/api/v2"
    let session: URLSession

    init() {
        // For making offline usage available
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }

    func pokemonList(urlString: String, completion: @escaping (Result<PokemonListResponse, Error>) -> Void) {
        fetch(urlString: urlString, completion: completion)
    }

    func pokemon(urlString: String, completion: @escaping (Result<Pokemon, Error>) -> Void) {
        fetch(urlString: urlString, completion: completion)
    }

    private func fetch<T: Decodable>(urlString: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(PokedexError.malformedUrl(url: urlString)))
            return
        }
        session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                NSLog("Call \(urlString) failed with error: \(error)")
                completion(.failure(error))
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                let error = PokedexError.statusCodeIsUnacceptable(code: (response as? HTTPURLResponse)?.statusCode)
                NSLog("Call \(urlString) failed with error: \(error)")
                completion(.failure(error))
                return
            }
            guard let data = data else {
                let error = PokedexError.missingData
                NSLog("Call \(urlString) failed with error: \(error)")
                completion(.failure(error))
                return
            }
            do {
                let response = try JSONDecoder().decode(T.self, from: data)
                completion(.success(response))
            } catch {
                NSLog("Call \(urlString) failed with error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchImage(urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(PokedexError.malformedUrl(url: urlString)))
            return
        }
        session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                NSLog("Call \(urlString) failed with error: \(error)")
                completion(.failure(error))
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                let error = PokedexError.statusCodeIsUnacceptable(code: (response as? HTTPURLResponse)?.statusCode)
                NSLog("Call \(urlString) failed with error: \(error)")
                completion(.failure(error))
                return
            }
            guard let data = data else {
                let error = PokedexError.missingData
                NSLog("Call \(urlString) failed with error: \(error)")
                completion(.failure(error))
                return
            }
            guard let image = UIImage(data: data) else {
                let error = PokedexError.imageParseFailed
                NSLog("Call \(urlString) failed with error: \(error)")
                completion(.failure(error))
                return
            }
            completion(.success(image))
        }.resume()
    }
    
}
