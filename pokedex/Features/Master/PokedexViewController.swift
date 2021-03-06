//
//  PokedexViewController.swift
//  pokedex
//
//  Created by Cristina De Rito on 10/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import UIKit
import CoreData

class PokedexViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var searchBar: UISearchBar!

    var detailViewController: PokemonViewController? = nil
    var managedObjectContext: NSManagedObjectContext!
    private let network = Network()
    lazy private var viewModel = PokemonViewModel(network: network, managedObjectContext: managedObjectContext)
    lazy private var asyncFetcher = AsyncFetcher(network: network, managedObjectContext: managedObjectContext)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? PokemonViewController
        }
        viewModel.nextPage {
            // Show error if any
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
            let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! PokemonViewController
                controller.detailItem = object
                if controller.asyncFetcher == nil {
                    controller.asyncFetcher = self.asyncFetcher
                }
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                detailViewController = controller
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PokemonRow.reuseIdentifier, for: indexPath)
        let pokemonSpecies = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withPokemonSpecies: pokemonSpecies)
        return cell
    }

    func configureCell(_ cell: UITableViewCell, withPokemonSpecies pokemonSpecies: SpeciesMO) {
        guard let cell = cell as? PokemonRow else {
            fatalError("Expected `\(PokemonRow.self)` type for reuseIdentifier \(PokemonRow.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        cell.configure(with: pokemonSpecies)
        if let url = pokemonSpecies.url  {
            asyncFetcher.fetchAsync(url, pokemonName: pokemonSpecies.name ?? "")
        }
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PokemonRow, let url = cell.representedIdentifier {
            asyncFetcher.cancelFetch(url)
        }
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<SpeciesMO> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest: NSFetchRequest<SpeciesMO> = SpeciesMO.fetchRequest()

        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 50

        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "index", ascending: true)

        fetchRequest.sortDescriptors = [sortDescriptor]

        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController

        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }

        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<SpeciesMO>? = nil

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }

}

// MARK: - UISearchBarDelegate

extension PokedexViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        search(searchText: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let searchText = searchBar.text ?? ""
        search(searchText: searchText)
    }

    private func search(searchText: String) {
        if searchText.isEmpty {
            fetchedResultsController.fetchRequest.predicate = nil
        } else {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "name BEGINSWITH[cd] %@", searchText)
        }
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
            NSLog("Searching for pokémon named %@", searchText)
        } catch {
            fetchedResultsController.fetchRequest.predicate = nil
            NSLog("Error searching for pokémon named %@", searchText)
        }
    }

}
