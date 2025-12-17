//
//  ColorLearningView.swift
//  Colourblind Camera
//
//  Interactive color learning mode with gamification
//

import SwiftUI
import AVFoundation

struct ColorLearningView: View {
    @StateObject private var learningEngine = ColorLearningEngine()
    @State private var currentChallenge: ColorChallenge?
    @State private var showResults = false
    @State private var selectedMode: LearningMode = .identification
    
    enum LearningMode: String, CaseIterable {
        case identification = "Color ID"
        case matching = "Matching"
        case sorting = "Sorting"
        case quiz = "Quiz"
        
        var icon: String {
            switch self {
            case .identification: return "eye.fill"
            case .matching: return "arrow.triangle.2.circlepath"
            case .sorting: return "line.3.horizontal.decrease"
            case .quiz: return "questionmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress Header
                VStack(spacing: 10) {
                    HStack {
                        Text("Color Learning")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Score display
                        VStack(alignment: .trailing) {
                            Text("Score: \(learningEngine.currentScore)")
                                .font(.headline)
                            Text("Level \(learningEngine.currentLevel)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Progress bar
                    ProgressView(value: learningEngine.levelProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                
                // Mode Selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(LearningMode.allCases, id: \.self) { mode in
                            ModeSelectionCard(
                                mode: mode,
                                isSelected: selectedMode == mode,
                                action: { selectedMode = mode }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Challenge Area
                if let challenge = currentChallenge {
                    ChallengeView(
                        challenge: challenge,
                        onAnswer: { answer in
                            learningEngine.submitAnswer(answer, for: challenge)
                            generateNextChallenge()
                        }
                    )
                } else {
                    // Start button
                    Button(action: generateNextChallenge) {
                        VStack(spacing: 10) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 50))
                            Text("Start Learning")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .background(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .cornerRadius(20)
                    }
                }
                
                Spacer()
                
                // Achievement display
                if !learningEngine.recentAchievements.isEmpty {
                    AchievementBanner(achievements: learningEngine.recentAchievements)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showResults) {
            LearningResultsView(learningEngine: learningEngine)
        }
    }
    
    private func generateNextChallenge() {
        currentChallenge = learningEngine.generateChallenge(for: selectedMode)
    }
}

struct ModeSelectionCard: View {
    let mode: ColorLearningView.LearningMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.title2)
                Text(mode.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .cornerRadius(15)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

struct ChallengeView: View {
    let challenge: ColorChallenge
    let onAnswer: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Challenge title
            Text(challenge.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Challenge content
            switch challenge.type {
            case .colorIdentification:
                ColorIdentificationChallenge(challenge: challenge, onAnswer: onAnswer)
            case .colorMatching:
                ColorMatchingChallenge(challenge: challenge, onAnswer: onAnswer)
            case .colorSorting:
                ColorSortingChallenge(challenge: challenge, onAnswer: onAnswer)
            case .colorQuiz:
                ColorQuizChallenge(challenge: challenge, onAnswer: onAnswer)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}

struct ColorIdentificationChallenge: View {
    let challenge: ColorChallenge
    let onAnswer: (String) -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            // Color display
            RoundedRectangle(cornerRadius: 15)
                .fill(challenge.targetColor ?? .gray)
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray, lineWidth: 2)
                )
            
            // Answer options
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                ForEach(challenge.options, id: \.self) { option in
                    Button(action: { onAnswer(option) }) {
                        Text(option)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
}

struct ColorMatchingChallenge: View {
    let challenge: ColorChallenge
    let onAnswer: (String) -> Void
    @State private var selectedColors: [Color] = []
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Match similar colors")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Colors to match
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(0..<challenge.colorOptions.count, id: \.self) { index in
                    let color = challenge.colorOptions[index]
                    Button(action: {
                        if selectedColors.contains(color) {
                            selectedColors.removeAll { $0 == color }
                        } else {
                            selectedColors.append(color)
                        }
                    }) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color)
                            .frame(height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        selectedColors.contains(color) ? Color.yellow : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                    }
                }
            }
            
            Button("Submit Match") {
                onAnswer(selectedColors.map { $0.description }.joined(separator: ","))
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(selectedColors.count >= 2 ? Color.green : Color.gray)
            .cornerRadius(10)
            .disabled(selectedColors.count < 2)
        }
    }
}

struct ColorSortingChallenge: View {
    let challenge: ColorChallenge
    let onAnswer: (String) -> Void
    @State private var sortedColors: [Color] = []
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Sort colors from lightest to darkest")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Drag and drop area would go here
            // For simplicity, showing tap-to-sort
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(0..<challenge.colorOptions.count, id: \.self) { index in
                    let color = challenge.colorOptions[index]
                    Button(action: {
                        if let existingIndex = sortedColors.firstIndex(of: color) {
                            sortedColors.remove(at: existingIndex)
                        } else {
                            sortedColors.append(color)
                        }
                    }) {
                        VStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color)
                                .frame(height: 40)
                            
                            if let sortIndex = sortedColors.firstIndex(of: color) {
                                Text("\(sortIndex + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            
            Button("Submit Order") {
                onAnswer(sortedColors.map { $0.description }.joined(separator: ","))
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(sortedColors.count == challenge.colorOptions.count ? Color.green : Color.gray)
            .cornerRadius(10)
            .disabled(sortedColors.count != challenge.colorOptions.count)
        }
    }
}

struct ColorQuizChallenge: View {
    let challenge: ColorChallenge
    let onAnswer: (String) -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Text(challenge.question ?? "What color is this?")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Quiz content based on question type
            if let targetColor = challenge.targetColor {
                RoundedRectangle(cornerRadius: 15)
                    .fill(targetColor)
                    .frame(height: 100)
            }
            
            // Multiple choice answers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 10) {
                ForEach(challenge.options, id: \.self) { option in
                    Button(action: { onAnswer(option) }) {
                        HStack {
                            Text(option)
                                .font(.headline)
                            Spacer()
                        }
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
}

struct AchievementBanner: View {
    let achievements: [Achievement]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(achievements, id: \.id) { achievement in
                    VStack(spacing: 5) {
                        Image(systemName: achievement.icon)
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text(achievement.name)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct LearningResultsView: View {
    let learningEngine: ColorLearningEngine
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Results summary
                VStack(spacing: 10) {
                    Text("Session Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Score: \(learningEngine.currentScore)")
                        .font(.headline)
                    
                    Text("Accuracy: \(Int(learningEngine.accuracy * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Continue Learning") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding()
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Supporting Models
struct ColorChallenge {
    let id = UUID()
    let type: ChallengeType
    let title: String
    let question: String?
    let targetColor: Color?
    let colorOptions: [Color]
    let options: [String]
    let correctAnswer: String
    let difficulty: Int
    
    enum ChallengeType {
        case colorIdentification
        case colorMatching
        case colorSorting
        case colorQuiz
    }
}

struct Achievement {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let unlockedAt: Date
}

class ColorLearningEngine: ObservableObject {
    @Published var currentScore: Int = 0
    @Published var currentLevel: Int = 1
    @Published var levelProgress: Double = 0.0
    @Published var accuracy: Double = 0.0
    @Published var recentAchievements: [Achievement] = []
    
    private var totalQuestions: Int = 0
    private var correctAnswers: Int = 0
    
    func generateChallenge(for mode: ColorLearningView.LearningMode) -> ColorChallenge {
        switch mode {
        case .identification:
            return generateIdentificationChallenge()
        case .matching:
            return generateMatchingChallenge()
        case .sorting:
            return generateSortingChallenge()
        case .quiz:
            return generateQuizChallenge()
        }
    }
    
    func submitAnswer(_ answer: String, for challenge: ColorChallenge) {
        totalQuestions += 1
        
        if answer == challenge.correctAnswer {
            correctAnswers += 1
            currentScore += 10 * challenge.difficulty
            
            // Check for level up
            if currentScore > currentLevel * 100 {
                levelUp()
            }
        }
        
        updateAccuracy()
        updateProgress()
    }
    
    private func generateIdentificationChallenge() -> ColorChallenge {
        let colors: [(Color, String)] = [
            (.red, "Red"), (.blue, "Blue"), (.green, "Green"),
            (.yellow, "Yellow"), (.orange, "Orange"), (.purple, "Purple")
        ]
        
        let targetColorPair = colors.randomElement()!
        let wrongOptions = colors.filter { $0.1 != targetColorPair.1 }.shuffled().prefix(3).map { $0.1 }
        let allOptions = ([targetColorPair.1] + wrongOptions).shuffled()
        
        return ColorChallenge(
            type: .colorIdentification,
            title: "What color is this?",
            question: nil,
            targetColor: targetColorPair.0,
            colorOptions: [],
            options: allOptions,
            correctAnswer: targetColorPair.1,
            difficulty: 1
        )
    }
    
    private func generateMatchingChallenge() -> ColorChallenge {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan]
        let selectedColors = colors.shuffled().prefix(6)
        
        return ColorChallenge(
            type: .colorMatching,
            title: "Match similar colors",
            question: nil,
            targetColor: nil,
            colorOptions: Array(selectedColors),
            options: [],
            correctAnswer: "matched",
            difficulty: 2
        )
    }
    
    private func generateSortingChallenge() -> ColorChallenge {
        let colors: [Color] = [.black, .gray, .white, Color(.systemGray2)]
        
        return ColorChallenge(
            type: .colorSorting,
            title: "Sort by brightness",
            question: nil,
            targetColor: nil,
            colorOptions: colors.shuffled(),
            options: [],
            correctAnswer: colors.map { $0.description }.joined(separator: ","),
            difficulty: 3
        )
    }
    
    private func generateQuizChallenge() -> ColorChallenge {
        let questions = [
            ("Which color is often associated with nature?", ["Green", "Red", "Blue", "Yellow"], "Green"),
            ("What color do you get when you mix red and blue?", ["Purple", "Orange", "Green", "Yellow"], "Purple"),
            ("Which color is typically used for warning signs?", ["Red", "Blue", "Green", "Purple"], "Red")
        ]
        
        let question = questions.randomElement()!
        
        return ColorChallenge(
            type: .colorQuiz,
            title: "Color Knowledge Quiz",
            question: question.0,
            targetColor: nil,
            colorOptions: [],
            options: question.1,
            correctAnswer: question.2,
            difficulty: 2
        )
    }
    
    private func levelUp() {
        currentLevel += 1
        let achievement = Achievement(
            name: "Level Up!",
            description: "Reached level \(currentLevel)",
            icon: "star.fill",
            unlockedAt: Date()
        )
        recentAchievements.append(achievement)
    }
    
    private func updateAccuracy() {
        accuracy = totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0.0
    }
    
    private func updateProgress() {
        let scoreInCurrentLevel = currentScore % 100
        levelProgress = Double(scoreInCurrentLevel) / 100.0
    }
}