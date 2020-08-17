//
//  UIColorExtension.swift
//  pokedex
//
//  Created by Cristina De Rito on 14/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import UIKit

extension UIColor {

    static let male = UIColor(red: 0.192, green: 0.412, blue: 0.659, alpha: 1)
    static let maleShiny = UIColor(red: 0.196, green: 0.553, blue: 0.96, alpha: 1)
    static let female = UIColor(red: 0.659, green: 0.071, blue: 0.373, alpha: 1)
    static let femaleShiny = UIColor(red: 0.96, green: 0.082, blue: 0.415, alpha: 1)

    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        assert(alpha >= 0.0 && alpha <= 1.0, "Invalid alpha component")

        self.init(red: CGFloat(red) / 255.0,
                  green: CGFloat(green) / 255.0,
                  blue: CGFloat(blue) / 255.0,
                  alpha: alpha)
    }

    convenience init(_ rgb: Int, a: CGFloat = 1.0) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF,
            alpha: a
        )
    }

}

extension Int {
    var cgColor: CGColor {
        UIColor(self).cgColor
    }
}
