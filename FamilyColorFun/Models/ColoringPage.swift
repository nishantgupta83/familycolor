import Foundation

struct ColoringPage: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String

    // Pages with actual images
    static let animals: [ColoringPage] = [
        ColoringPage(name: "Cat", imageName: "animal_cat"),
        ColoringPage(name: "Dog", imageName: "animal_dog"),
        ColoringPage(name: "Elephant", imageName: "animal_elephant"),
        ColoringPage(name: "Bunny", imageName: "animal_simple_01"),
        ColoringPage(name: "Bear", imageName: "animal_simple_03"),
        ColoringPage(name: "Bird", imageName: "animal_simple_04"),
        ColoringPage(name: "Fox", imageName: "animal_simple_06")
    ]

    static let vehicles: [ColoringPage] = [
        ColoringPage(name: "Car", imageName: "vehicle_car")
    ]

    static let houses: [ColoringPage] = [
        ColoringPage(name: "Cottage", imageName: "house_cottage")
    ]

    static let nature: [ColoringPage] = [
        ColoringPage(name: "Flower", imageName: "nature_flower"),
        ColoringPage(name: "Star", imageName: "nature_star"),
        ColoringPage(name: "Rose", imageName: "flower_01"),
        ColoringPage(name: "Daisy", imageName: "flower_02"),
        ColoringPage(name: "Tulip", imageName: "flower_03")
    ]

    static let ocean: [ColoringPage] = [
        ColoringPage(name: "Fish", imageName: "ocean_fish")
    ]

    static let retro90s: [ColoringPage] = [
        ColoringPage(name: "Boombox", imageName: "retro_boombox"),
        ColoringPage(name: "Turntable", imageName: "retro_turntable")
    ]

    static let mandalas: [ColoringPage] = [
        ColoringPage(name: "Mandala 1", imageName: "mandala_01"),
        ColoringPage(name: "Mandala 2", imageName: "mandala_02"),
        ColoringPage(name: "Mandala 3", imageName: "mandala_03"),
        ColoringPage(name: "Mandala 4", imageName: "mandala_04"),
        ColoringPage(name: "Mandala 5", imageName: "mandala_05"),
        ColoringPage(name: "Mandala 6", imageName: "mandala_06")
    ]

    static let geometric: [ColoringPage] = [
        ColoringPage(name: "Pattern 1", imageName: "geometric_01"),
        ColoringPage(name: "Pattern 2", imageName: "geometric_02"),
        ColoringPage(name: "Pattern 3", imageName: "geometric_03"),
        ColoringPage(name: "Pattern 4", imageName: "geometric_04"),
        ColoringPage(name: "Pattern 5", imageName: "geometric_05"),
        ColoringPage(name: "Pattern 6", imageName: "geometric_06")
    ]

    static let abstract: [ColoringPage] = [
        ColoringPage(name: "Abstract 1", imageName: "abstract_01"),
        ColoringPage(name: "Abstract 2", imageName: "abstract_04")
    ]

    // New categories - pages to be added
    static let dinosaurs: [ColoringPage] = [
        ColoringPage(name: "T-Rex", imageName: "dino_trex"),
        ColoringPage(name: "Triceratops", imageName: "dino_triceratops"),
        ColoringPage(name: "Stegosaurus", imageName: "dino_stegosaurus")
    ]

    static let space: [ColoringPage] = [
        ColoringPage(name: "Rocket", imageName: "space_rocket"),
        ColoringPage(name: "Astronaut", imageName: "space_astronaut"),
        ColoringPage(name: "Planet", imageName: "space_planet")
    ]

    static let food: [ColoringPage] = [
        ColoringPage(name: "Cupcake", imageName: "food_cupcake"),
        ColoringPage(name: "Ice Cream", imageName: "food_icecream"),
        ColoringPage(name: "Pizza", imageName: "food_pizza")
    ]

    static let holidays: [ColoringPage] = [
        ColoringPage(name: "Christmas Tree", imageName: "holiday_christmas"),
        ColoringPage(name: "Easter Egg", imageName: "holiday_easter"),
        ColoringPage(name: "Pumpkin", imageName: "holiday_pumpkin")
    ]

    static let sports: [ColoringPage] = [
        ColoringPage(name: "Soccer Ball", imageName: "sport_soccer"),
        ColoringPage(name: "Basketball", imageName: "sport_basketball"),
        ColoringPage(name: "Baseball", imageName: "sport_baseball")
    ]

    static let music: [ColoringPage] = [
        ColoringPage(name: "Guitar", imageName: "music_guitar"),
        ColoringPage(name: "Piano", imageName: "music_piano"),
        ColoringPage(name: "Drums", imageName: "music_drums")
    ]

    static let robots: [ColoringPage] = [
        ColoringPage(name: "Robot 1", imageName: "robot_01"),
        ColoringPage(name: "Robot 2", imageName: "robot_02"),
        ColoringPage(name: "Robot 3", imageName: "robot_03")
    ]

    static let fantasy: [ColoringPage] = [
        ColoringPage(name: "Unicorn", imageName: "fantasy_unicorn"),
        ColoringPage(name: "Dragon", imageName: "fantasy_dragon"),
        ColoringPage(name: "Castle", imageName: "fantasy_castle")
    ]

    static let underwater: [ColoringPage] = [
        ColoringPage(name: "Octopus", imageName: "underwater_octopus"),
        ColoringPage(name: "Seahorse", imageName: "underwater_seahorse"),
        ColoringPage(name: "Turtle", imageName: "underwater_turtle")
    ]

    static let zenPatterns: [ColoringPage] = [
        ColoringPage(name: "Zen 1", imageName: "zen_01"),
        ColoringPage(name: "Zen 2", imageName: "zen_02"),
        ColoringPage(name: "Zen 3", imageName: "zen_03")
    ]

    static let portraits: [ColoringPage] = [
        ColoringPage(name: "Princess", imageName: "portrait_princess"),
        ColoringPage(name: "Superhero", imageName: "portrait_superhero"),
        ColoringPage(name: "Fairy", imageName: "portrait_fairy")
    ]
}
