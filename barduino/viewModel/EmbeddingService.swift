//
//  EmbeddingService.swift
//  barduino
//
//  Created by Rafael Gorayb Correa on 27/10/24.
//

import Foundation

class EmbeddingService {
    private let apiKey = "INSERT-YPUR-OpenAi-API-KEY-HERE"

    func getEmbedding(for text: String, completion: @escaping ([Double]?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/embeddings")!
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let json: [String: Any] = [
            "input": text,
            "model": "text-embedding-3-large"
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
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataArray = json["data"] as? [[String: Any]],
                   let embedding = dataArray.first?["embedding"] as? [Double] {
                    completion(embedding)
                } else {
                    completion(nil)
                }
            } catch {
                print("Erro ao decodificar a resposta: \(error)")
                completion(nil)
            }
        }

        task.resume()
    }

}
