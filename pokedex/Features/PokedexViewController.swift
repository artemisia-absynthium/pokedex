//
//  PokedexViewController.swift
//  pokedex
//
//  Created by Cristina De Rito on 10/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import UIKit
import CoreData

class PokedexTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: PokemonViewController? = nil
    let network = Network()
    var managedObjectContext: NSManagedObjectContext!
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
        if let url = pokemonSpecies.url, asyncFetcher.fetchedData(for: url) == nil  {
            asyncFetcher.fetchAsync(url, pokemonName: pokemonSpecies.name ?? "")
        }
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PokemonRow, let url = cell.representedIdentifier, asyncFetcher.fetchedData(for: url) == nil {
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
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
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

//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        tableView.beginUpdates()
//    }

//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
//        switch type {
//            case .insert:
//                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
//            case .delete:
//                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
//            default:
//                return
//        }
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        switch type {
//            case .insert:
//                guard let newIndexPath = newIndexPath else {
//                    return
//                }
//                tableView.insertRows(at: [newIndexPath], with: .fade)
//            case .delete:
//                guard let indexPath = indexPath else {
//                    return
//                }
//                tableView.deleteRows(at: [indexPath], with: .fade)
//            case .update:
//                guard let indexPath = indexPath else {
//                    return
//                }
//                configureCell(tableView.cellForRow(at: indexPath)!, withPokemonSpecies: anObject as! SpeciesMO)
//            case .move:
//                guard let indexPath = indexPath, let newIndexPath = newIndexPath else {
//                    return
//                }
//                configureCell(tableView.cellForRow(at: indexPath)!, withPokemonSpecies: anObject as! SpeciesMO)
//                tableView.moveRow(at: indexPath, to: newIndexPath)
//            default:
//                return
//        }
//    }
//
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        tableView.endUpdates()
//    }


     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // In the simplest, most efficient, case, reload the table view.
        tableView.reloadData()
    }

}
