//
//  DrinkDetailView.swift
//  barduino
//
//  Created by Rafael Gorayb Correa on 15/08/23.
//

import SwiftUI


struct DrinkDetailView: View {
    let drink: Drink
    @State private var showConfirmationAlert = false
    @State private var prepareDrink = false
    @Environment(\.colorScheme) var colorScheme
    
    

    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                let y = geometry.frame(in: .global).minY/500
            VStack {
                    
                Image(drink.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: y > 0 ? 400 + y*500 : 400)
                        .scaleEffect(y > 0 ? y+1 : 1)
                        .clipped()
                }
               
                .offset(y: (y > 0 ? -y*500 : 0))
                .navigationTitle(y < 0 ? drink.name : "")
                
            }
            .frame(minHeight: 400)

            VStack(alignment: .leading) {
                Text(drink.name)
                    .font(.system(size: 32, weight: .bold))
                    .padding(.bottom, 5)
                Text(drink.description)
                    .font(.system(size: 16))
                    .opacity(0.7)
                VStack(alignment: .leading) {
                    Text("Volume: \(drink.volume)ml").font(.caption)
                    Text("Type: \(drink.category)").font(.caption)
                    if drink.alcoholInfo.hasAlcohol {
                        Text("Alcoólica").font(.caption).foregroundColor(.red)
                    } else {
                        Text("Não Alcoólica").font(.caption).foregroundColor(.green)
                    }
                }
                .padding(.top, 5)
            }


            Button(action: {
                showConfirmationAlert = true
            }, label: {
                Text("Selecionar")
                    .frame(width: UIScreen.main.bounds.width * 0.85)
            })
            .padding(.top)
            .tint(.black)
            .buttonStyle(.borderedProminent)
            .alert(isPresented: $showConfirmationAlert) {
                Alert(title: Text("Confirmação"),
                      message: Text("Você deseja preparar a bebida?"),
                      primaryButton: .default(Text("Sim")) {
                        prepareDrink = true
                        
                    },
                      secondaryButton: .cancel())
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $prepareDrink, content: {
            DrinkWaitingView()
        })

    }
}





struct DrinkDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DrinkDetailView(drink: drinks[0])
    }
}
