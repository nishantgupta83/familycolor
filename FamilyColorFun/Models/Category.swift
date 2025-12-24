import SwiftUI

struct Category: Identifiable {
    let id = UUID()
    let categoryId: String  // Stable ID for unlock tracking
    let name: String
    let icon: String
    let color: Color
    let pages: [ColoringPage]

    // 9 categories with actual coloringlover.com images (129 total pages)
    static let all: [Category] = [
        Category(
            categoryId: "animals",
            name: "Animals",
            icon: "hare.fill",
            color: .orange,
            pages: ColoringPage.animals
        ),
        Category(
            categoryId: "vehicles",
            name: "Vehicles",
            icon: "car.fill",
            color: .blue,
            pages: ColoringPage.vehicles
        ),
        Category(
            categoryId: "houses",
            name: "Houses",
            icon: "house.fill",
            color: .purple,
            pages: ColoringPage.houses
        ),
        Category(
            categoryId: "nature",
            name: "Nature",
            icon: "leaf.fill",
            color: .mint,
            pages: ColoringPage.nature
        ),
        Category(
            categoryId: "ocean",
            name: "Ocean",
            icon: "fish.fill",
            color: .cyan,
            pages: ColoringPage.ocean
        ),
        Category(
            categoryId: "underwater",
            name: "Underwater",
            icon: "drop.fill",
            color: .blue,
            pages: ColoringPage.underwater
        ),
        Category(
            categoryId: "dinosaurs",
            name: "Dinosaurs",
            icon: "fossil.shell.fill",
            color: .brown,
            pages: ColoringPage.dinosaurs
        ),
        Category(
            categoryId: "fantasy",
            name: "Fantasy",
            icon: "sparkles",
            color: .pink,
            pages: ColoringPage.fantasy
        ),
        Category(
            categoryId: "holidays",
            name: "Holidays",
            icon: "gift.fill",
            color: .red,
            pages: ColoringPage.holidays
        )
    ]

    /// Category for user-generated coloring pages from photos
    static let myCreations = Category(
        categoryId: "my_creations",
        name: "My Creations",
        icon: "camera.fill",
        color: .purple,
        pages: []
    )
}
