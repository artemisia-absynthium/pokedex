//
//  PokemonViewController.swift
//  pokedex
//
//  Created by Cristina De Rito on 10/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import UIKit
import CoreData

class PokemonViewController: UIViewController {

    @IBOutlet weak var pokemonImage: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var typesLabel: UILabel!
    @IBOutlet weak var statsLabel: UILabel!
    @IBOutlet weak var statsContainer: UIView!
    @IBOutlet weak var statsPointsLabel: UILabel!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyStateLabel: UILabel!

    var asyncFetcher: AsyncFetcher?
    var detailItem: SpeciesMO? {
        didSet {
            if isViewLoaded {
                configureView()
            }
        }
    }
    private var requestedOperations = [String]()
    private var selectedVariety: String? {
        didSet {
            guard let selectedVariety = selectedVariety, let variety = getSelectedVariety(selectedVariety: selectedVariety) else {
                return
            }
            buildTypesView(types: variety.types?.array as? [TypeMO] ?? [])
            buildStatsView(stats: variety.stats?.array as? [StatMO] ?? [])
        }
    }
    private var selectedImage: GalleryID = .frontDefault {
        didSet {
            guard let selectedVariety = selectedVariety, let variety = getSelectedVariety(selectedVariety: selectedVariety) else {
                self.transition(image: nil)
                return
            }
            switch selectedImage {
            case .frontDefault:
                guard let url = variety.spriteFrontDefaultUrl else {
                    self.transition()
                    return
                }
                if let image = variety.spriteFrontDefault {
                    self.transition(image: UIImage(data: image))
                } else {
                    self.loadImage(url: url, pokemon: variety, id: selectedImage)
                }
            case .frontShiny:
                guard let url = variety.spriteFrontShinyUrl else {
                    self.transition()
                    return
                }
                if let image = variety.spriteFrontShiny {
                    self.transition(image: UIImage(data: image))
                } else {
                    self.loadImage(url: url, pokemon: variety, id: selectedImage)
                }
            case .frontFemale:
                guard let url = variety.spriteFrontFemaleUrl else {
                    self.transition()
                    return
                }
                if let image = variety.spriteFrontFemale {
                    self.transition(image: UIImage(data: image))
                } else {
                    self.loadImage(url: url, pokemon: variety, id: selectedImage)
                }
            case .frontShinyFemale:
                guard let url = variety.spriteFrontShinyFemaleUrl else {
                    self.transition()
                    return
                }
                if let image = variety.spriteFrontShinyFemale {
                    self.transition(image: UIImage(data: image))
                } else {
                    self.loadImage(url: url, pokemon: variety, id: selectedImage)
                }
            }
        }
    }

    private func getSelectedVariety(selectedVariety: String) -> PokemonMO? {
        return (detailItem?.varieties?.array as? [PokemonMO])?.first(where: { pokemon in
            pokemon.name == selectedVariety
        })
    }

