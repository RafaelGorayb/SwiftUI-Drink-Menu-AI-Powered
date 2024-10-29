//
//  DrinkWaitingView.swift
//  barduino
//
//  Created by Rafael Gorayb Correa on 16/08/23.
//

import SwiftUI

struct DrinkWaitingView: View {
    @ObservedObject var viewModel = DrinkViewModel()

    var body: some View {
        VStack {
            ZStack {
                CircleWaveView(percent: Int(viewModel.percent))
                .background(Color(.clear))
                .cornerRadius(20)
                .frame(width: 80, height: 75)
                .padding(.bottom, 60)
                
                Image(systemName: "wineglass")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
            }
            
            Text("Preparando bebida...").font(.subheadline)
            Button(action: {
               
            }, label: {
                Text("Fechar")
            })
            .buttonStyle(.borderedProminent)
        }
    }
}





struct DrinkWaitingView_Previews: PreviewProvider {
    static var previews: some View {
        DrinkWaitingView()
       
    }
}
