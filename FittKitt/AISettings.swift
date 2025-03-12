//
//  AISettings.swift
//  FittKitt
//
//  Created on 3/11/25.
//

import SwiftUI

/// Manages AI-related settings and preferences for the app
class AISettingsManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Controls whether AI workout suggestions are enabled
    @Published var enableWorkoutSuggestions: Bool = true
    
    /// Controls whether voice coaching is enabled during workouts
    @Published var enableVoiceCoaching: Bool = true
    
    /// Controls whether the app learns from your workout history
    @Published var enablePersonalizedLearning: Bool = true
    
    /// Sets the guidance level (1-10) with 10 being most detailed
    @Published var guidanceLevel: Double = 7
    
    /// Controls workout difficulty adjustment rate
    @Published var adaptationSpeed: Double = 5
    
    // MARK: - Private Properties
    private let defaults = UserDefaults.standard
    private let suggestionsKey = "ai_enableWorkoutSuggestions"
    private let voiceCoachingKey = "ai_enableVoiceCoaching"
    private let learningKey = "ai_enablePersonalizedLearning"
    private let guidanceKey = "ai_guidanceLevel"
    private let adaptationKey = "ai_adaptationSpeed"
    
    // MARK: - Initialization
    
    init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Loads user settings from UserDefaults
    func loadSettings() {
        enableWorkoutSuggestions = defaults.bool(forKey: suggestionsKey, defaultValue: true)
        enableVoiceCoaching = defaults.bool(forKey: voiceCoachingKey, defaultValue: true)
        enablePersonalizedLearning = defaults.bool(forKey: learningKey, defaultValue: true)
        guidanceLevel = defaults.double(forKey: guidanceKey, defaultValue: 7)
        adaptationSpeed = defaults.double(forKey: adaptationKey, defaultValue: 5)
    }
    
    /// Saves all current settings to UserDefaults
    func saveSettings() {
        defaults.set(enableWorkoutSuggestions, forKey: suggestionsKey)
        defaults.set(enableVoiceCoaching, forKey: voiceCoachingKey)
        defaults.set(enablePersonalizedLearning, forKey: learningKey)
        defaults.set(guidanceLevel, forKey: guidanceKey)
        defaults.set(adaptationSpeed, forKey: adaptationKey)
    }
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        enableWorkoutSuggestions = true
        enableVoiceCoaching = true  
        enablePersonalizedLearning = true
        guidanceLevel = 7
        adaptationSpeed = 5
        saveSettings()
    }
    
    /// Returns a description of the current guidance level
    var guidanceLevelDescription: String {
        switch Int(guidanceLevel) {
        case 1...3:
            return "Minimal guidance - brief exercise instructions"
        case 4...7:
            return "Standard guidance - form tips and encouragement"
        case 8...10:
            return "Detailed guidance - comprehensive form coaching"
        default:
            return "Standard guidance"
        }
    }
    
    /// Returns a description of the current adaptation speed
    var adaptationSpeedDescription: String {
        switch Int(adaptationSpeed) {
        case 1...3:
            return "Slow adaptation - gradual workout difficulty changes"
        case 4...7:
            return "Medium adaptation - balanced adjustment rate"
        case 8...10:
            return "Fast adaptation - quick workout difficulty changes"
        default:
            return "Medium adaptation"
        }
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    /// Get a boolean with a default value if key doesn't exist
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        return object(forKey: key) == nil ? defaultValue : bool(forKey: key)
    }
    
    /// Get a double with a default value if key doesn't exist
    func double(forKey key: String, defaultValue: Double) -> Double {
        return object(forKey: key) == nil ? defaultValue : double(forKey: key)
    }
}

// MARK: - AI Settings View

struct AISettingsView: View {
    @StateObject private var settings = AISettingsManager()
    @Environment(\.dismiss) private var dismiss
    @State private var hasChanges = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        .luxuryBackgroundTop,
                        .luxuryBackgroundBottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // AI Features Section
                        featuresSection
                        
                        // AI Behavior Section
                        behaviorSection
                        
