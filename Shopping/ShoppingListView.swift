//
//  ShoppingListView.swift
//  Shopping
//
//  Created by Benjamin Couch on 4/8/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct ShoppingListView: View {
    @State private var items: [String] = []
    @State private var suggestedItems: [String] = []
    @State private var newItem: String = ""
    @State private var showSaveFilePicker: Bool = false
    @State private var showOpenFilePicker: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // TextField and Button for adding items
                HStack {
                    TextField("Enter item", text: $newItem)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color(UIColor.gray)) // Light gray background for the text field
                        .cornerRadius(10) // Rounded corners

                    Button(action: {
                        addItem()
                    }) {
                        Text("Add")
                            .fontWeight(.bold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)

                // Top List for shopping items
                List {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Text(item)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 40)
                                .padding()
                                .foregroundColor(.yellow)
                                .font(.headline)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .onDrag { NSItemProvider(object: item as NSString) }
                        .onDrop(of: [UTType.text], delegate: ShoppingListDropDelegate(items: $items, suggestedItems: $suggestedItems))
                        .swipeActions {
                            Button(role: .destructive) {
                                removeItem(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onMove(perform: move)
                }
                .listStyle(InsetGroupedListStyle()) // Rounded grouped list style

                // Suggested Items Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Items")
                        .font(.headline)
                        .padding(.leading)
                        .background(Color(UIColor.systemGray5)) // Light gray background for the title
                        .cornerRadius(8)
                        .shadow(radius: 2)

                    List {
                        ForEach(suggestedItems, id: \.self) { item in
                            HStack {
                                Text(item)
                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 40)
                                    .padding()
                                    .foregroundColor(.yellow)
                                    .font(.headline)
                                    .background(Color.red)
                                    .cornerRadius(8) // Rounded corners for the background
                            }
                            .onDrag { NSItemProvider(object: item as NSString) }
                            .onDrop(of: [UTType.text], delegate: SuggestedItemsDropDelegate(items: $suggestedItems, shoppingListItems: $items, suggestedItems: $items))
                        }
                        .onDelete(perform: deleteSuggestedItem)
                    }
                    .listStyle(InsetGroupedListStyle()) // Rounded grouped list style
                }
                .padding(.horizontal)

                // Save and Open File Buttons
                HStack {
                    Button("Save List As...") {
                        showSaveFilePicker = true
                    }
                    .fileExporter(isPresented: $showSaveFilePicker, document: ShoppingListDocument(items: items, suggestedItems: suggestedItems), contentType: .json, defaultFilename: "ShoppingList") { result in
                        switch result {
                        case .success(let url):
                            print("File saved to: \(url)")
                        case .failure(let error):
                            print("Error saving file: \(error.localizedDescription)")
                        }
                    }
                    
                    Button("Open List") {
                        showOpenFilePicker = true
                    }
                    .fileImporter(isPresented: $showOpenFilePicker, allowedContentTypes: [.json]) { result in
                        switch result {
                        case .success(let url):
                            loadList(from: url)
                        case .failure(let error):
                            print("Error opening file: \(error.localizedDescription)")
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Shopping List")
            .background(Color(UIColor.systemGray5))
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        showSaveFilePicker = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Open") {
                        showOpenFilePicker = true
                    }
                }
            }
            .onAppear(perform: loadSavedState) // Load state when view appears
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        autosave()
    }

    private func addItem() {
        let trimmedItem = newItem.trimmingCharacters(in: .whitespaces)
        if !trimmedItem.isEmpty && !items.contains(trimmedItem) {
            items.append(trimmedItem)
            newItem = ""
            autosave() // Save after adding
            // Duplicate to suggestedItems
            if !suggestedItems.contains(trimmedItem) {
                suggestedItems.append(trimmedItem)
                autosave() // Save after adding
            }
        }
    }

    private func removeItem(_ item: String) {
        if let index = items.firstIndex(of: item) {
            items.remove(at: index)
            autosave() // Save after removing
        }
    }

    private func loadList(from url: URL) {
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url)
            let container = try decoder.decode([String: [String]].self, from: data)
            items = container["items"] ?? []
            suggestedItems = container["suggestedItems"] ?? []
        } catch {
            print("Error loading file: \(error.localizedDescription)")
        }
    }

    private func deleteSuggestedItem(at offsets: IndexSet) {
        suggestedItems.remove(atOffsets: offsets)
        autosave() // Save after deleting
    }

    private func autosave() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(["items": items, "suggestedItems": suggestedItems])
            UserDefaults.standard.set(data, forKey: "savedState")
        } catch {
            print("Error saving state: \(error.localizedDescription)")
        }
    }

    private func loadSavedState() {
        if let data = UserDefaults.standard.data(forKey: "savedState") {
            let decoder = JSONDecoder()
            do {
                let container = try decoder.decode([String: [String]].self, from: data)
                items = container["items"] ?? []
                suggestedItems = container["suggestedItems"] ?? []
            } catch {
                print("Error loading saved state: \(error.localizedDescription)")
            }
        }
    }
}

