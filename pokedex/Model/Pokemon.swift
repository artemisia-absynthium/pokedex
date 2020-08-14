//
//  Pokemon.swift
//  pokedex
//
//  Created by Cristina De Rito on 11/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation
import UIKit

struct Reference: Decodable {
    let name: String
    let url: String
}

class Pokemon: Decodable {
    let name: String
    var sprites: Sprites?
    let stats: [Stat]?
    let types: [Type]?
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

    var gallery: [GalleryEntry] {
        var gallery = [GalleryEntry]()
        if let url = frontDefault {
            let name = frontFemale == nil ? " Default " : " ♂"
            gallery.append(GalleryEntry(name: name, imageUrl: url, image: frontDefaultImage, color: .male))
        }
        if let url = frontShiny {
            let name = frontShinyFemale == nil ? " Shiny " : " Shiny ♂"
            gallery.append(GalleryEntry(name: name, imageUrl: url, image: frontShinyImage, color: .maleShiny))
        }
        if let url = frontFemale {
            gallery.append(GalleryEntry(name: " ♀", imageUrl: url, image: frontFemaleImage, color: .female))
        }
        if let url = frontShinyFemale {
            gallery.append(GalleryEntry(name: " Shiny ♀", imageUrl: url, image: frontShinyFemaleImage, color: .femaleShiny))
        }
        return gallery
    }

}

struct GalleryEntry {
    let name: String
    let imageUrl: String
    var image: UIImage?
    let color: UIColor
}

struct Stat: Decodable {
    let baseStat: Int
    let effort: Int
    let stat: Reference

    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case effort, stat
    }
}

struct Type: Decodable {
    let slot: Int
    let type: Reference

    var color: UIColor {
        switch type.name {
        case "fighting":
            return .brown
        case "flying":
            return .systemTeal
        case "poison":
            return .purple
        case "ground":
            return .brown
        case "rock":
            return .darkGray
        case "bug":
            return .green
        case "ghost":
            return .black
        case "steel":
            return .lightGray
        case "fire":
            return .red
        case "water":
            return .blue
        case "grass":
            return .green
        case "electric":
            return .orange
        case "psychic":
            return .systemPink
        case "ice":
            return .cyan
        case "dragon":
            return .red
        case "dark":
            return .black
        case "fairy":
            return .systemPink
        case "shadow":
            return .darkGray
        default:
            return .gray
        }
    }
}
