//
//  OpenAIResponse.swift
//  barduino
//
//  Created by Rafael Gorayb Correa on 27/10/24.
//


import Foundation

struct OpenAIResponse: Decodable {
    let choices: [Choice]
}

struct Choice: Decodable {
    let message: Message
}

struct Message: Decodable {
    let content: String
}

struct Recommendation: Codable {
    let recommended_drink: String
    let explanation: String
}


class OpenAIService {
    private let apiKey = "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"

    func sendPrompt(prompt: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages = [
            ["role": "system", "content": "Você é um especialista em drinks que ajuda a recomendar bebidas com base nas preferências do usuário."],
            ["role": "user", "content": prompt]
        ]


        let json: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Erro na requisição: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("Dados vazios na resposta")
                completion(nil)
                return
            }

            do {
                let decoder = JSONDecoder()
                let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)
                let reply = openAIResponse.choices.first?.message.content
                completion(reply)
            } catch {
                print("Erro ao decodificar a resposta: \(error)")
                completion(nil)
            }
        }

        task.resume()
    }
}
