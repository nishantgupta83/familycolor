import Foundation

struct ColoringPage: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let imageName: String

    /// Stable ID for unlock/journey tracking (uses imageName)
    var pageId: String { imageName }

    // MARK: - All pages from coloringlover.com (cute kawaii style)

    static let animals: [ColoringPage] = [
        ColoringPage(name: "Cute Lion", imageName: "cute_lion"),
        ColoringPage(name: "Cute Elephant", imageName: "cute_elephant"),
        ColoringPage(name: "Cute Bunny", imageName: "cute_bunny"),
        ColoringPage(name: "Cute Cat", imageName: "cute_cat"),
        ColoringPage(name: "Cute Fox", imageName: "cute_fox"),
        ColoringPage(name: "Cute Panda", imageName: "cute_panda"),
        ColoringPage(name: "Cute Giraffe", imageName: "cute_giraffe"),
        ColoringPage(name: "Cute Koala", imageName: "cute_koala"),
        ColoringPage(name: "Cute Penguin", imageName: "cute_penguin"),
        ColoringPage(name: "Happy Dog", imageName: "easy_dog"),
        ColoringPage(name: "Sitting Cat", imageName: "easy_cat"),
        ColoringPage(name: "Happy Rabbit", imageName: "easy_rabbit"),
        ColoringPage(name: "Smiling Turtle", imageName: "easy_turtle"),
        ColoringPage(name: "Wise Owl", imageName: "easy_owl"),
        ColoringPage(name: "Rearing Horse", imageName: "easy_horse"),
    ]

    static let vehicles: [ColoringPage] = [
        ColoringPage(name: "Smiling Car", imageName: "cute_car_smiling"),
        ColoringPage(name: "Bunny's Truck", imageName: "cute_bunny_truck"),
        ColoringPage(name: "Bunny Driving", imageName: "cute_bunny_car"),
        ColoringPage(name: "Puppy Road Trip", imageName: "cute_puppy_roadtrip"),
        ColoringPage(name: "Rainbow Car", imageName: "cute_car_rainbow"),
        ColoringPage(name: "Truck with Hearts", imageName: "cute_truck_hearts"),
        ColoringPage(name: "Police Car", imageName: "cute_police_car"),
        ColoringPage(name: "Race Car", imageName: "cute_race_car"),
        ColoringPage(name: "Easy Car", imageName: "easy_car"),
        ColoringPage(name: "Toddler Car", imageName: "easy_car_toddler"),
        ColoringPage(name: "Car & Rainbow", imageName: "easy_car_rainbow"),
        ColoringPage(name: "Steam Train", imageName: "easy_train"),
        ColoringPage(name: "Airplane", imageName: "easy_airplane"),
        ColoringPage(name: "Tractor", imageName: "easy_tractor"),
        ColoringPage(name: "Sailboat", imageName: "easy_sailboat"),
    ]

    static let houses: [ColoringPage] = [
        ColoringPage(name: "Cozy House", imageName: "cute_cozy_house"),
        ColoringPage(name: "Cute House", imageName: "cute_house"),
        ColoringPage(name: "House & Garden", imageName: "cute_house_garden"),
        ColoringPage(name: "House & Butterflies", imageName: "cute_house_butterflies"),
        ColoringPage(name: "House & Chimney", imageName: "cute_house_chimney"),
        ColoringPage(name: "House & Trees", imageName: "cute_house_trees"),
        ColoringPage(name: "House & Sun", imageName: "cute_house_sun"),
        ColoringPage(name: "House & Rainbow", imageName: "cute_house_rainbow"),
        ColoringPage(name: "Gingerbread House", imageName: "cute_gingerbread"),
        ColoringPage(name: "Gingerbread Rainbow", imageName: "cute_gingerbread_rainbow"),
        ColoringPage(name: "Candy House", imageName: "cute_gingerbread_candy"),
        ColoringPage(name: "Countryside House", imageName: "easy_house"),
    ]

    static let nature: [ColoringPage] = [
        ColoringPage(name: "Rainbow & Clouds", imageName: "easy_rainbow"),
        ColoringPage(name: "Balloons", imageName: "easy_balloons"),
        ColoringPage(name: "Sunflower", imageName: "easy_sunflower"),
        ColoringPage(name: "Daisy", imageName: "easy_daisy"),
        ColoringPage(name: "Rose", imageName: "easy_rose"),
        ColoringPage(name: "Tulip", imageName: "easy_tulip"),
        ColoringPage(name: "Lily", imageName: "easy_lily"),
        ColoringPage(name: "Tree", imageName: "easy_tree"),
        ColoringPage(name: "Mountains Sunrise", imageName: "easy_mountains"),
        ColoringPage(name: "Waterfall", imageName: "easy_waterfall"),
        ColoringPage(name: "Night Sky", imageName: "easy_night_sky"),
        ColoringPage(name: "Butterfly Wreath", imageName: "cute_butterfly_wreath"),
        ColoringPage(name: "Butterfly & Roses", imageName: "cute_butterfly_roses"),
        ColoringPage(name: "Butterfly on Rose", imageName: "cute_butterfly_rose"),
    ]

    static let ocean: [ColoringPage] = [
        ColoringPage(name: "Cute Dolphin", imageName: "cute_dolphin"),
        ColoringPage(name: "Dolphin & Fish", imageName: "cute_dolphin_fish"),
        ColoringPage(name: "Dolphin & Pearl", imageName: "cute_dolphin_pearl"),
        ColoringPage(name: "Dolphin Ice Cream", imageName: "cute_dolphin_icecream"),
        ColoringPage(name: "Dolphin Family", imageName: "cute_dolphin_family"),
        ColoringPage(name: "Dolphin & Beach Ball", imageName: "cute_dolphin_beachball"),
        ColoringPage(name: "Dolphin Rainbow", imageName: "cute_dolphin_rainbow"),
        ColoringPage(name: "Clownfish", imageName: "cute_clownfish"),
        ColoringPage(name: "Fish in Love", imageName: "cute_fish_hearts"),
        ColoringPage(name: "Angelfish", imageName: "cute_angelfish"),
        ColoringPage(name: "Pufferfish", imageName: "cute_pufferfish"),
        ColoringPage(name: "Betta Fish", imageName: "cute_betafish"),
        ColoringPage(name: "Smiling Whale", imageName: "easy_whale"),
        ColoringPage(name: "Shark", imageName: "easy_shark"),
    ]

    static let underwater: [ColoringPage] = [
        ColoringPage(name: "Seahorse & Dolphin", imageName: "cute_seahorse_dolphin"),
        ColoringPage(name: "Easy Seahorse", imageName: "easy_seahorse"),
        ColoringPage(name: "Baby Turtle", imageName: "cute_baby_turtle"),
        ColoringPage(name: "Turtle on Mushroom", imageName: "cute_turtle_mushroom"),
        ColoringPage(name: "Party Turtle", imageName: "cute_turtle_balloon"),
        ColoringPage(name: "Turtle on Cloud", imageName: "cute_turtle_cloud"),
        ColoringPage(name: "Sea Turtle", imageName: "cute_sea_turtle"),
        ColoringPage(name: "Turtle Treasure", imageName: "cute_turtle_treasure"),
        ColoringPage(name: "Happy Octopus", imageName: "easy_octopus"),
        ColoringPage(name: "Lobster", imageName: "easy_lobster"),
        ColoringPage(name: "Dolphin Waves", imageName: "cute_dolphin_waves"),
        ColoringPage(name: "Dolphin Sunglasses", imageName: "cute_dolphin_sunglasses"),
    ]

    static let dinosaurs: [ColoringPage] = [
        ColoringPage(name: "Dino & Balloon", imageName: "cute_dino_balloon"),
        ColoringPage(name: "Jumping Dino", imageName: "cute_dino_trampoline"),
        ColoringPage(name: "Forest Dino", imageName: "cute_dino_forest"),
        ColoringPage(name: "Dino on Tricycle", imageName: "cute_dino_tricycle"),
        ColoringPage(name: "Dino & Stars", imageName: "cute_dino_stars"),
        ColoringPage(name: "Dino & Hearts", imageName: "cute_dino_hearts"),
        ColoringPage(name: "Dino & Rainbow", imageName: "cute_dino_rainbow"),
        ColoringPage(name: "Cute Triceratops", imageName: "cute_triceratops"),
        ColoringPage(name: "T-Rex Ice Cream", imageName: "cute_trex_icecream"),
        ColoringPage(name: "Dino Picnic", imageName: "cute_dino_watermelon"),
        ColoringPage(name: "Dino & Leaves", imageName: "cute_dino_leaves"),
        ColoringPage(name: "Dino & Clouds", imageName: "cute_dino_clouds"),
        ColoringPage(name: "T-Rex Exercise", imageName: "cute_trex_exercise"),
        ColoringPage(name: "T-Rex Skateboard", imageName: "cute_trex_skateboard"),
        ColoringPage(name: "Dino Lemonade", imageName: "cute_dino_lemonade"),
        ColoringPage(name: "Chef Dino", imageName: "cute_dino_chef"),
        ColoringPage(name: "Dino in Rain", imageName: "cute_dino_umbrella"),
        ColoringPage(name: "Flying Dino", imageName: "cute_flying_dino"),
    ]

    static let fantasy: [ColoringPage] = [
        ColoringPage(name: "Unicorn & Flowers", imageName: "cute_unicorn_flowers"),
        ColoringPage(name: "Princess Unicorn", imageName: "cute_unicorn_princess"),
        ColoringPage(name: "Fairy & Unicorn", imageName: "cute_unicorn_fairy"),
        ColoringPage(name: "Unicorn on Cloud", imageName: "cute_unicorn_cloud"),
        ColoringPage(name: "Unicorn Balloon", imageName: "cute_unicorn_balloon"),
        ColoringPage(name: "Unicorn Rainbow", imageName: "cute_unicorn_rainbow"),
        ColoringPage(name: "Unicorn Crown", imageName: "cute_unicorn_crown"),
        ColoringPage(name: "Unicorn Watering", imageName: "cute_unicorn_watering"),
        ColoringPage(name: "Unicorn Painting", imageName: "cute_unicorn_painting"),
        ColoringPage(name: "Beach Unicorn", imageName: "cute_unicorn_beach"),
        ColoringPage(name: "Mermaid Unicorn", imageName: "cute_unicorn_mermaid"),
        ColoringPage(name: "Carousel Unicorn", imageName: "cute_unicorn_carousel"),
        ColoringPage(name: "Ice Cream Unicorn", imageName: "cute_unicorn_icecream"),
        ColoringPage(name: "Reading Unicorn", imageName: "cute_unicorn_reading"),
        ColoringPage(name: "Ballerina Unicorn", imageName: "cute_unicorn_ballerina"),
        ColoringPage(name: "Baking Unicorn", imageName: "cute_unicorn_baking"),
        ColoringPage(name: "Biking Unicorn", imageName: "cute_unicorn_bike"),
        ColoringPage(name: "Waterfall Unicorn", imageName: "cute_unicorn_waterfall"),
    ]

    static let holidays: [ColoringPage] = [
        ColoringPage(name: "Christmas House", imageName: "cute_christmas_house"),
        ColoringPage(name: "Snowman House", imageName: "cute_christmas_snowman"),
        ColoringPage(name: "Hot Cocoa House", imageName: "cute_christmas_cocoa"),
        ColoringPage(name: "Haunted House", imageName: "cute_haunted_house"),
        ColoringPage(name: "Halloween House", imageName: "cute_halloween_house"),
        ColoringPage(name: "Christmas Flowers", imageName: "cute_christmas_flowers"),
        ColoringPage(name: "Valentine Roses", imageName: "cute_valentines_roses"),
        ColoringPage(name: "Birthday Bouquet", imageName: "cute_birthday_bouquet"),
        ColoringPage(name: "Mother's Day", imageName: "cute_mothers_day"),
        ColoringPage(name: "Birthday Dolphin", imageName: "cute_dolphin_birthday"),
        ColoringPage(name: "Birthday Turtle", imageName: "cute_turtle_birthday"),
    ]

}
