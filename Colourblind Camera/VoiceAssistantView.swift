//
//  VoiceAssistantView.swift
//  Colourblind Camera
//
//  Voice assistant integration for hands-free color identification
//

import SwiftUI
import Speech
import AVFoundation
import CoreML

struct VoiceAssistantView: View {
    @StateObject private var voiceAssistant = VoiceAssistant()
    @State private var showingSettings = false
    @State private var isListening = false
    @State private var transcribedText = ""
    @State private var assistantResponse = "Hi! I'm your color assistant. Try saying 'What color is this?'"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Assistant Avatar
                AssistantAvatarView(
                    isListening: isListening,
                    isResponding: voiceAssistant.isResponding,
                    microphoneLevel: voiceAssistant.microphoneLevel
                )
                
                // Conversation Display
                ConversationView(
                    transcribedText: transcribedText,
                    assistantResponse: assistantResponse,
                    conversationHistory: voiceAssistant.conversationHistory
                )
                
                // Voice Controls
                VoiceControlsView(
                    isListening: isListening,
                    isEnabled: voiceAssistant.isEnabled,
                    onStartListening: startListening,
                    onStopListening: stopListening,
                    onToggleAssistant: { voiceAssistant.toggleAssistant() }
                )
                
                // Quick Commands
                QuickCommandsView(
                    onCommandTapped: { command in
                        processCommand(command)
                    }
                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("Voice Assistant")
            .navigationBarItems(
                trailing: Button("Settings") {
                    showingSettings = true
                }
            )
        }
        .onReceive(voiceAssistant.$lastTranscription) { text in
            transcribedText = text
        }
        .onReceive(voiceAssistant.$lastResponse) { response in
            assistantResponse = response
        }
        .onReceive(voiceAssistant.$isListening) { listening in
            isListening = listening
        }
        .sheet(isPresented: $showingSettings) {
            VoiceAssistantSettingsView(voiceAssistant: voiceAssistant)
        }
        .onAppear {
            voiceAssistant.initialize()
        }
    }
    
    private func startListening() {
        voiceAssistant.startListening()
    }
    
    private func stopListening() {
        voiceAssistant.stopListening()
    }
    
    private func processCommand(_ command: VoiceCommand) {
        voiceAssistant.processVoiceCommand(command)
    }
}

struct AssistantAvatarView: View {
    let isListening: Bool
    let isResponding: Bool
    let microphoneLevel: Float
    
    var body: some View {
        ZStack {
            // Outer ring - microphone level indicator
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 180, height: 180)
                .scaleEffect(isListening ? 1.0 + CGFloat(microphoneLevel) * 0.3 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: microphoneLevel)
            
            // Middle ring - listening indicator
            Circle()
                .stroke(
                    isListening ? Color.green : Color.gray.opacity(0.5),
                    lineWidth: 3
                )
                .frame(width: 140, height: 140)
                .scaleEffect(isListening ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isListening)
            
            // Inner circle - avatar
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: isResponding ? "speaker.wave.2.fill" : (isListening ? "mic.fill" : "eye.fill"))
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .scaleEffect(isResponding ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isResponding)
                )
        }
    }
}

struct ConversationView: View {
    let transcribedText: String
    let assistantResponse: String
    let conversationHistory: [ConversationEntry]
    
    var body: some View {
        VStack(spacing: 20) {
            // Current conversation
            VStack(spacing: 15) {
                // User input
                if !transcribedText.isEmpty {
                    HStack {
                        Spacer()
                        Text(transcribedText)
                            .font(.body)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(15)
                            .frame(maxWidth: .infinity * 0.8, alignment: .trailing)
                    }
                }
                
                // Assistant response
                if !assistantResponse.isEmpty {
                    HStack {
                        Text(assistantResponse)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                            .frame(maxWidth: .infinity * 0.8, alignment: .leading)
                        Spacer()
                    }
                }
            }
            
            // Conversation history
            if !conversationHistory.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(conversationHistory.suffix(5), id: \.id) { entry in
                            ConversationEntryView(entry: entry)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 200)
            }
        }
    }
}

