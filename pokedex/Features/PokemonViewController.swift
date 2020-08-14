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
    var detailItem: Pokemon? {
        didSet {
            if isViewLoaded {
                configureView()
            }
        }
    }
    var network: Network?

    override func viewDidLoad() {
        super.viewDidLoad()
        pokemonImage.layer.cornerRadius = 15
        pokemonImage.backgroundColor = .systemTeal
        configureView()
    }
    
    func configureView() {
        if let detail = detailItem {
            navigationItem.title = detail.name.formatted()
            pokemonImage.image = detail.sprites?.frontDefaultImage

            buildGalleryButtonsView(gallery: detail.sprites?.gallery ?? [])
            buildTypesView(types: detail.types ?? [])

            var statsText = [String]()
            for stat in detail.stats ?? [] {
                statsText.append("\(stat.stat.name.formatted()): \(stat.baseStat)")
            }
            statsLabel.text = statsText.joined(separator: "\n")
        }
    }

    private func buildTypesView(types: [Type]) {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .center
        view.spacing = 4
        stackView.insertArrangedSubview(view, at: 1)
        for type in types.sorted(by: { t1, t2 in t1.slot < t2.slot }) {
            let container = UIView()
            container.backgroundColor = type.color
            container.layer.cornerRadius = 15
            let label = UILabel()
            label.textColor = .white
            container.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            container.topAnchor.constraint(equalTo: label.topAnchor, constant: -4).isActive = true
            container.leadingAnchor.constraint(equalTo: label.leadingAnchor, constant: -12).isActive = true
            container.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 12).isActive = true
            container.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 4).isActive = true
            label.text = type.type.name.formatted()
            view.addArrangedSubview(container)
        }
    }

    /// This and the UIImageView above should be abstracted to a custom UIView (e.g. GalleryView) to remove gallery logic from this UIViewController
    private func buildGalleryButtonsView(gallery: [GalleryEntry]) {
        let galleryButtonsView = UIStackView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 180))
        galleryButtonsView.axis = .horizontal
        galleryButtonsView.alignment = .fill
        galleryButtonsView.distribution = .fill
        galleryButtonsView.spacing = 4
        stackView.insertArrangedSubview(galleryButtonsView, at: 0)
        for (offset, var entry) in gallery.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(entry.name, for: [])
            button.titleLabel?.font = .systemFont(ofSize: 18)
            button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
            button.setTitleColor(.white, for: [])
            button.backgroundColor = entry.color
            button.layer.cornerRadius = 15
            button.tag = offset
            button.addTarget(self, action: #selector(setImage(_:)), for: .touchUpInside)
            if entry.image != nil {
                self.gallery[offset] = entry
                galleryButtonsView.addArrangedSubview(button)
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
                        galleryButtonsView.addArrangedSubview(button)
                    }
                })
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

    
}
