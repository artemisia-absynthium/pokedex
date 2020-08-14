//
//  PokemonViewController.swift
//  pokedex
//
//  Created by Cristina De Rito on 10/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import UIKit

class PokemonViewController: UIViewController {

    @IBOutlet weak var pokemonImage: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var statsLabel: UILabel!

    var gallery: [Int : GalleryEntry] = [:]
    
    func configureView() {
        if let detail = detailItem {
            navigationItem.title = detail.name.formatted()
            pokemonImage.image = detail.sprites?.frontDefaultImage

            let galleryView = UIStackView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 180))
            galleryView.axis = .horizontal
            galleryView.alignment = .fill
            galleryView.distribution = .fill
            galleryView.spacing = 4
            stackView.insertArrangedSubview(galleryView, at: 0)
            for (offset, var entry) in (detail.sprites?.gallery ?? []).enumerated() {
                let button = UIButton(type: .system)
                button.setTitle(entry.name, for: [])
                button.titleLabel?.font = .systemFont(ofSize: 20)
                button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
                button.setTitleColor(.white, for: [])
                button.backgroundColor = entry.color
                button.layer.cornerRadius = 12
                button.tag = offset
                button.addTarget(self, action: #selector(setImage(_:)), for: .touchUpInside)
                if entry.image != nil {
                    self.gallery[offset] = entry
                    galleryView.addArrangedSubview(button)
                } else {
                    network?.fetchImage(urlString: entry.imageUrl, completion: { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let image):
                                entry.image = image
                            case .failure:
                                entry.image = UIImage(named: "slash.circle")
                            }
                            self.gallery[offset] = entry
                            galleryView.addArrangedSubview(button)
                        }
                    })
                }
            }

            var statsText = [String]()
            for stat in detail.stats ?? [] {
                statsText.append("\(stat.stat.name.formatted()): \(stat.baseStat)")
            }
            statsLabel.text = statsText.joined(separator: "\n")

            let view = UIStackView()
            view.axis = .vertical
            view.alignment = .center
            view.spacing = 4
            stackView.insertArrangedSubview(view, at: 1)
            for type in detail.types?.sorted(by: { t1, t2 in t1.slot < t2.slot }) ?? [] {
                let label = UILabel()
                label.text = type.type.name.formatted()
                view.addArrangedSubview(label)
            }
        }
    }

    @objc func setImage(_ sender: UIButton) {
        UIView.transition(
            with: self.pokemonImage,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: {
                self.pokemonImage.image = self.gallery[sender.tag]?.image
            },
            completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    var detailItem: Pokemon? {
        didSet {
            if isViewLoaded {
                configureView()
            }
        }
    }
    var network: Network?

    
}
