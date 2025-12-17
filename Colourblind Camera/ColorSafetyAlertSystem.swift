//
//  ColorSafetyAlertSystem.swift
//  Colourblind Camera
//
//  Safety alert system for critical color recognition scenarios
//

import SwiftUI
import CoreLocation
import UserNotifications
import AVFoundation
import Vision

struct ColorSafetyAlertView: View {
    @StateObject private var safetySystem = ColorSafetyAlertSystem()
    @State private var selectedScenarios: Set<SafetyScenario> = [.trafficLights, .warningLabels]
    @State private var enableLocationAlerts = true
    @State private var alertSensitivity: Float = 0.7
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Header
                StatusHeaderView(safetySystem: safetySystem)
                
                // Active Scenarios
                ActiveScenariosView(
                    scenarios: selectedScenarios,
                    safetySystem: safetySystem
                )
                
                // Recent Alerts
                if !safetySystem.recentAlerts.isEmpty {
                    RecentAlertsView(alerts: safetySystem.recentAlerts)
                }
                
                Spacer()
                
                // Emergency Contact Button
                EmergencyContactView()
            }
            .padding()
            .navigationTitle("Safety Alerts")
            .navigationBarItems(
                trailing: Button("Settings") {
                    showingSettings = true
                }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SafetySettingsView(
                selectedScenarios: $selectedScenarios,
                enableLocationAlerts: $enableLocationAlerts,
                alertSensitivity: $alertSensitivity,
                safetySystem: safetySystem
            )
        }
        .onAppear {
            safetySystem.configure(
                scenarios: selectedScenarios,
                locationAlertsEnabled: enableLocationAlerts,
                sensitivity: alertSensitivity
            )
            safetySystem.startMonitoring()
        }
        .onDisappear {
            safetySystem.stopMonitoring()
        }
    }
}

