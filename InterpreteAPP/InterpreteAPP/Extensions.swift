//
//  Extensions.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import SwiftUI
import Foundation

// MARK: - Extensiones de Color
extension Color {
    static let backgroundGradientStart = Color(.systemBackground)
    static let backgroundGradientEnd = Color(.systemGray6).opacity(0.3)
    static let bubbleUserStart = Color.blue
    static let bubbleUserEnd = Color.blue.opacity(0.8)
    static let bubbleAssistantBackground = Color(.systemGray6)
    static let assistantAvatarStart = Color.purple
    static let assistantAvatarEnd = Color.blue
    
    // Colores personalizados
    static let accentBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let softGray = Color(red: 0.96, green: 0.96, blue: 0.96)
    static let warmWhite = Color(red: 0.99, green: 0.99, blue: 0.99)
}

// MARK: - Extensiones de View
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func cardStyle() -> some View {
        self
            .background(Color.warmWhite)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    func pulseAnimation() -> some View {
        self
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
    }
}

// MARK: - Extensiones de Animation
extension Animation {
    static let smoothBounce = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    static let quickFade = Animation.easeInOut(duration: 0.2)
    static let slowFade = Animation.easeInOut(duration: 0.5)
}

// MARK: - Extensiones de String
extension String {
    var isValidText: Bool {
        return !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func truncated(toLength length: Int) -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + "..."
    }
    
    var wordCount: Int {
        return self.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    func estimatedReadingTime() -> String {
        let wordsPerMinute = 200
        let words = self.wordCount
        let minutes = max(1, words / wordsPerMinute)
        return "\(minutes) min de lectura"
    }
}

// MARK: - Extensiones de UIImage
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? self
    }
    
    func compressedData(quality: CGFloat = 0.8) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
    
    var sizeInMB: Double {
        guard let data = self.compressedData() else { return 0 }
        return Double(data.count) / (1024 * 1024)
    }
}

// MARK: - Extensiones de Date
extension Date {
    func timeAgoDisplay() -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(self)
        
        if timeInterval < 60 {
            return "Ahora"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "hace \(minutes) min"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "hace \(hours) h"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: self)
        }
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
}

// MARK: - Extensiones de Array
extension Array where Element == Mensaje {
    func filteredByDate(_ date: Date) -> [Mensaje] {
        return self.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    func groupedByDate() -> [Date: [Mensaje]] {
        return Dictionary(grouping: self) { mensaje in
            Calendar.current.startOfDay(for: mensaje.timestamp)
        }
    }
    
    mutating func limitToCount(_ maxCount: Int) {
        if self.count > maxCount {
            self = Array(self.suffix(maxCount))
        }
    }
}

// MARK: - Modificadores de Vista Personalizados
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .white.opacity(0.4), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
            )
            .onAppear {
                phase = 300
            }
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
    
    func glow(color: Color = .blue, radius: CGFloat = 4) -> some View {
        self.modifier(GlowEffect(color: color, radius: radius))
    }
}

// MARK: - Utilitarios de Haptic Feedback
struct HapticFeedback {
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    static func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
}

// MARK: - Gestos Personalizados
struct SwipeGesture: ViewModifier {
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 50 {
                            onSwipeRight()
                        } else if value.translation.width < -50 {
                            onSwipeLeft()
                        }
                    }
            )
    }
}

extension View {
    func swipeGesture(
        onSwipeLeft: @escaping () -> Void = {},
        onSwipeRight: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(SwipeGesture(onSwipeLeft: onSwipeLeft, onSwipeRight: onSwipeRight))
    }
}
