#!/usr/bin/env python3
"""
Download cute coloring pages from coloringlover.com for ALL categories
Organizes images in separate folders by category
"""

import os
import urllib.request
import ssl
import json
import shutil
from pathlib import Path

ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

script_dir = Path(__file__).parent
base_download_dir = script_dir / "coloringlover_downloads"
assets_dir = script_dir.parent / "FamilyColorFun" / "Assets.xcassets" / "ColoringPages"

# All categories with their images from coloringlover.com
CATEGORIES = {
    "animals": [
        ("cute_lion", "https://www.coloringlover.com/wp-content/uploads/2024/12/Happy-Cute-Lion-Coloring-Page-For-Kids.jpg"),
        ("cute_elephant", "https://www.coloringlover.com/wp-content/uploads/2024/12/Sweet-Cute-Elephant-Coloring-Page-For-Kids.jpg"),
        ("cute_bunny", "https://www.coloringlover.com/wp-content/uploads/2024/12/Playful-Cute-Bunny-Coloring-Page-For-Kids.jpg"),
        ("cute_cat", "https://www.coloringlover.com/wp-content/uploads/2024/12/Playful-Cute-Cat-Coloring-Page-With-Yarn-Ball.jpg"),
        ("cute_fox", "https://www.coloringlover.com/wp-content/uploads/2024/12/Smiling-Cute-Fox-Coloring-Page-Under-Starry-Night.jpg"),
        ("cute_panda", "https://www.coloringlover.com/wp-content/uploads/2024/12/Adorable-Cute-Panda-Coloring-Page-With-Bamboo-Plant.jpg"),
        ("cute_giraffe", "https://www.coloringlover.com/wp-content/uploads/2024/12/Smiling-Cute-Giraffe-Coloring-Page-For-Kids.jpg"),
        ("cute_koala", "https://www.coloringlover.com/wp-content/uploads/2024/12/Adorable-Cute-Koala-Coloring-Sheet-Climbing-A-Tree.jpg"),
        ("cute_penguin", "https://www.coloringlover.com/wp-content/uploads/2024/12/Cute-Penguin-Coloring-Sheet-With-Icy-Mountain-Background.jpg"),
        ("easy_dog", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Sitting-Cute-Dog-Coloring-Page.jpg"),
        ("easy_cat", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Sitting-Cat-Coloring-Page.jpg"),
        ("easy_rabbit", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Happy-Rabbit-Sitting-Coloring-Sheet.jpg"),
        ("easy_turtle", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Smiling-Turtle-Coloring-Page.jpg"),
        ("easy_owl", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Owl-Perched-On-A-Branch-Coloring-Page.jpg"),
        ("easy_horse", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Rearing-Horse-Coloring-Page.jpg"),
    ],

    "dinosaurs": [
        ("cute_dino_balloon", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Dinosaur-Flying-With-Balloon-Under-Moonlight-Coloring-Page.jpg"),
        ("cute_dino_trampoline", "https://www.coloringlover.com/wp-content/uploads/2025/05/Happy-Dinosaur-Jumping-On-Trampoline-In-Garden-Coloring-Page.jpg"),
        ("cute_dino_forest", "https://www.coloringlover.com/wp-content/uploads/2025/05/Friendly-Dinosaur-Walking-Through-Peaceful-Forest-Coloring-Page.jpg"),
        ("cute_dino_tricycle", "https://www.coloringlover.com/wp-content/uploads/2025/05/Playful-Dinosaur-Riding-Tricycle-Near-Pond-Coloring-Page.jpg"),
        ("cute_dino_stars", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Dinosaur-With-Stars-Easy-Coloring-Page.jpg"),
        ("cute_dino_hearts", "https://www.coloringlover.com/wp-content/uploads/2025/05/Happy-Dinosaur-With-Hearts-Preschool-Coloring-Page.jpg"),
        ("cute_dino_rainbow", "https://www.coloringlover.com/wp-content/uploads/2025/05/Smiling-Dinosaur-And-Rainbow-Easy-Coloring-Sheet.jpg"),
        ("cute_triceratops", "https://www.coloringlover.com/wp-content/uploads/2025/05/Triceratops-In-Flower-Garden-Easy-Coloring-Page.jpg"),
        ("cute_trex_icecream", "https://www.coloringlover.com/wp-content/uploads/2025/05/T-Rex-Happily-Holding-Ice-Cream-With-Hearts-Coloring-Page.jpg"),
        ("cute_dino_watermelon", "https://www.coloringlover.com/wp-content/uploads/2025/05/Hungry-Dinosaur-Eating-Watermelon-At-Picnic-Table-Coloring-Page.jpg"),
        ("cute_dino_leaves", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cheerful-Dinosaur-Collecting-Leaves-On-Forest-Floor-Coloring-Page.jpg"),
        ("cute_dino_clouds", "https://www.coloringlover.com/wp-content/uploads/2025/05/Tall-Dinosaur-Under-Clouds-Preschool-Coloring-Page.jpg"),
        ("cute_trex_exercise", "https://www.coloringlover.com/wp-content/uploads/2025/05/T-Rex-Dinosaur-Doing-Exercise-Under-Sunny-Sky-Coloring-Page.jpg"),
        ("cute_trex_skateboard", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cool-T-Rex-Dinosaur-Skateboarding-In-Park-Coloring-Page.jpg"),
        ("cute_dino_lemonade", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Dinosaur-Selling-Lemonade-At-Sunny-Stand-Coloring-Page.jpg"),
        ("cute_dino_chef", "https://www.coloringlover.com/wp-content/uploads/2025/05/Chef-Dinosaur-Cooking-Happily-In-Kitchen-Coloring-Page.jpg"),
        ("cute_dino_umbrella", "https://www.coloringlover.com/wp-content/uploads/2025/05/Dinosaur-Under-Umbrella-In-Rain-With-Snail-Coloring-Page.jpg"),
        ("cute_flying_dino", "https://www.coloringlover.com/wp-content/uploads/2025/05/Flying-Dinosaur-Over-Hills-Preschool-Coloring-Sheet.jpg"),
    ],

    "underwater": [
        ("cute_dolphin", "https://www.coloringlover.com/wp-content/uploads/2024/10/Cute-Baby-Dolphin-Jumping-With-Rainbow-Coloring-Page.jpg"),
        ("cute_dolphin_fish", "https://www.coloringlover.com/wp-content/uploads/2024/10/Cute-Baby-Dolphin-Swimming-With-Fish-Coloring-Page.jpg"),
        ("cute_dolphin_pearl", "https://www.coloringlover.com/wp-content/uploads/2024/10/Cute-Baby-Dolphin-With-Pearl-And-Starfish-Coloring-Page.jpg"),
        ("cute_dolphin_icecream", "https://www.coloringlover.com/wp-content/uploads/2024/10/Smiling-Baby-Dolphin-Holding-Ice-Cream-Coloring-Page.jpg"),
        ("cute_dolphin_family", "https://www.coloringlover.com/wp-content/uploads/2024/10/Family-Of-Baby-Dolphins-Playing-With-Hearts-Coloring-Page.jpg"),
        ("cute_seahorse_dolphin", "https://www.coloringlover.com/wp-content/uploads/2024/10/Baby-Dolphin-And-Seahorse-In-Coral-Reef-Coloring-Page.jpg"),
        ("cute_dolphin_beachball", "https://www.coloringlover.com/wp-content/uploads/2024/10/Happy-Dolphin-Playing-With-A-Beach-Ball-Coloring-Sheet.jpg"),
        ("cute_dolphin_waves", "https://www.coloringlover.com/wp-content/uploads/2024/10/Cheerful-Dolphin-Jumping-Over-Waves-With-The-Sun-Coloring-Page.jpg"),
        ("cute_dolphin_rainbow", "https://www.coloringlover.com/wp-content/uploads/2024/10/Dolphin-Jumping-In-Front-Of-Rainbow-Coloring-Page.jpg"),
        ("cute_dolphin_sunglasses", "https://www.coloringlover.com/wp-content/uploads/2024/10/Dolphin-Wearing-Sunglasses-Riding-The-Waves-Coloring-Page.jpg"),
        ("cute_baby_turtle", "https://www.coloringlover.com/wp-content/uploads/2024/11/Baby-Turtle-With-Bubbles-Coloring-Page.jpg"),
        ("cute_turtle_mushroom", "https://www.coloringlover.com/wp-content/uploads/2024/11/Cute-Turtle-On-Mushroom-Coloring-Sheet.jpg"),
        ("cute_turtle_balloon", "https://www.coloringlover.com/wp-content/uploads/2024/11/Party-Baby-Turtle-With-Balloon-Coloring-Page.jpg"),
        ("cute_turtle_cloud", "https://www.coloringlover.com/wp-content/uploads/2024/11/Baby-Turtle-On-Cloud-Coloring-Sheet.jpg"),
        ("cute_sea_turtle", "https://www.coloringlover.com/wp-content/uploads/2024/11/Sea-Turtle-Coral-Reef-Coloring-Page.jpg"),
        ("cute_turtle_treasure", "https://www.coloringlover.com/wp-content/uploads/2024/11/Turtle-With-Treasure-Chest-Coloring-Page.jpg"),
        ("easy_octopus", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Happy-Octopus-Coloring-Page.jpg"),
        ("easy_whale", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Smiling-Whale-Coloring-Page.jpg"),
        ("easy_seahorse", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Standing-Seahorse-Coloring-Page.jpg"),
        ("easy_shark", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Swimming-Shark-Coloring-Page.jpg"),
        ("easy_lobster", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Lobster-With-Big-Claws-Coloring-Page.jpg"),
        ("cute_clownfish", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Clown-Fish-Swimming-Through-Coral-Reef-Coloring-Page.jpg"),
        ("cute_fish_hearts", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Fish-Couple-Surrounded-By-Hearts-Coloring-Page.jpg"),
        ("cute_angelfish", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Angelfish-Swimming-Among-Sea-Plants-Coloring-Page.jpg"),
        ("cute_pufferfish", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Puffer-Fish-And-Crab-On-Ocean-Floor-Coloring-Page.jpg"),
        ("cute_betafish", "https://www.coloringlover.com/wp-content/uploads/2025/05/Kawaii-Betta-Fish-Gliding-Near-Lily-Pads-Coloring-Page.jpg"),
    ],

    "vehicles": [
        ("cute_car_smiling", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Smiling-Car-Driving-Country-Road-Coloring-Page.jpg"),
        ("cute_bunny_truck", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Bunny-On-Adventure-Truck-Coloring-Page.jpg"),
        ("cute_bunny_car", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Bunny-Driving-Fast-Car-Coloring-Page.jpg"),
        ("cute_puppy_roadtrip", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Puppy-On-Best-Road-Trip-Coloring-Page.jpg"),
        ("cute_car_rainbow", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Smiling-Car-With-Rainbow-Background-Coloring-Page.jpg"),
        ("cute_truck_hearts", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Little-Truck-With-Hearts-And-Smile-Coloring-Page.jpg"),
        ("cute_police_car", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Police-Car-In-Neighborhood-Coloring-Page.jpg"),
        ("cute_race_car", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Race-Car-Speeding-On-Track-Coloring-Page.jpg"),
        ("easy_car", "https://www.coloringlover.com/wp-content/uploads/2025/05/Easy-Car-Coloring-Page-For-Preschool-Kids.jpg"),
        ("easy_car_toddler", "https://www.coloringlover.com/wp-content/uploads/2025/05/Simple-Car-Drawing-Activity-For-Toddlers.jpg"),
        ("easy_car_rainbow", "https://www.coloringlover.com/wp-content/uploads/2025/05/Smiling-Car-With-Rainbow-For-Preschool-Kids.jpg"),
        ("easy_train", "https://www.coloringlover.com/wp-content/uploads/2025/01/Simple-Train-Coloring-Page-With-Vintage-Steam-Engine-Design.jpg"),
        ("easy_airplane", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-Airplane-Coloring-Page-With-Clear-And-Bold-Outlines.jpg"),
        ("easy_tractor", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-Tractor-Coloring-Page-With-Large-Wheels-And-Simple-Design.jpg"),
        ("easy_sailboat", "https://www.coloringlover.com/wp-content/uploads/2025/01/Simple-Sailboat-Coloring-Page-With-A-Flag-And-Waves.jpg"),
    ],

    "fantasy": [
        ("cute_unicorn_flowers", "https://www.coloringlover.com/wp-content/uploads/2024/10/Cute-Baby-Unicorn-With-Flowers-Coloring-Page-For-Kids.jpg"),
        ("cute_unicorn_princess", "https://www.coloringlover.com/wp-content/uploads/2024/10/Princess-Unicorn-With-Magic-Wand-Coloring-Page-For-Girls.jpg"),
        ("cute_unicorn_fairy", "https://www.coloringlover.com/wp-content/uploads/2024/10/Fairy-Riding-A-Unicorn-On-Mushrooms-Coloring-Page-For-Girls.jpg"),
        ("cute_unicorn_cloud", "https://www.coloringlover.com/wp-content/uploads/2024/10/Unicorn-On-A-Cloud-With-Magic-Wand-Coloring-Page.jpg"),
        ("cute_unicorn_balloon", "https://www.coloringlover.com/wp-content/uploads/2024/10/Unicorn-With-Heart-Balloon-Coloring-Page.jpg"),
        ("cute_unicorn_rainbow", "https://www.coloringlover.com/wp-content/uploads/2024/10/Unicorn-And-Rainbow-Coloring-Page-For-Kids.jpg"),
        ("cute_unicorn_crown", "https://www.coloringlover.com/wp-content/uploads/2024/10/Cute-Unicorn-With-Flower-Crown-Coloring-Page-For-Girls.jpg"),
        ("cute_unicorn_watering", "https://www.coloringlover.com/wp-content/uploads/2024/10/Unicorn-Watering-Daisies-Under-The-Sun-Coloring-Page-For-Girls.jpg"),
        ("cute_unicorn_painting", "https://www.coloringlover.com/wp-content/uploads/2024/10/Unicorn-Painting-Rainbow-On-Canvas-Coloring-Page-For-Kids.jpg"),
        ("cute_unicorn_beach", "https://www.coloringlover.com/wp-content/uploads/2024/10/Unicorn-Relaxing-At-The-Beach-With-Sunglasses-Coloring-Page-For-Kids.jpg"),
        ("cute_unicorn_mermaid", "https://www.coloringlover.com/wp-content/uploads/2024/10/Mermaid-Unicorn-Swimming-Underwater-Coloring-Page.jpg"),
        ("cute_unicorn_carousel", "https://www.coloringlover.com/wp-content/uploads/2024/10/Unicorn-Riding-A-Carousel-Coloring-Page.jpg"),
        ("cute_unicorn_icecream", "https://www.coloringlover.com/wp-content/uploads/2024/10/Unicorn-Enjoying-Ice-Cream-At-The-Beach-For-Girls-Coloring-Page.jpg"),
        ("cute_unicorn_reading", "https://www.coloringlover.com/wp-content/uploads/2024/10/Unicorn-Reading-A-Book-For-Girls-Coloring-Page.jpg"),
        ("cute_unicorn_ballerina", "https://www.coloringlover.com/wp-content/uploads/2024/10/Ballerina-Unicorn-For-Girls-Coloring-Page.jpg"),
        ("cute_unicorn_baking", "https://www.coloringlover.com/wp-content/uploads/2024/10/Unicorn-Baking-Cupcakes-For-Girls-Coloring-Page.jpg"),
        ("cute_unicorn_bike", "https://www.coloringlover.com/wp-content/uploads/2024/10/Unicorn-Riding-A-Bike-In-The-Sun-Coloring-Page-For-Kids.jpg"),
        ("cute_unicorn_waterfall", "https://www.coloringlover.com/wp-content/uploads/2024/10/Unicorn-Near-Rainbow-And-Waterfall-For-Kids-Coloring-Page.jpg"),
    ],

    "houses": [
        ("cute_cozy_house", "https://www.coloringlover.com/wp-content/uploads/2025/03/Cozy-House-Coloring-Page-For-Kids.jpg"),
        ("cute_house", "https://www.coloringlover.com/wp-content/uploads/2025/03/Cute-House-Coloring-Page-For-Kids.jpg"),
        ("cute_house_garden", "https://www.coloringlover.com/wp-content/uploads/2025/03/Charming-House-Coloring-Page-With-Garden.jpg"),
        ("cute_house_butterflies", "https://www.coloringlover.com/wp-content/uploads/2025/03/House-Coloring-Page-With-Butterflies-And-Text.jpg"),
        ("cute_house_chimney", "https://www.coloringlover.com/wp-content/uploads/2025/03/Classic-House-Coloring-Page-With-Chimney.jpg"),
        ("cute_house_trees", "https://www.coloringlover.com/wp-content/uploads/2025/03/Whimsical-House-Coloring-Page-With-Trees.jpg"),
        ("cute_house_sun", "https://www.coloringlover.com/wp-content/uploads/2025/03/Simple-House-Coloring-Page-With-Happy-Sun.jpg"),
        ("cute_house_rainbow", "https://www.coloringlover.com/wp-content/uploads/2025/03/House-Coloring-Page-With-Rainbow-And-Clouds.jpg"),
        ("cute_gingerbread", "https://www.coloringlover.com/wp-content/uploads/2025/03/Gingerbread-House-Coloring-Page-With-Cookies.jpg"),
        ("cute_gingerbread_rainbow", "https://www.coloringlover.com/wp-content/uploads/2025/03/Cute-Gingerbread-House-Coloring-Page-With-Rainbow.jpg"),
        ("cute_gingerbread_candy", "https://www.coloringlover.com/wp-content/uploads/2025/03/Candy-Themed-Gingerbread-House-Coloring-Sheet.jpg"),
        ("easy_house", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Countryside-House-Coloring-Page.jpg"),
    ],

    "nature": [
        ("easy_rainbow", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-Rainbow-Coloring-Page-With-Fluffy-Clouds.jpg"),
        ("easy_balloons", "https://www.coloringlover.com/wp-content/uploads/2025/01/Simple-Balloons-Coloring-Page-With-Three-Floating-Balloons.jpg"),
        ("easy_sunflower", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-Sunflower-Coloring-Page-With-Decorative-Petal-Design.jpg"),
        ("easy_daisy", "https://www.coloringlover.com/wp-content/uploads/2025/01/Simple-Daisy-Coloring-Page-For-Kids-To-Color.jpg"),
        ("easy_rose", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-Rose-Coloring-Page-With-Simple-Petals-And-Leaves.jpg"),
        ("easy_tulip", "https://www.coloringlover.com/wp-content/uploads/2025/01/Simple-Tulip-Coloring-Page-With-Graceful-Floral-Details.jpg"),
        ("easy_lily", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-Lily-Coloring-Page-With-Soft-Petal-Outlines.jpg"),
        ("easy_tree", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Tree-With-Leaves-Coloring-Page.jpg"),
        ("easy_mountains", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Sunrise-Over-Mountains-Coloring-Page.jpg"),
        ("easy_waterfall", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Peaceful-Waterfall-Coloring-Page.jpg"),
        ("easy_night_sky", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Night-Sky-With-Moon-And-Stars-Coloring-Page.jpg"),
        ("cute_butterfly_wreath", "https://www.coloringlover.com/wp-content/uploads/2025/01/Butterfly-Surrounded-By-Floral-Wreath-Coloring-Page.jpg"),
        ("cute_butterfly_roses", "https://www.coloringlover.com/wp-content/uploads/2025/01/Decorative-Butterfly-With-Roses-And-Tulips-Coloring-Page.jpg"),
        ("cute_butterfly_rose", "https://www.coloringlover.com/wp-content/uploads/2025/01/Butterfly-Perched-On-A-Blooming-Rose-Coloring-Page.jpg"),
    ],

    "holidays": [
        ("cute_christmas_house", "https://www.coloringlover.com/wp-content/uploads/2025/03/Christmas-House-Coloring-Page-With-Gifts.jpg"),
        ("cute_christmas_snowman", "https://www.coloringlover.com/wp-content/uploads/2025/03/Snowy-Christmas-House-Coloring-Page-With-Snowman.jpg"),
        ("cute_christmas_cocoa", "https://www.coloringlover.com/wp-content/uploads/2025/03/Cozy-Christmas-House-Coloring-Page-With-Hot-Cocoa.jpg"),
        ("cute_haunted_house", "https://www.coloringlover.com/wp-content/uploads/2025/03/Haunted-House-Coloring-Page-With-Spooky-Tree.jpg"),
        ("cute_halloween_house", "https://www.coloringlover.com/wp-content/uploads/2025/03/Halloween-House-Coloring-Page-With-Pumpkins-And-Owl.jpg"),
        ("cute_christmas_flowers", "https://www.coloringlover.com/wp-content/uploads/2025/01/Flower-Coloring-Pages-Of-Christmas-Flowers-With-Pinecones.jpg"),
        ("cute_valentines_roses", "https://www.coloringlover.com/wp-content/uploads/2025/01/Flower-Coloring-Pages-Of-Heart-Shaped-Roses-For-Valentines-Day.jpg"),
        ("cute_birthday_bouquet", "https://www.coloringlover.com/wp-content/uploads/2025/01/Flower-Coloring-Pages-Of-Birthday-Bouquet-With-Balloons-And-Ribbon.jpg"),
        ("cute_mothers_day", "https://www.coloringlover.com/wp-content/uploads/2025/01/Flower-Coloring-Pages-Of-Floral-Wreath-For-Mothers-Day.jpg"),
        ("cute_dolphin_birthday", "https://www.coloringlover.com/wp-content/uploads/2024/10/Happy-Birthday-Dolphin-Coloring-Page.jpg"),
        ("cute_turtle_birthday", "https://www.coloringlover.com/wp-content/uploads/2024/11/Happy-Birthday-Turtle-Coloring-Page-For-Kids.jpg"),
    ],
}


def download_image(name, url, category_dir):
    """Download a single image to the category folder."""
    output_path = category_dir / f"{name}.jpg"

    if output_path.exists():
        print(f"    Skipping {name} (exists)")
        return True

    try:
        req = urllib.request.Request(
            url,
            headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'}
        )
        with urllib.request.urlopen(req, context=ssl_context, timeout=30) as response:
            data = response.read()
            with open(output_path, 'wb') as f:
                f.write(data)
        print(f"    Downloaded: {name}")
        return True
    except Exception as e:
        print(f"    Failed {name}: {e}")
        return False


def create_imageset(image_name, source_path):
    """Create an imageset directory with Contents.json and image."""
    imageset_dir = assets_dir / f"{image_name}.imageset"

    if imageset_dir.exists():
        shutil.rmtree(imageset_dir)

    imageset_dir.mkdir(exist_ok=True)

    dest_image = imageset_dir / f"{image_name}.jpg"
    shutil.copy(source_path, dest_image)

    contents = {
        "images": [
            {"filename": f"{image_name}.jpg", "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"}
        ],
        "info": {"author": "xcode", "version": 1}
    }

    with open(imageset_dir / "Contents.json", 'w') as f:
        json.dump(contents, f, indent=2)


def main():
    print("=" * 60)
    print("Downloading ALL cute coloring pages from coloringlover.com")
    print("=" * 60)

    total_success = 0
    total_images = 0

    # Download all categories
    for category, images in CATEGORIES.items():
        category_dir = base_download_dir / category
        category_dir.mkdir(parents=True, exist_ok=True)

        print(f"\n[{category.upper()}] ({len(images)} images)")

        success = 0
        for name, url in images:
            total_images += 1
            if download_image(name, url, category_dir):
                success += 1
                total_success += 1

        print(f"  Downloaded: {success}/{len(images)}")

    print(f"\n{'=' * 60}")
    print(f"TOTAL: {total_success}/{total_images} images downloaded")
    print(f"{'=' * 60}")

    # Create imagesets
    print("\nCreating Xcode imagesets...")
    for category_dir in base_download_dir.iterdir():
        if category_dir.is_dir():
            for image_file in category_dir.glob("*.jpg"):
                create_imageset(image_file.stem, image_file)

    print("\nDone! Run 'xcodebuild build' to rebuild with new images.")


if __name__ == "__main__":
    main()
