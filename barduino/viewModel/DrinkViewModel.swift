//
//  DrinkViewModel.swift
//  barduino
//
//  Created by Rafael Gorayb Correa on 15/08/23.
//

import Foundation
import SwiftUI


class DrinkViewModel: ObservableObject {
    @Published var percent: Double = 30.0
    
    
    @Published var mood: String = ""
    @Published var flavorPreference: String = ""
    @Published var alcoholicPreference: String = ""
    @Published var experienceProfile: String = ""
    @Published var drinkPace: String = ""
    @Published var recommendedDrink: String = ""
    @Published var topDrinks: [Drink] = []

    
    var drinks_menu: [Drink] = []

    init() {
        self.drinks_menu = drinks // 'drinks' é a variável global que eu já tenho
    }
    
    //function to check if all options were selected
    func isSelected() -> Bool {
        return !mood.isEmpty && !flavorPreference.isEmpty && !alcoholicPreference.isEmpty && !experienceProfile.isEmpty && !drinkPace.isEmpty
    }
    
    // Função para criar o prompt baseado nas seleções do usuário
    func generatePrompt(with drinks: [Drink]) -> String {
        let drinksList = drinks.map { "\($0.name): \($0.description)" }.joined(separator: "\n")
        
        let prompt = """
        Com base nas suas preferências:
        - Ânimo: \(mood)
        - Sabor preferido: \(flavorPreference)
        - Experiência desejada: \(experienceProfile)
        - Teor alcoólico: \(alcoholicPreference)
        - Objetivo: \(drinkPace)
        
        O drink escolhido foi:
        
        \(drinksList)
        
        Por favor, de uma curta explicaçao (máximo de 25 palavras) de o por que ele é a opçao mais recomendada.
        """
        
        return prompt
    }


    
    // Função para obter a recomendação
    func getRecommendation() {
        getUserPreferenceEmbedding { [weak self] userEmbedding in
            guard let self = self, let userEmbedding = userEmbedding else {
                DispatchQueue.main.async {
                    self?.recommendedDrink = "Não foi possível processar suas preferências no momento."
                }
                return
            }

            // Computar os top drinks no thread de background
            let topDrinks = self.getTopDrinks(userEmbedding: userEmbedding, topK: 3)

            // Atualizar a propriedade publicada no thread principal
            DispatchQueue.main.async {
                self.topDrinks = topDrinks

                // Verificar se há drinks disponíveis após a filtragem
                if self.topDrinks.isEmpty {
                    self.recommendedDrink = "Desculpe, não temos drinks que correspondam à sua preferência alcoólica."
                    return
                }

                let prompt = self.generatePrompt(with: [self.topDrinks[0]])
                let openAIService = OpenAIService()

                // Enviar o prompt (assumindo que sendPrompt já lida com threads corretamente)
                openAIService.sendPrompt(prompt: prompt) { response in
                    DispatchQueue.main.async {
                        if let response = response {
                            self.recommendedDrink = response
                        } else {
                            self.recommendedDrink = "Não foi possível obter uma recomendação no momento."
                        }
                    }
                }
            }
        }
    }


    
    func getUserPreferenceEmbedding(completion: @escaping ([Double]?) -> Void) {
        let preferenceText = """
        Meu ânimo hoje é \(mood). Prefiro sabores \(flavorPreference). Estou disposto a uma experiência \(experienceProfile). Prefiro bebidas \(alcoholicPreference). Quero algo para \(drinkPace).
        """
        let embeddingService = EmbeddingService()
        embeddingService.getEmbedding(for: preferenceText) { embedding in
            completion(embedding)
        }
    }

    
    func calculateCosineSimilarity(_ vectorA: [Double], _ vectorB: [Double]) -> Double {
        let dotProduct = zip(vectorA, vectorB).map(*).reduce(0, +)
        let magnitudeA = sqrt(vectorA.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(vectorB.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (magnitudeA * magnitudeB)
    }

    func getTopDrinks(userEmbedding: [Double], topK: Int) -> [Drink] {
        // Filtrar os drinks com base na preferência alcoólica
        let filteredDrinks = drinks.filter { drink in
            if alcoholicPreference == "Com álcool" {
                return drink.alcoholInfo.hasAlcohol == true
            } else {
                return drink.alcoholInfo.hasAlcohol == false
            }
        }

        // Se nenhum drink corresponder à preferência alcoólica, retorne uma lista vazia
        guard !filteredDrinks.isEmpty else {
            return []
        }

        // Calcular a similaridade apenas com os drinks filtrados
        let drinksWithSimilarities = filteredDrinks.compactMap { drink -> (Drink, Double)? in
            let embedding = drink.embedding
            guard embedding.count > 0 else { return nil }
            let similarity = calculateCosineSimilarity(userEmbedding, embedding)
            return (drink, similarity)
        }

        let sortedDrinks = drinksWithSimilarities.sorted { $0.1 > $1.1 }
        let topDrinks = sortedDrinks.prefix(topK).map { $0.0 }
        return Array(topDrinks)
    }




    func incrementPercent() {
        self.percent += 15
        if self.percent > 100 {
            self.percent = 100
        }
    }
}


