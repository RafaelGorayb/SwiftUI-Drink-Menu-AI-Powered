//
//  AiDrinkView.swift
//  barduino
//
//  Created by Rafael Gorayb Correa on 25/10/24.
//

import SwiftUI

struct AiDrinkView: View {
    @State private var preferences: [String] = Array(repeating: "", count: 4)
    @State private var navigateToLoading = false
    @Binding var navigateToRoot: Bool // Referência ao estado de navegação para
    @ObservedObject var viewModel: DrinkViewModel

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "apple.intelligence")
                    .foregroundStyle(.purple)
                    .padding(.top, 50)

                Text("Escolher com AI")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(10)

                // Usando o componente de pergunta reutilizável
                QuestionView(questionText: "Qual é o seu animo hoje?",
                             option1: "Animado",
                             option2: "Tranquilo",
                             selection: $viewModel.mood)

                QuestionView(questionText: "Prefere sabores mais:",
                             option1: "Doce",
                             option2: "Amargo/Azedo",
                             selection: $viewModel.flavorPreference)

                QuestionView(questionText: "Está disposto a uma experiencia mais:",
                             option1: "Clássica",
                             option2: "Diferenciada",
                             selection: $viewModel.experienceProfile)

                QuestionView(questionText: "Prefere bebidas: ",
                             option1: "Com álcool",
                             option2: "Sem álcool",
                             selection: $viewModel.alcoholicPreference)
                
                QuestionView(questionText: "Quer algo para:",
                             option1: "Saborear lentamente",
                             option2: "Se refrescar",
                             selection: $viewModel.drinkPace)

                Spacer()

                // Botão para enviar e navegar para LoadingView
                Button(action: {
                    navigateToLoading = true // Ativa a navegação para a LoadingView
                    viewModel.getRecommendation()
                }, label: {
                    Text("Enviar")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                        .font(.title3)
                        .padding()
                        .opacity(viewModel.isSelected() ? 1 : 0.7)
                })
                .disabled(!viewModel.isSelected())
            }
            .navigationDestination(isPresented: $navigateToLoading) {
                LoadingView(navigateToRoot: $navigateToRoot, viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.purple.opacity(0.1))
    }
}

struct QuestionView: View {
    var questionText: String
    var option1: String
    var option2: String
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(questionText)
                .font(.headline)
                .padding(.bottom, 2)
            
            HStack {
                Button(option1) {
                    selection = option1
                }
                .buttonStyle(OptionButtonStyle(isSelected: selection == option1))
                
                Button(option2) {
                    selection = option2
                }
                .buttonStyle(OptionButtonStyle(isSelected: selection == option2))
            }
        }
        .padding()
    }
}


struct OptionButtonStyle: ButtonStyle {
    var isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .black.opacity(0.8) : .black)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


#Preview {
    AiDrinkView(navigateToRoot: .constant(false), viewModel: DrinkViewModel())
    
}
