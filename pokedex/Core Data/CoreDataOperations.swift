//
//  CoreDataOperations.swift
//  pokedex
//
//  Created by Cristina De Rito on 20/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation
import CoreData

class CoreDataOperations {

    static func save(species: PokemonSpeciesResponse, context: NSManagedObjectContext) {
        context.performAndWait {
            let fetchRequest: NSFetchRequest<SpeciesMO> = SpeciesMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name == %@", species.name)
            do {
                let results = try context.fetch(fetchRequest)
                let speciesMO = results.first ?? SpeciesMO(context: context)
                speciesMO.order = species.order == nil ? 0 : Int64(species.order!)
                speciesMO.hasGenderDifferences = species.hasGenderDifferences
                let varieties = save(varieties: species.varieties, species: speciesMO, context: context)
                if let varieties = varieties {
                    speciesMO.addToVarieties(NSOrderedSet(array: varieties))
                    speciesMO.speciesDownloaded = true
                }
                do {
                    try context.save()
                } catch {
                    NSLog("Error saving species %@: \(error)", species.name)
                }
            } catch {
                NSLog("Error saving species %@: \(error)", species.name)
            }
        }
    }

    private static func save(varieties: [PokemonVarietiesResponse], species: SpeciesMO, context: NSManagedObjectContext) -> [PokemonMO]? {
        do {
            var savedPokemonList = [PokemonMO]()
            for variety in varieties {
                // I would rather have done a single fetch request for all the varieties with a predicate "name IN %@" and an array parameter but it caused a crash so for now I'm doing this way
                let fetchRequest: NSFetchRequest<PokemonMO> = PokemonMO.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "name == %@", variety.pokemon.name)
                let result = try context.fetch(fetchRequest)
                let pokemon: PokemonMO
                var shouldAppendPokemon = false
                if let result = result.first(where: { pokemonMO in
                    pokemonMO.name == variety.pokemon.name
                }) {
                    pokemon = result
                } else {
                    pokemon = PokemonMO(context: context)
                    shouldAppendPokemon = true
                }
                pokemon.isDefault = variety.isDefault
                pokemon.name = variety.pokemon.name
                pokemon.url = variety.pokemon.url
                pokemon.species = species
                if shouldAppendPokemon {
                    savedPokemonList.append(pokemon)
                }
            }
            try context.save()
            return savedPokemonList
        } catch {
            NSLog("Error saving varieties for species %@: \(error)", species.name ?? "")
            return nil
        }
    }

    static func save(pokemon: PokemonResponse, context: NSManagedObjectContext) {
        context.performAndWait {
            let request: NSFetchRequest<PokemonMO> = PokemonMO.fetchRequest()
            request.predicate = NSPredicate(format: "name == %@", pokemon.name)
            do {
                let result = try context.fetch(request)
                let pokemonMO = result.first ?? PokemonMO(context: context)
                pokemonMO.name = pokemon.name
                pokemonMO.spriteFrontDefaultUrl = pokemon.sprites?.frontDefault
                pokemonMO.spriteFrontShinyUrl = pokemon.sprites?.frontShiny
                pokemonMO.spriteFrontFemaleUrl = pokemon.sprites?.frontFemale
                pokemonMO.spriteFrontShinyFemaleUrl = pokemon.sprites?.frontShinyFemale
                pokemonMO.pokemonDownloaded = true
                if let types = save(types: pokemon.types, pokemon: pokemonMO, context: context) {
                    if let oldTypes = pokemonMO.types {
                        pokemonMO.removeFromTypes(oldTypes)
                    }
                    pokemonMO.addToTypes(NSOrderedSet(array: types))
                } else {
                    pokemonMO.pokemonDownloaded = false
                }
                if let stats = save(stats: pokemon.stats, pokemon: pokemonMO, context: context) {
                    if let oldStats = pokemonMO.stats {
                        pokemonMO.removeFromStats(oldStats)
                    }
                    pokemonMO.addToStats(NSOrderedSet(array: stats))
                } else {
                   pokemonMO.pokemonDownloaded = false
               }
                try context.save()
            } catch {
                NSLog("Error saving pokemon %@: \(error)", pokemon.name)
            }
        }
    }

    private static func save(types: [TypeResponse], pokemon: PokemonMO, context: NSManagedObjectContext) -> [TypeMO]? {
        var savedTypes = [TypeMO]()
        for type in types {
            let typeMO = TypeMO(context: context)
            typeMO.slot = Int64(type.slot)
            typeMO.name = type.type.name
            typeMO.url = type.type.url
            typeMO.pokemon = pokemon
            savedTypes.append(typeMO)
        }
        do {
            try context.save()
            return savedTypes
        } catch {
            NSLog("Error saving types for pokemon %@: \(error)", pokemon.name ?? "")
            return nil
        }
    }

    private static func save(stats: [StatResponse], pokemon: PokemonMO, context: NSManagedObjectContext) -> [StatMO]? {
        var savedStats = [StatMO]()
        for stat in stats {
            let statMO = StatMO(context: context)
            statMO.baseStat = Int64(stat.baseStat)
            statMO.effort = Int64(stat.effort)
            statMO.stat = stat.stat.name
            statMO.url = stat.stat.url
            statMO.pokemon = pokemon
            savedStats.append(statMO)
        }
        do {
            try context.save()
            return savedStats
        } catch {
            NSLog("Error saving stats for pokemon %@: \(error)", pokemon.name ?? "")
            return nil
        }
    }

    static func save(image: Data, forPokemonName pokemonName: String, with id: GalleryID, context: NSManagedObjectContext) {
        context.perform {
            do {
                let request: NSFetchRequest<PokemonMO> = PokemonMO.fetchRequest()
                request.predicate = NSPredicate(format: "name == %@", pokemonName)
                let results = try context.fetch(request)
                guard let pokemon = results.first else {
                    NSLog("Save image \(id) failed: No pokemon named \(pokemonName) found")
                    return
                }
                switch id {
                case .frontDefault:
                    pokemon.spriteFrontDefault = image
                case .frontShiny:
                    pokemon.spriteFrontShiny = image
                case .frontFemale:
                    pokemon.spriteFrontFemale = image
                case .frontShinyFemale:
                    pokemon.spriteFrontShinyFemale = image
                }
                try context.save()
            } catch {
                NSLog("Error saving image \(id) for pokemon \(pokemonName): \(error)")
            }
        }
    }
}
