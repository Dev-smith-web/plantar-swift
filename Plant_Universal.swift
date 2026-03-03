import Foundation
import SwiftUI

// MARK: - Core Data Models

struct Plant: Identifiable, Codable, Hashable {
    let id: String
    let commonName: String
    let scientificName: String
    let description: String

    // UI Branding
    let icon: String
    let color: String
    let difficulty: Int

    // Bloom and Rarity Info
    var bloomMonths: [Int] = [1,2,3,4,5,6,7,8,9,10,11,12] // 1-12 for Jan-Dec
    var rarity: PlantRarity = .common
    var hasARModel: Bool = true

    // Image URL for real photos (from Perenual API)
    var imageURL: String? = nil

    // Perenual API ID for fetching additional data
    var apiId: Int? = nil

    // API search name (more specific than common name for better API matches)
    var apiSearchName: String? = nil

    // Geographic Range
    var nativeRegion: String = "Worldwide"
    var availability: PlantAvailability = .yearRound

    // AR Setup
    let modelName: String
    let arImageReferenceName: String
    let scale: Float
    let yOffset: Float
    var xOffset: Float = 0.0

    // AR Interaction
    var allowRotation: Bool = true
    var minZoom: Float = 0.5
    var maxZoom: Float = 3.0

    // Content
    let rootType: RootSystemType
    let plantParts: [PlantPart]
    let funFacts: [String]
    let quizQuestions: [QuizQuestion]
}

// Plant availability/seasonality
enum PlantAvailability: String, Codable {
    case yearRound = "Year-round"
    case seasonal = "Seasonal"
    case springOnly = "Spring only"
    case summerOnly = "Summer only"
}

enum PlantRarity: String, Codable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"

    var color: String {
        switch self {
        case .common: return "#4CAF50"
        case .uncommon: return "#FF9800"
        case .rare: return "#9C27B0"
        }
    }
}

enum RootSystemType: String, Codable {
    case fibrous, taproot, adventitious, bulb
    
    var description: String {
        switch self {
        case .fibrous: return "Fibrous roots spread out like a net to absorb water from topsoil."
        case .taproot: return "A single deep root that anchors the plant, like a carrot."
        case .adventitious: return "Roots that grow from stems or leaves rather than the main system."
        case .bulb: return "An underground stem that stores energy, like an onion."
        }
    }
    
    var icon: String {
        switch self {
        case .fibrous: return "🌾"
        case .taproot: return "🥕"
        case .adventitious: return "🍃"
        case .bulb: return "🧅"
        }
    }
}



struct PlantPart: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let scientificName: String
    let function: String
    let modelPartName: String?
}

struct QuizQuestion: Identifiable, Codable, Hashable {
    let id: String
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String
}

// MARK: - Plant Database (with comprehensive descriptions for quizzes)

