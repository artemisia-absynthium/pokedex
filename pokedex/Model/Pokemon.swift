//
//  Pokemon.swift
//  pokedex
//
//  Created by Cristina De Rito on 11/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation
import UIKit

struct Pokemon: Decodable {
    let name: String
    let url: String
}

class PokemonDetails: Decodable {
    var sprites: Sprites?
}

struct Sprites: Decodable {

    /// The default depiction of this Pokémon from the front in battle
    let frontDefault: String?
    var frontDefaultImage: UIImage?

    /// The shiny depiction of this Pokémon from the front in battle
    let frontShiny: String?
    var frontShinyImage: UIImage?

    /// The female depiction of this Pokémon from the front in battle
    let frontFemale: String?
    var frontFemaleImage: UIImage?

    /// The shiny female depiction of this Pokémon from the front
    let frontShinyFemale: String?
    var frontShinyFemaleImage: UIImage?

    /// The default depiction of this Pokémon from the back in battle
    let backDefault: String?
    var backDefaultImage: UIImage?

    /// The shiny depiction of this Pokémon from the back in battle
    let backShiny: String?
    var backShinyImage: UIImage?

    /// The female depiction of this Pokémon from the back in battle
    let backFemale: String?
    var backFemaleImage: UIImage?

    /// The shiny female depiction of this Pokémon from the back in battle
    let backShinyFemale: String?
    var backShinyFemaleImage: UIImage?

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
        case frontShiny = "front_shiny"
        case frontFemale = "front_female"
        case frontShinyFemale = "front_shiny_female"
        case backDefault = "back_default"
        case backShiny = "back_shiny"
        case backFemale = "back_female"
        case backShinyFemale = "back_shiny_female"
    }
}
