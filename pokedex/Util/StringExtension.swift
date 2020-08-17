//
//  StringExtension.swift
//  pokedex
//
//  Created by Cristina De Rito on 12/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation

extension String {
    func formatted() -> String {
        return self.replacingOccurrences(of: "-", with: " ").trimmingCharacters(in: .whitespaces).capitalized
    }
}
