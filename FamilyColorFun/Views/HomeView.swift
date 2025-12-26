import SwiftUI

struct HomeView: View {
    let categories = Category.all
    @State private var showSettings = false
    @State private var showPhotoUpload = false
    @State private var navigateToUserPage: UserGeneratedPage?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with decorations
                    categoryHeader
                        .padding(.top, 8)

                    // Upload Photo Card
                    uploadPhotoCard
                        .padding(.horizontal, 16)

                    // Category Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(categories) { category in
                            NavigationLink(destination: CategoryView(category: category)) {
                                CuteCategoryCard(category: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color.orange.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                        SoundManager.shared.playTap()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPhotoUpload) {
                PhotoUploadView { page in
                    navigateToUserPage = page
                }
            }
            .fullScreenCover(item: $navigateToUserPage) { page in
                NavigationStack {
                    CanvasView(page: page.toColoringPage(), category: .myCreations)
                }
            }
        }
    }

    // MARK: - Header with Decorations
    private var categoryHeader: some View {
        HStack(spacing: 12) {
            // Left rainbow
            Text("🌈")
                .font(.system(size: 32))

            VStack(spacing: 4) {
                Text("Choose a")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Text("Category")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            // Right rainbow
            Text("🌈")
                .font(.system(size: 32))
        }
        .padding(.vertical, 8)
    }

    // MARK: - Upload Photo Card
    private var uploadPhotoCard: some View {
        Button {
            showPhotoUpload = true
            SoundManager.shared.playTap()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Your Own!")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Turn any photo into a coloring page")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.pink.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.pink.opacity(0.1), .pink.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.pink.opacity(0.3), .pink.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cute Category Card
struct CuteCategoryCard: View {
    let category: Category
    @State private var isPressed = false

    // Define gradient colors for each category type
    private var gradientColors: [Color] {
        switch category.name {
        case "Animals":
            return [Color(hex: "4ECDC4"), Color(hex: "44A08D")]
        case "Dinosaurs":
            return [Color(hex: "11998E"), Color(hex: "38EF7D")]
        case "Vehicles":
            return [Color(hex: "FC4A1A"), Color(hex: "F7B733")]
        case "Fantasy":
            return [Color(hex: "8E2DE2"), Color(hex: "4A00E0")]
        case "Nature":
            return [Color(hex: "56AB2F"), Color(hex: "A8E063")]
        case "Ocean", "Underwater":
            return [Color(hex: "2193B0"), Color(hex: "6DD5ED")]
        case "Space":
            return [Color(hex: "0F2027"), Color(hex: "2C5364")]
        case "Food":
            return [Color(hex: "FF416C"), Color(hex: "FF4B2B")]
        case "Houses":
            return [Color(hex: "834D9B"), Color(hex: "D04ED6")]
        case "Mandalas", "Zen Patterns":
            return [Color(hex: "5433FF"), Color(hex: "20BDFF")]
        case "Geometric", "Abstract":
            return [Color(hex: "C33764"), Color(hex: "1D2671")]
        case "Retro 90s":
            return [Color(hex: "FF0099"), Color(hex: "493240")]
        case "Holidays":
            return [Color(hex: "D4145A"), Color(hex: "FBB03B")]
        case "Sports":
            return [Color(hex: "11998E"), Color(hex: "38EF7D")]
        case "Music":
            return [Color(hex: "7F00FF"), Color(hex: "E100FF")]
        case "Robots":
            return [Color(hex: "636363"), Color(hex: "A2AB58")]
        case "Portraits":
            return [Color(hex: "FF9966"), Color(hex: "FF5E62")]
        default:
            return [category.color, category.color.opacity(0.7)]
        }
    }

    // Cute emoji icon for each category
    private var categoryEmoji: String {
        switch category.name {
        case "Animals": return "🦁"
        case "Dinosaurs": return "🦕"
        case "Vehicles": return "🚗"
        case "Fantasy": return "🦄"
        case "Nature": return "🌸"
        case "Ocean": return "🐠"
        case "Underwater": return "🐙"
        case "Space": return "🚀"
        case "Food": return "🧁"
        case "Houses": return "🏠"
        case "Mandalas": return "🌀"
        case "Zen Patterns": return "☯️"
        case "Geometric": return "💎"
        case "Abstract": return "🎨"
        case "Retro 90s": return "📼"
        case "Holidays": return "🎄"
        case "Sports": return "⚽"
        case "Music": return "🎸"
        case "Robots": return "🤖"
        case "Portraits": return "👤"
        default: return "🎨"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Emoji icon with white circle background
            ZStack {
                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 70, height: 70)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                Text(categoryEmoji)
                    .font(.system(size: 38))
            }

            // Category name
            Text(category.name)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // Page count
            Text("\(category.pages.count) coloring pages")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            // Subtle inner glow
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.3), lineWidth: 2)
                .blur(radius: 1)
        )
        .shadow(color: gradientColors[0].opacity(0.4), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    HomeView()
}
