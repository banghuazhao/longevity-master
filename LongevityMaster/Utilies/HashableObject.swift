//
// Created by Banghua Zhao on 24/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import Foundation

protocol HashableObject: AnyObject, Hashable {}

extension HashableObject {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs === rhs
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
