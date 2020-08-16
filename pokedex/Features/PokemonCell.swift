//
//  PokemonCell.swift
//  pokedex
//
//  Created by Cristina De Rito on 11/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import UIKit
import RxSwift

class PokemonCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    static let reuseIdentifier = "pokemonCell"

    /// The Pokemon URL for the pokemon this cell is presenting.
    var representedIdentifier: String?

    var disposeBag = DisposeBag()

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
    func configure(with pokemon: PokemonSpeciesResponse?) {
        disposeBag = DisposeBag()
        label.text = pokemon?.name.formatted()
        imageView.image = nil
        var defaultForm = pokemon?.varieties.first(where: { variety in
            variety.isDefault
        })
        defaultForm?.loadedPokemon
            .observeOn(MainScheduler.instance)
            .subscribe({ event in
                switch event {
                case .next(let pokemon):
                    pokemon.sprites?.frontDefaultImage?
                        .observeOn(MainScheduler.instance)
                        .subscribe({ event in
                            switch event {
                            case .next(let image):
                                self.imageView.image = image
                            case .error:
                                self.imageView.image = UIImage(named: "slash.circle")
                            case .completed:
                                return
                            }
                        }).disposed(by: self.disposeBag)
                case .error:
                    self.imageView.image = UIImage(named: "slash.circle")
                case .completed:
                    return
                }
            }).disposed(by: disposeBag)
    }
    
}
