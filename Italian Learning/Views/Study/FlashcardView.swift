import SwiftUI

struct FlashcardView: View {
    let card: Flashcard
    @Binding var isFlipped: Bool

    @AppStorage("showPolishOnFront") private var showPolishOnFront: Bool = true
    
    var body: some View {
        ZStack {
            Group {
                if showPolishOnFront {
                    CardFace(text: card.back, subtitle: "Polski", example: card.example)
                } else {
                    CardFace(text: card.front, subtitle: "Włoski")
                }
            }
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            
            Group {
                if showPolishOnFront {
                    CardFace(text: card.front, subtitle: "Włoski")
                } else {
                    CardFace(text: card.back, subtitle: "Polski", example: card.example)
                }
            }
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 400)
    }
}

struct CardFace: View {
    var text: String
    var subtitle: String
    var example: String? = nil
    
    var body: some View {
        VStack {
            Text(subtitle.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.top, 30)
            
            Spacer()
            
            Text(text)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .padding(.horizontal)
            
            if let example = example, !example.isEmpty {
                Text(example)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Image(systemName: "hand.tap.fill")
                .foregroundColor(Color.gray.opacity(0.3))
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
    }
}

struct StudyButton: View {
    var title: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
