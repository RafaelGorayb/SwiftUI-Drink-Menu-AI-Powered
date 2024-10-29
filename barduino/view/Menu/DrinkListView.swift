//
//  DrinkListView.swift
//  barduino
//
//  Created by Rafael Gorayb Correa on 15/08/23.
//

import SwiftUI

struct DrinkListView: View {
    @Namespace private var DrinkItemTransition
    @Namespace private var DrinkFormTransition
    @State var searchText: String = ""
    @State private var navigateToAiDrinkView = false // Controla a navegação para AiDrinkView

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // Computed property para filtrar os drinks com base no searchText
    var filteredDrinks: [Drink] {
        if searchText.isEmpty {
            return drinks
        } else {
            return drinks.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                HStack {
                    NavigationLink(
                        destination: AiDrinkView(navigateToRoot: $navigateToAiDrinkView, viewModel: DrinkViewModel())
                            .navigationTransition(.zoom(sourceID: "AiSuggest", in: DrinkFormTransition)),
                        isActive: $navigateToAiDrinkView
                    ) {
                        SuggestButtons(namespace: DrinkFormTransition)
                    }
                    Spacer()
                }
                .padding(.bottom, 8)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(filteredDrinks, id: \.name) { drink in
                        NavigationLink(destination: DrinkDetailView(drink: drink)
                            .navigationTitle(drink.name)
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationTransition(.zoom(sourceID: "zoom\(drink.name)", in: DrinkItemTransition))) {
                            DrinkListItem(drink: drink, namespace: DrinkItemTransition)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Bebidas")
            .padding([.leading, .trailing])
        }
    }
}
struct SuggestButtons: View {
    var namespace: Namespace.ID
    var body: some View {
        HStack {
            Image(systemName: "apple.intelligence").foregroundStyle(.purple)
            Text("Escolher com AI")
        }
        .padding(10)
        .background(Color.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .matchedTransitionSource(id: "AiSuggest", in: namespace)
    }
}





struct DrinkListView_Previews: PreviewProvider {
    static var previews: some View {
        DrinkListView()
    }
}
