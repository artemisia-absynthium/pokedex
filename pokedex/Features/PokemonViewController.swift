//
//  PokemonViewController.swift
//  pokedex
//
//  Created by Cristina De Rito on 10/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import UIKit
import RxSwift

class PokemonViewController: UIViewController {

    @IBOutlet weak var pokemonImage: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var typesLabel: UILabel!
    @IBOutlet weak var statsLabel: UILabel!
    @IBOutlet weak var statsContainer: UIView!
    @IBOutlet weak var statsPointsLabel: UILabel!

    var detailItem: PokemonSpeciesResponse? {
        didSet {
            if isViewLoaded {
                configureView()
            }
        }
    }
    private var disposeBag = DisposeBag()
    private var gallery: [String : [GalleryID : UIImage]] = [:]
    private var forms: [String : PokemonResponse] = [:]
    private var selectedForm: String? {
        didSet {
            guard let selectedForm = selectedForm, let form = forms[selectedForm] else {
                return
            }
            buildTypesView(types: form.types)
            buildStatsView(stats: form.stats)
        }
    }
    private var selectedImage: GalleryID = .frontDefault {
        didSet {
            guard let selectedForm = selectedForm else {
                pokemonImage.image = nil
                return
            }
            pokemonImage.image = gallery[selectedForm]?[selectedImage]
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
    
    func configureView() {
        disposeBag = DisposeBag()
        selectedImage = .frontDefault
        selectedForm = nil
        pokemonImage.image = nil
        gallery.removeAll()
        forms.removeAll()
        if let detail = detailItem { // TODO: Else show empty state
            navigationItem.title = detail.name.formatted()
            let defaultForm = detail.varieties.first { $0.isDefault }
            selectedForm = defaultForm?.pokemon.name
            let imageClosure: (PokemonResponse, Event<UIImage>, GalleryID) -> Void = { pokemon, event, id in
                switch event {
                case .next(let image):
                    self.gallery[pokemon.name, default: [:]][id] = image
                case .error:
                    self.gallery[pokemon.name, default: [:]][id] = UIImage(named: "slash.circle")!
                case .completed:
                    return
                }
                if self.selectedForm == pokemon.name && self.selectedImage == id {
                    self.pokemonImage.image = self.gallery[pokemon.name]?[id]
                }
            }
            for var variety in detail.varieties {
                variety.loadedPokemon
                    .observeOn(MainScheduler.instance)
                    .subscribe({ event in
                        switch event {
                        case .next(let pokemon):
                            self.forms[pokemon.name] = pokemon
                            if self.selectedForm == pokemon.name {
                                self.buildTypesView(types: pokemon.types)
                                self.buildStatsView(stats: pokemon.stats)
                            }
                            pokemon.sprites?.frontDefaultImage?.observeOn(MainScheduler.instance)
                                .subscribe({ event in
                                    imageClosure(pokemon, event, .frontDefault)
                                })
                                .disposed(by: self.disposeBag)
                            pokemon.sprites?.frontFemaleImage?.observeOn(MainScheduler.instance)
                                .subscribe({ event in
                                    imageClosure(pokemon, event, .frontFemale)
                                })
                                .disposed(by: self.disposeBag)
                            pokemon.sprites?.frontShinyImage?.observeOn(MainScheduler.instance)
                                .subscribe({ event in
                                    imageClosure(pokemon, event, .frontShiny)
                                })
                                .disposed(by: self.disposeBag)
                            pokemon.sprites?.frontShinyFemaleImage?.observeOn(MainScheduler.instance)
                                .subscribe({ event in
                                    imageClosure(pokemon, event, .frontShinyFemale)
                                })
                                .disposed(by: self.disposeBag)
                        case .error:
                            // TODO: Show error
                            return
                        case .completed:
                            return
                        }
                    })
                    .disposed(by: disposeBag)
            }
            buildGalleryButtonsView()
        }
    }

    private func buildStatsView(stats: [Stat]) {
        var statsText = [String]()
        var statsPointsText = [String]()
        for stat in stats {
            statsText.append("\(stat.stat.name.formatted()):")
            statsPointsText.append("\(stat.baseStat)")
        }
        statsLabel.text = statsText.joined(separator: "\n")
        statsPointsLabel.text = statsPointsText.joined(separator: "\n")
    }

    private func buildTypesView(types: [Type]) {
        let typesString = types.map { $0.type.name.uppercased() }.joined(separator: "/")
        typesLabel.text = "TYPE: \(typesString)"
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
        if detail.hasMultipleForms {
            container.addArrangedSubview(formsNamesContainer)
        }
        let buttonsContainer = UIStackView(frame: CGRect(x: 0, y: 0, width: stackView.frame.width, height: 180))
        buttonsContainer.axis = .vertical
        buttonsContainer.spacing = 8
        container.addArrangedSubview(buttonsContainer)
        detail.varieties.enumerated().forEach { offset, variety in
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
            if detail.hasMultipleForms {
                var varietyName = variety.pokemon.name.replacingOccurrences(of: detail.name, with: "").formatted()
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

    private func createGalleryButton(pokemon: PokemonSpeciesResponse, variety: PokemonVarietiesResponse, id: GalleryID) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(id.name(hasGenderDifferences: pokemon.hasGenderDifferences), for: [])
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        button.setTitleColor(.white, for: [])
        button.layer.cornerRadius = 15
        button.backgroundColor = id.color
        button.accessibilityIdentifier = variety.pokemon.name
        button.tag = id.rawValue
        button.addTarget(self, action: #selector(setImage(_:)), for: .touchUpInside)
        return button
    }

    @objc func setImage(_ sender: UIButton) {
        guard let varietyName = sender.accessibilityIdentifier, let id = GalleryID(rawValue: sender.tag) else {
            return
        }
        selectedForm = varietyName
        UIView.transition(
            with: self.pokemonImage,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: {
                self.pokemonImage.image = self.gallery[varietyName]?[id] ?? UIImage(named: "slash.circle")
            },
            completion: nil)
    }

    
}
