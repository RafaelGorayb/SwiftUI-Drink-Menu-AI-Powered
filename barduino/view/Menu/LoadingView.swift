import SwiftUI

struct LoadingView: View {
    @Binding var navigateToRoot: Bool
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DrinkViewModel
    @Namespace var namespace

    // Variáveis de estado para animação
    @State private var isRotating = false
    @State private var isScaling = false

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.recommendedDrink == nil {
                // Indicador de carregamento
                VStack(spacing: 16) {
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
                            Text("Drink recomendado:")
                                .font(.headline)
                                .foregroundColor(.primary)

                            if let recommendedDrink = viewModel.recommendedDrink {
                                DrinkListItem(drink: recommendedDrink, namespace: namespace)
                                
                            }
                        }

                        // Outros drinks recomendados
                        HStack(spacing: 12) {
                            Text("Outros drinks recomendados:")
                                .font(.headline)
                                .foregroundColor(.primary)

                            ForEach(viewModel.topDrinks.dropFirst(), id: \.id) { drink in
                                DrinkListItem(drink: drink, namespace: namespace)
                            }
                        }
                    }
                    .padding()
                }
            }

            Button("Fechar") {
                self.dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .onDisappear{
            viewModel.recommendedDrink = nil
        }
    }
}
