//
//  PokedexError.swift
//  pokedex
//
//  Created by Cristina De Rito on 11/08/2020.
//  Copyright © 2020 Cristina De Rito. All rights reserved.
//

import Foundation

enum PokedexError: Error {
    case malformedUrl(url: String)
    case missingData
    case statusCodeIsUnacceptable(code: Int?)
    case imageParseFailed
}

extension PokedexError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .malformedUrl(let url):
            return "\(url) is not a valid URL"
        case .missingData:
            return "Data is missing in response"
        case .statusCodeIsUnacceptable(let code):
            return "Status code is unacceptable \(String(describing: code))"
        case .imageParseFailed:
            return "Image parse failed"
        }
    }
}

extension PokedexError: CustomNSError {
    var errorUserInfo: [String : Any] {
        var userInfo: [String : Any] = [:]
        userInfo[NSLocalizedDescriptionKey] = errorDescription
        return userInfo
    }

    var errorCode: Int {
        switch self {
        case .malformedUrl:
            return 9999
        case .missingData:
            return 9998
        case .statusCodeIsUnacceptable:
            return 9997
        case .imageParseFailed:
            return 9996
        }
    }
}
