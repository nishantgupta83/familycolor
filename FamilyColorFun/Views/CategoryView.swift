import SwiftUI

struct CategoryView: View {
    let category: Category

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(category.pages) { page in
                    NavigationLink(destination: CanvasView(page: page, category: category)) {
                        PageThumbnail(page: page, accentColor: category.color)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

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
