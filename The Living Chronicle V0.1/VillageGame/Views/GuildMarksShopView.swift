//
//  GuildMarksShopView.swift
//  VillageGame
//
//  Created by Kaleb on 1/18/26.
//
import SwiftUI

// MARK: - Convertible Resource
enum ConvertibleResource: String, CaseIterable {
    case food = "Food"
    case water = "Water"
    case firewood = "Firewood"
    case salt = "Salt"
    case stone = "Stone"
    case metal = "Metal"
    
    var icon: String {
        switch self {
        case .food: return "leaf.fill"
        case .water: return "drop.fill"
        case .firewood: return "flame.fill"
        case .salt: return "cube.fill"
        case .stone: return "mountain.2.fill"
        case .metal: return "gearshape.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .green
        case .water: return .blue
        case .firewood: return .orange
        case .salt: return .gray
        case .stone: return .brown
        case .metal: return .gray
        }
    }
}

// MARK: - Guild Marks Shop View
struct GuildMarksShopView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedAmount = 1
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Current marks
                HStack {
                    Image(systemName: "seal.fill")
                        .foregroundColor(.yellow)
                        .font(.title)
                    Text("\(viewModel.village.resources.guildMarks)")
                        .font(.largeTitle.bold())
                    Text("Guild Marks")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
                
                // Amount selector
                HStack {
                    Text("Convert:")
                    Picker("Amount", selection: $selectedAmount) {
                        Text("1 Mark").tag(1)
                        Text("5 Marks").tag(5)
                        Text("10 Marks").tag(10)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                
                Text("= \(selectedAmount * 100) resources")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                // Resource options
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(ConvertibleResource.allCases, id: \.self) { resource in
                        Button(action: {
                            viewModel.convertGuildMarks(to: resource, amount: selectedAmount)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: resource.icon)
                                    .font(.title)
                                    .foregroundColor(resource.color)
                                
                                Text(resource.rawValue)
                                    .font(.caption.bold())
                                    .foregroundColor(.primary)
                                
                                Text("+\(selectedAmount * 100)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.village.resources.guildMarks < selectedAmount)
                        .opacity(viewModel.village.resources.guildMarks < selectedAmount ? 0.5 : 1.0)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Guild Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
