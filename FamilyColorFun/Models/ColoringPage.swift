import Foundation

struct ColoringPage: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String

    // Pages with actual images
    static let animals: [ColoringPage] = [
        ColoringPage(name: "Cat", imageName: "animal_cat"),
        ColoringPage(name: "Dog", imageName: "animal_dog"),
        ColoringPage(name: "Elephant", imageName: "animal_elephant")
    ]

    static let vehicles: [ColoringPage] = [
        ColoringPage(name: "Car", imageName: "vehicle_car")
    ]

    static let houses: [ColoringPage] = [
        ColoringPage(name: "Cottage", imageName: "house_cottage")
    ]

    static let nature: [ColoringPage] = [
        ColoringPage(name: "Flower", imageName: "nature_flower"),
        ColoringPage(name: "Star", imageName: "nature_star")
    ]

    static let ocean: [ColoringPage] = [
        ColoringPage(name: "Fish", imageName: "ocean_fish")
    ]

    static let retro90s: [ColoringPage] = [
        ColoringPage(name: "Boombox", imageName: "retro_boombox"),
        ColoringPage(name: "Turntable", imageName: "retro_turntable")
    ]
}
