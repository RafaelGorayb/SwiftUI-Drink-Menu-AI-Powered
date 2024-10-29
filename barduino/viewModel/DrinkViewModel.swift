import Foundation
import SwiftUI

struct DrinkRecommendation {
    let drink: Drink
    let explanation: String
}

class DrinkViewModel: ObservableObject {
    // Variáveis para controlar a animação de loading das ondas do copo
    @Published var percent: Double = 30.0

    // Respostas do formulário
    @Published var mood: String = ""
    @Published var flavorPreference: String = ""
    @Published var servingTemperature: String = ""
    @Published var experienceType: String = ""
    @Published var dietaryRestriction: String = ""
    @Published var baseType: String = ""
    @Published var flavorStyle: String = ""

    // Variáveis do resultado da recomendação
    @Published var recommendedDrink: Drink? = nil
    @Published var recommendations: [DrinkRecommendation] = []
    @Published var topDrinks: [Drink] = []

    var drinks_menu: [Drink] = []

    init() {
        self.drinks_menu = drinks // 'drinks' é a variável global que você já tem
    }

    func isSelected() -> Bool {
        return !mood.isEmpty && !flavorPreference.isEmpty && !servingTemperature.isEmpty && !experienceType.isEmpty && !dietaryRestriction.isEmpty
    }

    // Função para concatenar as preferências do usuário em uma frase
    func concatenateUserPreferences() -> String {
        return """
        O usuario expressou o mood dele como: \(mood.lowercased()); 
        Prefire sabores: \(flavorPreference.lowercased()) e de preferencia mais \(flavorStyle);        
        Gosta de bebidas: \(servingTemperature.lowercased());
        Estou buscando uma experiência: \(experienceType.lowercased());
        Sobre açucar da bebida: \(dietaryRestriction.lowercased());
        A base da bebida ele prefere algo que tenha: \(baseType)
        """
    }

    // Função para gerar um prompt para o ChatGPT
    func generateChatGPTPrompt() -> String {
        let drinkNames = drinks_menu.map { $0.name }.joined(separator: ", ")
        let userPreferencesText = concatenateUserPreferences()

        let prompt = """
        Você é um especialista em drinks que ajuda a recomendar bebidas com base nas preferências do usuário.

        Com base nas seguintes preferências do usuário:
        \(userPreferencesText)

        Dentre as seguintes opções de drinks:
        \(drinkNames)

        Por favor, rankeie os top 3 drinks que você recomendaria ao usuário, levando em consideração as preferências dele, e forneça uma breve explicação para cada um (Máximo de 15 palavras). **Responda apenas com o JSON, sem texto adicional, sem formatação, sem blocos de código, no seguinte formato:**

        {
          "recommendations": [
            {
              "drink_name": "Nome do Drink 1",
              "explanation": "Breve explicação"
            },
            {
              "drink_name": "Nome do Drink 2",
              "explanation": "Breve explicação"
            },
            {
              "drink_name": "Nome do Drink 3",
              "explanation": "Breve explicação"
            }
          ]
        }
        """
        return prompt
    }

    // Função para enviar o prompt para o GPT
    func sendPromptToGPT(prompt: String, completion: @escaping (String?) -> Void) {
        let openAIService = OpenAIService()
        openAIService.sendPrompt(prompt: prompt) { response in
            completion(response)
        }
    }
    
    func extractJSON(from response: String) -> String {
        // Remover blocos de código e texto adicional
        var jsonString = response

        // Remover blocos de código
        if jsonString.contains("```") {
            // Dividir a resposta pelos blocos de código
            let components = jsonString.components(separatedBy: "```")
            // Procurar o componente que contém o JSON
            for component in components {
                let trimmedComponent = component.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedComponent.starts(with: "{") && trimmedComponent.hasSuffix("}") {
                    jsonString = trimmedComponent
                    break
                }
            }
        }

        // Caso ainda tenha texto adicional, tentar localizar o JSON
        if let jsonStart = jsonString.firstIndex(of: "{"), let jsonEnd = jsonString.lastIndex(of: "}") {
            jsonString = String(jsonString[jsonStart...jsonEnd])
        }

        // Remover espaços em branco e novas linhas
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        return jsonString
    }

    
    // Função para processar o resultado do prompt e popular as variáveis
        func processGPTResponse(_ response: String?) {
            guard let response = response else {
                print("Nenhuma resposta do GPT")
                return
            }

            // Pré-processar a resposta para extrair o conteúdo JSON
            let jsonString = extractJSON(from: response)

            guard let data = jsonString.data(using: .utf8) else {
                print("Falha ao converter a resposta em dados")
                print("Resposta do GPT: \(response)")
                return
            }

            do {
                let decoder = JSONDecoder()
                struct GPTResponse: Codable {
                    struct Recommendation: Codable {
                        let drink_name: String
                        let explanation: String
                    }
                    let recommendations: [Recommendation]
                }
                let gptResponse = try decoder.decode(GPTResponse.self, from: data)
                let gptRecommendations = gptResponse.recommendations

                // Criar um dicionário para correspondência rápida dos drinks pelo nome
                let drinkNameToDrink = Dictionary(uniqueKeysWithValues: self.drinks_menu.map { ($0.name.lowercased(), $0) })

                var recommendations: [DrinkRecommendation] = []
                for gptRecommendation in gptRecommendations {
                    let name = gptRecommendation.drink_name
                    let explanation = gptRecommendation.explanation
                    let lowercasedName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    if let drink = drinkNameToDrink[lowercasedName] {
                        let drinkRecommendation = DrinkRecommendation(drink: drink, explanation: explanation)
                        recommendations.append(drinkRecommendation)
                    } else {
                        print("Drink não encontrado no menu: \(name)")
                    }
                }

                DispatchQueue.main.async {
                    self.recommendations = recommendations
                    if let firstRecommendation = recommendations.first {
                        self.recommendedDrink = firstRecommendation.drink
                    }
                    self.topDrinks = recommendations.map { $0.drink }
                }
            } catch {
                print("Falha ao analisar a resposta do GPT: \(error)")
                print("Resposta do GPT: \(response)")
            }
        }

