//
//  ColorReplacementSuggestionView.swift
//  Colourblind Camera
//
//  Color replacement suggestions for designers and creators
//

import SwiftUI
import CoreImage

struct ColorReplacementSuggestionView: View {
    @StateObject private var suggestionEngine = ColorSuggestionEngine()
    @State private var inputColors: [ColorInput] = []
    @State private var showColorPicker = false
    @State private var selectedColorBlindType: ColorBlindnessType = .deuteranopia
    @State private var inputFormat: ColorFormat = .hex
    
    enum ColorFormat: String, CaseIterable {
        case hex = "HEX"
        case rgb = "RGB"
        case pantone = "Pantone"
        
        var icon: String {
            switch self {
            case .hex: return "number.circle"
            case .rgb: return "slider.horizontal.3"
            case .pantone: return "paintpalette.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    HeaderSection(
                        selectedType: $selectedColorBlindType,
                        inputFormat: $inputFormat
                    )
                    
                    // Input Colors Section
                    InputColorsSection(
                        inputColors: $inputColors,
                        format: inputFormat,
                        onAddColor: { showColorPicker = true }
                    )
                    
                    // Suggestions Section
                    if !suggestionEngine.suggestions.isEmpty {
                        SuggestionsSection(suggestions: suggestionEngine.suggestions)
                    }
                    
                    // Analysis Section
                    if !inputColors.isEmpty {
                        AnalysisSection(
                            analysis: suggestionEngine.currentAnalysis,
                            colorBlindType: selectedColorBlindType
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Color Suggestions")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showColorPicker) {
                ColorPickerSheet(
                    format: inputFormat,
                    onColorSelected: { color in
                        inputColors.append(color)
                        updateSuggestions()
                    }
                )
            }
            .onChange(of: selectedColorBlindType) { _ in updateSuggestions() }
            .onChange(of: inputColors) { _ in updateSuggestions() }
        }
    }
    
    private func updateSuggestions() {
        suggestionEngine.generateSuggestions(
            for: inputColors,
            colorBlindType: selectedColorBlindType
        )
    }
}

struct HeaderSection: View {
    @Binding var selectedType: ColorBlindnessType
    @Binding var inputFormat: ColorReplacementSuggestionView.ColorFormat
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Get color-blind friendly alternatives for your designs")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Color blind type selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Color Vision Type")
                    .font(.headline)
                
                Picker("Color Blind Type", selection: $selectedType) {
                    Text("Protanopia (Red-blind)").tag(ColorBlindnessType.protanopia)
                    Text("Deuteranopia (Green-blind)").tag(ColorBlindnessType.deuteranopia)
                    Text("Tritanopia (Blue-blind)").tag(ColorBlindnessType.tritanopia)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Input format selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Input Format")
                    .font(.headline)
                
                HStack(spacing: 10) {
                    ForEach(ColorReplacementSuggestionView.ColorFormat.allCases, id: \.self) { format in
                        Button(action: { inputFormat = format }) {
                            HStack {
                                Image(systemName: format.icon)
                                Text(format.rawValue)
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(inputFormat == format ? .white : .primary)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(inputFormat == format ? Color.blue : Color(.systemGray5))
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

struct InputColorsSection: View {
    @Binding var inputColors: [ColorInput]
    let format: ColorReplacementSuggestionView.ColorFormat
    let onAddColor: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Input Colors")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onAddColor) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Color")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
            }
            
            if inputColors.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No colors added yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Tap 'Add Color' to start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                    ForEach(inputColors.indices, id: \.self) { index in
                        ColorCard(
                            colorInput: inputColors[index],
                            format: format,
                            onDelete: { inputColors.remove(at: index) }
                        )
                    }
                }
            }
        }
    }
}

struct ColorCard: View {
    let colorInput: ColorInput
    let format: ColorReplacementSuggestionView.ColorFormat
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Color swatch
            RoundedRectangle(cornerRadius: 10)
                .fill(colorInput.color)
                .frame(height: 60)
                .overlay(
                    HStack {
                        Spacer()
                        VStack {
                            Button(action: onDelete) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                )
            
            // Color value
            VStack(spacing: 2) {
                Text(colorInput.displayValue(for: format))
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text(colorInput.name)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SuggestionsSection: View {
    let suggestions: [ColorSuggestion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recommended Alternatives")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 15) {
                ForEach(suggestions, id: \.id) { suggestion in
                    SuggestionCard(suggestion: suggestion)
                }
            }
        }
    }
}

struct SuggestionCard: View {
    let suggestion: ColorSuggestion
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(suggestion.title)
                        .font(.headline)
                    Text(suggestion.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("Compatibility")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(suggestion.compatibilityScore * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(compatibilityColor(suggestion.compatibilityScore))
                }
            }
            
            // Before/After comparison
            HStack(spacing: 15) {
                VStack(spacing: 8) {
                    Text("Original")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        ForEach(suggestion.originalColors.indices, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(suggestion.originalColors[index])
                                .frame(height: 40)
                        }
                    }
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text("Suggested")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        ForEach(suggestion.suggestedColors.indices, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(suggestion.suggestedColors[index])
                                .frame(height: 40)
                        }
                    }
                }
            }
            
