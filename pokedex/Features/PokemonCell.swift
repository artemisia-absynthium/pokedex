//
//  PokemonCell.swift
//  pokedex
//
//  Created by Cristina De Rito on 11/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import UIKit

class PokemonCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    static let reuseIdentifier = "pokemonCell"

    /// The Pokemon URL for the pokemon this cell is presenting.
    var representedIdentifier: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 10
    }

    // MARK: Convenience

    /**
     Configures the cell for display based on the model.

     - Parameters:
         - data: An optional `Pokemon` object to display.
    */
    func configure(with pokemon: Pokemon?) {
        label.text = pokemon?.name.formatted()
        imageView.image = pokemon?.sprites?.frontDefaultImage
    }
    
}