struct ConversationEntryView: View {
    let entry: ConversationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.userInput)
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(10)
            
            HStack {
                Text(entry.assistantResponse)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

struct VoiceControlsView: View {
    let isListening: Bool
    let isEnabled: Bool
    let onStartListening: () -> Void
    let onStopListening: () -> Void
    let onToggleAssistant: () -> Void
    
    var body: some View {
        HStack(spacing: 30) {
            // Toggle assistant
            Button(action: onToggleAssistant) {
                VStack {
                    Image(systemName: isEnabled ? "power.on" : "power")
                        .font(.title2)
                    Text(isEnabled ? "On" : "Off")
                        .font(.caption)
                }
                .foregroundColor(isEnabled ? .green : .gray)
            }
            
            // Main microphone button
            Button(action: isListening ? onStopListening : onStartListening) {
                Image(systemName: isListening ? "mic.slash.fill" : "mic.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: isListening ? [.red, .orange] : [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(radius: 5)
                    .scaleEffect(isListening ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isListening)
            }
            .disabled(!isEnabled)
            
            // Help button
            Button(action: {}) {
                VStack {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                    Text("Help")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
        }
    }
}

struct QuickCommandsView: View {
    let onCommandTapped: (VoiceCommand) -> Void
    
    let commands: [VoiceCommand] = [
        VoiceCommand(text: "What color is this?", type: .colorIdentification),
        VoiceCommand(text: "Find red objects", type: .colorSearch),
        VoiceCommand(text: "Describe the scene", type: .sceneDescription),
        VoiceCommand(text: "Read color palette", type: .paletteReading)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Commands")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                ForEach(commands, id: \.id) { command in
                    Button(action: { onCommandTapped(command) }) {
                        HStack {
                            Image(systemName: command.type.icon)
                                .font(.caption)
                            Text(command.text)
                                .font(.caption)
                                .lineLimit(2)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
        }
    }
}

struct VoiceAssistantSettingsView: View {
    @ObservedObject var voiceAssistant: VoiceAssistant
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedVoice = 0
    @State private var speechRate: Float = 0.5
    @State private var autoListen = false
    @State private var contextAware = true
    @State private var enableHaptics = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Voice Settings")) {
                    Picker("Voice", selection: $selectedVoice) {
                        Text("Default").tag(0)
                        Text("Male").tag(1)
                        Text("Female").tag(2)
                        Text("Child").tag(3)
                    }
                    .onChange(of: selectedVoice) { value in
                        voiceAssistant.setVoice(value)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Speech Rate")
                        Slider(value: $speechRate, in: 0.1...1.0, step: 0.1) {
                            Text("Rate")
                        } minimumValueLabel: {
                            Text("Slow")
                        } maximumValueLabel: {
                            Text("Fast")
                        }
                        .onChange(of: speechRate) { value in
                            voiceAssistant.setSpeechRate(value)
                        }
                    }
                }
                
                Section(header: Text("Behavior")) {
                    Toggle("Auto-listen after response", isOn: $autoListen)
                        .onChange(of: autoListen) { value in
                            voiceAssistant.setAutoListen(value)
                        }
                    
                    Toggle("Context-aware responses", isOn: $contextAware)
                        .onChange(of: contextAware) { value in
                            voiceAssistant.setContextAware(value)
                        }
                    
                    Toggle("Haptic feedback", isOn: $enableHaptics)
                        .onChange(of: enableHaptics) { value in
                            voiceAssistant.setHapticsEnabled(value)
                        }
                }
                
                Section(header: Text("Commands")) {
                    NavigationLink("Custom Commands") {
                        CustomCommandsView(voiceAssistant: voiceAssistant)
                    }
                    
                    NavigationLink("Voice Training") {
                        VoiceTrainingView(voiceAssistant: voiceAssistant)
                    }
                }
                
                Section(header: Text("Privacy")) {
                    Button("Clear Conversation History") {
                        voiceAssistant.clearHistory()
                    }
                    
                    Button("Reset Voice Profile") {
                        voiceAssistant.resetVoiceProfile()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Voice Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct CustomCommandsView: View {
    @ObservedObject var voiceAssistant: VoiceAssistant
    @State private var showingAddCommand = false
    
    var body: some View {
        List {
            ForEach(voiceAssistant.customCommands, id: \.id) { command in
                VStack(alignment: .leading) {
                    Text(command.text)
                        .font(.headline)
                    Text(command.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onDelete { indexSet in
                voiceAssistant.deleteCustomCommands(at: indexSet)
            }
        }
        .navigationTitle("Custom Commands")
        .navigationBarItems(
            trailing: Button("Add") {
                showingAddCommand = true
            }
        )
        .sheet(isPresented: $showingAddCommand) {
            AddCustomCommandView(voiceAssistant: voiceAssistant)
        }
    }
}

struct AddCustomCommandView: View {
    @ObservedObject var voiceAssistant: VoiceAssistant
    @Environment(\.presentationMode) var presentationMode
    
    @State private var commandText = ""
    @State private var commandType: VoiceCommandType = .colorIdentification
    @State private var response = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Command")) {
                    TextField("Voice command", text: $commandText)
                    
                    Picker("Type", selection: $commandType) {
                        ForEach(VoiceCommandType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Response")) {
                    TextField("Assistant response", text: $response, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Command")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let command = VoiceCommand(text: commandText, type: commandType)
                    voiceAssistant.addCustomCommand(command, response: response)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(commandText.isEmpty)
            )
        }
    }
}

struct VoiceTrainingView: View {
    @ObservedObject var voiceAssistant: VoiceAssistant
    @State private var isTraining = false
    @State private var trainingStep = 0
    
    let trainingPhrases = [
        "What color is this?",
        "Find blue objects",
        "Describe the scene",
        "Help me identify colors",
        "Read the color palette"
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            if !isTraining {
                VStack(spacing: 20) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Voice Training")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Improve recognition accuracy by training the assistant with your voice")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button("Start Training") {
                        startTraining()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            } else {
                VStack(spacing: 20) {
                    Text("Step \(trainingStep + 1) of \(trainingPhrases.count)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Please say:")
                        .font(.subheadline)
                    
                    Text("\"\(trainingPhrases[trainingStep])\"")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    
                    Button(voiceAssistant.isListening ? "Stop" : "Record") {
                        if voiceAssistant.isListening {
                            voiceAssistant.stopListening()
                        } else {
                            voiceAssistant.startTrainingRecording(phrase: trainingPhrases[trainingStep])
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(voiceAssistant.isListening ? Color.red : Color.green)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .navigationTitle("Voice Training")
        .onReceive(voiceAssistant.$trainingCompleted) { completed in
            if completed {
                nextTrainingStep()
            }
        }
    }
    
    private func startTraining() {
        isTraining = true
        trainingStep = 0
    }
    
    private func nextTrainingStep() {
        if trainingStep < trainingPhrases.count - 1 {
            trainingStep += 1
        } else {
            // Training complete
            isTraining = false
            voiceAssistant.completeTraining()
        }
    }
}

// MARK: - Supporting Models and Classes

struct VoiceCommand {
    let id = UUID()
    let text: String
    let type: VoiceCommandType
}

enum VoiceCommandType: String, CaseIterable {
    case colorIdentification = "Color Identification"
    case colorSearch = "Color Search"
    case sceneDescription = "Scene Description"
    case paletteReading = "Palette Reading"
    case objectDetection = "Object Detection"
    case help = "Help"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .colorIdentification: return "eye.fill"
        case .colorSearch: return "magnifyingglass"
        case .sceneDescription: return "camera.viewfinder"
        case .paletteReading: return "paintpalette.fill"
        case .objectDetection: return "viewfinder"
        case .help: return "questionmark.circle"
        case .settings: return "gear"
        }
    }
}

struct ConversationEntry {
    let id = UUID()
    let userInput: String
    let assistantResponse: String
    let timestamp: Date
}

class VoiceAssistant: NSObject, ObservableObject {
    @Published var isEnabled = false
    @Published var isListening = false
    @Published var isResponding = false
    @Published var microphoneLevel: Float = 0.0
    @Published var lastTranscription = ""
    @Published var lastResponse = ""
    @Published var conversationHistory: [ConversationEntry] = []
    @Published var customCommands: [VoiceCommand] = []
    @Published var trainingCompleted = false
    
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    // Settings
    private var speechRate: Float = 0.5
    private var selectedVoice = 0
    private var autoListen = false
    private var contextAware = true
    private var hapticsEnabled = true
    
    // Context
    private var currentColorBlindType: ColorBlindnessType = .normal
    private var lastDetectedColors: [String] = []
    private var currentLocation: String?
    
    override init() {
        super.init()
        setupAudio()
    }
    
    func initialize() {
        requestPermissions()
        loadCustomCommands()
    }
    
    func toggleAssistant() {
        isEnabled.toggle()
        
        if !isEnabled {
            stopListening()
        }
    }
    
    func startListening() {
        guard isEnabled else { return }
        
        do {
            try startSpeechRecognition()
            isListening = true
            
            if hapticsEnabled {
                hapticFeedback.impactOccurred()
            }
        } catch {
            print("Failed to start speech recognition: \(error)")
        }
    }
    
    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        isListening = false
        microphoneLevel = 0.0
    }
    
    func processVoiceCommand(_ command: VoiceCommand) {
        lastTranscription = command.text
        
        let response = generateResponse(for: command)
        respondWithText(response)
        
        addToConversationHistory(userInput: command.text, response: response)
    }
    
    // Settings methods
    func setVoice(_ voice: Int) {
        selectedVoice = voice
    }
    
    func setSpeechRate(_ rate: Float) {
        speechRate = rate
    }
    
    func setAutoListen(_ enabled: Bool) {
        autoListen = enabled
    }
    
    func setContextAware(_ enabled: Bool) {
        contextAware = enabled
    }
    
    func setHapticsEnabled(_ enabled: Bool) {
        hapticsEnabled = enabled
    }
    
    func addCustomCommand(_ command: VoiceCommand, response: String) {
        customCommands.append(command)
        // Save to persistent storage
    }
    
    func deleteCustomCommands(at indexSet: IndexSet) {
        customCommands.remove(atOffsets: indexSet)
    }
    
    func clearHistory() {
        conversationHistory.removeAll()
    }
    
    func resetVoiceProfile() {
        // Reset voice training data
    }
    
    func startTrainingRecording(phrase: String) {
        startListening()
        // Additional training-specific logic
    }
    
    func completeTraining() {
        // Process training data and update recognition model
        trainingCompleted = true
    }
    
    private func setupAudio() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition not authorized")
                @unknown default:
                    break
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("Microphone permission granted")
            } else {
                print("Microphone permission denied")
            }
        }
    }
    
    private func startSpeechRecognition() throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "VoiceAssistant", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
            
            // Update microphone level
            let channelData = buffer.floatChannelData?[0]
            let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
            let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(channelDataArray.count))
            
            DispatchQueue.main.async {
                self.microphoneLevel = min(rms * 10, 1.0) // Normalize to 0-1
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                
                DispatchQueue.main.async {
                    self?.lastTranscription = transcription
                }
                
                if result.isFinal {
                    self?.processTranscription(transcription)
                }
            }
            
            if error != nil {
                self?.stopListening()
            }
        }
    }
    
    private func processTranscription(_ transcription: String) {
        stopListening()
        
        let command = interpretCommand(transcription)
        let response = generateResponse(for: command)
        
        respondWithText(response)
        addToConversationHistory(userInput: transcription, response: response)
        
        // Auto-listen if enabled
        if autoListen {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.startListening()
            }
        }
    }
    
    private func interpretCommand(_ text: String) -> VoiceCommand {
        let lowercaseText = text.lowercased()
        
        // Check custom commands first
        for customCommand in customCommands {
            if lowercaseText.contains(customCommand.text.lowercased()) {
                return customCommand
            }
        }
        
        // Built-in command recognition
        if lowercaseText.contains("what color") || lowercaseText.contains("identify color") {
            return VoiceCommand(text: text, type: .colorIdentification)
        } else if lowercaseText.contains("find") && (lowercaseText.contains("color") || lowercaseText.contains("red") || lowercaseText.contains("blue") || lowercaseText.contains("green")) {
            return VoiceCommand(text: text, type: .colorSearch)
        } else if lowercaseText.contains("describe") || lowercaseText.contains("scene") {
            return VoiceCommand(text: text, type: .sceneDescription)
        } else if lowercaseText.contains("palette") || lowercaseText.contains("colors in") {
            return VoiceCommand(text: text, type: .paletteReading)
        } else if lowercaseText.contains("help") {
            return VoiceCommand(text: text, type: .help)
        }
        
        return VoiceCommand(text: text, type: .colorIdentification)
    }
    
    private func generateResponse(for command: VoiceCommand) -> String {
        switch command.type {
        case .colorIdentification:
            return generateColorIdentificationResponse()
        case .colorSearch:
            return generateColorSearchResponse(command.text)
        case .sceneDescription:
            return generateSceneDescriptionResponse()
        case .paletteReading:
            return generatePaletteReadingResponse()
        case .objectDetection:
            return generateObjectDetectionResponse()
        case .help:
            return generateHelpResponse()
        case .settings:
            return "Voice assistant settings can be accessed through the settings button."
        }
    }
    
    private func generateColorIdentificationResponse() -> String {
        // This would integrate with the camera system to identify colors
        let mockColors = ["Deep Blue", "Forest Green", "Warm White"]
        let randomColor = mockColors.randomElement() ?? "Unknown"
        
        return "I can see \(randomColor) in the center of your view. The dominant color appears to be \(randomColor)."
    }
    
    private func generateColorSearchResponse(_ query: String) -> String {
        // Extract color from query
        let colors = ["red", "blue", "green", "yellow", "orange", "purple", "pink", "brown", "black", "white"]
        let foundColor = colors.first { query.lowercased().contains($0) } ?? "the requested color"
        
        return "I found several objects with \(foundColor) in the current view. There appear to be \(Int.random(in: 2...5)) items containing \(foundColor)."
    }
    
    private func generateSceneDescriptionResponse() -> String {
        return "I can see a scene with multiple objects. The dominant colors are blue, green, and white. There appear to be both natural and artificial elements in view."
    }
    
    private func generatePaletteReadingResponse() -> String {
        let colors = ["Deep Blue", "Forest Green", "Warm White", "Coral Pink"]
        return "The current color palette contains: \(colors.joined(separator: ", ")). These colors work well together and provide good contrast."
    }
    
    private func generateObjectDetectionResponse() -> String {
        return "I can detect several objects in the scene. The main objects appear to be furniture, plants, and decorative items."
    }
    
    private func generateHelpResponse() -> String {
        return """
        I can help you with color identification. Try saying:
        'What color is this?' to identify colors at the center of your view.
        'Find blue objects' to search for specific colors.
        'Describe the scene' for an overview of what I can see.
        'Read color palette' to hear all colors in view.
        """
    }
    
    private func respondWithText(_ text: String) {
        lastResponse = text
        isResponding = true
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.volume = 0.8
        
        // Set voice based on selection
        if let voice = getSelectedVoice() {
            utterance.voice = voice
        }
        
        speechSynthesizer.speak(utterance)
        
        // Reset responding state when done
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(text.count) * 0.1) {
            self.isResponding = false
        }
    }
    
    private func getSelectedVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        switch selectedVoice {
        case 1: // Male
            return voices.first { $0.gender == .male }
        case 2: // Female
            return voices.first { $0.gender == .female }
        case 3: // Child-like (higher pitch)
            return voices.first { $0.name.lowercased().contains("compact") }
        default:
            return AVSpeechSynthesisVoice(language: "en-US")
        }
    }
    
    private func addToConversationHistory(userInput: String, response: String) {
        let entry = ConversationEntry(
            userInput: userInput,
            assistantResponse: response,
            timestamp: Date()
        )
        
        conversationHistory.append(entry)
        
        // Keep only last 20 conversations
        if conversationHistory.count > 20 {
            conversationHistory.removeFirst()
        }
    }
    
    private func loadCustomCommands() {
        // Load custom commands from persistent storage
        // This is a placeholder implementation
    }
}