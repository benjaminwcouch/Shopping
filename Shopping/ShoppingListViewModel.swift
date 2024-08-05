//
//  ShoppingListViewModel.swift
//  Shopping
//
//  Created by Benjamin Couch on 4/8/2024.
//

import Foundation

class ShoppingListViewModel: ObservableObject {
    @Published var items: [ShoppingItem] = []

    func addItem(name: String) {
        let newItem = ShoppingItem(name: name)
        items.append(newItem)
    }

    func removeItem(atOffsets offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func moveItem(fromOffsets source: IndexSet, toOffset destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}