    private func loadImage(url: String, pokemon: PokemonMO, id: GalleryID) {
        if let data = asyncFetcher?.fetchedImage(for: url) {
            self.transition(image: UIImage(data: data))
        } else {
            requestedOperations.append(url)
            asyncFetcher?.fetchAsyncImage(url, pokemonName: pokemon.name ?? "", id: selectedImage, completion: { data in
                if self.selectedVariety == pokemon.name && self.selectedImage == id, let data = data {
                    let image = UIImage(data: data)
                    DispatchQueue.main.async {
                        self.transition(image: image)
                    }
                }
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let gradient = CAGradientLayer()
        gradient.frame = view.frame
        gradient.colors = [0x20E2D7.cgColor, 0xF9FEA5.cgColor]
        view.layer.insertSublayer(gradient, at: 0)
        
        configureView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        for identifier in requestedOperations {
            asyncFetcher?.cancelFetch(identifier)
        }
        requestedOperations.removeAll()
    }
    
    func configureView() {
        emptyStateLabel.text = NSLocalizedString("EmptyState", value: "Welcome to the Pokédex, choose a Pokémon to see its details", comment: "Empty state default message")
        emptyStateView.isHidden = detailItem != nil
        for identifier in requestedOperations {
            asyncFetcher?.cancelFetch(identifier)
        }
        requestedOperations.removeAll()
        selectedVariety = nil
        pokemonImage.image = nil
        if let detail = detailItem {
            navigationItem.title = detail.name?.formatted()
            let varieties = getVarieties()
            let defaultForm = varieties.first { $0.isDefault }
            self.buildTypesView(types: defaultForm?.types?.array as? [TypeMO] ?? [])
            self.buildStatsView(stats: defaultForm?.stats?.array as? [StatMO] ?? [])
            selectedVariety = defaultForm?.name
            buildGalleryButtonsView()
        }
        selectedImage = .frontDefault
    }

    private func buildStatsView(stats: [StatMO]) {
        var statsText = [String]()
        var statsPointsText = [String]()
        for stat in stats {
            statsText.append("\(stat.stat?.formatted() ?? "NA"):")
            statsPointsText.append("\(stat.baseStat)")
        }
        statsLabel.text = statsText.joined(separator: "\n")
        statsPointsLabel.text = statsPointsText.joined(separator: "\n")
    }

    private func buildTypesView(types: [TypeMO]) {
        let typesString = types.map { ($0.name ?? "NA").uppercased() }.joined(separator: "/")
        typesLabel.text = "TYPE: \(typesString)"
    }

    private func hasMultipleForms() -> Bool {
        return detailItem?.varieties?.count ?? 1 > 1
    }

    private func getVarieties() -> [PokemonMO] {
        return (detailItem?.varieties?.array as? [PokemonMO]) ?? []
    }

    private func buildGalleryButtonsView() {
        guard let detail = detailItem else {
            return
        }
        let container = UIStackView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 180))
        container.spacing = 16
        stackView.insertArrangedSubview(container, at: 0)
        let formsNamesContainer = UIStackView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width / 3, height: 180))
        formsNamesContainer.axis = .vertical
        formsNamesContainer.spacing = 8
        formsNamesContainer.distribution = .equalSpacing
        if hasMultipleForms() {
            container.addArrangedSubview(formsNamesContainer)
        }
        let buttonsContainer = UIStackView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 180))
        buttonsContainer.axis = .vertical
        buttonsContainer.spacing = 8
        container.addArrangedSubview(buttonsContainer)
        getVarieties().enumerated().forEach { offset, variety in
            let galleryButtonsView = UIStackView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 180))
            galleryButtonsView.spacing = 4
            buttonsContainer.addArrangedSubview(galleryButtonsView)
            let buttonFrontDefault = createGalleryButton(pokemon: detail, variety: variety, id: .frontDefault)
            galleryButtonsView.addArrangedSubview(buttonFrontDefault)
            let buttonFrontShiny = createGalleryButton(pokemon: detail, variety: variety, id: .frontShiny)
            galleryButtonsView.addArrangedSubview(buttonFrontShiny)
            if detail.hasGenderDifferences {
                let buttonFrontFemale = createGalleryButton(pokemon: detail, variety: variety, id: .frontFemale)
                galleryButtonsView.addArrangedSubview(buttonFrontFemale)
                let buttonFrontShinyFemale = createGalleryButton(pokemon: detail, variety: variety, id: .frontShinyFemale)
                galleryButtonsView.addArrangedSubview(buttonFrontShinyFemale)
            }
            if hasMultipleForms() {
                var varietyName = (variety.name ?? "").replacingOccurrences(of: detail.name ?? "", with: "").formatted()
                if varietyName.isEmpty {
                    varietyName = NSLocalizedString("Normal", comment: "Default form name")
                }
                let label = UILabel()
                label.textAlignment = .right
                label.text = varietyName
                label.textColor = .black
                formsNamesContainer.addArrangedSubview(label)
                label.translatesAutoresizingMaskIntoConstraints = false
                label.heightAnchor.constraint(equalTo: galleryButtonsView.heightAnchor).isActive = true
            }
        }
    }

    private func createGalleryButton(pokemon: SpeciesMO, variety: PokemonMO, id: GalleryID) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(id.name(hasGenderDifferences: pokemon.hasGenderDifferences), for: [])
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        button.setTitleColor(.white, for: [])
        button.layer.cornerRadius = 15
        button.backgroundColor = id.color
        button.accessibilityIdentifier = variety.name
        button.tag = id.rawValue
        button.addTarget(self, action: #selector(setImage(_:)), for: .touchUpInside)
        return button
    }

    @objc func setImage(_ sender: UIButton) {
        guard let varietyName = sender.accessibilityIdentifier, let id = GalleryID(rawValue: sender.tag) else {
            return
        }
        selectedVariety = varietyName
        selectedImage = id
    }

    private func transition(image: UIImage? = UIImage(named: "image.not.available")) {
        UIView.transition(
        with: self.pokemonImage,
        duration: 0.3,
        options: .transitionCrossDissolve,
        animations: {
            self.pokemonImage.image = image
        },
        completion: nil)
    }

    
}
