//
//  GalleryCell.swift
//  pokedex
//
//  Created by Cristina De Rito on 12/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import UIKit

class GalleryCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!

    static let reuseIdentifier = "galleryCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 10
    }

    
}
