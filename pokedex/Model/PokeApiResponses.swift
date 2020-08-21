//
//  PokemonSpeciesListResponse.swift
//  pokedex
//
//  Created by Cristina De Rito on 11/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation
import UIKit


enum GalleryID: Int {
    case frontDefault = 0
    case frontFemale = 1
    case frontShiny = 2
    case frontShinyFemale = 3

    func name(hasGenderDifferences: Bool) -> String {
        switch self {
        case .frontDefault:
            return hasGenderDifferences ? " ♂" : " ♂♀"
        case .frontFemale:
            return " ♀"
        case .frontShiny:
            return hasGenderDifferences ? " ♂★" : " ♂♀★"
        case .frontShinyFemale:
            return " ♀★"
        }
    }

    var color: UIColor {
        switch self {
        case .frontDefault:
            return .male
        case .frontFemale:
            return .female
        case .frontShiny:
            return .maleShiny
        case .frontShinyFemale:
            return .femaleShiny
        }
    }
}

struct PokemonSpeciesListResponse: Decodable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [NamedApiResource]
}

struct NamedApiResource: Decodable {
    let name: String
    let url: String
}

class PokemonSpeciesResponse: Decodable {
    let name: String
    let order: Int?
//    let formDescriptions: [String]?
    let hasGenderDifferences: Bool
//    let evolutionChain
    let varieties: [PokemonVarietiesResponse]

    var hasMultipleForms: Bool {
        return varieties.count > 1
    }

    enum CodingKeys: String, CodingKey {
        case name, order, varieties
        case hasGenderDifferences = "has_gender_differences"
    }
}

struct PokemonVarietiesResponse: Decodable {
    let isDefault: Bool
    let pokemon: NamedApiResource

    enum CodingKeys: String, CodingKey {
        case isDefault = "is_default"
        case pokemon
    }
}

class PokemonResponse: Decodable {
    let name: String
    var sprites: SpritesResponse?
    let stats: [StatResponse]
    let types: [TypeResponse]
}

struct SpritesResponse: Decodable {

    /// The default depiction of this Pokémon from the front in battle
    let frontDefault: String?

    /// The shiny depiction of this Pokémon from the front in battle
    let frontShiny: String?

    /// The female depiction of this Pokémon from the front in battle
    let frontFemale: String?

    /// The shiny female depiction of this Pokémon from the front in battle
    let frontShinyFemale: String?

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
        case frontShiny = "front_shiny"
        case frontFemale = "front_female"
        case frontShinyFemale = "front_shiny_female"
    }
}

struct StatResponse: Decodable {
    let baseStat: Int
    let effort: Int
    let stat: NamedApiResource

    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case effort, stat
    }
}

struct TypeResponse: Decodable {
    let slot: Int
    let type: NamedApiResource
}
