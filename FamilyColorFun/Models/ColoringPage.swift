import Foundation

struct ColoringPage: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let imageName: String

    // MARK: - Page Definitions
    // Includes cute kawaii-style pages from coloringlover.com

    static let animals: [ColoringPage] = [
        // Cute animals (kawaii style)
        ColoringPage(name: "Cute Lion", imageName: "cute_lion"),
        ColoringPage(name: "Cute Elephant", imageName: "cute_elephant"),
        ColoringPage(name: "Cute Bunny", imageName: "cute_bunny"),
        ColoringPage(name: "Cute Cat", imageName: "cute_cat"),
        ColoringPage(name: "Cute Fox", imageName: "cute_fox"),
        ColoringPage(name: "Cute Panda", imageName: "cute_panda"),
        ColoringPage(name: "Cute Giraffe", imageName: "cute_giraffe"),
        ColoringPage(name: "Cute Koala", imageName: "cute_koala"),
        ColoringPage(name: "Cute Penguin", imageName: "cute_penguin"),
        // Easy animals
        ColoringPage(name: "Happy Dog", imageName: "easy_dog"),
        ColoringPage(name: "Sitting Cat", imageName: "easy_cat"),
        ColoringPage(name: "Happy Rabbit", imageName: "easy_rabbit"),
        ColoringPage(name: "Smiling Turtle", imageName: "easy_turtle"),
        // Original animals
        ColoringPage(name: "Cat", imageName: "animal_cat"),
        ColoringPage(name: "Dog", imageName: "animal_dog"),
        ColoringPage(name: "Elephant", imageName: "animal_elephant"),
        ColoringPage(name: "Bunny", imageName: "animal_simple_01"),
        ColoringPage(name: "Bear", imageName: "animal_simple_03"),
        ColoringPage(name: "Bird", imageName: "animal_simple_04"),
        ColoringPage(name: "Fox", imageName: "animal_simple_06")
    ]

    static let vehicles: [ColoringPage] = [
        // Easy vehicles
        ColoringPage(name: "Cute Car", imageName: "easy_car"),
        ColoringPage(name: "Steam Train", imageName: "easy_train"),
        ColoringPage(name: "Airplane", imageName: "easy_airplane"),
        // Original
        ColoringPage(name: "Car", imageName: "vehicle_car")
    ]

    static let houses: [ColoringPage] = [
        ColoringPage(name: "Cozy House", imageName: "easy_house"),
        ColoringPage(name: "Cottage", imageName: "house_cottage")
    ]

    static let nature: [ColoringPage] = [
        // Easy nature
        ColoringPage(name: "Rainbow", imageName: "easy_rainbow"),
        ColoringPage(name: "Balloons", imageName: "easy_balloons"),
        ColoringPage(name: "Sunflower", imageName: "easy_sunflower"),
        // Original
        ColoringPage(name: "Flower", imageName: "nature_flower"),
        ColoringPage(name: "Star", imageName: "nature_star"),
        ColoringPage(name: "Rose", imageName: "flower_01"),
        ColoringPage(name: "Daisy", imageName: "flower_02"),
        ColoringPage(name: "Tulip", imageName: "flower_03")
    ]

    static let ocean: [ColoringPage] = [
        // Easy ocean
        ColoringPage(name: "Happy Whale", imageName: "easy_whale"),
        ColoringPage(name: "Happy Octopus", imageName: "easy_octopus"),
        // Original
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

    static let dinosaurs: [ColoringPage] = [
        // Cute dinosaurs (kawaii style)
        ColoringPage(name: "Dino with Balloon", imageName: "cute_dino_balloon"),
        ColoringPage(name: "Jumping Dino", imageName: "cute_dino_trampoline"),
        ColoringPage(name: "Forest Dino", imageName: "cute_dino_forest"),
        ColoringPage(name: "Dino on Tricycle", imageName: "cute_dino_tricycle"),
        ColoringPage(name: "Dino & Stars", imageName: "cute_dino_stars"),
        ColoringPage(name: "Dino & Hearts", imageName: "cute_dino_hearts"),
        ColoringPage(name: "Dino & Rainbow", imageName: "cute_dino_rainbow"),
        ColoringPage(name: "Cute Triceratops", imageName: "cute_triceratops"),
        ColoringPage(name: "T-Rex Ice Cream", imageName: "cute_trex_icecream"),
        // Original
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
