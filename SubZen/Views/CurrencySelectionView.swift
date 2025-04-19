//
//  CurrencySelectionView.swift
//  SubZen
//
//  Created by Star on 2025/4/19.
//

import SwiftUI

struct CurrencySelectionView: View {
    @Binding var selectedCurrency: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(CurrencyList.allCurrencies) { currency in
                    Button {
                        selectedCurrency = currency.code
                        dismiss()
                    } label: {
                        HStack {
                            Text("\(currency.code) (\(currency.symbol))")
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedCurrency == currency.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CurrencySelectionView(selectedCurrency: .constant("USD"))
}
