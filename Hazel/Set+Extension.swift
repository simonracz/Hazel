//
//  Set+Extension.swift
//  Hazel
//
//  Created by Simon Racz on 07/01/16.
//  Copyright © 2016 Simon Racz. All rights reserved.
//

import Foundation

extension Set {

    mutating func nonUpdatingInsert(member: Element) {
        if !self.contains(member) {
            self.insert(member)
        }
    }
    
    mutating func nonUpdatingUnionInPlace<S : SequenceType where S.Generator.Element == Element>(sequence: S) {
        for item in sequence {
            if !self.contains(item) {
                self.insert(item)
            }
        }
    }
}