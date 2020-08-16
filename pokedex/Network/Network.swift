//
//  Network.swift
//  pokedex
//
//  Created by Cristina De Rito on 11/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class Network {

    // TODO: Implement manual cache for lazy Observables to be transparent

    private let pokeApiBaseURL = "https://pokeapi.co/api/v2"
    let session: URLSession

    init() {
        // For making offline usage available
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }

    func pokemonList(urlString: String, completion: @escaping (Result<PokemonSpeciesListResponse, Error>) -> Void) {
        fetch(urlString: urlString, completion: completion)
    }

    func pokemonSpecies(urlString: String, completion: @escaping (Result<PokemonSpeciesResponse, Error>) -> Void) {
        fetch(urlString: urlString, completion: completion)
    }

    func pokemon(urlString: String, completion: @escaping (Result<PokemonResponse, Error>) -> Void) {
        fetch(urlString: urlString, completion: completion)
    }

    func pokemon(urlString: String) -> Observable<PokemonResponse> {
        return fetch(urlString: urlString)
    }

    private func fetch<T: Decodable>(urlString: String) -> Observable<T> {
        return Observable<T>.create { observer in
            guard let url = URL(string: urlString) else {
                observer.onError(PokedexError.malformedUrl(url: urlString))
                return Disposables.create()
            }
            NSLog("GET \(url)")
            let task = self.session.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    NSLog("Call \(urlString) failed with error: \(error)")
                    observer.onError(error)
                    return
                }
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                    let error = PokedexError.statusCodeIsUnacceptable(code: (response as? HTTPURLResponse)?.statusCode)
                    NSLog("Call \(urlString) failed with error: \(error)")
                    observer.onError(error)
                    return
                }
                guard let data = data else {
                    let error = PokedexError.missingData
                    NSLog("Call \(urlString) failed with error: \(error)")
                    observer.onError(error)
                    return
                }
                do {
                    NSLog("Response: \(String(describing: response))")
                    let response = try JSONDecoder().decode(T.self, from: data)
                    observer.onNext(response)
                    observer.onCompleted()
                } catch {
                    NSLog("Call \(urlString) failed with error: \(error)")
                    observer.onError(error)
                }
            }
            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }

    private func fetch<T: Decodable>(urlString: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(PokedexError.malformedUrl(url: urlString)))
            return
        }
        NSLog("GET \(url)")
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
                NSLog("Response: \(String(describing: response))")
                let response = try JSONDecoder().decode(T.self, from: data)
                completion(.success(response))
            } catch {
                NSLog("Call \(urlString) failed with error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchImage(urlString: String) -> Observable<UIImage> {
        return Observable<UIImage>.create { observer in
            guard let url = URL(string: urlString) else {
                observer.onError(PokedexError.malformedUrl(url: urlString))
                return Disposables.create()
            }
            NSLog("GET \(url)")
            let task = self.session.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    NSLog("Call \(urlString) failed with error: \(error)")
                    observer.onError(error)
                    return
                }
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                    let error = PokedexError.statusCodeIsUnacceptable(code: (response as? HTTPURLResponse)?.statusCode)
                    NSLog("Call \(urlString) failed with error: \(error)")
                    observer.onError(error)
                    return
                }
                guard let data = data else {
                    let error = PokedexError.missingData
                    NSLog("Call \(urlString) failed with error: \(error)")
                    observer.onError(error)
                    return
                }
                guard let image = UIImage(data: data) else {
                    let error = PokedexError.imageParseFailed
                    NSLog("Call \(urlString) failed with error: \(error)")
                    observer.onError(error)
                    return
                }
                observer.onNext(image)
                observer.onCompleted()
            }
            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }
    
}
