//
//  PokemonListResponse.swift
//  pokedex
//
//  Created by Cristina De Rito on 11/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation

struct PokemonListResponse: Decodable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Reference]
}
