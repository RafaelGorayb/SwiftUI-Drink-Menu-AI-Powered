import SwiftUI

// Estrutura que representa cada pergunta
struct QuestionData {
    let questionText: String
    let options: [String]
    let keyPath: ReferenceWritableKeyPath<DrinkViewModel, String>
}

struct AiDrinkView: View {
    @State private var currentQuestionIndex = 0
    @State private var navigateToLoading = false
    @Binding var navigateToRoot: Bool
    @ObservedObject var viewModel: DrinkViewModel

    // Lista de perguntas
    let questions: [QuestionData]

    init(navigateToRoot: Binding<Bool>, viewModel: DrinkViewModel) {
        self._navigateToRoot = navigateToRoot
        self.viewModel = viewModel

        // Inicializa as perguntas com o texto, opções e a propriedade correspondente no ViewModel
        self.questions = [
            QuestionData(
                questionText: "Qual é o seu humor hoje?",
                options: ["Relaxado", "Animado", "Tranquilo", "Ansioso"],
                keyPath: \DrinkViewModel.mood
            ),
            QuestionData(
                questionText: "Você prefere algo mais:",
                options: ["Doce", "Azedo", "Amargo"],
                keyPath: \DrinkViewModel.flavorPreference
            ),
            QuestionData(
                questionText: "Prefiro um sabor:",
                options: ["Cítrico", "Frutado", "Herbal"],
                keyPath: \DrinkViewModel.flavorStyle
            ),
            QuestionData(
                questionText: "Prefere sua bebida:",
                options: ["Bem gelada", "Temperatura ambiente", "Sem preferência"],
                keyPath: \DrinkViewModel.servingTemperature
            ),
            QuestionData(
                questionText: "Você está buscando uma experiência mais:",
                options: ["Elegante", "Extrovertida", "Casual"],
                keyPath: \DrinkViewModel.experienceType
            ),
            QuestionData(
                questionText: "Está de dieta?",
                options: ["Tanto faz", "Baixo açúcar", "Sem Açucar"],
                keyPath: \DrinkViewModel.dietaryRestriction
            ),
            QuestionData(
                questionText: "Bebida base",
                options: ["Vodka", "Gin", "Tequila", "Tanto faz", "Sem álcool"],
                keyPath: \DrinkViewModel.baseType
            ),
        ]
    }

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

                // Barra de progresso
                if currentQuestionIndex < 8 {
                    Text("Pergunta: \(currentQuestionIndex + 1)/7")
                }
                ProgressView(value: progress)
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                // Verifica se ainda há perguntas
                if currentQuestionIndex < questions.count {
                    let question = questions[currentQuestionIndex]
                    let selectionBinding = Binding<String>(
                        get: { self.viewModel[keyPath: question.keyPath] },
                        set: { newValue in
                            self.viewModel[keyPath: question.keyPath] = newValue
                            // Avança para a próxima pergunta ao selecionar uma opção
                            withAnimation {
                                self.currentQuestionIndex += 1
                            }
                        }
                    )

                    QuestionView(
                        questionText: question.questionText,
                        options: question.options,
                        selection: selectionBinding
                    )
                } else {
                    // Todas as perguntas foram respondidas, mostra o resumo e o botão para enviar
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Respostas escolhidas:")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.bottom, 10)

                            ForEach(questions, id: \.questionText) { question in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(question.questionText)
                                        .font(.headline)
                                    Text(viewModel[keyPath: question.keyPath])
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            Button(action: {
                                navigateToLoading = true
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
                            })
                            .navigationDestination(isPresented: $navigateToLoading) {
                                LoadingView(navigateToRoot: $navigateToRoot, viewModel: viewModel)
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.purple.opacity(0.1))
        }
    }

    // Cálculo do progresso
    private var progress: Double {
        Double(currentQuestionIndex) / Double(questions.count)
    }
}

struct QuestionView: View {
    var questionText: String
    var options: [String]
    @Binding var selection: String

    // Layout do grid com 2 colunas
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading) {
            Text(questionText)
                .font(.headline)
                .padding(.bottom, 10)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selection = option
                    }) {
                        Text(option)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding()
                            .background(selection == option ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    AiDrinkView(navigateToRoot: .constant(false), viewModel: DrinkViewModel())
}
