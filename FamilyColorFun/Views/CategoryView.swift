import SwiftUI

struct CategoryView: View {
    let category: Category
    @ObservedObject private var progression = ProgressionEngine.shared

    @State private var showUnlockSheet = false
    @State private var selectedPageIndex: Int?
    @State private var showParentGate = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            // Stars header
            StarsHeader(stars: progression.stars)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(category.pages.enumerated()), id: \.element.id) { index, page in
                    let isLocked = !progression.isUnlocked(
                        categoryId: category.categoryId,
                        index: index
                    )

                    ZStack {
                        NavigationLink(destination: CanvasView(page: page, category: category)) {
                            PageThumbnail(page: page, accentColor: category.color)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLocked)

                        if isLocked {
                            LockedPageOverlay(unlockCost: ProgressionEngine.costPerPage)
                                .onTapGesture {
                                    selectedPageIndex = index
                                    showUnlockSheet = true
                                    SoundManager.shared.playTap()
                                }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showUnlockSheet) {
            if let index = selectedPageIndex, index < category.pages.count {
                let page = category.pages[index]
                UnlockSheetContainer(
                    page: page,
                    categoryId: category.categoryId,
                    pageIndex: index,
                    onDismiss: { showUnlockSheet = false },
                    onAskParent: {
                        showUnlockSheet = false
                        showParentGate = true
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showParentGate) {
            ParentGateView()
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Stars Header

struct StarsHeader: View {
    let stars: Int

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(stars)")
                    .font(.headline.bold())
                Text("stars")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
            )

            Spacer()
        }
    }
}

// MARK: - Unlock Sheet Container

struct UnlockSheetContainer: View {
    let page: ColoringPage
    let categoryId: String
    let pageIndex: Int
    let onDismiss: () -> Void
    let onAskParent: () -> Void

    @ObservedObject private var progression = ProgressionEngine.shared

    var body: some View {
        VStack {
            Spacer()
            UnlockSheet(
                pageName: page.name,
                unlockCost: ProgressionEngine.costPerPage,
                availableStars: progression.stars,
                onUnlock: {
                    if progression.unlockPage(categoryId: categoryId, index: pageIndex) {
                        SoundManager.shared.playCelebration()
                        onDismiss()
                    }
                },
                onDismiss: onDismiss,
                onAskParent: onAskParent
            )
            Spacer()
        }
        .background(Color.black.opacity(0.001)) // Tap area
    }
}

// MARK: - Placeholder Parent Gate

struct ParentGateView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Parent Zone")
                .font(.title.bold())

            Text("This area is for parents only.\nComing soon!")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Page Thumbnail

struct PageThumbnail: View {
    let page: ColoringPage
    let accentColor: Color
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .aspectRatio(1, contentMode: .fit)

                // Try to load actual image, fallback to placeholder
                if let uiImage = UIImage(named: page.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                } else {
                    // Placeholder icon if image not found
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(accentColor.opacity(0.3))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accentColor.opacity(0.3), lineWidth: 2)
            )

            Text(page.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
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
    NavigationStack {
        CategoryView(category: Category.all[0])
    }
}
