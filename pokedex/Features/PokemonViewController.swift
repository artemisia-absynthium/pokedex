//
//  PokemonViewController.swift
//  pokedex
//
//  Created by Cristina De Rito on 10/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import UIKit

class PokemonViewController: UIViewController {


    func configureView() {
        if let detail = detailItem {
            navigationItem.title = detail.name.capitalized
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    var detailItem: Pokemon? {
        didSet {
            configureView()
        }
    }

    
}
