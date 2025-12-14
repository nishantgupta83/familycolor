import SwiftUI

struct Category: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let pages: [ColoringPage]

    static let all: [Category] = [
        Category(
            name: "Animals",
            icon: "hare.fill",
            color: .orange,
            pages: ColoringPage.animals
        ),
        Category(
            name: "Vehicles",
            icon: "car.fill",
            color: .blue,
            pages: ColoringPage.vehicles
        ),
        Category(
            name: "Houses",
            icon: "house.fill",
            color: .purple,
            pages: ColoringPage.houses
        ),
        Category(
            name: "Nature",
            icon: "leaf.fill",
            color: .mint,
            pages: ColoringPage.nature
        ),
        Category(
            name: "Ocean",
            icon: "fish.fill",
            color: .cyan,
            pages: ColoringPage.ocean
        ),
        Category(
            name: "Retro 90s",
            icon: "radio.fill",
            color: .pink,
            pages: ColoringPage.retro90s
        )
    ]
}
