//
//  ColorBlindnessDetectionView.swift
//  Colourblind Camera
//
//  Automatic color blindness type detection through interactive tests
//

import SwiftUI
import CoreGraphics

struct ColorBlindnessDetectionView: View {
    @StateObject private var detectionEngine = ColorBlindnessDetectionEngine()
    @State private var showingResults = false
    @State private var currentTestIndex = 0
    @State private var hasStartedTest = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if !hasStartedTest {
                        WelcomeView(onStartTest: {
                            hasStartedTest = true
                            detectionEngine.startDetection()
                        })
                        .padding()
                    } else if !detectionEngine.isComplete {
                        TestView(
                            detectionEngine: detectionEngine,
                            currentTestIndex: $currentTestIndex
                        )
                        .padding()
                    } else if let result = detectionEngine.detectionResult {
                        ResultsView(
                            result: result,
                            onSaveResults: {
                                detectionEngine.saveResults()
                                showingResults = false
                            },
                            onRetakeTest: {
                                detectionEngine.resetTest()
                                hasStartedTest = false
                                currentTestIndex = 0
                            }
                        )
                        .padding()
                    }
                }
            }
            .navigationTitle("Vision Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct WelcomeView: View {
    let onStartTest: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "eye.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Color Vision Assessment")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("This test will help determine your color vision type to optimize the app for your needs.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 20) {
                InfoCard(
                    icon: "clock",
                    title: "Duration",
                    description: "Takes about 3-5 minutes"
                )
                
                InfoCard(
                    icon: "eye",
                    title: "Instructions",
                    description: "Look at each image and select what you see"
                )
                
                InfoCard(
                    icon: "shield.checkered",
                    title: "Privacy",
                    description: "Results are stored locally on your device"
                )
            }
            
            Button(action: onStartTest) {
                Text("Start Assessment")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TestView: View {
    @ObservedObject var detectionEngine: ColorBlindnessDetectionEngine
    @Binding var currentTestIndex: Int
    
    var body: some View {
        VStack(spacing: 30) {
            // Progress indicator
            ProgressView(
                value: Float(detectionEngine.currentTestIndex + 1),
                total: Float(detectionEngine.totalTests)
            )
            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            .scaleEffect(x: 1, y: 2, anchor: .center)
            .padding(.horizontal)
            
            VStack(spacing: 10) {
                Text("Test \(detectionEngine.currentTestIndex + 1) of \(detectionEngine.totalTests)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if let currentTest = detectionEngine.currentTest {
                    Text(currentTest.instruction)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Test content
            if let currentTest = detectionEngine.currentTest {
                ColorBlindnessTestCard(
                    test: currentTest,
                    onAnswerSelected: { answer in
                        detectionEngine.recordAnswer(answer)
                    }
                )
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ColorBlindnessTestCard: View {
    let test: ColorBlindnessTest
    let onAnswerSelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            // Test image
            TestImageView(test: test)
            
            // Answer options
            VStack(spacing: 12) {
                ForEach(test.options, id: \.self) { option in
                    Button(action: { onAnswerSelected(option) }) {
                        HStack {
                            Text(option)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // "I don't see anything" option
                Button(action: { onAnswerSelected("Nothing visible") }) {
                    HStack {
                        Text("I don't see anything clear")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                }
            }
        }
    }
}

struct TestImageView: View {
    let test: ColorBlindnessTest
    
    var body: some View {
        ZStack {
            // Generate test pattern based on test type
            switch test.type {
            case .ishihara:
                IshiharaPatternView(pattern: test.pattern)
            case .colorArrangement:
                ColorArrangementView(colors: test.colors)
            case .contrastSensitivity:
                ContrastSensitivityView(pattern: test.pattern)
            }
        }
        .frame(width: 250, height: 250)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct IshiharaPatternView: View {
    let pattern: TestPattern
    
    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            let radius = min(size.width, size.height) / 2
            
            // Background dots
            for _ in 0..<200 {
                let angle = Double.random(in: 0...(2 * .pi))
                let distance = Double.random(in: 0...Double(radius - 10))
                let x = centerX + CGFloat(cos(angle) * distance)
                let y = centerY + CGFloat(sin(angle) * distance)
                let dotRadius = CGFloat.random(in: 3...8)
                
                let color = pattern.backgroundColors.randomElement() ?? Color.gray
                context.fill(
                    Path(ellipseIn: CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)),
                    with: .color(color)
                )
            }
            
            // Foreground pattern (number or shape)
            drawForegroundPattern(context: context, size: size, pattern: pattern)
        }
    }
    
    private func drawForegroundPattern(context: GraphicsContext, size: CGSize, pattern: TestPattern) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Draw number or shape with foreground colors
        switch pattern.hiddenContent {
        case "8":
            drawNumber8(context: context, center: CGPoint(x: centerX, y: centerY), colors: pattern.foregroundColors)
        case "12":
            drawNumber12(context: context, center: CGPoint(x: centerX, y: centerY), colors: pattern.foregroundColors)
        case "29":
            drawNumber29(context: context, center: CGPoint(x: centerX, y: centerY), colors: pattern.foregroundColors)
        case "circle":
            drawCircle(context: context, center: CGPoint(x: centerX, y: centerY), colors: pattern.foregroundColors)
        case "triangle":
            drawTriangle(context: context, center: CGPoint(x: centerX, y: centerY), colors: pattern.foregroundColors)
        default:
            break
        }
    }
    
    private func drawNumber8(context: GraphicsContext, center: CGPoint, colors: [Color]) {
        // Draw number 8 using dots
        let points = getNumber8Points(center: center)
        drawDotsAtPoints(context: context, points: points, colors: colors)
    }
    
    private func drawNumber12(context: GraphicsContext, center: CGPoint, colors: [Color]) {
        // Draw number 12 using dots
        let points = getNumber12Points(center: center)
        drawDotsAtPoints(context: context, points: points, colors: colors)
    }
    
    private func drawNumber29(context: GraphicsContext, center: CGPoint, colors: [Color]) {
        // Draw number 29 using dots
        let points = getNumber29Points(center: center)
        drawDotsAtPoints(context: context, points: points, colors: colors)
    }
    
    private func drawCircle(context: GraphicsContext, center: CGPoint, colors: [Color]) {
        // Draw circle using dots
        let points = getCirclePoints(center: center, radius: 40)
        drawDotsAtPoints(context: context, points: points, colors: colors)
    }
    
    private func drawTriangle(context: GraphicsContext, center: CGPoint, colors: [Color]) {
        // Draw triangle using dots
        let points = getTrianglePoints(center: center, size: 60)
        drawDotsAtPoints(context: context, points: points, colors: colors)
    }
    
    private func drawDotsAtPoints(context: GraphicsContext, points: [CGPoint], colors: [Color]) {
        for point in points {
            let color = colors.randomElement() ?? Color.red
            let radius = CGFloat.random(in: 4...7)
            context.fill(
                Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                with: .color(color)
            )
        }
    }
    
    // Helper methods to generate point patterns for numbers and shapes
    private func getNumber8Points(center: CGPoint) -> [CGPoint] {
        var points: [CGPoint] = []
        
        // Top circle of 8
        for angle in stride(from: 0, to: 2 * Double.pi, by: 0.3) {
            let x = center.x + CGFloat(cos(angle) * 25)
            let y = center.y - 25 + CGFloat(sin(angle) * 15)
            points.append(CGPoint(x: x, y: y))
        }
        
        // Bottom circle of 8
        for angle in stride(from: 0, to: 2 * Double.pi, by: 0.3) {
            let x = center.x + CGFloat(cos(angle) * 25)
            let y = center.y + 25 + CGFloat(sin(angle) * 15)
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    private func getNumber12Points(center: CGPoint) -> [CGPoint] {
        var points: [CGPoint] = []
        
        // Number 1
        for y in stride(from: -40, to: 40, by: 8) {
            points.append(CGPoint(x: center.x - 20, y: center.y + CGFloat(y)))
        }
        
        // Number 2
        // Top horizontal line
        for x in stride(from: 5, to: 35, by: 6) {
            points.append(CGPoint(x: center.x + CGFloat(x), y: center.y - 30))
        }
        // Diagonal line
        for i in 0..<8 {
            let x = 35 - i * 4
            let y = -30 + i * 8
            points.append(CGPoint(x: center.x + CGFloat(x), y: center.y + CGFloat(y)))
        }
        // Bottom horizontal line
        for x in stride(from: 5, to: 35, by: 6) {
            points.append(CGPoint(x: center.x + CGFloat(x), y: center.y + 30))
        }
        
        return points
    }
    
    private func getNumber29Points(center: CGPoint) -> [CGPoint] {
        var points: [CGPoint] = []
        
        // Number 2
        for x in stride(from: -35, to: -5, by: 6) {
            points.append(CGPoint(x: center.x + CGFloat(x), y: center.y - 30))
        }
        for i in 0..<8 {
            let x = -5 - i * 4
            let y = -30 + i * 8
            points.append(CGPoint(x: center.x + CGFloat(x), y: center.y + CGFloat(y)))
        }
        for x in stride(from: -35, to: -5, by: 6) {
            points.append(CGPoint(x: center.x + CGFloat(x), y: center.y + 30))
        }
        
        // Number 9
        for angle in stride(from: 0, to: 2 * Double.pi, by: 0.4) {
            let x = 20 + cos(angle) * 15
            let y = -10 + sin(angle) * 15
            points.append(CGPoint(x: center.x + CGFloat(x), y: center.y + CGFloat(y)))
        }
        for y in stride(from: 5, to: 35, by: 6) {
            points.append(CGPoint(x: center.x + 35, y: center.y + CGFloat(y)))
        }
        
        return points
    }
    
    private func getCirclePoints(center: CGPoint, radius: CGFloat) -> [CGPoint] {
        var points: [CGPoint] = []
        
        for angle in stride(from: 0, to: 2 * Double.pi, by: 0.2) {
            let x = center.x + CGFloat(cos(angle) * Double(radius))
            let y = center.y + CGFloat(sin(angle) * Double(radius))
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    private func getTrianglePoints(center: CGPoint, size: CGFloat) -> [CGPoint] {
        var points: [CGPoint] = []
        
        let height = size * sqrt(3) / 2
        
        // Top vertex
        points.append(CGPoint(x: center.x, y: center.y - height / 2))
        
        // Left side
        for i in 1..<10 {
            let t = CGFloat(i) / 10
            let x = center.x - size / 2 * t
            let y = center.y - height / 2 + height * t
            points.append(CGPoint(x: x, y: y))
        }
        
        // Right side
        for i in 1..<10 {
            let t = CGFloat(i) / 10
            let x = center.x + size / 2 * t
            let y = center.y - height / 2 + height * t
            points.append(CGPoint(x: x, y: y))
        }
        
        // Bottom side
        for i in 1..<10 {
            let t = CGFloat(i) / 10
            let x = center.x - size / 2 + size * t
            let y = center.y + height / 2
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
}

struct ColorArrangementView: View {
    let colors: [Color]
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<colors.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 8)
                    .fill(colors[index])
                    .frame(width: 30, height: 200)
            }
        }
    }
}

struct ContrastSensitivityView: View {
    let pattern: TestPattern
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<10, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<10, id: \.self) { col in
                        let isCheckerboard = (row + col) % 2 == 0
                        Rectangle()
                            .fill(isCheckerboard ? pattern.foregroundColors.first ?? .black : pattern.backgroundColors.first ?? .white)
                            .frame(width: 25, height: 25)
                    }
                }
            }
        }
    }
}

struct ResultsView: View {
    let result: ColorBlindnessDetectionResult
    let onSaveResults: () -> Void
    let onRetakeTest: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Results header
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Assessment Complete")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
                // Results details
                VStack(spacing: 20) {
                    ResultCard(
                        title: "Vision Type",
                        value: result.detectedType.displayName,
                        description: result.detectedType.description,
                        confidence: result.confidence
                    )
                    
                    if result.confidence < 0.7 {
                        InfoBox(
                            title: "Uncertain Result",
                            message: "The test results are not conclusive. You may want to retake the test or consult with an eye care professional.",
                            type: .warning
                        )
                    }
                    
                    // Recommendations
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Recommendations")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(result.recommendations, id: \.self) { recommendation in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(recommendation)
                                        .font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onSaveResults) {
                        Text("Save Results & Apply Settings")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: onRetakeTest) {
                        Text("Retake Test")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal)
        }
    }
}


struct ResultCard: View {
    let title: String
    let value: String
    let description: String
    let confidence: Float
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Confidence: \(Int(confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct InfoBox: View {
    let title: String
    let message: String
    let type: InfoType
    
    enum InfoType {
        case info, warning, error
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(type.color)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(type.color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Supporting Models and Classes

struct ColorBlindnessTest {
    let id = UUID()
    let type: TestType
    let instruction: String
    let pattern: TestPattern
    let colors: [Color]
    let options: [String]
    let correctAnswer: String
    let targetTypes: [ColorBlindnessType]
    
    enum TestType {
        case ishihara
        case colorArrangement
        case contrastSensitivity
    }
}

struct TestPattern {
    let hiddenContent: String
    let foregroundColors: [Color]
    let backgroundColors: [Color]
}

struct ColorBlindnessDetectionResult {
    let detectedType: ColorBlindnessType
    let confidence: Float
    let recommendations: [String]
    let testResults: [TestResult]
}

struct TestResult {
    let testId: UUID
    let userAnswer: String
    let correctAnswer: String
    let isCorrect: Bool
    let responseTime: TimeInterval
}

extension ColorBlindnessType {
    var description: String {
        switch self {
        case .normal:
            return "You have normal color vision and can distinguish between all colors effectively."
        case .protanopia:
            return "You have protanopia, a form of red-green color blindness where red cones are absent."
        case .deuteranopia:
            return "You have deuteranopia, a form of red-green color blindness where green cones are absent."
        case .tritanopia:
            return "You have tritanopia, a rare form of blue-yellow color blindness."
        }
    }
}

class ColorBlindnessDetectionEngine: ObservableObject {
    @Published var currentTestIndex = 0
    @Published var isComplete = false
    @Published var currentTest: ColorBlindnessTest?
    @Published var detectionResult: ColorBlindnessDetectionResult?
    
    private var tests: [ColorBlindnessTest] = []
    private var testResults: [TestResult] = []
    private var startTime: Date = Date()
    
    var totalTests: Int {
        return tests.count
    }
    
    init() {
        generateTests()
    }
    
    func startDetection() {
        currentTestIndex = 0
        isComplete = false
        testResults.removeAll()
        loadCurrentTest()
    }
    
    func recordAnswer(_ answer: String) {
        guard let test = currentTest else { return }
        
        let result = TestResult(
            testId: test.id,
            userAnswer: answer,
            correctAnswer: test.correctAnswer,
            isCorrect: answer == test.correctAnswer,
            responseTime: Date().timeIntervalSince(startTime)
        )
        
        testResults.append(result)
        
        // Move to next test
        currentTestIndex += 1
        
        if currentTestIndex >= tests.count {
            completeDetection()
        } else {
            loadCurrentTest()
        }
        
        startTime = Date()
    }
    
    func resetTest() {
        currentTestIndex = 0
        isComplete = false
        testResults.removeAll()
        detectionResult = nil
        currentTest = nil
    }
    
    func saveResults() {
        guard let result = detectionResult else { return }
        
        // Save results to UserDefaults or Core Data
        UserDefaults.standard.set(result.detectedType.rawValue, forKey: "DetectedColorBlindnessType")
        UserDefaults.standard.set(result.confidence, forKey: "DetectionConfidence")
        
        // Apply settings based on detected type
        applySettingsForDetectedType(result.detectedType)
    }
    
    private func generateTests() {
        tests = [
            // Ishihara-style tests
            ColorBlindnessTest(
                type: .ishihara,
                instruction: "What number do you see in this image?",
                pattern: TestPattern(
                    hiddenContent: "8",
                    foregroundColors: [Color.red, Color(red: 0.8, green: 0.2, blue: 0.2)],
                    backgroundColors: [Color.green, Color(red: 0.2, green: 0.8, blue: 0.2)]
                ),
                colors: [],
                options: ["8", "3", "6", "0"],
                correctAnswer: "8",
                targetTypes: [.protanopia, .deuteranopia]
            ),
            
            ColorBlindnessTest(
                type: .ishihara,
                instruction: "What number do you see in this image?",
                pattern: TestPattern(
                    hiddenContent: "12",
                    foregroundColors: [Color(red: 0.9, green: 0.1, blue: 0.1)],
                    backgroundColors: [Color(red: 0.1, green: 0.7, blue: 0.1)]
                ),
                colors: [],
                options: ["12", "17", "21", "71"],
                correctAnswer: "12",
                targetTypes: [.protanopia, .deuteranopia]
            ),
            
            ColorBlindnessTest(
                type: .ishihara,
                instruction: "What number do you see in this image?",
                pattern: TestPattern(
                    hiddenContent: "29",
                    foregroundColors: [Color.blue, Color(red: 0.2, green: 0.2, blue: 0.9)],
                    backgroundColors: [Color.yellow, Color(red: 0.9, green: 0.9, blue: 0.2)]
                ),
                colors: [],
                options: ["29", "20", "70", "25"],
                correctAnswer: "29",
                targetTypes: [.tritanopia]
            ),
            
            // Shape recognition tests
            ColorBlindnessTest(
                type: .ishihara,
                instruction: "What shape do you see in this image?",
                pattern: TestPattern(
                    hiddenContent: "circle",
                    foregroundColors: [Color.red],
                    backgroundColors: [Color.green]
                ),
                colors: [],
                options: ["Circle", "Square", "Triangle", "Star"],
                correctAnswer: "Circle",
                targetTypes: [.protanopia, .deuteranopia]
            ),
            
            // Color arrangement test
            ColorBlindnessTest(
                type: .colorArrangement,
                instruction: "Arrange these colors from lightest to darkest",
                pattern: TestPattern(hiddenContent: "", foregroundColors: [], backgroundColors: []),
                colors: [
                    Color(red: 0.2, green: 0.8, blue: 0.2),
                    Color(red: 0.8, green: 0.2, blue: 0.2),
                    Color(red: 0.5, green: 0.5, blue: 0.2),
                    Color(red: 0.2, green: 0.5, blue: 0.5)
                ],
                options: ["Light to Dark", "Similar Colors", "Different Colors", "Can't distinguish"],
                correctAnswer: "Light to Dark",
                targetTypes: [.protanopia, .deuteranopia, .tritanopia]
            )
        ]
    }
    
    private func loadCurrentTest() {
        if currentTestIndex < tests.count {
            currentTest = tests[currentTestIndex]
        }
    }
    
    private func completeDetection() {
        isComplete = true
        detectionResult = analyzeResults()
    }
    
    private func analyzeResults() -> ColorBlindnessDetectionResult {
        var scores: [ColorBlindnessType: Float] = [
            .normal: 0,
            .protanopia: 0,
            .deuteranopia: 0,
            .tritanopia: 0
        ]
        
        // Analyze test results
        for (index, result) in testResults.enumerated() {
            let test = tests[index]
            
            if result.isCorrect {
                // Correct answer suggests normal vision for this test type
                scores[.normal, default: 0] += 1.0
            } else {
                // Incorrect answer suggests specific type of color blindness
                for targetType in test.targetTypes {
                    scores[targetType, default: 0] += 0.8
                }
            }
        }
        
        // Determine most likely type
        let detectedType = scores.max(by: { $0.value < $1.value })?.key ?? .normal
        let maxScore = scores[detectedType] ?? 0
        let totalTests = Float(testResults.count)
        let confidence = min(maxScore / totalTests, 1.0)
        
        let recommendations = generateRecommendations(for: detectedType)
        
        return ColorBlindnessDetectionResult(
            detectedType: detectedType,
            confidence: confidence,
            recommendations: recommendations,
            testResults: testResults
        )
    }
    
    private func generateRecommendations(for type: ColorBlindnessType) -> [String] {
        switch type {
        case .normal:
            return [
                "Your color vision appears to be functioning normally",
                "You can use all features of the app without special adaptations",
                "Consider helping others by testing color accessibility"
            ]
        case .protanopia:
            return [
                "Enable red-green color correction in settings",
                "Use high contrast mode for better visibility",
                "Try the voice assistant for color identification",
                "Be extra careful with traffic lights and warning signs"
            ]
        case .deuteranopia:
            return [
                "Enable green-red color correction in settings",
                "Use enhanced contrast for text and interfaces",
                "Take advantage of color labeling features",
                "Consider safety alerts for critical color situations"
            ]
        case .tritanopia:
            return [
                "Enable blue-yellow color correction in settings",
                "Use the AR mode for better color identification",
                "Be aware that this type is less common",
                "Consider professional consultation for confirmation"
            ]
        }
    }
    
    private func applySettingsForDetectedType(_ type: ColorBlindnessType) {
        // Apply app settings based on detected type
        UserDefaults.standard.set(true, forKey: "ColorCorrectionEnabled")
        UserDefaults.standard.set(type.rawValue, forKey: "ColorBlindnessType")
        UserDefaults.standard.set(true, forKey: "VoiceAnnouncementsEnabled")
        
        if type != .normal {
            UserDefaults.standard.set(true, forKey: "HighContrastEnabled")
            UserDefaults.standard.set(true, forKey: "SafetyAlertsEnabled")
        }
    }
}