                        // Reset button
                        Button("Reset to Default Settings") {
                            settings.resetToDefaults()
                            hasChanges = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if hasChanges {
                            settings.saveSettings()
                        }
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.luxuryAccent)
                }
            }
        }
    }
    
    // MARK: - Feature Toggles Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Features")
                .font(.headline)
                .foregroundColor(.luxuryText)
                .padding(.bottom, 4)
            
            Toggle(isOn: $settings.enableWorkoutSuggestions.onChange { _ in hasChanges = true }) {
                VStack(alignment: .leading) {
                    Text("Workout Suggestions")
                        .foregroundColor(.luxuryText)
                    Text("Get AI-powered workout recommendations")
                        .font(.caption)
                        .foregroundColor(.luxuryText.opacity(0.7))
                }
            }
            .tint(.luxuryAccent)
            
            Divider().background(Color.luxuryText.opacity(0.3))
            
            Toggle(isOn: $settings.enableVoiceCoaching.onChange { _ in hasChanges = true }) {
                VStack(alignment: .leading) {
                    Text("Voice Coaching")
                        .foregroundColor(.luxuryText)
                    Text("Receive verbal guidance during workouts")
                        .font(.caption)
                        .foregroundColor(.luxuryText.opacity(0.7))
                }
            }
            .tint(.luxuryAccent)
            
            Divider().background(Color.luxuryText.opacity(0.3))
            
            Toggle(isOn: $settings.enablePersonalizedLearning.onChange { _ in hasChanges = true }) {
                VStack(alignment: .leading) {
                    Text("Personalized Learning")
                        .foregroundColor(.luxuryText)
                    Text("Allow AI to adapt based on your performance")
                        .font(.caption)
                        .foregroundColor(.luxuryText.opacity(0.7))
                }
            }
            .tint(.luxuryAccent)
        }
        .padding()
        .background(Color.luxuryCardBg)
        .cornerRadius(15)
    }
    
    // MARK: - AI Behavior Configuration
    
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Behavior")
                .font(.headline)
                .foregroundColor(.luxuryText)
                .padding(.bottom, 4)
            
            // Guidance Level
            VStack(alignment: .leading, spacing: 10) {
                Text("Guidance Detail Level")
                    .foregroundColor(.luxuryText)
                
                HStack {
                    Text("Basic")
                        .foregroundColor(.luxuryText.opacity(0.7))
                        .font(.caption)
                    Slider(value: $settings.guidanceLevel.onChange { _ in hasChanges = true }, 
                           in: 1...10, 
                           step: 1)
                        .tint(.luxuryAccent)
                        .frame(height: 44) // Proper touch target
                    Text("Detailed")
                        .foregroundColor(.luxuryText.opacity(0.7))
                        .font(.caption)
                }
                
                Text(settings.guidanceLevelDescription)
                    .font(.caption)
                    .foregroundColor(.luxuryAccent)
            }
            
            Divider().background(Color.luxuryText.opacity(0.3))
            
            // Adaptation Speed
            VStack(alignment: .leading, spacing: 10) {
                Text("Workout Adaptation Speed")
                    .foregroundColor(.luxuryText)
                
                HStack {
                    Text("Gradual")
                        .foregroundColor(.luxuryText.opacity(0.7))
                        .font(.caption)
                    Slider(value: $settings.adaptationSpeed.onChange { _ in hasChanges = true }, 
                           in: 1...10, 
                           step: 1)
                        .tint(.luxuryAccent)
                        .frame(height: 44) // Proper touch target
                    Text("Rapid")
                        .foregroundColor(.luxuryText.opacity(0.7))
                        .font(.caption)
                }
                
                Text(settings.adaptationSpeedDescription)
                    .font(.caption)
                    .foregroundColor(.luxuryAccent)
            }
        }
        .padding()
        .background(Color.luxuryCardBg)
        .cornerRadius(15)
    }
}

// MARK: - Binding Extension for Change Detection

extension Binding {
    /// Adds change handler to Binding
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

#Preview {
    AISettingsView()
} 