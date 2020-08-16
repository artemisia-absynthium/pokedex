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
    private var gallery: [Int : UIImage] = [:]
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
            pokemonImage.image = gallery[selectedImage.rawValue]
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        pokemonImage.layer.cornerRadius = 15
        statsContainer.layer.cornerRadius = 15
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
                    self.gallery[id.rawValue] = image
                case .error:
                    self.gallery[id.rawValue] = UIImage(named: "slash.circle")
                case .completed:
                    return
                }
                if self.selectedForm == pokemon.name && self.selectedImage == id {
                    self.pokemonImage.image = self.gallery[id.rawValue]
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

//            buildGalleryButtonsView(gallery: detail.sprites?.gallery ?? [])
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
//            if entry.image != nil {
//                self.gallery[offset] = entry
//                galleryButtonsView.addArrangedSubview(button)
//            } else {
//                network?.fetchImage(urlString: entry.imageUrl, completion: { result in
//                    DispatchQueue.main.async {
//                        switch result {
//                        case .success(let image):
//                            entry.image = image
//                        case .failure:
//                            entry.image = UIImage(named: "slash.circle")
//                        }
//                        self.gallery[offset] = entry
//                        galleryButtonsView.addArrangedSubview(button)
//                    }
//                })
//            }
        }
    }

    @objc func setImage(_ sender: UIButton) {
        UIView.transition(
            with: self.pokemonImage,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: {
                self.pokemonImage.image = self.gallery[sender.tag]
            },
            completion: nil)
    }

    
}
