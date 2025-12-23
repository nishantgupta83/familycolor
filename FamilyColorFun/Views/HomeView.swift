import SwiftUI

struct HomeView: View {
    let categories = Category.all
    @State private var showSettings = false
    @State private var showPhotoUpload = false
    @State private var navigateToUserPage: UserGeneratedPage?

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Upload Photo Card
                    uploadPhotoCard
                        .padding(.horizontal, 20)

                    // Category Grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(categories) { category in
                            NavigationLink(destination: CategoryView(category: category)) {
                                CategoryCard(category: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Color Fun")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                        SoundManager.shared.playTap()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
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

    private var uploadPhotoCard: some View {
        Button {
            showPhotoUpload = true
            SoundManager.shared.playTap()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)

                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Upload Photo")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Turn your photo into a coloring page")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CategoryCard: View {
    let category: Category
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: category.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(category.color)
            }

            Text(category.name)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
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
