//
//  DrinkListItem.swift
//  barduino
//
//  Created by Rafael Gorayb Correa on 25/10/24.
//

import SwiftUI

struct DrinkListItem: View {
    let drink: Drink
    var namespace: Namespace.ID

    var body: some View {
        VStack {
            Image(drink.imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
            Spacer()
            VStack(alignment: .leading) {
                Text(drink.name).font(.headline)
                Text(drink.description).font(.system(size: 12))
            }
            .padding()
            Spacer()
        }
        
        .frame(width: UIScreen.main.bounds.width * 0.43, height: 300)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .matchedTransitionSource(id: "zoom\(drink.name)", in: namespace)
    }
}

#Preview {
    @Previewable @Namespace var namespace
    DrinkListItem(drink: drinks[0], namespace: namespace )
}
