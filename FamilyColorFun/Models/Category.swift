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
        ),
        Category(
            name: "Mandalas",
            icon: "circle.hexagongrid.fill",
            color: .indigo,
            pages: ColoringPage.mandalas
        ),
        Category(
            name: "Geometric",
            icon: "diamond.fill",
            color: .teal,
            pages: ColoringPage.geometric
        ),
        Category(
            name: "Abstract",
            icon: "scribble.variable",
            color: .red,
            pages: ColoringPage.abstract
        ),
        Category(
            name: "Dinosaurs",
            icon: "fossil.shell.fill",
            color: .brown,
            pages: ColoringPage.dinosaurs
        ),
        Category(
            name: "Space",
            icon: "moon.stars.fill",
            color: .indigo,
            pages: ColoringPage.space
        ),
        Category(
            name: "Food",
            icon: "birthday.cake.fill",
            color: .pink,
            pages: ColoringPage.food
        ),
        Category(
            name: "Holidays",
            icon: "gift.fill",
            color: .red,
            pages: ColoringPage.holidays
        ),
        Category(
            name: "Sports",
            icon: "sportscourt.fill",
            color: .green,
            pages: ColoringPage.sports
        ),
        Category(
            name: "Music",
            icon: "music.note.list",
            color: .purple,
            pages: ColoringPage.music
        ),
        Category(
            name: "Robots",
            icon: "cpu.fill",
            color: .gray,
            pages: ColoringPage.robots
        ),
        Category(
            name: "Fantasy",
            icon: "sparkles",
            color: .pink,
            pages: ColoringPage.fantasy
        ),
        Category(
            name: "Underwater",
            icon: "drop.fill",
            color: .blue,
            pages: ColoringPage.underwater
        ),
        Category(
            name: "Zen Patterns",
            icon: "circle.grid.cross.fill",
            color: .teal,
            pages: ColoringPage.zenPatterns
        ),
        Category(
            name: "Portraits",
            icon: "person.crop.square.fill",
            color: .orange,
            pages: ColoringPage.portraits
        )
    ]

    /// Category for user-generated coloring pages from photos
    static let myCreations = Category(
        name: "My Creations",
        icon: "camera.fill",
        color: .purple,
        pages: []
    )
}
