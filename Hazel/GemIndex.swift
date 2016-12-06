//
//  GemIndex.swift
//  Hazel
//
//  Created by Simon Racz on 07/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import Foundation

struct GemIndex: Hashable {
    let x: Int
    let y: Int
    // MARK: Hashable
    var hashValue: Int {
        return x * 100 + y
    }
}

// MARK: Equatable
func ==(lhs: GemIndex, rhs: GemIndex) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}