struct ShoppingListDropDelegate: DropDelegate {
    @Binding var items: [String]
    @Binding var suggestedItems: [String]
    
    private func autosave() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(["items": items, "suggestedItems": suggestedItems])
            UserDefaults.standard.set(data, forKey: "savedState")
        } catch {
            print("Error saving state: \(error.localizedDescription)")
        }
    }
    

    func performDrop(info: DropInfo) -> Bool {
        let itemProvider = info.itemProviders(for: [UTType.text]).first

        itemProvider?.loadObject(ofClass: String.self) { item, error in
            DispatchQueue.main.async {
                if let item = item as? String {
                    // Add item to shopping list if not already present
                    if !items.contains(item) {
                        items.append(item)
                        autosave() // Save after adding
                    }
                    // Duplicate item to suggested items if not already present
                    if !suggestedItems.contains(item) {
                        suggestedItems.append(item)
                        autosave() // Save after adding
                    }
                } else if let error = error {
                    print("Error loading object: \(error.localizedDescription)")
                }
            }
        }

        return true
    }

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.text])
    }
}

struct SuggestedItemsDropDelegate: DropDelegate {
    @Binding var items: [String]
    @Binding var shoppingListItems: [String]
    @Binding var suggestedItems: [String]
    private func autosave() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(["items": items, "suggestedItems": suggestedItems])
            UserDefaults.standard.set(data, forKey: "savedState")
        } catch {
            print("Error saving state: \(error.localizedDescription)")
        }
    }
    

    func performDrop(info: DropInfo) -> Bool {
        let itemProvider = info.itemProviders(for: [UTType.text]).first

        itemProvider?.loadObject(ofClass: String.self) { item, error in
            DispatchQueue.main.async {
                if let item = item as? String {
                    // Add item to suggested items if not already present
                    if !items.contains(item) {
                        items.append(item)
                        autosave() // Save after adding
                    }
                    // Duplicate item to shopping list if not already present
                    if !shoppingListItems.contains(item) {
                        shoppingListItems.append(item)
                        autosave() // Save after adding
                    }
                } else if let error = error {
                    print("Error loading object: \(error.localizedDescription)")
                }
            }
        }

        return true
    }

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.text])
    }
}

struct ShoppingListDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var items: [String] = []
    var suggestedItems: [String] = []

    init(items: [String] = [], suggestedItems: [String] = []) {
        self.items = items
        self.suggestedItems = suggestedItems
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            let decoder = JSONDecoder()
            let container = try decoder.decode([String: [String]].self, from: data)
            items = container["items"] ?? []
            suggestedItems = container["suggestedItems"] ?? []
        } else {
            items = []
            suggestedItems = []
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        let data = try encoder.encode(["items": items, "suggestedItems": suggestedItems])
        return FileWrapper(regularFileWithContents: data)
    }
}

struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListView()
    }
}