            // Action buttons
            HStack {
                Button("Details") {
                    showDetails = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Copy Values") {
                    copyColorValues(suggestion.suggestedColors)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(15)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 3)
        .sheet(isPresented: $showDetails) {
            SuggestionDetailView(suggestion: suggestion)
        }
    }
    
    private func compatibilityColor(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        if score >= 0.6 { return .orange }
        return .red
    }
    
    private func copyColorValues(_ colors: [Color]) {
        // Implementation for copying color values to clipboard
        let colorStrings = colors.map { color in
            // Convert Color to hex string
            return color.description
        }
        UIPasteboard.general.string = colorStrings.joined(separator: ", ")
    }
}

struct AnalysisSection: View {
    let analysis: ColorAnalysis?
    let colorBlindType: ColorBlindnessType
    
    var body: some View {
        if let analysis = analysis {
            VStack(alignment: .leading, spacing: 15) {
                Text("Accessibility Analysis")
                    .font(.headline)
                
                VStack(spacing: 10) {
                    AnalysisRow(
                        title: "Overall Accessibility",
                        value: "\(Int(analysis.accessibilityScore * 100))%",
                        color: accessibilityColor(analysis.accessibilityScore)
                    )
                    
                    AnalysisRow(
                        title: "Contrast Ratio",
                        value: String(format: "%.1f:1", analysis.contrastRatio),
                        color: contrastColor(analysis.contrastRatio)
                    )
                    
                    AnalysisRow(
                        title: "Distinguishability",
                        value: analysis.distinguishabilityLevel.rawValue,
                        color: distinguishabilityColor(analysis.distinguishabilityLevel)
                    )
                }
                
                if !analysis.issues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Issues Found:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(analysis.issues, id: \.self) { issue in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text(issue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(15)
        }
    }
    
    private func accessibilityColor(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        if score >= 0.5 { return .orange }
        return .red
    }
    
    private func contrastColor(_ ratio: Double) -> Color {
        if ratio >= 4.5 { return .green }
        if ratio >= 3.0 { return .orange }
        return .red
    }
    
    private func distinguishabilityColor(_ level: DistinguishabilityLevel) -> Color {
        switch level {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}

struct AnalysisRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct ColorPickerSheet: View {
    let format: ColorReplacementSuggestionView.ColorFormat
    let onColorSelected: (ColorInput) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedColor: Color = .red
    @State private var hexInput: String = "#FF0000"
    @State private var rgbR: Double = 255
    @State private var rgbG: Double = 0
    @State private var rgbB: Double = 0
    @State private var colorName: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Color preview
                RoundedRectangle(cornerRadius: 15)
                    .fill(selectedColor)
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                
                // Color input based on format
                switch format {
                case .hex:
                    hexInputView
                case .rgb:
                    rgbInputView
                case .pantone:
                    pantoneInputView
                }
                
                // Color name input
                VStack(alignment: .leading) {
                    Text("Color Name (Optional)")
                        .font(.headline)
                    TextField("e.g., Primary Blue", text: $colorName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
                
                Button("Add Color") {
                    let colorInput = ColorInput(
                        color: selectedColor,
                        name: colorName.isEmpty ? "Untitled" : colorName,
                        hexValue: hexInput,
                        rgbValue: (Int(rgbR), Int(rgbG), Int(rgbB))
                    )
                    onColorSelected(colorInput)
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding()
            .navigationTitle("Add Color")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var hexInputView: some View {
        VStack(alignment: .leading) {
            Text("HEX Value")
                .font(.headline)
            TextField("#FF0000", text: $hexInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: hexInput) { value in
                    if let color = Color(hex: value) {
                        selectedColor = color
                    }
                }
        }
    }
    
    private var rgbInputView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("RGB Values")
                .font(.headline)
            
            VStack(spacing: 10) {
                HStack {
                    Text("R:")
                    Slider(value: $rgbR, in: 0...255, step: 1)
                    Text("\(Int(rgbR))")
                        .frame(width: 40)
                }
                
                HStack {
                    Text("G:")
                    Slider(value: $rgbG, in: 0...255, step: 1)
                    Text("\(Int(rgbG))")
                        .frame(width: 40)
                }
                
                HStack {
                    Text("B:")
                    Slider(value: $rgbB, in: 0...255, step: 1)
                    Text("\(Int(rgbB))")
                        .frame(width: 40)
                }
            }
        }
        .onChange(of: rgbR) { _ in updateColorFromRGB() }
        .onChange(of: rgbG) { _ in updateColorFromRGB() }
        .onChange(of: rgbB) { _ in updateColorFromRGB() }
    }
    
    private var pantoneInputView: some View {
        VStack(alignment: .leading) {
            Text("Pantone Color")
                .font(.headline)
            
            // Color picker fallback for Pantone
            ColorPicker("Select Color", selection: $selectedColor)
                .onChange(of: selectedColor) { color in
                    // Update other values based on selected color
                    updateValuesFromColor(color)
                }
        }
    }
    
    private func updateColorFromRGB() {
        selectedColor = Color(
            red: rgbR / 255,
            green: rgbG / 255,
            blue: rgbB / 255
        )
        hexInput = String(format: "#%02X%02X%02X", Int(rgbR), Int(rgbG), Int(rgbB))
    }
    
    private func updateValuesFromColor(_ color: Color) {
        // This would need UIColor conversion for accurate RGB extraction
        hexInput = color.description // Simplified
    }
}

struct SuggestionDetailView: View {
    let suggestion: ColorSuggestion
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Detailed comparison
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Color Comparison")
                            .font(.headline)
                        
                        ForEach(suggestion.originalColors.indices, id: \.self) { index in
                            HStack {
                                VStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(suggestion.originalColors[index])
                                        .frame(width: 50, height: 50)
                                    Text("Original")
                                        .font(.caption)
                                }
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.secondary)
                                
                                VStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(suggestion.suggestedColors[index])
                                        .frame(width: 50, height: 50)
                                    Text("Suggested")
                                        .font(.caption)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Improvement")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("+\(Int(suggestion.improvementPercentage))%")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    
                    // Technical details
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Technical Details")
                            .font(.headline)
                        
                        Text(suggestion.technicalExplanation)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Usage recommendations
                    if !suggestion.usageRecommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Usage Recommendations")
                                .font(.headline)
                            
                            ForEach(suggestion.usageRecommendations, id: \.self) { recommendation in
                                HStack(alignment: .top) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(recommendation)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// Supporting Models and Classes
struct ColorInput: Identifiable, Equatable {
    let id = UUID()
    let color: Color
    let name: String
    let hexValue: String
    let rgbValue: (r: Int, g: Int, b: Int)
    
    static func == (lhs: ColorInput, rhs: ColorInput) -> Bool {
        return lhs.id == rhs.id
    }
    
    func displayValue(for format: ColorReplacementSuggestionView.ColorFormat) -> String {
        switch format {
        case .hex:
            return hexValue
        case .rgb:
            return "RGB(\(rgbValue.r), \(rgbValue.g), \(rgbValue.b))"
        case .pantone:
            return "Pantone \(name)"
        }
    }
}

struct ColorSuggestion {
    let id = UUID()
    let title: String
    let description: String
    let originalColors: [Color]
    let suggestedColors: [Color]
    let compatibilityScore: Double
    let improvementPercentage: Double
    let technicalExplanation: String
    let usageRecommendations: [String]
}

struct ColorAnalysis {
    let accessibilityScore: Double
    let contrastRatio: Double
    let distinguishabilityLevel: DistinguishabilityLevel
    let issues: [String]
}

enum DistinguishabilityLevel: String {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

class ColorSuggestionEngine: ObservableObject {
    @Published var suggestions: [ColorSuggestion] = []
    @Published var currentAnalysis: ColorAnalysis?
    
    func generateSuggestions(for colors: [ColorInput], colorBlindType: ColorBlindnessType) {
        // Simulate suggestion generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.suggestions = self.createMockSuggestions(for: colors, type: colorBlindType)
            self.currentAnalysis = self.analyzeColors(colors, type: colorBlindType)
        }
    }
    
    private func createMockSuggestions(for colors: [ColorInput], type: ColorBlindnessType) -> [ColorSuggestion] {
        guard !colors.isEmpty else { return [] }
        
        return [
            ColorSuggestion(
                title: "High Contrast Alternative",
                description: "Improved visibility for \(type.rawValue)",
                originalColors: colors.map { $0.color },
                suggestedColors: colors.map { adjustColorForColorBlindness($0.color, type: type) },
                compatibilityScore: 0.9,
                improvementPercentage: 45,
                technicalExplanation: "This suggestion adjusts the color values to maximize distinguishability for users with \(type.rawValue). The adjustments focus on enhancing contrast while maintaining aesthetic appeal.",
                usageRecommendations: [
                    "Ideal for UI buttons and important elements",
                    "Maintains brand recognition",
                    "Improves accessibility compliance"
                ]
            )
        ]
    }
    
    private func adjustColorForColorBlindness(_ color: Color, type: ColorBlindnessType) -> Color {
        // Simplified color adjustment logic
        switch type {
        case .protanopia, .deuteranopia:
            return Color.blue // Simplified - use blue as it's more distinguishable
        case .tritanopia:
            return Color.red // Simplified - use red as it's more distinguishable
        case .normal:
            return color
        }
    }
    
    private func analyzeColors(_ colors: [ColorInput], type: ColorBlindnessType) -> ColorAnalysis {
        return ColorAnalysis(
            accessibilityScore: 0.7,
            contrastRatio: 3.2,
            distinguishabilityLevel: .medium,
            issues: [
                "Low contrast between primary and secondary colors",
                "Similar hues may be difficult to distinguish"
            ]
        )
    }
}

// Color extension for hex support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}