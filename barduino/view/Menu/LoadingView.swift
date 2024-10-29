//
//  LoadingView.swift
//  barduino
//
//  Created by Rafael Gorayb Correa on 27/10/24.
//
import SwiftUI

struct LoadingView: View {
    @Binding var navigateToRoot: Bool
    @State private var isRotating = false
    @State private var isScaling = false
    @Environment(\.dismiss) var presentationManager
    @ObservedObject var viewModel: DrinkViewModel
    @Namespace var namespace

    var body: some View {
        VStack(spacing: 20) { // Espaçamento consistente entre elementos
            if viewModel.recommendedDrink.isEmpty {
                // Indicador de carregamento
                VStack(spacing: 16) { // Espaçamento entre imagem e texto de carregamento
                    Image(systemName: "apple.intelligence")
                        .foregroundStyle(.purple)
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .scaleEffect(isScaling ? 1.2 : 0.8)
                        .onAppear {
                            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                isRotating = true
                            }
                            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                isScaling = true
                            }
                            viewModel.getRecommendation()
                        }

                    Text("Carregando...")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
            } else {
                // Exibe os drinks recomendados
                ScrollView {
                    VStack(spacing: 24) {
                        // Drink recomendado
                        VStack(spacing: 12) {
                            if let recommendedDrink = viewModel.topDrinks.first {
                                Text("Drink recomendado:")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                DrinkListItem(drink: recommendedDrink, namespace: namespace)
                                    .padding(.bottom, 8) // Espaçamento adicional abaixo do card
                                Text(viewModel.recommendedDrink)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    
                            }
                        }

                        // Outros drinks recomendados
                        VStack(spacing: 12) {
                            HStack{
                                Text("Outros drinks recomendados:")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.topDrinks.dropFirst(), id: \.id) { drink in
                                        DrinkListItem(drink: drink, namespace: namespace)
                                            
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }

            Button("Fechar") {
                self.presentationManager()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea()) // Background geral para diferenciar a view
    }
}
