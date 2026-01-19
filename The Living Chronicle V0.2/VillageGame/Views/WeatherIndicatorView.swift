//
//  WeatherIndicatorView.swift
//  VillageGame
//
//  Created by Kaleb on 1/19/26.
//

import SwiftUI

// MARK: - Weather Indicator View
struct WeatherIndicatorView: View {
    let weather: Weather
    let season: Season
    
    var body: some View {
        HStack(spacing: 4) {
            weatherIcon
                .font(.title3)
            Text(weather.name)
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
    
    private var weatherIcon: some View {
        let iconName: String
        
        switch (season, weather) {
        case (.winter, .dangerous): iconName = "cloud.snow.fill"
        case (.winter, _): iconName = "snowflake"
        case (_, .dangerous): iconName = "sun.max.fill"
        case (_, .heavy): iconName = "cloud.bolt.rain.fill"
        case (_, .mild): iconName = "cloud.sun.fill"
        case (_, .weak): iconName = "sun.max.fill"
        }
        
        return Image(systemName: iconName)
    }
}
