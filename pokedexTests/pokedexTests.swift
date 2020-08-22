//
//  pokedexTests.swift
//  pokedexTests
//
//  Created by Cristina De Rito on 10/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import XCTest
import CoreData
@testable import Pokédex

class pokedexTests: XCTestCase {

    var network: Networkable!
    var managedObjectContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        network = TestNetwork()
        managedObjectContext = TestCoreData().persistentContainer.viewContext
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let fetcher = Pokédex.AsyncFetcher(network: network, managedObjectContext: managedObjectContext)
        let expectation = XCTestExpectation(description: "Download info for Venusaur")

        fetcher.fetchAsync("https://pokeapi.co/api/v2/pokemon-species/3", pokemonName: "venusaur") {

            let fetchRequest: NSFetchRequest<Pokédex.SpeciesMO> = Pokédex.SpeciesMO.fetchRequest()
            do {
                let results = try self.managedObjectContext.fetch(fetchRequest)
                XCTAssertNotNil(results, "No data was written on Core Data.")
                XCTAssertEqual(results.count, 1, "There are a wrong number of species on Core Data")
                XCTAssertNotNil(results.first!.varieties, "Species varieties are nil")
                XCTAssertEqual(results.first!.varieties!.count, 2, "Pokemon varieties are different from 2")
                expectation.fulfill()
            } catch {
                XCTFail("Fetch request failed")
            }

        }

        wait(for: [expectation], timeout: 30)
    }

}
