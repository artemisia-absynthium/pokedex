//
//  PokedexViewController.swift
//  pokedex
//
//  Created by Cristina De Rito on 10/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import UIKit
import CoreData

class PokedexViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    var detailViewController: PokemonViewController? = nil
    let network = Network()
    lazy private var viewModel = PokemonViewModel(network: network)
    lazy private var asyncFetcher = AsyncFetcher(network: network)
    


    override func viewDidLoad() {
        super.viewDidLoad()

        let gradient = CAGradientLayer()
        gradient.frame = view.frame
        gradient.colors = [0x20E2D7.cgColor, 0xF9FEA5.cgColor]
        view.layer.insertSublayer(gradient, at: 0)

        viewModel.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        viewModel.nextPage {
            self.collectionView.reloadData()
        }
        // Do any additional setup after loading the view.
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? PokemonViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        if splitViewController!.isCollapsed, let selections = collectionView.indexPathsForSelectedItems {
            for indexPath in selections {
                collectionView.deselectItem(at: indexPath, animated: false)
            }
        }
        super.viewWillAppear(animated)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = collectionView.indexPathsForSelectedItems?.first {
                let pokemon = viewModel.pokemonList[indexPath.row]
                let identifier = pokemon.url
                if let fetchedData = asyncFetcher.fetchedData(for: identifier) {
                    let controller = (segue.destination as! UINavigationController).topViewController as! PokemonViewController
                    controller.detailItem = fetchedData
                    controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                    controller.navigationItem.leftItemsSupplementBackButton = true
                    detailViewController = controller
                }
            }
        }
    }
}

// MARK: - Collection View

extension PokedexViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.pokemonResponse?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PokemonCell.reuseIdentifier, for: indexPath) as? PokemonCell else {
            fatalError("Expected `\(PokemonCell.self)` type for reuseIdentifier \(PokemonCell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        configure(cell: cell, at: indexPath)
        return cell
    }

    private func configure(cell: PokemonCell, at indexPath: IndexPath) {
        if indexPath.row < viewModel.pokemonList.count {
            let pokemon = viewModel.pokemonList[indexPath.row]
            let identifier = pokemon.url
            cell.representedIdentifier = identifier

            if let fetchedData = asyncFetcher.fetchedData(for: identifier) {
                cell.configure(with: fetchedData)
            } else {
                cell.configure(with: nil)

                asyncFetcher.fetchAsync(identifier) { fetchedData in
                    DispatchQueue.main.async {
                        guard cell.representedIdentifier == identifier else { return }
                        cell.configure(with: fetchedData)
                    }
                }
            }
        } else {
            cell.configure(with: nil)
            viewModel.nextPage {
                self.configure(cell: cell, at: indexPath)
            }
        }
    }

    // MARK: UICollectionViewDataSourcePrefetching

    /// - Tag: Prefetching
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // Begin asynchronously fetching data for the requested index paths.
        let maxRow = indexPaths.sorted { (i1, i2) -> Bool in
            i1.row < i2.row
        }.last?.row ?? 0
        fetchTo(maxRow: maxRow, indexPaths: indexPaths)
    }

    private func fetchTo(maxRow: Int, indexPaths: [IndexPath]) {
        if maxRow < viewModel.pokemonList.count {
            for indexPath in indexPaths {
                let model = viewModel.pokemonList[indexPath.row]
                asyncFetcher.fetchAsync(model.url)
            }
        } else {
            viewModel.nextPage {
                self.fetchTo(maxRow: maxRow, indexPaths: indexPaths)
            }
        }
    }

    /// - Tag: CancelPrefetching
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if indexPath.row < viewModel.pokemonList.count {
                let model = viewModel.pokemonList[indexPath.row]
                asyncFetcher.cancelFetch(model.url)
            } // Otherwise I cannot have possibly enqueued any fetch request for it
        }
    }

    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as? UICollectionViewFlowLayout
        let width = collectionView.frame.width - collectionView.contentInset.left - collectionView.contentInset.right - (layout?.sectionInset.left ?? 0) - (layout?.sectionInset.right ?? 0)
        return CGSize(width: width, height: 100)
    }
    
}

extension PokedexViewController: PokemonViewModelDelegate {
    func error(error: Error) {
        // Show error
    }
}