    // Função principal para obter a recomendação
    func getRecommendation() {
        // Passo 1: Concatenar as preferências do usuário (já feito dentro das funções)

        // Passo 2: Gerar o prompt para o ChatGPT
        let prompt = self.generateChatGPTPrompt()

        // Passo 3: Enviar o prompt para o GPT
        self.sendPromptToGPT(prompt: prompt) { [weak self] response in
            guard let self = self else { return }

            // Passo 4: Processar a resposta do GPT
            self.processGPTResponse(response)
        }
    }

    // Função para controlar a animação do copo enchendo
    func incrementPercent() {
        DispatchQueue.main.async {
            self.percent += 25
            if self.percent > 100 {
                self.percent = 100
            }
        }
    }
}



















//import Foundation
//import SwiftUI
//
//class DrinkViewModel: ObservableObject {
//    // Variáveis para controlar a animação de loading das ondas do copo
//    @Published var percent: Double = 30.0
//
//    // Respostas do formulário
//    @Published var mood: String = ""
//    @Published var flavorPreference: String = ""
//    @Published var servingTemperature: String = ""
//    @Published var experienceType: String = ""
//    @Published var dietaryRestriction: String = ""
//
//    // Variáveis do resultado da recomendação
//    @Published var recommendedDrink: Drink? = nil
//    @Published var topDrinks: [Drink] = []
//
//    var drinks_menu: [Drink] = []
//
//    init() {
//        self.drinks_menu = drinks // 'drinks' é a variável global que você já tem
//    }
//
//    func isSelected() -> Bool {
//        return !mood.isEmpty && !flavorPreference.isEmpty && !servingTemperature.isEmpty && !experienceType.isEmpty && !dietaryRestriction.isEmpty
//    }
//
//
//    // Função para concatenar as preferências do usuário em uma frase
//    func concatenateUserPreferences() -> String {
//        return "Estou me sentindo \(mood.lowercased()), prefiro sabores \(flavorPreference.lowercased()), gosto de bebidas \(servingTemperature.lowercased()), estou buscando uma experiência \(experienceType.lowercased()) e tenho a seguinte restrição alimentar: \(dietaryRestriction.lowercased())."
//    }
//
//    // Função para gerar o embedding da frase com as preferências do usuário
//    func getUserPreferencesEmbedding(completion: @escaping ([Double]?) -> Void) {
//        let userPreferencesText = concatenateUserPreferences()
//        let embeddingService = EmbeddingService()
//        embeddingService.getEmbedding(for: userPreferencesText) { embedding in
//            completion(embedding)
//        }
//    }
//
//    // Função para calcular a similaridade entre as preferências do usuário e o cardápio e retornar as 6 mais próximas
//    func getTopSimilarDrinks(userEmbedding: [Double]) -> [Drink] {
//        var similarities: [(drink: Drink, similarity: Double)] = []
//
//        for drink in drinks_menu {
//            let drinkEmbedding = drink.embedding
//            let similarity = cosineSimilarity(vectorA: userEmbedding, vectorB: drinkEmbedding)
//            similarities.append((drink: drink, similarity: similarity))
//        }
//
//        let sortedDrinks = similarities.sorted { $0.similarity > $1.similarity }
//        let topDrinks = sortedDrinks.prefix(6).map { $0.drink }
//        return Array(topDrinks)
//    }
//
//    // Função para calcular a similaridade do cosseno
//    func cosineSimilarity(vectorA: [Double], vectorB: [Double]) -> Double {
//        guard vectorA.count == vectorB.count else {
//            return 0.0
//        }
//
//        let dotProduct = zip(vectorA, vectorB).map(*).reduce(0, +)
//        let magnitudeA = sqrt(vectorA.map { $0 * $0 }.reduce(0, +))
//        let magnitudeB = sqrt(vectorB.map { $0 * $0 }.reduce(0, +))
//
//        if magnitudeA == 0 || magnitudeB == 0 {
//            return 0.0
//        } else {
//            return dotProduct / (magnitudeA * magnitudeB)
//        }
//    }
//
//    // Função para gerar um prompt para o ChatGPT
//    func generateChatGPTPrompt(topDrinks: [Drink]) -> String {
//        let drinkNames = topDrinks.map { $0.name }.joined(separator: ", ")
//        let userPreferencesText = concatenateUserPreferences()
//
//        let prompt = """
//        Com base nas seguintes preferências do usuário:
//        \(userPreferencesText)
//
//        Dentre as seguintes opções de drinks:
//        \(drinkNames)
//
//        Por favor, rankeie os top 3 drinks que você recomendaria ao usuário, levando em consideração as preferências dele, e forneça uma breve explicação para cada um (Máximo de 15 palavras). Responda no seguinte formato JSON:
//
//        {
//          "recommendations": [
//            {
//              "drink_name": "Nome do Drink 1",
//              "explanation": "Breve explicação"
//            },
//            {
//              "drink_name": "Nome do Drink 2",
//              "explanation": "Breve explicação"
//            },
//            {
//              "drink_name": "Nome do Drink 3",
//              "explanation": "Breve explicação"
//            }
//          ]
//        }
//        """
//        return prompt
//    }
//
//    // Função para enviar o prompt para o GPT
//    func sendPromptToGPT(prompt: String, completion: @escaping (String?) -> Void) {
//        let openAIService = OpenAIService()
//        openAIService.sendPrompt(prompt: prompt) { response in
//            completion(response)
//        }
//    }
//
//    // Função para processar o resultado do prompt e popular as variáveis recommendedDrink e topDrinks
//    func processGPTResponse(_ response: String?, from topDrinks: [Drink]) {
//        guard let response = response else {
//            print("Nenhuma resposta do GPT")
//            return
//        }
//
//        // Tenta converter a resposta em dados JSON
//        if let data = response.data(using: .utf8) {
//            do {
//                let decoder = JSONDecoder()
//                struct GPTResponse: Codable {
//                    struct Recommendation: Codable {
//                        let drink_name: String
//                        let explanation: String
//                    }
//                    let recommendations: [Recommendation]
//                }
//                let gptResponse = try decoder.decode(GPTResponse.self, from: data)
//                let recommendedDrinkNames = gptResponse.recommendations.map { $0.drink_name }
//
//                DispatchQueue.main.async {
//                    let recommendedDrinks = topDrinks.filter { recommendedDrinkNames.contains($0.name) }
//                    if let firstDrink = recommendedDrinks.first {
//                        self.recommendedDrink = firstDrink
//                    }
//                    self.topDrinks = recommendedDrinks
//                }
//            } catch {
//                print("Falha ao analisar a resposta do GPT: \(error)")
//            }
//        } else {
//            print("Falha ao converter a resposta do GPT em dados")
//        }
//    }
//
//    // Função principal para obter a recomendação
//    func getRecommendation() {
//        // Passo 1: Concatenar as preferências do usuário (já feito dentro das funções)
//        // Passo 2: Obter o embedding das preferências do usuário
//        getUserPreferencesEmbedding { [weak self] userEmbedding in
//            guard let self = self, let userEmbedding = userEmbedding else {
//                print("Falha ao obter o embedding do usuário")
//                return
//            }
//
//            // Passo 3: Calcular a similaridade e obter os top 6 drinks
//            let topDrinks = self.getTopSimilarDrinks(userEmbedding: userEmbedding)
//
//
//            // Passo 4: Gerar o prompt para o ChatGPT
//            let prompt = self.generateChatGPTPrompt(topDrinks: topDrinks)
//
//            // Passo 5: Enviar o prompt para o GPT
//            self.sendPromptToGPT(prompt: prompt) { [weak self] response in
//                guard let self = self else { return }
//
//                // Passo 6: Processar a resposta do GPT
//                self.processGPTResponse(response, from: topDrinks)
//            }
//        }
//    }
//
//    // Função para controlar a animação do copo enchendo
//    func incrementPercent() {
//        DispatchQueue.main.async {
//            self.percent += 15
//            if self.percent > 100 {
//                self.percent = 100
//            }
//        }
//    }
//}