let plantDatabase: [Plant] = [
    Plant(
        id: "rose",
        commonName: "Rose",
        scientificName: "Rosa spp.",
        description: """
Roses are woody perennial flowering plants of the genus Rosa, in the family Rosaceae. There are over 300 species and tens of thousands of cultivars worldwide. Native to Asia, roses have been cultivated for over 5,000 years, making them one of the oldest ornamental plants.

STRUCTURE: Roses have compound leaves with 5-7 leaflets, and thorny stems called "prickles" that help protect against herbivores. The flowers typically have 5 petals in wild species, but cultivated varieties can have many more. Petals are arranged in a spiral pattern.

ROOT SYSTEM: Roses have a fibrous root system that spreads horizontally through the soil, allowing efficient water and nutrient absorption from the topsoil layer.

REPRODUCTION: Roses reproduce through seeds (found in rose hips) and can also be propagated through cuttings. They are pollinated primarily by bees attracted to their color and fragrance.

GROWING CONDITIONS: Roses prefer full sun (6+ hours daily), well-drained soil with pH 6.0-6.5, and regular watering. They bloom most prolifically in spring and fall.
""",
        icon: "🌹",
        color: "#E63946",
        difficulty: 2,
        bloomMonths: [4, 5, 6, 7, 8, 9, 10],
        rarity: .common,
        hasARModel: true,
        imageURL: nil,
        apiSearchName: "Rosa flower",
        nativeRegion: "Asia (China, Japan, Middle East)",
        availability: .seasonal,
        modelName: "rose",
        arImageReferenceName: "rose",
        scale: 1.0,
        yOffset: -0.10,
        rootType: .fibrous,
        plantParts: [
            PlantPart(id: "petals", name: "Petals", scientificName: "Tepals", function: "Attract pollinators with color and scent", modelPartName: "Petals"),
            PlantPart(id: "stem", name: "Stem", scientificName: "Caulis", function: "Supports the flower and transports water", modelPartName: "Stem"),
            PlantPart(id: "thorns", name: "Thorns/Prickles", scientificName: "Aculei", function: "Defense against herbivores", modelPartName: nil),
            PlantPart(id: "leaves", name: "Leaves", scientificName: "Folia", function: "Photosynthesis - converting sunlight to energy", modelPartName: nil)
        ],
        funFacts: [
            "Roses have been cultivated for over 5,000 years!",
            "The oldest living rose plant is over 1,000 years old in Germany.",
            "Rose oil requires 60,000 roses to make one ounce!",
            "The rose is the national flower of the United States."
        ],
        quizQuestions: [
            QuizQuestion(id: "rose_q1", question: "What is the primary function of roots?", options: ["Absorb water and minerals", "Produce seeds", "Perform photosynthesis", "Attract pollinators"], correctAnswerIndex: 0, explanation: "Roots absorb water and minerals from the soil and anchor the plant."),
            QuizQuestion(id: "rose_q2", question: "What type of root system do roses have?", options: ["Taproot", "Fibrous", "Bulb", "Adventitious"], correctAnswerIndex: 1, explanation: "Roses have fibrous roots that spread horizontally through topsoil."),
            QuizQuestion(id: "rose_q3", question: "What are the sharp parts on rose stems called?", options: ["Thorns", "Prickles", "Spines", "Needles"], correctAnswerIndex: 1, explanation: "Technically they are prickles - outgrowths of the outer layer of the stem.")
        ]
    ),

    Plant(
        id: "orchid",
        commonName: "Orchid",
        scientificName: "Orchidaceae",
        description: """
Orchids are one of the two largest families of flowering plants, with over 28,000 species found on every continent except Antarctica. They are known for their incredibly diverse and often exotic flowers, which have evolved unique relationships with specific pollinators.

STRUCTURE: Orchid flowers have three petals and three sepals. The middle petal, called the "lip" or "labellum," is often modified to attract pollinators. Many orchids are epiphytes, meaning they grow on trees without being parasitic.

ROOT SYSTEM: Orchids have adventitious roots that can grow from stems and leaves. Epiphytic orchids have aerial roots covered in velamen - a spongy tissue that absorbs moisture from the air.

REPRODUCTION: Orchids produce the smallest seeds in the plant kingdom - a single seed pod can contain millions of dust-like seeds. They require specific fungi (mycorrhiza) to germinate.

GROWING CONDITIONS: Most orchids prefer indirect light, high humidity (50-70%), and well-draining potting mix. They are native to tropical and subtropical regions worldwide.
""",
        icon: "🌸",
        color: "#A967E9",
        difficulty: 3,
        bloomMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        rarity: .common,
        hasARModel: true,
        imageURL: nil,
        apiSearchName: "Phalaenopsis orchid",
        nativeRegion: "Tropical regions worldwide",
        availability: .yearRound,
        modelName: "orchid",
        arImageReferenceName: "orchid",
        scale: 0.8,
        yOffset: -0.05,
        rootType: .adventitious,
        plantParts: [
            PlantPart(id: "petal", name: "Petals", scientificName: "Tepals", function: "Attract pollinators", modelPartName: "Flower"),
            PlantPart(id: "lip", name: "Lip/Labellum", scientificName: "Labellum", function: "Landing platform for pollinators", modelPartName: nil),
            PlantPart(id: "aerial_roots", name: "Aerial Roots", scientificName: "Radices adventitiae", function: "Absorb moisture from air", modelPartName: nil)
        ],
        funFacts: [
            "Orchids produce the tiniest seeds in the plant kingdom!",
            "Some orchids live for over 100 years.",
            "Vanilla comes from an orchid species (Vanilla planifolia).",
            "Some orchids mimic female insects to attract male pollinators."
        ],
        quizQuestions: [
            QuizQuestion(id: "orchid_q1", question: "How many orchid species exist?", options: ["About 1,000", "About 10,000", "Over 28,000", "Over 100,000"], correctAnswerIndex: 2, explanation: "Over 28,000 orchid species exist worldwide, making it one of the largest plant families."),
            QuizQuestion(id: "orchid_q2", question: "What type of root system do orchids have?", options: ["Fibrous", "Taproot", "Adventitious", "Bulb"], correctAnswerIndex: 2, explanation: "Orchids have adventitious roots that can grow from stems and absorb moisture from air."),
            QuizQuestion(id: "orchid_q3", question: "What is the modified petal that attracts pollinators called?", options: ["Sepal", "Labellum/Lip", "Stamen", "Pistil"], correctAnswerIndex: 1, explanation: "The labellum or lip is a modified petal that serves as a landing platform for pollinators.")
        ]
    ),

    Plant(
        id: "lily",
        commonName: "Lily",
        scientificName: "Lilium spp.",
        description: """
Lilies are herbaceous flowering plants that grow from bulbs. The genus Lilium contains about 100 species native to the temperate Northern Hemisphere. They are prized for their large, fragrant, and colorful flowers.

STRUCTURE: Lily flowers have six petal-like tepals (3 petals and 3 sepals that look identical), prominent stamens with large anthers, and a single pistil. The flowers can be trumpet-shaped, bowl-shaped, or recurved.

ROOT SYSTEM: Lilies grow from bulbs - underground storage organs made of fleshy scales. The bulb stores energy during dormancy and produces new growth each spring. They also develop contractile roots that pull the bulb deeper into soil.

REPRODUCTION: Lilies reproduce through seeds, bulb division, and bulbils (small bulbs that form on stems). The bright colors and strong fragrance attract butterflies and moths for pollination.

GROWING CONDITIONS: Lilies prefer full sun to partial shade, well-drained soil, and consistent moisture. Most species bloom in early to mid-summer and go dormant in winter.
""",
        icon: "⚪",
        color: "#90EE90",
        difficulty: 2,
        bloomMonths: [5, 6, 7, 8],
        rarity: .common,
        hasARModel: true,
        imageURL: nil,
        apiSearchName: "Lilium flower",
        nativeRegion: "Northern Hemisphere (Europe, Asia, North America)",
        availability: .summerOnly,
        modelName: "lilium",
        arImageReferenceName: "lilium",
        scale: 1.2,
        yOffset: -0.15,
        rootType: .bulb,
        plantParts: [
            PlantPart(id: "stamen", name: "Stamen", scientificName: "Androecium", function: "Male reproductive organ producing pollen", modelPartName: "Stamen"),
            PlantPart(id: "pistil", name: "Pistil", scientificName: "Gynoecium", function: "Female reproductive organ", modelPartName: nil),
            PlantPart(id: "bulb", name: "Bulb", scientificName: "Bulbus", function: "Underground energy storage", modelPartName: nil),
            PlantPart(id: "tepals", name: "Tepals", scientificName: "Tepala", function: "Attract pollinators", modelPartName: nil)
        ],
        funFacts: [
            "Lily pollen is bright orange-yellow and can stain clothing permanently!",
            "Some lilies can grow over 6 feet tall!",
            "The Easter Lily symbolizes purity and rebirth.",
            "Lilies are toxic to cats - even small amounts can cause kidney failure."
        ],
        quizQuestions: [
            QuizQuestion(id: "lily_q1", question: "What is the yellow powder on stamens called?", options: ["Nectar", "Pollen", "Spores", "Seeds"], correctAnswerIndex: 1, explanation: "Pollen is produced by the anthers on stamens and is essential for plant reproduction."),
            QuizQuestion(id: "lily_q2", question: "What type of underground structure do lilies grow from?", options: ["Tuber", "Corm", "Bulb", "Rhizome"], correctAnswerIndex: 2, explanation: "Lilies grow from bulbs, which are underground storage organs made of fleshy scales."),
            QuizQuestion(id: "lily_q3", question: "What is the female reproductive organ of a flower called?", options: ["Stamen", "Anther", "Pistil", "Petal"], correctAnswerIndex: 2, explanation: "The pistil is the female part, consisting of stigma, style, and ovary.")
        ]
    ),

    Plant(
        id: "daisy",
        commonName: "African Daisy",
        scientificName: "Osteospermum",
        description: """
African Daisies (Osteospermum) are flowering plants native to South Africa. Despite their common name, they are not true daisies but belong to the Asteraceae family. They are popular ornamental plants known for their vibrant colors and drought tolerance.

STRUCTURE: What appears to be a single flower is actually a composite flower head (capitulum) containing two types of florets: ray florets (colorful outer "petals") and disc florets (tiny flowers in the center). This is characteristic of the Asteraceae family.

ROOT SYSTEM: African daisies have a fibrous root system that spreads horizontally, making them efficient at capturing water in their native dry climate.

REPRODUCTION: They are pollinated by bees and butterflies attracted to their bright colors. Seeds develop in the disc florets. They can also be propagated through stem cuttings.

SPECIAL ADAPTATION: African daisies exhibit nyctinasty - their flowers close at night and during cloudy weather. This protects the reproductive parts from cold temperatures and dew.
""",
        icon: "🌼",
        color: "#FFB703",
        difficulty: 2,
        bloomMonths: [3, 4, 5, 6, 7, 8, 9, 10],
        rarity: .common,
        hasARModel: true,
        imageURL: nil,
        apiSearchName: "Osteospermum",
        nativeRegion: "South Africa",
        availability: .seasonal,
        modelName: "africandaisy",
        arImageReferenceName: "africandaisy",
        scale: 0.9,
        yOffset: -0.08,
        rootType: .fibrous,
        plantParts: [
            PlantPart(id: "ray", name: "Ray Florets", scientificName: "Flores radii", function: "Attract pollinators (look like petals)", modelPartName: nil),
            PlantPart(id: "disc", name: "Disc Florets", scientificName: "Flores disci", function: "Produce seeds (center of flower)", modelPartName: nil),
            PlantPart(id: "receptacle", name: "Receptacle", scientificName: "Receptaculum", function: "Base that holds all florets", modelPartName: nil)
        ],
        funFacts: [
            "They close their petals at night - a behavior called nyctinasty.",
            "What looks like one flower is actually hundreds of tiny flowers!",
            "They can survive with very little water (drought-tolerant).",
            "The genus name means 'bone seed' in Greek, referring to the hard seeds."
        ],
        quizQuestions: [
            QuizQuestion(id: "daisy_q1", question: "What is nyctinasty?", options: ["Growing toward light", "Closing flowers at night", "Releasing seeds", "Absorbing water"], correctAnswerIndex: 1, explanation: "Nyctinasty is the closing of flowers at night to protect reproductive parts from cold and dew."),
            QuizQuestion(id: "daisy_q2", question: "What are the colorful outer 'petals' of a daisy actually called?", options: ["True petals", "Sepals", "Ray florets", "Bracts"], correctAnswerIndex: 2, explanation: "The colorful outer parts are ray florets - individual flowers that look like petals."),
            QuizQuestion(id: "daisy_q3", question: "What plant family do daisies belong to?", options: ["Rosaceae", "Asteraceae", "Liliaceae", "Orchidaceae"], correctAnswerIndex: 1, explanation: "Daisies belong to Asteraceae, the largest family of flowering plants.")
        ]
    ),

    // MARK: - Additional Plants (No AR Models Yet)

    Plant(
        id: "sunflower",
        commonName: "Sunflower",
        scientificName: "Helianthus annuus",
        description: """
Sunflowers are iconic annual plants known for their large, bright yellow flower heads that follow the sun across the sky (heliotropism). Native to North America, they have been cultivated for over 4,500 years.

STRUCTURE: The flower head is actually composed of thousands of tiny flowers. The outer ray florets are sterile and attract pollinators, while the inner disc florets produce seeds.

ROOT SYSTEM: Sunflowers have a deep taproot that can extend 6 feet into the soil, plus lateral roots for stability.

USES: Seeds are edible and used for cooking oil. The plants can extract toxins from soil (phytoremediation).
""",
        icon: "🌻",
        color: "#FFD700",
        difficulty: 1,
        bloomMonths: [6, 7, 8, 9],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Helianthus annuus",
        nativeRegion: "North America",
        availability: .summerOnly,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .taproot,
        plantParts: [
            PlantPart(id: "ray_florets", name: "Ray Florets", scientificName: "Flores ligulati", function: "Attract pollinators", modelPartName: nil),
            PlantPart(id: "disc_florets", name: "Disc Florets", scientificName: "Flores tubulosi", function: "Produce seeds", modelPartName: nil)
        ],
        funFacts: [
            "Young sunflowers follow the sun across the sky (heliotropism).",
            "A single sunflower head can contain up to 2,000 seeds!",
            "Sunflowers can remove radioactive contaminants from soil.",
            "The tallest sunflower ever grown was over 30 feet tall!"
        ],
        quizQuestions: [
            QuizQuestion(id: "sunflower_q1", question: "What is heliotropism?", options: ["Growing in shade", "Following the sun", "Blooming at night", "Growing toward water"], correctAnswerIndex: 1, explanation: "Heliotropism is the movement of plants to follow the sun across the sky.")
        ]
    ),

    Plant(
        id: "tulip",
        commonName: "Tulip",
        scientificName: "Tulipa spp.",
        description: """
Tulips are spring-blooming perennial bulbs native to Central Asia. They became famous during the Dutch Golden Age, when "Tulip Mania" made some bulbs worth more than houses!

STRUCTURE: Tulips have cup-shaped flowers with six petals in nearly every color. Each bulb produces one stem with 2-6 leaves.

ROOT SYSTEM: Like lilies, tulips grow from bulbs that store energy through winter dormancy.

BLOOMING: Tulips require a cold period (vernalization) to bloom. They flower for 1-2 weeks in spring.
""",
        icon: "🌷",
        color: "#FF6B6B",
        difficulty: 2,
        bloomMonths: [3, 4, 5],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Tulipa",
        nativeRegion: "Central Asia (Turkey, Afghanistan)",
        availability: .springOnly,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .bulb,
        plantParts: [
            PlantPart(id: "petals", name: "Petals", scientificName: "Tepala", function: "Attract pollinators", modelPartName: nil),
            PlantPart(id: "bulb", name: "Bulb", scientificName: "Bulbus", function: "Store nutrients for next season", modelPartName: nil)
        ],
        funFacts: [
            "During Tulip Mania (1637), one bulb sold for 10x a craftsman's annual income!",
            "Tulips continue to grow after being cut.",
            "There are over 3,000 registered varieties of tulips.",
            "Tulip petals are edible and taste like lettuce!"
        ],
        quizQuestions: [
            QuizQuestion(id: "tulip_q1", question: "What do tulips need to bloom?", options: ["Constant heat", "A cold period", "Salty soil", "Full shade"], correctAnswerIndex: 1, explanation: "Tulips require vernalization - a cold period - to trigger blooming.")
        ]
    ),

    Plant(
        id: "lavender",
        commonName: "Lavender",
        scientificName: "Lavandula",
        description: """
Lavender is a fragrant flowering plant in the mint family, native to the Mediterranean region. It's prized for its aromatic flowers and essential oils.

STRUCTURE: Small purple flowers grow in whorls on spikes above silvery-green foliage. The entire plant is aromatic.

ROOT SYSTEM: Lavender has a taproot system that allows it to access deep water sources, making it drought-tolerant.

USES: Used in aromatherapy, cooking, cosmetics, and as a natural insect repellent.
""",
        icon: "💜",
        color: "#9B59B6",
        difficulty: 2,
        bloomMonths: [6, 7, 8],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Lavandula",
        nativeRegion: "Mediterranean",
        availability: .summerOnly,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .taproot,
        plantParts: [
            PlantPart(id: "flower_spike", name: "Flower Spike", scientificName: "Spica", function: "Hold flowers for pollination", modelPartName: nil),
            PlantPart(id: "leaves", name: "Leaves", scientificName: "Folia", function: "Produce essential oils", modelPartName: nil)
        ],
        funFacts: [
            "Lavender oil has been used for over 2,500 years.",
            "Romans used lavender to scent their baths - 'lavare' means 'to wash' in Latin.",
            "Lavender can repel mosquitoes, moths, and flies.",
            "Bees love lavender and produce delicious lavender honey!"
        ],
        quizQuestions: [
            QuizQuestion(id: "lavender_q1", question: "What plant family does lavender belong to?", options: ["Rose family", "Mint family", "Daisy family", "Lily family"], correctAnswerIndex: 1, explanation: "Lavender is in the Lamiaceae (mint) family.")
        ]
    ),

    Plant(
        id: "cactus",
        commonName: "Cactus",
        scientificName: "Cactaceae",
        description: """
Cacti are succulent plants native to the Americas, adapted to survive in extremely arid conditions. There are about 2,000 species ranging from small button cacti to towering saguaros.

STRUCTURE: Cacti have thick, fleshy stems that store water. Leaves have evolved into spines that reduce water loss and protect from predators.

ROOT SYSTEM: Most cacti have shallow, widespread fibrous roots that can quickly absorb rain before it evaporates.

ADAPTATION: Cacti perform CAM photosynthesis - opening their stomata only at night to reduce water loss.
""",
        icon: "🌵",
        color: "#2ECC71",
        difficulty: 1,
        bloomMonths: [4, 5, 6],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Opuntia cactus",
        nativeRegion: "Americas (North & South America)",
        availability: .yearRound,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .fibrous,
        plantParts: [
            PlantPart(id: "spines", name: "Spines", scientificName: "Spinae", function: "Protection and reduce water loss", modelPartName: nil),
            PlantPart(id: "stem", name: "Stem", scientificName: "Caulis", function: "Water storage and photosynthesis", modelPartName: nil)
        ],
        funFacts: [
            "The saguaro cactus can live for 200 years!",
            "Cacti can survive years without rain.",
            "Some cacti bloom only once per year, for just one night.",
            "The largest cactus can grow over 60 feet tall and weigh tons!"
        ],
        quizQuestions: [
            QuizQuestion(id: "cactus_q1", question: "What are cactus spines actually modified versions of?", options: ["Stems", "Roots", "Leaves", "Flowers"], correctAnswerIndex: 2, explanation: "Cactus spines are highly modified leaves that reduce water loss.")
        ]
    ),

    Plant(
        id: "hibiscus",
        commonName: "Hibiscus",
        scientificName: "Hibiscus rosa-sinensis",
        description: """
Hibiscus is a tropical flowering plant famous for its large, colorful, trumpet-shaped flowers. Native to tropical Asia, it's the national flower of Malaysia.

STRUCTURE: Flowers can be 4-8 inches across, with five overlapping petals and a prominent central column of fused stamens (staminal column).

ROOT SYSTEM: Hibiscus has a fibrous root system that spreads horizontally near the surface.

USES: Used for tea (hibiscus tea), traditional medicine, and as a natural hair conditioner in many cultures.
""",
        icon: "🌺",
        color: "#E74C3C",
        difficulty: 2,
        bloomMonths: [5, 6, 7, 8, 9, 10],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Hibiscus rosa-sinensis",
        nativeRegion: "Tropical Asia",
        availability: .seasonal,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .fibrous,
        plantParts: [
            PlantPart(id: "petals", name: "Petals", scientificName: "Petala", function: "Attract pollinators", modelPartName: nil),
            PlantPart(id: "staminal_column", name: "Staminal Column", scientificName: "Columna staminalis", function: "Fused male reproductive parts", modelPartName: nil)
        ],
        funFacts: [
            "Hibiscus flowers typically last only one day!",
            "Hibiscus tea is naturally caffeine-free and rich in vitamin C.",
            "In Hawaii, wearing a hibiscus behind your left ear means you're taken.",
            "Some hibiscus flowers can change color as they age!"
        ],
        quizQuestions: [
            QuizQuestion(id: "hibiscus_q1", question: "How long do hibiscus flowers typically last?", options: ["One week", "One month", "One day", "One hour"], correctAnswerIndex: 2, explanation: "Most hibiscus flowers bloom for just one day before wilting.")
        ]
    ),

    Plant(
        id: "jasmine",
        commonName: "Jasmine",
        scientificName: "Jasminum",
        description: """
Jasmine is a genus of fragrant flowering plants in the olive family, native to tropical and warm temperate regions. Known for its intensely sweet fragrance, especially at night.

STRUCTURE: Small, star-shaped flowers with 5-9 petals, usually white or yellow. Many species are climbing vines.

ROOT SYSTEM: Jasmine has a fibrous root system that can become quite extensive as the plant matures.

USES: Used in perfumes, jasmine tea, religious ceremonies, and aromatherapy. The scent is strongest at night.
""",
        icon: "⭐",
        color: "#F8F9FA",
        difficulty: 2,
        bloomMonths: [4, 5, 6, 7, 8, 9],
        rarity: .uncommon,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Jasminum",
        nativeRegion: "Tropical Asia, Middle East",
        availability: .seasonal,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .fibrous,
        plantParts: [
            PlantPart(id: "flowers", name: "Flowers", scientificName: "Flores", function: "Attract night-flying pollinators", modelPartName: nil),
            PlantPart(id: "vines", name: "Climbing Vines", scientificName: "Scandentes", function: "Reach sunlight by climbing structures", modelPartName: nil)
        ],
        funFacts: [
            "Jasmine is the national flower of Pakistan, Philippines, and Indonesia.",
            "It takes 8,000 jasmine flowers to produce 1ml of essential oil!",
            "Jasmine releases most of its fragrance at night.",
            "Cleopatra reportedly used jasmine oil to seduce Mark Antony."
        ],
        quizQuestions: [
            QuizQuestion(id: "jasmine_q1", question: "When is jasmine most fragrant?", options: ["Morning", "Noon", "Night", "Afternoon"], correctAnswerIndex: 2, explanation: "Jasmine releases most of its fragrance at night to attract night-flying pollinators.")
        ]
    ),

    Plant(
        id: "monstera",
        commonName: "Monstera",
        scientificName: "Monstera deliciosa",
        description: """
Monstera, also known as the Swiss Cheese Plant, is a tropical climbing plant famous for its large, fenestrated (hole-filled) leaves. Native to Central American rainforests.

STRUCTURE: Leaves can grow over 3 feet wide with characteristic splits and holes (fenestrations) that help the plant withstand heavy tropical rain.

ROOT SYSTEM: Monstera has both underground roots and aerial roots that help it climb trees and absorb moisture from the air.

ADAPTATION: The leaf holes are thought to help leaves resist wind damage and allow light to reach lower leaves.
""",
        icon: "🍃",
        color: "#27AE60",
        difficulty: 2,
        bloomMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Monstera deliciosa",
        nativeRegion: "Central America (Mexico, Panama)",
        availability: .yearRound,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .adventitious,
        plantParts: [
            PlantPart(id: "fenestrated_leaves", name: "Fenestrated Leaves", scientificName: "Folia fenestrata", function: "Photosynthesis and wind resistance", modelPartName: nil),
            PlantPart(id: "aerial_roots", name: "Aerial Roots", scientificName: "Radices adventitiae", function: "Climbing and moisture absorption", modelPartName: nil)
        ],
        funFacts: [
            "The holes in Monstera leaves develop as the plant matures.",
            "Wild Monstera can produce edible fruit that tastes like pineapple-banana!",
            "Monstera can grow over 60 feet tall in the wild.",
            "It's one of the most popular houseplants in the world!"
        ],
        quizQuestions: [
            QuizQuestion(id: "monstera_q1", question: "What are the holes in Monstera leaves called?", options: ["Perforations", "Fenestrations", "Vacuoles", "Stomata"], correctAnswerIndex: 1, explanation: "The holes are called fenestrations, from the Latin word for window.")
        ]
    ),

    Plant(
        id: "bamboo",
        commonName: "Bamboo",
        scientificName: "Bambusoideae",
        description: """
Bamboo is a fast-growing grass (not a tree!) with over 1,400 species. Some species can grow up to 35 inches per day, making it the fastest-growing plant on Earth.

STRUCTURE: Hollow, jointed stems (culms) with nodes. Despite being a grass, bamboo can grow over 100 feet tall.

ROOT SYSTEM: Bamboo has an extensive rhizome (underground stem) system that can spread rapidly, with fibrous roots growing from the rhizomes.

USES: Construction, textiles, food (bamboo shoots), paper, and musical instruments. It's also a major food source for pandas.
""",
        icon: "🎋",
        color: "#7CB342",
        difficulty: 1,
        bloomMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Bambusa",
        nativeRegion: "Asia, Americas, Africa, Australia",
        availability: .yearRound,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .fibrous,
        plantParts: [
            PlantPart(id: "culm", name: "Culm", scientificName: "Culmus", function: "Main stem for support and transport", modelPartName: nil),
            PlantPart(id: "rhizome", name: "Rhizome", scientificName: "Rhizoma", function: "Underground stem for spreading", modelPartName: nil)
        ],
        funFacts: [
            "Bamboo can grow 35 inches in a single day!",
            "Bamboo releases 35% more oxygen than equivalent trees.",
            "Some bamboo species flower only once every 120 years!",
            "Bamboo is stronger than steel in tensile strength."
        ],
        quizQuestions: [
            QuizQuestion(id: "bamboo_q1", question: "What type of plant is bamboo?", options: ["Tree", "Fern", "Grass", "Vine"], correctAnswerIndex: 2, explanation: "Despite its tree-like appearance, bamboo is actually a grass.")
        ]
    ),

    Plant(
        id: "fern",
        commonName: "Fern",
        scientificName: "Polypodiopsida",
        description: """
Ferns are ancient plants that appeared over 360 million years ago, predating dinosaurs. They reproduce via spores rather than seeds, making them fundamentally different from flowering plants.

STRUCTURE: Ferns have fronds (leaves) that unfurl from coiled fiddleheads. Spores are produced in clusters (sori) on the undersides of fronds.

ROOT SYSTEM: Ferns have fibrous roots growing from a rhizome (horizontal stem). Some tropical ferns are epiphytic, growing on trees.

EVOLUTION: Ferns once dominated Earth's forests. Fossil ferns from the Carboniferous period became coal deposits.
""",
        icon: "🌿",
        color: "#1E8449",
        difficulty: 2,
        bloomMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Boston fern",
        nativeRegion: "Worldwide (especially tropical regions)",
        availability: .yearRound,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .fibrous,
        plantParts: [
            PlantPart(id: "frond", name: "Frond", scientificName: "Frons", function: "Photosynthesis and spore production", modelPartName: nil),
            PlantPart(id: "sori", name: "Sori", scientificName: "Sori", function: "Clusters that produce spores", modelPartName: nil),
            PlantPart(id: "fiddlehead", name: "Fiddlehead", scientificName: "Circinate vernation", function: "Coiled young frond", modelPartName: nil)
        ],
        funFacts: [
            "Ferns are older than dinosaurs - over 360 million years old!",
            "Ferns don't have seeds or flowers - they reproduce with spores.",
            "Some fern fronds can grow over 15 feet long!",
            "Fiddleheads (young fern fronds) are edible in some species."
        ],
        quizQuestions: [
            QuizQuestion(id: "fern_q1", question: "How do ferns reproduce?", options: ["Seeds", "Bulbs", "Spores", "Runners"], correctAnswerIndex: 2, explanation: "Ferns reproduce through spores, which are produced on the undersides of fronds.")
        ]
    ),

    Plant(
        id: "succulent",
        commonName: "Succulent",
        scientificName: "Various genera",
        description: """
Succulents are plants with thickened, fleshy tissues adapted to store water. Found in over 60 plant families, they've evolved independently in many different lineages.

STRUCTURE: Thick leaves, stems, or roots store water. Many have waxy coatings (cuticle) to reduce water loss. Some, like Echeveria, form rosettes.

ROOT SYSTEM: Most succulents have shallow, fibrous root systems that spread widely to capture any available moisture quickly.

ADAPTATION: Like cacti, many succulents use CAM photosynthesis to minimize water loss in arid environments.
""",
        icon: "🪴",
        color: "#48C9B0",
        difficulty: 1,
        bloomMonths: [3, 4, 5, 6, 7, 8],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Echeveria",
        nativeRegion: "Arid regions worldwide",
        availability: .yearRound,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .fibrous,
        plantParts: [
            PlantPart(id: "fleshy_leaves", name: "Fleshy Leaves", scientificName: "Folia succulenta", function: "Water storage", modelPartName: nil),
            PlantPart(id: "rosette", name: "Rosette", scientificName: "Rosula", function: "Efficient light capture", modelPartName: nil)
        ],
        funFacts: [
            "Succulents can survive months without water!",
            "Many succulents can grow new plants from a single leaf.",
            "Aloe vera is one of the most famous succulents.",
            "Some succulents can live for over 100 years!"
        ],
        quizQuestions: [
            QuizQuestion(id: "succulent_q1", question: "What makes a plant a succulent?", options: ["Large flowers", "Water-storing tissues", "Thorns", "Climbing vines"], correctAnswerIndex: 1, explanation: "Succulents are defined by their fleshy, water-storing tissues.")
        ]
    ),

    Plant(
        id: "peace_lily",
        commonName: "Peace Lily",
        scientificName: "Spathiphyllum",
        description: """
Peace Lilies are popular houseplants known for their elegant white flowers and air-purifying abilities. Native to tropical Americas and Southeast Asia.

STRUCTURE: The white "petal" is actually a modified leaf (spathe) surrounding a spike of tiny flowers (spadix). Glossy dark green leaves grow from the base.

ROOT SYSTEM: Peace lilies have fibrous roots that grow from a rhizome. They prefer to be slightly root-bound.

AIR PURIFICATION: NASA research found peace lilies can remove toxins like benzene, formaldehyde, and carbon monoxide from indoor air.
""",
        icon: "☮️",
        color: "#FDFEFE",
        difficulty: 1,
        bloomMonths: [3, 4, 5, 6, 7, 8, 9],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Spathiphyllum",
        nativeRegion: "Tropical Americas, Southeast Asia",
        availability: .yearRound,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .fibrous,
        plantParts: [
            PlantPart(id: "spathe", name: "Spathe", scientificName: "Spatha", function: "Modified leaf that attracts pollinators", modelPartName: nil),
            PlantPart(id: "spadix", name: "Spadix", scientificName: "Spadix", function: "Spike containing tiny true flowers", modelPartName: nil)
        ],
        funFacts: [
            "The white 'flower' is actually a modified leaf!",
            "Peace lilies are one of NASA's top air-purifying plants.",
            "They can tell you when they're thirsty - leaves droop dramatically.",
            "Despite the name, they're not true lilies (and are toxic to cats)."
        ],
        quizQuestions: [
            QuizQuestion(id: "peace_lily_q1", question: "What is the white 'petal' of a peace lily?", options: ["True petal", "Modified leaf (spathe)", "Sepal", "Stamen"], correctAnswerIndex: 1, explanation: "The white part is a spathe - a modified leaf that surrounds the actual flowers.")
        ]
    ),

    Plant(
        id: "pothos",
        commonName: "Pothos",
        scientificName: "Epipremnum aureum",
        description: """
Pothos (also called Devil's Ivy) is one of the easiest houseplants to grow, tolerating low light and irregular watering. Native to Southeast Asia.

STRUCTURE: Heart-shaped leaves on long, trailing vines. Leaves can be solid green or variegated with white, yellow, or silver.

ROOT SYSTEM: Pothos develops both soil roots and aerial roots along its stems, which help it climb in the wild.

ADAPTATION: Pothos can survive in water alone, making it perfect for hydroponic growing. Nearly impossible to kill!
""",
        icon: "💚",
        color: "#58D68D",
        difficulty: 1,
        bloomMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Epipremnum aureum",
        nativeRegion: "Southeast Asia (Mo'orea, French Polynesia)",
        availability: .yearRound,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .adventitious,
        plantParts: [
            PlantPart(id: "heart_leaves", name: "Heart-shaped Leaves", scientificName: "Folia cordata", function: "Photosynthesis", modelPartName: nil),
            PlantPart(id: "aerial_roots", name: "Aerial Roots", scientificName: "Radices adventitiae", function: "Climbing and moisture absorption", modelPartName: nil)
        ],
        funFacts: [
            "Pothos is called 'Devil's Ivy' because it's nearly impossible to kill!",
            "It can grow in just water - no soil needed.",
            "A single cutting can grow into a full plant.",
            "In the wild, pothos leaves can grow over 3 feet long!"
        ],
        quizQuestions: [
            QuizQuestion(id: "pothos_q1", question: "Why is pothos called 'Devil's Ivy'?", options: ["It's poisonous", "It's hard to kill", "It grows in dark places", "It has thorns"], correctAnswerIndex: 1, explanation: "Pothos earned the nickname because it's extremely resilient and hard to kill.")
        ]
    ),

    Plant(
        id: "snake_plant",
        commonName: "Snake Plant",
        scientificName: "Dracaena trifasciata",
        description: """
Snake Plant (also known as Mother-in-Law's Tongue) is a nearly indestructible houseplant with striking, upright sword-shaped leaves. Native to West Africa.

STRUCTURE: Stiff, upright leaves with distinctive horizontal stripes. Leaves grow directly from underground rhizomes.

ROOT SYSTEM: Snake plants spread via rhizomes and have fibrous roots. They're prone to root rot if overwatered.

UNIQUE TRAIT: Unlike most plants, snake plants release oxygen at night (due to CAM photosynthesis), making them ideal bedroom plants.
""",
        icon: "🐍",
        color: "#1D8348",
        difficulty: 1,
        bloomMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Dracaena trifasciata",
        nativeRegion: "West Africa",
        availability: .yearRound,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .fibrous,
        plantParts: [
            PlantPart(id: "sword_leaves", name: "Sword-shaped Leaves", scientificName: "Folia ensiformia", function: "Photosynthesis and water storage", modelPartName: nil),
            PlantPart(id: "rhizome", name: "Rhizome", scientificName: "Rhizoma", function: "Underground stem for spreading", modelPartName: nil)
        ],
        funFacts: [
            "Snake plants produce oxygen at night - perfect for bedrooms!",
            "They can go weeks without water.",
            "NASA listed snake plants as top air purifiers.",
            "The name 'Mother-in-Law's Tongue' refers to the sharp leaf tips!"
        ],
        quizQuestions: [
            QuizQuestion(id: "snake_plant_q1", question: "What makes snake plants unique at night?", options: ["They close up", "They release oxygen", "They glow", "They grow faster"], correctAnswerIndex: 1, explanation: "Snake plants perform CAM photosynthesis, releasing oxygen at night unlike most plants.")
        ]
    ),

    Plant(
        id: "aloe_vera",
        commonName: "Aloe Vera",
        scientificName: "Aloe vera",
        description: """
Aloe Vera is a succulent plant famous for its medicinal gel, used for thousands of years to treat burns, wounds, and skin conditions. Likely native to the Arabian Peninsula.

STRUCTURE: Thick, fleshy leaves arranged in a rosette. The clear gel inside leaves contains beneficial compounds including vitamins, minerals, and antioxidants.

ROOT SYSTEM: Aloe has a shallow, fibrous root system typical of succulents, allowing quick absorption of rare desert rainfall.

USES: The gel is used for burns, sunburns, moisturizers, and drinks. The latex (yellow layer) has laxative properties.
""",
        icon: "🧴",
        color: "#76D7C4",
        difficulty: 1,
        bloomMonths: [3, 4, 5, 6, 7, 8],
        rarity: .common,
        hasARModel: false,
        imageURL: nil,
        apiSearchName: "Aloe vera",
        nativeRegion: "Arabian Peninsula",
        availability: .yearRound,
        modelName: "",
        arImageReferenceName: "",
        scale: 1.0,
        yOffset: 0,
        rootType: .fibrous,
        plantParts: [
            PlantPart(id: "gel", name: "Gel", scientificName: "Gel", function: "Water storage and medicinal compounds", modelPartName: nil),
            PlantPart(id: "latex", name: "Latex Layer", scientificName: "Latex", function: "Yellow layer with different properties", modelPartName: nil)
        ],
        funFacts: [
            "Cleopatra used aloe vera as part of her beauty regimen!",
            "Aloe vera has been called 'the plant of immortality'.",
            "It contains over 75 active compounds!",
            "Ancient Egyptians called it 'the plant of immortality'."
        ],
        quizQuestions: [
            QuizQuestion(id: "aloe_q1", question: "What part of aloe vera is commonly used for burns?", options: ["Roots", "Clear gel", "Flowers", "Spines"], correctAnswerIndex: 1, explanation: "The clear gel inside aloe leaves contains compounds that soothe burns and promote healing.")
        ]
    )
]

// MARK: - Global Helper Functions

func plantByID(_ id: String) -> Plant? {
    plantDatabase.first { $0.id == id }
}

func plantByModelName(_ modelName: String) -> Plant? {
    plantDatabase.first { $0.modelName == modelName }
}

func plantByCommonName(_ name: String) -> Plant? {
    plantDatabase.first { $0.commonName.lowercased() == name.lowercased() }
}

func getPlantOfTheDay() -> Plant {
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    let index = (dayOfYear - 1) % plantDatabase.count
    return plantDatabase[index]
}

func searchPlants(query: String) -> [Plant] {
    let q = query.lowercased().trimmingCharacters(in: .whitespaces)
    if q.isEmpty { return plantDatabase }
    return plantDatabase.filter {
        $0.commonName.lowercased().contains(q) ||
        $0.scientificName.lowercased().contains(q) ||
        $0.description.lowercased().contains(q)
    }
}
