//
//  Gem.swift
//  Hazel
//
//  Created by Simon Racz on 05/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import Foundation

func <<T: RawRepresentable where T.RawValue: Comparable>(a: T, b: T) -> Bool {
    return a.rawValue < b.rawValue
}

enum GemType: Int, Comparable {
    case None = 0
    case Gem1
    case Gem2
    case Gem3
    case Gem4
    case Gem5
    case SuperGemLine
    case SuperGemBomb
    case SuperGemColor
}

// At the moment this is just a wrapper around the GemType enum to be able to serialize it easily
class Gem: NSObject, NSCoding {
    var type: GemType
    
    struct PropertyKey {
        static let typeKey = "type"
    }
    
    init(type: GemType) {
        self.type = type
    }
    
    required init(coder aDecoder: NSCoder) {
        type = GemType(rawValue: aDecoder.decodeIntegerForKey(PropertyKey.typeKey))!
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(type.rawValue, forKey: PropertyKey.typeKey)
    }
    
    override var description: String {
        return String(type.rawValue)
    }
    
    // MARK: Hashable
    override var hashValue: Int {
        return type.hashValue
    }
}

// MARK: Equatable

func ==(lhs: Gem, rhs: Gem) -> Bool {
    return lhs.type == rhs.type
}
