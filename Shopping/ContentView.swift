//
//  ContentView.swift
//  Shopping
//
//  Created by Benjamin Couch on 4/8/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ShoppingListViewModel()
    @State private var newItemName = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter item name", text: $newItemName, onCommit: {
                    if !newItemName.isEmpty {
                        viewModel.addItem(name: newItemName)
                        newItemName = ""
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                List {
                    ForEach(viewModel.items) { item in
                        Text(item.name)
                    }
                    .onDelete(perform: viewModel.removeItem)
                    .onMove(perform: viewModel.moveItem)
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add any action here if needed
                    }) {
                        Text("Add Item")
                    }
                }
            }
        }
    }
}





#Preview {
    ContentView()
}
