import SwiftUI
import UniformTypeIdentifiers

/// 图片选择组件
struct ImagePickerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedImage: NSImage?
    @State private var isShowingFilePicker = false

    let onComplete: (Data) -> Void
    let onCancel: (() -> Void)?

    init(onComplete: @escaping (Data) -> Void, onCancel: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 24) {
            // 标题
            Text("选择图片")
                .font(.headline)

            // 图片预览
            if let image = selectedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 300, height: 200)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)

                            Text("选择图片或拖放到此处")
                                .foregroundColor(.secondary)
                        }
                    }
            }

            // 按钮
            HStack(spacing: 16) {
                Button("取消") {
                    onCancel?()
                    dismiss()
                }

                Button("选择文件") {
                    isShowingFilePicker = true
                }

                Button("完成") {
                    handleComplete()
                }
                .disabled(selectedImage == nil)
            }
        }
        .padding(32)
        .frame(width: 400, height: 450)
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            loadImage(from: url)

        case .failure(let error):
            print("❌ 选择文件失败：\(error)")
        }
    }

    private func loadImage(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        if let data = try? Data(contentsOf: url),
           let image = NSImage(data: data) {
            selectedImage = image
        }
    }

    private func handleComplete() {
        guard let image = selectedImage,
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [:]) else {
            return
        }

        onComplete(jpegData)
        dismiss()
    }
}

// MARK: - Preview
// Removed due to init ambiguity
