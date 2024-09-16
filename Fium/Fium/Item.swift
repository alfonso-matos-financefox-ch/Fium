//
//  Item.swift
//  Fium
//
//  Created by Alfonso Matos Martínez on 13/9/24.
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
