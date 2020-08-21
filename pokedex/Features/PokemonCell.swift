//
//  PokemonCell.swift
//  pokedex
//
//  Created by Cristina De Rito on 11/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import UIKit

class PokemonRow: UITableViewCell {

    @IBOutlet weak var pokemonImageView: UIImageView!
    @IBOutlet weak var pokemonNameLabel: UILabel!

    static let reuseIdentifier = "pokemonCell"

    /// The Pokemon species URL for the pokemon this cell is presenting.
    var representedIdentifier: String?

    // MARK: Convenience

        /**
         Configures the cell for display based on the model.

         - Parameters:
             - data: An optional `Pokemon` object to display.
        */
        func configure(with pokemon: SpeciesMO?) {
            pokemonNameLabel.text = pokemon?.name?.formatted()
            let defaultForm = (pokemon?.varieties?.array as? [PokemonMO])?.first(where: { variety in
                variety.isDefault
            })
            let image: UIImage?
            if let data = defaultForm?.spriteFrontDefault {
                image = UIImage(data: data)
            } else {
                image = UIImage(named: "image.not.available")
            }
            pokemonImageView.image = image
        }
    
}
