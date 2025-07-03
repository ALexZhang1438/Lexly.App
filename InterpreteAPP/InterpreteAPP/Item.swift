//
//  Item.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