struct StatusHeaderView: View {
    @ObservedObject var safetySystem: ColorSafetyAlertSystem
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Safety Status")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(safetySystem.isActive ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(safetySystem.isActive ? "Active" : "Inactive")
                            .font(.subheadline)
                            .foregroundColor(safetySystem.isActive ? .green : .red)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Alerts Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(safetySystem.alertsToday)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            // Current detection status
            if let currentDetection = safetySystem.currentDetection {
                CurrentDetectionView(detection: currentDetection)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

struct CurrentDetectionView: View {
    let detection: SafetyDetection
    
    var body: some View {
        HStack {
            Image(systemName: detection.scenario.icon)
                .foregroundColor(detection.alertLevel.color)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(detection.scenario.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(detection.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Text(detection.alertLevel.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(detection.alertLevel.color)
                
                Text("\(Int(detection.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(detection.alertLevel.backgroundColor)
        .cornerRadius(10)
    }
}

struct ActiveScenariosView: View {
    let scenarios: Set<SafetyScenario>
    @ObservedObject var safetySystem: ColorSafetyAlertSystem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Active Scenarios")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                ForEach(Array(scenarios), id: \.self) { scenario in
                    ScenarioCard(
                        scenario: scenario,
                        isActive: true,
                        detectionCount: safetySystem.getDetectionCount(for: scenario)
                    )
                }
            }
            
            if scenarios.isEmpty {
                Text("No active safety scenarios")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
}

struct ScenarioCard: View {
    let scenario: SafetyScenario
    let isActive: Bool
    let detectionCount: Int
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: scenario.icon)
                    .font(.title2)
                    .foregroundColor(isActive ? .blue : .secondary)
                
                Spacer()
                
                if detectionCount > 0 {
                    Text("\(detectionCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                
                Text(scenario.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .opacity(isActive ? 1.0 : 0.6)
    }
}

struct RecentAlertsView: View {
    let alerts: [SafetyAlert]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Alerts")
                .font(.headline)
            
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(alerts.prefix(5), id: \.id) { alert in
                        AlertRow(alert: alert)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
    }
}

struct AlertRow: View {
    let alert: SafetyAlert
    
    var body: some View {
        HStack {
            Image(systemName: alert.scenario.icon)
                .foregroundColor(alert.alertLevel.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(alert.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if alert.isLocationBased {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct EmergencyContactView: View {
    @State private var showingEmergencyOptions = false
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Need Help?")
                .font(.headline)
            
            Button(action: { showingEmergencyOptions = true }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Emergency Assistance")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.red)
                .cornerRadius(10)
            }
            
            Text("For immediate color identification help")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .actionSheet(isPresented: $showingEmergencyOptions) {
            ActionSheet(
                title: Text("Emergency Assistance"),
                message: Text("Choose an option for immediate help"),
                buttons: [
                    .default(Text("Call Emergency Services")) {
                        if let url = URL(string: "tel://911") {
                            UIApplication.shared.open(url)
                        }
                    },
                    .default(Text("Contact Family/Friend")) {
                        // Open contacts or pre-configured emergency contact
                    },
                    .default(Text("Voice Assistant")) {
                        // Activate voice assistant for help
                    },
                    .cancel()
                ]
            )
        }
    }
}

struct SafetySettingsView: View {
    @Binding var selectedScenarios: Set<SafetyScenario>
    @Binding var enableLocationAlerts: Bool
    @Binding var alertSensitivity: Float
    let safetySystem: ColorSafetyAlertSystem
    @Environment(\.presentationMode) var presentationMode
    
    @State private var enableSound = true
    @State private var enableVibration = true
    @State private var enableNotifications = true
    @State private var emergencyContact = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Safety Scenarios")) {
                    ForEach(SafetyScenario.allCases, id: \.self) { scenario in
                        ScenarioToggleRow(
                            scenario: scenario,
                            isSelected: selectedScenarios.contains(scenario),
                            onToggle: { isSelected in
                                if isSelected {
                                    selectedScenarios.insert(scenario)
                                } else {
                                    selectedScenarios.remove(scenario)
                                }
                            }
                        )
                    }
                }
                
                Section(header: Text("Alert Settings")) {
                    VStack(alignment: .leading) {
                        Text("Sensitivity: \(Int(alertSensitivity * 100))%")
                        Slider(value: $alertSensitivity, in: 0.1...1.0, step: 0.1)
                    }
                    
                    Toggle("Location-based Alerts", isOn: $enableLocationAlerts)
                    Toggle("Sound Alerts", isOn: $enableSound)
                    Toggle("Vibration", isOn: $enableVibration)
                    Toggle("Push Notifications", isOn: $enableNotifications)
                }
                
                Section(header: Text("Emergency Contact")) {
                    TextField("Phone Number", text: $emergencyContact)
                        .keyboardType(.phonePad)
                    
                    Text("This contact will be notified in high-risk situations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Advanced")) {
                    Button("Test Alert System") {
                        safetySystem.testAlert()
                    }
                    
                    Button("Reset Alert History") {
                        safetySystem.resetHistory()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Safety Settings")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveSettings()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func saveSettings() {
        safetySystem.configure(
            scenarios: selectedScenarios,
            locationAlertsEnabled: enableLocationAlerts,
            sensitivity: alertSensitivity
        )
        
        safetySystem.updateAlertSettings(
            sound: enableSound,
            vibration: enableVibration,
            notifications: enableNotifications
        )
        
        if !emergencyContact.isEmpty {
            safetySystem.setEmergencyContact(emergencyContact)
        }
    }
}

struct ScenarioToggleRow: View {
    let scenario: SafetyScenario
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: scenario.icon)
                .foregroundColor(isSelected ? .blue : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(scenario.rawValue)
                    .font(.subheadline)
                
                Text(scenario.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: onToggle
            ))
        }
    }
}

// MARK: - Supporting Models and Enums

enum SafetyScenario: String, CaseIterable {
    case trafficLights = "Traffic Lights"
    case warningLabels = "Warning Labels"
    case medicalAlerts = "Medical Alerts"
    case foodSafety = "Food Safety"
    case chemicalLabels = "Chemical Labels"
    case emergencySignage = "Emergency Signs"
    case navigationSigns = "Navigation Signs"
    
    var icon: String {
        switch self {
        case .trafficLights: return "traffic.light"
        case .warningLabels: return "exclamationmark.triangle.fill"
        case .medicalAlerts: return "cross.circle.fill"
        case .foodSafety: return "fork.knife.circle.fill"
        case .chemicalLabels: return "flame.circle.fill"
        case .emergencySignage: return "escape.hatch"
        case .navigationSigns: return "arrow.triangle.turn.up.right.diamond.fill"
        }
    }
    
    var description: String {
        switch self {
        case .trafficLights: return "Red, yellow, green traffic signals"
        case .warningLabels: return "Danger and caution warnings"
        case .medicalAlerts: return "Medicine and medical device colors"
        case .foodSafety: return "Food spoilage and safety indicators"
        case .chemicalLabels: return "Hazardous material warnings"
        case .emergencySignage: return "Exit and emergency indicators"
        case .navigationSigns: return "Directional and location signs"
        }
    }
    
    var criticalColors: [String] {
        switch self {
        case .trafficLights: return ["Red", "Yellow", "Green"]
        case .warningLabels: return ["Red", "Orange", "Yellow"]
        case .medicalAlerts: return ["Red", "Blue", "Green", "Yellow"]
        case .foodSafety: return ["Green", "Yellow", "Red", "Brown"]
        case .chemicalLabels: return ["Red", "Orange", "Yellow", "Blue"]
        case .emergencySignage: return ["Red", "Green"]
        case .navigationSigns: return ["Blue", "Green", "Red"]
        }
    }
}

enum AlertLevel: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
    
    var backgroundColor: Color {
        return color.opacity(0.1)
    }
}

struct SafetyDetection {
    let id = UUID()
    let scenario: SafetyScenario
    let alertLevel: AlertLevel
    let confidence: Float
    let description: String
    let location: CLLocation?
    let timestamp: Date
    let detectedColors: [String]
}

struct SafetyAlert {
    let id = UUID()
    let scenario: SafetyScenario
    let alertLevel: AlertLevel
    let title: String
    let message: String
    let timestamp: Date
    let location: CLLocation?
    let isLocationBased: Bool
    let wasActionTaken: Bool
}

// MARK: - Color Safety Alert System
class ColorSafetyAlertSystem: NSObject, ObservableObject {
    @Published var isActive = false
    @Published var currentDetection: SafetyDetection?
    @Published var recentAlerts: [SafetyAlert] = []
    @Published var alertsToday: Int = 0
    
    private var activeScenarios: Set<SafetyScenario> = []
    private var locationManager = CLLocationManager()
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var hapticFeedback = UINotificationFeedbackGenerator()
    
    // Settings
    private var locationAlertsEnabled = true
    private var sensitivity: Float = 0.7
    private var soundEnabled = true
    private var vibrationEnabled = true
    private var notificationsEnabled = true
    private var emergencyContact: String?
    
    // Detection counters
    private var detectionCounts: [SafetyScenario: Int] = [:]
    
    override init() {
        super.init()
        setupLocationManager()
        setupNotifications()
    }
    
    func configure(scenarios: Set<SafetyScenario>, locationAlertsEnabled: Bool, sensitivity: Float) {
        self.activeScenarios = scenarios
        self.locationAlertsEnabled = locationAlertsEnabled
        self.sensitivity = sensitivity
        
        // Reset detection counts
        detectionCounts = [:]
        for scenario in scenarios {
            detectionCounts[scenario] = 0
        }
    }
    
    func startMonitoring() {
        isActive = true
        
        if locationAlertsEnabled {
            locationManager.startUpdatingLocation()
        }
        
        // Start color detection monitoring
        startColorDetectionMonitoring()
    }
    
    func stopMonitoring() {
        isActive = false
        locationManager.stopUpdatingLocation()
        currentDetection = nil
    }
    
    func getDetectionCount(for scenario: SafetyScenario) -> Int {
        return detectionCounts[scenario] ?? 0
    }
    
    func updateAlertSettings(sound: Bool, vibration: Bool, notifications: Bool) {
        soundEnabled = sound
        vibrationEnabled = vibration
        notificationsEnabled = notifications
    }
    
    func setEmergencyContact(_ contact: String) {
        emergencyContact = contact
    }
    
    func testAlert() {
        let testDetection = SafetyDetection(
            scenario: .trafficLights,
            alertLevel: .medium,
            confidence: 0.9,
            description: "Test alert - Red traffic light detected",
            location: locationManager.location,
            timestamp: Date(),
            detectedColors: ["Red"]
        )
        
        processDetection(testDetection)
    }
    
    func resetHistory() {
        recentAlerts.removeAll()
        alertsToday = 0
        detectionCounts = [:]
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    private func startColorDetectionMonitoring() {
        // This would integrate with the camera system to continuously monitor for safety scenarios
        // For now, we'll simulate periodic detection
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.simulateDetection()
        }
    }
    
    private func simulateDetection() {
        guard isActive, !activeScenarios.isEmpty else { return }
        
        // Simulate random detection
        if Float.random(in: 0...1) < 0.1 { // 10% chance of detection
            let randomScenario = activeScenarios.randomElement()!
            let detection = SafetyDetection(
                scenario: randomScenario,
                alertLevel: .medium,
                confidence: Float.random(in: 0.6...0.9),
                description: "Detected \(randomScenario.criticalColors.randomElement()!) in \(randomScenario.rawValue.lowercased())",
                location: locationManager.location,
                timestamp: Date(),
                detectedColors: [randomScenario.criticalColors.randomElement()!]
            )
            
            processDetection(detection)
        }
    }
    
    private func processDetection(_ detection: SafetyDetection) {
        currentDetection = detection
        
        // Update detection count
        detectionCounts[detection.scenario, default: 0] += 1
        
        // Determine if alert should be triggered
        if shouldTriggerAlert(for: detection) {
            triggerAlert(for: detection)
        }
        
        // Clear current detection after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.currentDetection?.id == detection.id {
                self.currentDetection = nil
            }
        }
    }
    
    private func shouldTriggerAlert(for detection: SafetyDetection) -> Bool {
        // Check confidence threshold
        guard detection.confidence >= sensitivity else { return false }
        
        // Check if we've already alerted for this scenario recently
        let recentAlertExists = recentAlerts.contains { alert in
            alert.scenario == detection.scenario &&
            Date().timeIntervalSince(alert.timestamp) < 60 // Within last minute
        }
        
        return !recentAlertExists
    }
    
    private func triggerAlert(for detection: SafetyDetection) {
        let alert = SafetyAlert(
            scenario: detection.scenario,
            alertLevel: detection.alertLevel,
            title: "\(detection.scenario.rawValue) Alert",
            message: detection.description,
            timestamp: Date(),
            location: detection.location,
            isLocationBased: detection.location != nil,
            wasActionTaken: false
        )
        
        recentAlerts.insert(alert, at: 0)
        alertsToday += 1
        
        // Provide feedback
        provideFeedback(for: alert)
        
        // Send notification if enabled
        if notificationsEnabled {
            sendNotification(for: alert)
        }
        
        // Check if emergency contact should be notified
        if detection.alertLevel == .critical, let contact = emergencyContact {
            notifyEmergencyContact(contact, alert: alert)
        }
    }
    
    private func provideFeedback(for alert: SafetyAlert) {
        // Voice announcement
        if soundEnabled {
            let utterance = AVSpeechUtterance(string: alert.message)
            utterance.rate = 0.6
            utterance.volume = 1.0
            speechSynthesizer.speak(utterance)
        }
        
        // Haptic feedback
        if vibrationEnabled {
            switch alert.alertLevel {
            case .low:
                hapticFeedback.notificationOccurred(.success)
            case .medium:
                hapticFeedback.notificationOccurred(.warning)
            case .high, .critical:
                hapticFeedback.notificationOccurred(.error)
            }
        }
    }
    
    private func sendNotification(for alert: SafetyAlert) {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func notifyEmergencyContact(_ contact: String, alert: SafetyAlert) {
        // This would send SMS or call emergency contact
        print("Notifying emergency contact \(contact) about \(alert.title)")
    }
}

// MARK: - CLLocationManagerDelegate
extension ColorSafetyAlertSystem: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Process location-based safety scenarios
        if let location = locations.last {
            checkLocationBasedScenarios(at: location)
        }
    }
    
    private func checkLocationBasedScenarios(at location: CLLocation) {
        // This would check for known dangerous locations or intersection
        // For now, this is a placeholder
    }
}