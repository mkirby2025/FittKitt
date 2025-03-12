//
//  ContentView.swift
//  FittKitt
//
//  Created by Madeline Crawford on 2/23/25.
//

import SwiftUI
import AVFoundation

// Add these color extensions at the top of the file
extension Color {
    static let luxuryDark = Color(red: 20/255, green: 28/255, blue: 45/255)       // Dark blue base
    static let luxuryMid = Color(red: 41/255, green: 63/255, blue: 107/255)       // Medium blue
    static let luxuryAccent = Color(red: 103/255, green: 157/255, blue: 237/255)  // Bright blue
    static let luxuryBackgroundTop = Color(red: 31/255, green: 41/255, blue: 61/255)    // Lighter navy
    static let luxuryBackgroundBottom = Color(red: 25/255, green: 33/255, blue: 51/255)  // Darker navy
    static let luxuryCardBg = Color(red: 37/255, green: 49/255, blue: 75/255)     // Card background
    static let luxuryText = Color(red: 226/255, green: 232/255, blue: 240/255)    // Light gray text
}

// Add this view modifier for card styling
struct LuxuryCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.luxuryCardBg)
                    .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.luxuryAccent.opacity(0.3), lineWidth: 1)
            )
    }
}

// Custom font extension
extension Font {
    static func customTitle() -> Font {
        .custom("Avenir-Heavy", size: 32)
    }
    
    static func customHeading() -> Font {
        .custom("Avenir-Medium", size: 24)
    }
}

// Add AudioManager to handle sounds
class AudioManager {
    static let shared = AudioManager()
    private var audioPlayer: AVAudioPlayer?
    
    func playSound(for event: WorkoutEvent) {
        guard let soundURL = Bundle.main.url(forResource: event.soundFile, withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
}

enum WorkoutEvent {
    case startWork
    case startRest
    case lastThreeSeconds
    case complete
    
    var soundFile: String {
        switch self {
        case .startWork: return "start_work"
        case .startRest: return "start_rest"
        case .lastThreeSeconds: return "countdown"
        case .complete: return "complete"
        }
    }
}

struct ContentView: View {
    @State private var workoutDuration: Double = 30 // in minutes
    @State private var numberOfExercises: Double = 5
    @State private var intensity: Double = 5
    @State private var hasStartedWorkout = false
    @State private var showingPersonalization = false
    @State private var workoutHistory = WorkoutHistoryManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Keep the background gradient
                LinearGradient(
                    colors: [
                        .luxuryBackgroundTop,
                        .luxuryBackgroundBottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .overlay(
                    Color.black.opacity(0.02)
                        .blendMode(.multiply)
                )
                .ignoresSafeArea()
                
                // Add ScrollView to ensure all content is accessible
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 25) {
                        Text("Let's Plan Your Workout")
                            .font(.customHeading())
                            .foregroundColor(.luxuryText)
                            .padding(.top, 20)
                        
                        // NEW: Workout History Section
                        WorkoutHistoryView(workoutHistory: workoutHistory)
                        
                        // Group related controls together with visual separation
                        VStack(spacing: 20) { // Increased spacing between major sections
                            // Workout configuration section
                            VStack(spacing: 16) { // Consistent spacing within a section
                                Text("Configure Your Workout")
                                    .font(.headline)
                                    .foregroundColor(.luxuryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Duration control
                                workoutDurationControl
                                
                                // Exercise count control
                                exerciseCountControl
                                
                                // Intensity control
                                intensityControl
                            }
                            .padding()
                            .background(Color.luxuryCardBg.opacity(0.7))
                            .cornerRadius(15)
                            
                            // Action buttons with proper spacing and sizing
                            HStack(spacing: 16) {
                                Button("Reset") {
                                    resetWorkoutSettings()
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                
                                Button("Start Workout") {
                                    startWorkout()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationDestination(isPresented: $hasStartedWorkout) {
                WorkoutView(duration: Int(workoutDuration),
                          exercises: Int(numberOfExercises),
                          intensity: Int(intensity))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("FITTKITT")
                        .font(.customTitle())
                        .foregroundColor(.luxuryAccent)
                        .shadow(color: .luxuryAccent.opacity(0.5), radius: 10, x: 0, y: 0)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingPersonalization = true
                    }) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.luxuryAccent)
                    }
                }
            }
            .sheet(isPresented: $showingPersonalization) {
                PersonalizationView()
            }
            .onAppear {
                // Load workout history when view appears
                workoutHistory.loadWorkouts()
            }
        }
    }
    
    // Duration control
    var workoutDurationControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How much time do you have?")
                .font(.headline)
                .foregroundColor(.luxuryText)
                
            HStack {
                Slider(value: $workoutDuration, in: 5...120, step: 5)
                    .tint(.luxuryAccent)
                    .frame(height: 44) // Ensure minimum height for touch
                Text("\(Int(workoutDuration)) min")
                    .frame(width: 60)
                    .foregroundColor(.white)
            }
            .padding(.top, 4)
        }
    }
    
    // Exercise count control
    var exerciseCountControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Number of exercises")
                .font(.headline)
                .foregroundColor(.luxuryText)
                
            HStack {
                Slider(value: $numberOfExercises, in: 3...15, step: 1)
                    .tint(.luxuryAccent)
                    .frame(height: 44) // Ensure minimum height for touch
                Text("\(Int(numberOfExercises))")
                    .frame(width: 40)
                    .foregroundColor(.white)
            }
            .padding(.top, 4)
        }
    }
    
    // Intensity control
    var intensityControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Workout intensity")
                .font(.headline)
                .foregroundColor(.luxuryText)
                
            HStack {
                Text("Low")
                    .foregroundColor(.luxuryText.opacity(0.7))
                Slider(value: $intensity, in: 1...10, step: 1)
                    .tint(.luxuryAccent)
                    .frame(height: 44) // Ensure minimum height for touch
                Text("High")
                    .foregroundColor(.luxuryText.opacity(0.7))
            }
            .padding(.top, 4)
            
            Text(intensityDescription)
                .font(.caption)
                .foregroundColor(.luxuryAccent)
                .opacity(0.9)
        }
    }
    
    // Reset workout settings
    func resetWorkoutSettings() {
        workoutDuration = 30
        numberOfExercises = 5
        intensity = 5
    }
    
    // Start workout
    func startWorkout() {
        hasStartedWorkout = true
    }
    
    // Intensity description
    var intensityDescription: String {
        switch Int(intensity) {
        case 1...3:
            return "Low intensity - good for beginners or recovery days"
        case 4...7:
            return "Moderate intensity - balanced workout"
        case 8...10:
            return "High intensity - challenging workout for experienced users"
        default:
            return ""
        }
    }
}

// Add this model for Tabata exercises
struct TabataExercise: Identifiable {
    let id = UUID()
    let name: String
    let workSeconds: Int = 30  // Work period
    let restSeconds: Int = 15  // Rest period between exercises
    
    var totalDuration: Int {
        workSeconds + restSeconds
    }
}

// Add this transition view
struct ExerciseTransitionView: View {
    let nextExercise: String
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 15) {
            Text("NEXT UP")
                .font(.headline)
                .foregroundColor(.luxuryText.opacity(0.8))
            
            Text(nextExercise)
                .font(.title)
                .bold()
                .foregroundColor(.luxuryAccent)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// Update WorkoutTimerManager to handle both work and rest periods
class WorkoutTimerManager: ObservableObject {
    @Published var timeRemaining: Int = 30
    @Published var currentExerciseIndex = 0
    @Published var isActive = false
    @Published var isPaused = false
    @Published var isWorkoutComplete = false
    @Published var isResting = false // Add this to track rest periods
    
    private var timer: Timer?
    private var exercises: [TabataExercise] = []
    
    func startWorkout(with exercises: [TabataExercise]) {
        self.exercises = exercises
        self.isActive = true
        self.isPaused = false
        self.currentExerciseIndex = 0
        self.isResting = false
        self.timeRemaining = exercises[0].workSeconds
        self.isWorkoutComplete = false
        
        AudioManager.shared.playSound(for: .startWork)
        startTimer()
    }
    
    func pauseWorkout() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    func resumeWorkout() {
        isPaused = false
        startTimer()
    }
    
    func stopWorkout() {
        timer?.invalidate()
        timer = nil
        isActive = false
        isPaused = false
        timeRemaining = 30
        currentExerciseIndex = 0
        isWorkoutComplete = true
        AudioManager.shared.playSound(for: .complete)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        if timeRemaining > 0 {
            if timeRemaining <= 3 {
                AudioManager.shared.playSound(for: .lastThreeSeconds)
            }
            timeRemaining -= 1
        } else {
            if isResting {
                moveToNextExercise()
            } else {
                startRestPeriod()
            }
        }
    }
    
    private func startRestPeriod() {
        isResting = true
        timeRemaining = exercises[currentExerciseIndex].restSeconds
        AudioManager.shared.playSound(for: .startRest)
    }
    
    private func moveToNextExercise() {
        currentExerciseIndex += 1
        if currentExerciseIndex >= exercises.count {
            stopWorkout()
            return
        }
        
        isResting = false
        timeRemaining = exercises[currentExerciseIndex].workSeconds
        AudioManager.shared.playSound(for: .startWork)
    }
}

// Add this struct for tracking workout history
struct WorkoutHistoryManager {
    // Array to store completed workouts
    private(set) var completedWorkouts: [WorkoutLog] = []
    
    // Current streak of consecutive days with workouts
    var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    // Longest ever streak
    var longestStreak: Int {
        calculateLongestStreak()
    }
    
    // Add a completed workout to history
    mutating func addWorkout(_ workout: WorkoutLog) {
        completedWorkouts.append(workout)
        // Sort by date descending (newest first)
        completedWorkouts.sort { $0.date > $1.date }
        
        // In a real app, would save to persistent storage
        saveWorkouts()
    }
    
    // Calculate current streak of consecutive workout days
    private func calculateCurrentStreak() -> Int {
        guard !completedWorkouts.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 1
        var lastDate = calendar.startOfDay(for: completedWorkouts[0].date)
        
        // Start from the second workout (if any)
        for i in 1..<completedWorkouts.count {
            let currentDate = calendar.startOfDay(for: completedWorkouts[i].date)
            
            // Check if this workout was completed on the day before lastDate
            if let dayBefore = calendar.date(byAdding: .day, value: -1, to: lastDate),
               calendar.isDate(currentDate, inSameDayAs: dayBefore) {
                streak += 1
                lastDate = currentDate
            } else if !calendar.isDate(currentDate, inSameDayAs: lastDate) {
                // If not consecutive and not the same day, break the streak
                break
            }
        }
        
        return streak
    }
    
    // Calculate longest streak ever achieved
    private func calculateLongestStreak() -> Int {
        guard !completedWorkouts.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var currentStreak = 1
        var maxStreak = 1
        var lastDate = calendar.startOfDay(for: completedWorkouts[0].date)
        
        for i in 1..<completedWorkouts.count {
            let currentDate = calendar.startOfDay(for: completedWorkouts[i].date)
            
            if let dayBefore = calendar.date(byAdding: .day, value: -1, to: lastDate),
               calendar.isDate(currentDate, inSameDayAs: dayBefore) {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else if !calendar.isDate(currentDate, inSameDayAs: lastDate) {
                currentStreak = 1
            }
            
            lastDate = currentDate
        }
        
        return maxStreak
    }
    
    // Save workouts to UserDefaults (in a real app might use CoreData)
    private func saveWorkouts() {
        // Implementation would encode and save the data
    }
    
    // Load workouts from storage
    mutating func loadWorkouts() {
        // Implementation would load and decode the data
    }
}

// Add this struct for tracking workout history
struct WorkoutLog: Identifiable, Codable {
    var id = UUID() // Changed from 'let' to 'var' to fix the warning
    let date: Date
    let duration: Int
    let exercises: Int
    let intensity: Int
    let completed: Bool
}

// Break WorkoutView into smaller components to prevent compiler timeout
struct WorkoutView: View {
    let duration: Int
    let exercises: Int
    let intensity: Int
    
    @StateObject private var timerManager = WorkoutTimerManager()
    @Environment(\.presentationMode) var presentationMode
    @State private var workoutSeed = UUID()
    @State private var workoutDate = Date()
    @State private var isLoggingWorkout = false
    
    // Update the low-intensity exercises list with the specific exercises
    private let lowIntensityExercises = [
        // Walking/Movement
        "Walking in Place",
        "Marching in Place",
        "Toe Taps",
        "Heel-to-toe Walk",
        
        // Seated Exercises
        "Seated Leg Lifts",
        "Seated Knee Extensions",
        "Seated Torso Twists",
        
        // Standing Exercises
        "Wall Push-ups",
        "Standing Calf Raises",
        "Side Leg Lifts",
        "Standing Side Bends",
        "Chair-assisted Squats",
        
        // Floor Exercises
        "Glute Bridges",
        "Pelvic Tilts",
        "Bird-dog Exercise",
        "Dead Bug Exercise",
        
        // Upper Body
        "Shoulder Rolls",
        "Neck Stretches",
        "Gentle Arm Circles",
        
        // Controlled Movements
        "Slow Controlled Lunges"
    ]
    
    // Update the moderate-intensity exercises list with only the specified exercises
    private let moderateIntensityExercises = [
        // Lower body
        "Bodyweight Squats",
        "Goblet Squats",
        "Lunges with Dumbbells",
        "Step-ups",
        "Bulgarian Split Squats",
        "Romanian Deadlifts",
        "Calf Raises with Dumbbells",
        "Glute Bridges with Dumbbell",
        "Hip Thrusts with Resistance Band",
        "Side-lying Leg Lifts with Band",
        
        // Upper body
        "Push-ups",
        "Incline Push-ups",
        "Dumbbell Bench Press",
        "Dumbbell Shoulder Press",
        "Bent-over Dumbbell Rows",
        "Dumbbell Bicep Curls",
        "Triceps Dips",
        "Overhead Triceps Extensions",
        "Lateral Raises with Dumbbells",
        "Front Raises with Dumbbells",
        
        // Core/Functional
        "Plank with Shoulder Taps",
        "Side Plank with Hip Dips",
        "Russian Twists with Dumbbell",
        "Bicycle Crunches",
        "Dead Bug Exercise with Resistance Bands",
        "Seated Resistance Band Rows",
        "Resistance Band Lateral Walks",
        "Resistance Band Shoulder Presses",
        "Standing Banded Leg Curls",
        "Band-assisted Pull-aparts"
    ]
    
    // Update the high-intensity exercises with the specified challenging/intense exercises
    private let highIntensityExercises = [
        // Lower body
        "Jump Squats",
        "Bulgarian Split Squats with Dumbbells",
        "Jump Lunges",
        "Pistol Squats",
        "Step-ups with Dumbbells",
        "Romanian Deadlifts with Heavy Dumbbells",
        "Glute Bridges with Resistance Band and Dumbbell",
        "Wall Sits with Dumbbell Press",
        "Explosive Calf Raises",
        "Banded Lateral Walks",
        
        // Upper body
        "Burpees",
        "Push-up to Dumbbell Row",
        "Clap Push-ups",
        "Handstand Push-ups Against Wall",
        "Dumbbell Thrusters",
        "Overhead Dumbbell Press with Squat",
        "Renegade Rows with Dumbbells",
        "Triceps Dips",
        "Bicep Curls to Shoulder Press",
        "Resistance Band Overhead Presses",
        
        // Core/Functional
        "Plank with Dumbbell Drag",
        "Side Plank with Resistance Band Row",
        "Russian Twists with Heavy Dumbbell",
        "Hanging Knee Raises with Resistance Band",
        "Mountain Climbers at High Speed",
        "Bicycle Crunches with Dumbbell Hold",
        "Jumping Jacks with Resistance Bands",
        "Medicine Ball Slams",
        "Kettlebell Swings",
        "Battle Rope Exercises"
    ]
    
    // Update the tabataWorkout logic to match intensity descriptions
    var tabataWorkout: [TabataExercise] {
        // Select exercise pool based on intensity
        let exercisePool: [String]
        
        switch intensity {
        case 1...3:
            // Light intensity (1-3)
            exercisePool = lowIntensityExercises
        case 4...6:
            // Moderate intensity (4-6)
            exercisePool = moderateIntensityExercises
        case 7...10:
            // High intensity (7-10)
            exercisePool = highIntensityExercises
        default:
            exercisePool = moderateIntensityExercises // Fallback
        }
        
        // Shuffle and select the required number of exercises
        return exercisePool.shuffled().prefix(exercises).map { exercise in
            TabataExercise(name: exercise)
        }
    }
    
    // Formatted date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: workoutDate)
    }
    
    var body: some View {
        WorkoutContentView(
            duration: duration,
            exercises: exercises,
            intensity: intensity,
            timerManager: timerManager,
            tabataWorkout: tabataWorkout,
            formattedDate: formattedDate,
            isLoggingWorkout: $isLoggingWorkout,
            presentationMode: presentationMode,
            logWorkout: logWorkout
        )
    }
    
    // Function to log completed workouts
    private func logWorkout(completed: Bool) {
        // Create workout log
        // Use _ to address the warning about unused variable
        _ = WorkoutLog(
            date: workoutDate,
            duration: duration,
            exercises: exercises,
            intensity: intensity,
            completed: completed
        )
        
        // In a real app, would save to UserDefaults or a database
        print("Workout logged: \(formattedDate), \(completed ? "Completed" : "Partial")")
    }
}

// Create a separate content view to reduce complexity
struct WorkoutContentView: View {
    let duration: Int
    let exercises: Int
    let intensity: Int
    let timerManager: WorkoutTimerManager
    let tabataWorkout: [TabataExercise]
    let formattedDate: String
    @Binding var isLoggingWorkout: Bool
    let presentationMode: Binding<PresentationMode>
    let logWorkout: (Bool) -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.luxuryBackgroundTop, .luxuryBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Text("Today's Workout")
                    .font(.customHeading())
                    .foregroundColor(.luxuryText)
                
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.luxuryAccent)
                    .padding(.top, -15)
                
                if timerManager.isWorkoutComplete {
                    WorkoutCompletionView(logWorkout: logWorkout, presentationMode: presentationMode)
                } else if !timerManager.isActive {
                    WorkoutPreviewView(tabataWorkout: tabataWorkout, timerManager: timerManager)
                } else {
                    ActiveWorkoutView(timerManager: timerManager, tabataWorkout: tabataWorkout)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    if timerManager.isActive {
                        isLoggingWorkout = true
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Exit")
                        .foregroundColor(.luxuryAccent)
                }
            )
            .alert("End Workout?", isPresented: $isLoggingWorkout) {
                Button("Save Progress") {
                    logWorkout(false)
                    presentationMode.wrappedValue.dismiss()
                }
                
                Button("Discard", role: .destructive) {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Button("Continue Workout", role: .cancel) { }
            } message: {
                Text("Do you want to save your progress or discard this workout?")
            }
        }
    }
}

// Define the WorkoutCompletionView
struct WorkoutCompletionView: View {
    let logWorkout: (Bool) -> Void
    let presentationMode: Binding<PresentationMode>
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.luxuryAccent)
            
            Text("Workout Complete!")
                .font(.title)
                .foregroundColor(.luxuryText)
            
            Text("Great job!")
                .font(.headline)
                .foregroundColor(.luxuryText.opacity(0.8))
            
            Button(action: {
                logWorkout(true)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Save and Return Home")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.luxuryAccent)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(Color.luxuryCardBg.opacity(0.7))
        .cornerRadius(15)
        .padding()
    }
}

// Update TimerDisplay to show work/rest status
struct TimerDisplay: View {
    let timeRemaining: Int
    let exerciseName: String
    let isResting: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Text(isResting ? "REST" : "WORK")
                .font(.title)
                .foregroundColor(isResting ? .luxuryAccent : .luxuryText)
            
            Text("\(timeRemaining)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.luxuryText)
                .contentTransition(.numericText())
            
            Text(exerciseName)
                .font(.title2)
                .foregroundColor(isResting ? .luxuryText.opacity(0.7) : .luxuryAccent)
            
            // Progress indicator
            Text(isResting ? "Rest before next exercise" : "Complete the exercise")
                .font(.subheadline)
                .foregroundColor(.luxuryText.opacity(0.8))
        }
        .padding()
        .background(Color.luxuryCardBg)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isResting ? Color.luxuryAccent.opacity(0.3) : Color.luxuryAccent, lineWidth: isResting ? 1 : 2)
        )
    }
}

// Update TabataExerciseRow to show more status information
struct TabataExerciseRow: View {
    let exercise: TabataExercise
    let isActive: Bool
    let isCompleted: Bool
    let isNext: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if isActive {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.luxuryAccent)
                } else if isNext {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.luxuryAccent.opacity(0.7))
                }
                
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(isActive ? .luxuryAccent : 
                                   isCompleted ? .luxuryText.opacity(0.5) :
                                   isNext ? .luxuryText : .luxuryText.opacity(0.8))
            }
            
            HStack {
                Label("\(exercise.workSeconds)s", systemImage: "bolt.fill")
                    .foregroundColor(isActive ? .luxuryAccent : .luxuryText.opacity(0.8))
            }
            .font(.caption)
        }
        .padding()
        .background(Color.luxuryCardBg)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isActive ? Color.luxuryAccent :
                    isNext ? Color.luxuryAccent.opacity(0.4) :
                    Color.luxuryAccent.opacity(0.2),
                    lineWidth: isActive ? 2 : 1
                )
        )
        .opacity(isCompleted ? 0.6 : 1.0)
    }
}

// Helper views
struct WorkoutStat: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.luxuryText.opacity(0.8))
            Text(value)
                .font(.headline)
                .foregroundColor(.luxuryText)
        }
    }
}

struct ExerciseRow: View {
    let number: Int
    let name: String
    let duration: Int
    
    var body: some View {
        HStack {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(
                    LinearGradient(
                        colors: [.luxuryAccent, .luxuryMid],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
            
            Text(name)
                .font(.headline)
                .foregroundColor(.luxuryText)
            
            Spacer()
            
            Text("\(duration) min")
                .foregroundColor(.luxuryText.opacity(0.8))
        }
        .padding()
        .background(Color.luxuryCardBg)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.luxuryAccent.opacity(0.4), lineWidth: 1)
        )
    }
}

// Add the exerciseIcon function
func exerciseIcon(for exercise: String) -> String {
    switch exercise {
    // Original high-intensity exercises
    case "Burpees":
        return "figure.mixed.cardio"
    case "Mountain Climbers":
        return "figure.climbing"
    case "Jump Squats":
        return "figure.2.arms.open"
    case "Push-ups":
        return "figure.strengthtraining.traditional"
    
    // Low-intensity exercises
    case "Walking in Place", "Chair-assisted Squats":
        return "figure.strengthtraining.functional"
    case "Seated Leg Lifts", "Seated Knee Extensions", "Seated Torso Twists":
        return "figure.arms.open"
    case "Standing Calf Raises", "Standing Side Bends":
        return "figure.legs.open"
    case "Glute Bridges", "Wall Sit":
        return "figure.stand"
    
    // Incline Push-ups needs a different icon
    case "Incline Push-ups":
        return "figure.arms.open" // Different icon than regular push-ups
    
    // Squats and variations
    case "Squats":
        return "figure.strengthtraining.functional"
    case "Lunges":
        return "figure.walk"
    case "Plank":
        return "figure.core.training"
    
    // Default case
    default:
        return "figure.mind.and.body"
    }
}

// Update ActiveWorkoutView to remove animations when changing exercises
struct ActiveWorkoutView: View {
    let timerManager: WorkoutTimerManager
    let tabataWorkout: [TabataExercise]
    
    var body: some View {
        // Active workout
        VStack(spacing: 25) {
            // Timer and current exercise only
            VStack(spacing: 15) {
                // Exercise Name
                Text(tabataWorkout[timerManager.currentExerciseIndex].name)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.luxuryText)
                    .padding(.vertical, 8)
                    .animation(.none, value: timerManager.currentExerciseIndex)
                
                // Timer
                TimerDisplay(
                    timeRemaining: timerManager.timeRemaining,
                    exerciseName: tabataWorkout[timerManager.currentExerciseIndex].name,
                    isResting: timerManager.isResting
                )
            }
            .padding()
            .background(Color.luxuryCardBg)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.luxuryAccent, lineWidth: 2)
            )
            .animation(.none, value: timerManager.currentExerciseIndex)
            
            // Pause/Resume Button
            Button(action: {
                if timerManager.isPaused {
                    timerManager.resumeWorkout()
                } else {
                    timerManager.pauseWorkout()
                }
            }) {
                Image(systemName: timerManager.isPaused ? "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.luxuryAccent)
                    .frame(width: 80, height: 80)
                    .contentShape(Rectangle())
            }
            .padding()
            
            // Exercise Video Display - updated to remove animations
            ExerciseVideoView(exerciseName: tabataWorkout[timerManager.currentExerciseIndex].name)
                .animation(nil) // Disable animation when changing exercises
        }
        .animation(nil) // Disable overall container animation
    }
}

// Update ExerciseVideoView to remove animations
struct ExerciseVideoView: View {
    let exerciseName: String
    @State private var showingDetailedInstructions = false
    
    var body: some View {
        VStack(spacing: 15) {
            // Exercise demonstration image or animation - now static
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.luxuryCardBg.opacity(0.7))
                
                VStack {
                    // Static icon instead of animation
                    Image(systemName: exerciseIcon(for: exerciseName))
                        .font(.system(size: 50))
                        .foregroundColor(.luxuryAccent)
                        .padding()
                        .animation(.none, value: exerciseName)
                    
                    Text(exerciseName)
                        .font(.title2) // At least 16pt
                        .bold()
                        .foregroundColor(.luxuryText) // Ensure good contrast with background
                        .padding(.vertical, 8)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .animation(nil) // Ensure no animation when text changes
                }
            }
            .frame(height: 180)
            .onTapGesture {
                showingDetailedInstructions = true
            }
            .animation(nil) // Disable animation for the container
            
            // Brief instruction - static display
            Text(briefInstruction(for: exerciseName))
                .font(.callout)
                .foregroundColor(.luxuryText.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .animation(nil) // Ensure no animation when text changes
            
            // "See details" button
            Button(action: {
                showingDetailedInstructions = true
            }) {
                Text("See detailed instructions")
                    .font(.caption)
                    .foregroundColor(.luxuryAccent)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.luxuryAccent.opacity(0.2))
                    .cornerRadius(20)
            }
        }
        .animation(nil) // Disable overall container animation
        .sheet(isPresented: $showingDetailedInstructions) {
            ExerciseDetailsView(exerciseName: exerciseName)
        }
    }
    
    // Brief instructions for each exercise - unchanged
    private func briefInstruction(for exercise: String) -> String {
        switch exercise {
        case "Push-ups":
            return "Start in plank position, lower your body, then push back up"
        case "Squats":
            return "Stand with feet shoulder-width apart, bend knees, lower as if sitting"
        case "Lunges":
            return "Step forward with one leg, lower until both knees are bent 90°"
        case "Mountain Climbers":
            return "Start in plank position, rapidly alternate bringing knees to chest"
        case "Burpees":
            return "Squat, place hands on floor, jump back to plank, return to squat, jump up"
        case "Plank":
            return "Hold a push-up position with straight body alignment"
        case "Jump Squats":
            return "Perform a squat, then explosively jump upward"
        case "Incline Push-ups":
            return "Perform push-ups with hands on elevated surface for reduced difficulty"
        case "Walking in Place":
            return "March in place, lifting knees to comfortable height"
        case "Chair-assisted Squats":
            return "Perform squats while holding onto a chair for stability"
        case "Seated Leg Lifts":
            return "While seated, extend one leg at a time"
        case "Standing Calf Raises":
            return "Rise onto toes, then lower heels back to floor"
        case "Glute Bridges":
            return "Lie on back, feet flat, lift hips toward ceiling"
        default:
            return "Perform the exercise with controlled movements"
        }
    }
}

// Add detailed exercise instructions view
struct ExerciseDetailsView: View {
    let exerciseName: String
    @Environment(\.dismiss) var dismiss
    @State private var selectedLevel: FitnessLevel = .intermediate
    
    enum FitnessLevel: String, CaseIterable, Identifiable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Exercise header
                    HStack {
                        Image(systemName: exerciseIcon(for: exerciseName))
                            .font(.system(size: 40))
                            .foregroundColor(.luxuryAccent)
                        
                        VStack(alignment: .leading) {
                            Text(exerciseName)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.luxuryText)
                            
                            Text(exerciseCategory(for: exerciseName))
                                .font(.subheadline)
                                .foregroundColor(.luxuryAccent)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.luxuryCardBg.opacity(0.5))
                    .cornerRadius(15)
                    
                    // Difficulty level picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Choose your level:")
                            .font(.headline)
                            .foregroundColor(.luxuryText)
                        
                        Picker("Level", selection: $selectedLevel) {
                            ForEach(FitnessLevel.allCases) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 5)
                    }
                    
                    // Instructions based on selected level
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Instructions")
                            .font(.headline)
                            .foregroundColor(.luxuryText)
                        
                        ForEach(exerciseSteps(for: exerciseName, level: selectedLevel), id: \.self) { step in
                            HStack(alignment: .top) {
                                Circle()
                                    .fill(Color.luxuryAccent)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 6)
                                
                                Text(step)
                                    .foregroundColor(.luxuryText.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                    .padding()
                    .background(Color.luxuryCardBg.opacity(0.5))
                    .cornerRadius(15)
                    
                    // Target muscles
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Target Muscles")
                            .font(.headline)
                            .foregroundColor(.luxuryText)
                        
                        Text(targetMuscles(for: exerciseName))
                            .foregroundColor(.luxuryText.opacity(0.9))
                    }
                    .padding()
                    .background(Color.luxuryCardBg.opacity(0.5))
                    .cornerRadius(15)
                    
                    // Common mistakes to avoid
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Common Mistakes to Avoid")
                            .font(.headline)
                            .foregroundColor(.luxuryText)
                        
                        ForEach(commonMistakes(for: exerciseName), id: \.self) { mistake in
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                    .padding(.top, 2)
                                
                                Text(mistake)
                                    .foregroundColor(.luxuryText.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                    .padding()
                    .background(Color.luxuryCardBg.opacity(0.5))
                    .cornerRadius(15)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.luxuryBackgroundTop, .luxuryBackgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.luxuryAccent)
                }
            }
        }
    }
    
    // Exercise category
    private func exerciseCategory(for exercise: String) -> String {
        switch exercise {
        case "Push-ups", "Squats", "Lunges", "Glute Bridges":
            return "Strength Training"
        case "Mountain Climbers", "Burpees", "Jump Squats", "Walking in Place":
            return "Cardio"
        case "Plank", "Seated Leg Lifts":
            return "Core"
        default:
            return "General Fitness"
        }
    }
    
    // Exercise steps by fitness level
    private func exerciseSteps(for exercise: String, level: FitnessLevel) -> [String] {
        switch exercise {
        case "Push-ups":
            switch level {
            case .beginner:
                return [
                    "Start with knees on the ground for reduced difficulty",
                    "Place hands slightly wider than shoulder-width apart",
                    "Keep your body in a straight line from head to knees",
                    "Lower your chest toward the ground by bending your elbows",
                    "Push back up to the starting position",
                    "Aim for 5-8 repetitions"
                ]
            case .intermediate:
                return [
                    "Start in a plank position with hands slightly wider than shoulder-width",
                    "Keep your body in a straight line from head to heels",
                    "Lower your chest toward the ground until elbows reach 90°",
                    "Push back up to the starting position",
                    "Maintain core engagement throughout",
                    "Aim for 8-12 repetitions"
                ]
            case .advanced:
                return [
                    "Start in a plank position with hands slightly narrower than shoulder-width",
                    "Keep your body perfectly straight with tight core",
                    "Lower your chest toward the ground until it nearly touches",
                    "Push explosively back to the starting position",
                    "For extra challenge, add a clap at the top of the movement",
                    "Aim for 12-20 repetitions"
                ]
            }
        case "Squats":
            switch level {
            case .beginner:
                return [
                    "Stand with feet shoulder-width apart",
                    "Hold onto a stable surface if needed for balance",
                    "Bend your knees and push hips back as if sitting in a chair",
                    "Lower only as far as comfortable",
                    "Return to standing position",
                    "Keep weight in your heels throughout"
                ]
            case .intermediate:
                return [
                    "Stand with feet shoulder-width apart, toes slightly turned out",
                    "Extend arms in front for counterbalance",
                    "Bend knees and push hips back to lower into a squat",
                    "Aim to get thighs parallel to the ground",
                    "Push through heels to return to standing",
                    "Keep chest up and back straight throughout"
                ]
            case .advanced:
                return [
                    "Stand with feet shoulder-width apart",
                    "Engage core and keep chest proud",
                    "Bend knees and push hips back deeply",
                    "Lower until thighs are below parallel with the ground",
                    "Maintain weight in heels and proper back alignment",
                    "Explosively return to standing position"
                ]
            }
        // Additional exercise instructions would be added for other exercises
        default:
            return ["Perform the exercise with proper form", "Focus on controlled movements", "Breathe steadily throughout"]
        }
    }
    
    // Target muscles for each exercise
    private func targetMuscles(for exercise: String) -> String {
        switch exercise {
        case "Push-ups":
            return "Chest, shoulders, triceps, core"
        case "Squats":
            return "Quadriceps, hamstrings, glutes, core"
        case "Lunges":
            return "Quadriceps, hamstrings, glutes, calves"
        case "Mountain Climbers":
            return "Core, shoulders, hip flexors, quadriceps"
        case "Burpees":
            return "Full body: chest, arms, quads, hamstrings, core"
        case "Plank":
            return "Core, shoulders, back, glutes"
        case "Jump Squats":
            return "Quadriceps, hamstrings, glutes, calves"
        case "Incline Push-ups":
            return "Chest, shoulders, triceps"
        case "Walking in Place":
            return "Calves, quadriceps, hip flexors"
        case "Chair-assisted Squats":
            return "Quadriceps, hamstrings, glutes"
        case "Seated Leg Lifts":
            return "Hip flexors, quadriceps"
        case "Standing Calf Raises":
            return "Calves, ankles"
        case "Glute Bridges":
            return "Glutes, hamstrings, lower back"
        default:
            return "Multiple muscle groups"
        }
    }
    
    // Common mistakes to avoid for each exercise
    private func commonMistakes(for exercise: String) -> [String] {
        switch exercise {
        case "Push-ups":
            return [
                "Sagging or arching the back",
                "Not lowering chest enough",
                "Flaring elbows too far out",
                "Looking up instead of keeping neck neutral",
                "Holding breath during exertion"
            ]
        case "Squats":
            return [
                "Letting knees collapse inward",
                "Raising heels off the ground",
                "Rounding the lower back",
                "Not descending deep enough",
                "Leaning too far forward"
            ]
        case "Lunges":
            return [
                "Front knee extending past the toes",
                "Upper body leaning too far forward",
                "Rear knee not lowering enough",
                "Hips not squared forward",
                "Step length too short"
            ]
        // Additional mistakes would be added for other exercises
        default:
            return [
                "Using momentum instead of controlled motion",
                "Improper breathing technique",
                "Going too fast and sacrificing form"
            ]
        }
    }
}

// Update the AnimatedExerciseView with more accurate exercise icons
struct AnimatedExerciseView: View {
    let exerciseName: String
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background animation
            Circle()
                .fill(Color.luxuryAccent.opacity(0.1))
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .opacity(isAnimating ? 0.6 : 0.3)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            
            // Exercise icon with specific animations
            Image(systemName: exerciseIcon(for: exerciseName))
                .font(.system(size: 100))
                .foregroundColor(.luxuryAccent)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .rotationEffect(rotationAngle(for: exerciseName))
                .offset(y: verticalOffset(for: exerciseName))
                .animation(animation(for: exerciseName), value: isAnimating)
        }
        .frame(height: 200)
        .onAppear {
            isAnimating = true
        }
    }
    
    // Custom animation for each exercise type
    private func animation(for exercise: String) -> Animation {
        switch exercise {
        case "Burpees", "Jump Squats":
            return .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        case "Mountain Climbers", "High Knees", "Bicycle Crunches":
            return .easeInOut(duration: 0.4).repeatForever(autoreverses: true)
        case "Jump Rope", "Speed Skaters":
            return .spring(response: 0.3, dampingFraction: 0.6).repeatForever(autoreverses: true)
        default:
            return .easeInOut(duration: 1).repeatForever(autoreverses: true)
        }
    }
    
    // Custom vertical movement for jumping exercises
    private func verticalOffset(for exercise: String) -> CGFloat {
        switch exercise {
        case "Burpees", "Jump Squats", "Jumping Lunges":
            return isAnimating ? -20 : 0
        case "Jump Rope":
            return isAnimating ? -10 : 0
        default:
            return 0
        }
    }
    
    // Custom rotation for specific exercises
    private func rotationAngle(for exercise: String) -> Angle {
        switch exercise {
        case "Bicycle Crunches":
            return isAnimating ? .degrees(360) : .degrees(0)
        case "Speed Skaters":
            return isAnimating ? .degrees(15) : .degrees(-15)
        default:
            return .degrees(0)
        }
    }
}

// Add this struct to track fitness targets
struct FitnessTarget: Codable, Identifiable {
    var id = UUID()
    var type: TargetType
    var value: Int
    var currentProgress: Int = 0
    var startDate: Date
    var endDate: Date
    
    enum TargetType: String, Codable, CaseIterable {
        case weeklyWorkouts = "Weekly Workouts"
        case monthlyWorkouts = "Monthly Workouts"
        case weeklyMinutes = "Weekly Minutes"
        case monthlyMinutes = "Monthly Minutes" 
    }
    
    var progressPercentage: Double {
        guard value > 0 else { return 0 }
        return min(Double(currentProgress) / Double(value), 1.0)
    }
    
    var isCompleted: Bool {
        return currentProgress >= value
    }
    
    var timeRemaining: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        guard let days = components.day, days >= 0 else { return "Expired" }
        
        return "\(days) day\(days == 1 ? "" : "s") left"
    }
}

// Update PersonalizationView to include fitness targets
struct PersonalizationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var fitnessLevel = 2 // 1-beginner, 2-intermediate, 3-advanced
    @State private var preferredWorkoutType = 0 // 0-HIIT, 1-Strength, 2-Cardio
    @State private var excludedExercises: Set<String> = []
    
    // Add physical attributes
    @State private var weight = 150.0
    @State private var weightUnit = 0 // 0-lbs, 1-kg
    @State private var heightFeet = 5
    @State private var heightInches = 8
    @State private var heightCm = 173.0
    @State private var useMetric = false
    @State private var gender = 0 // 0-male, 1-female, 2-other
    
    // New states for fitness targets
    @State private var showingAddTargetSheet = false
    @State private var fitnessTargets: [FitnessTarget] = []
    @State private var newTargetType: FitnessTarget.TargetType = .weeklyWorkouts
    @State private var newTargetValue: String = ""
    @State private var selectedPeriod: TargetPeriod = .weekly
    
    enum TargetPeriod: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
    
    private let workoutTypes = ["HIIT", "Strength", "Cardio"]
    private let commonExercises = ["Burpees", "Push-ups", "Jumping Lunges", "Mountain Climbers", "Planks"]
    private let genderOptions = ["Male", "Female", "Other"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.luxuryBackgroundTop.ignoresSafeArea()
                
                // Improve scrolling behavior
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 20) {
                        // Profile section
                        VStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.luxuryAccent)
                            
                            TextField("Your Name", text: $username)
                                .padding()
                                .background(Color.luxuryCardBg)
                                .cornerRadius(8)
                                .foregroundColor(.luxuryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical)
                        
                        // Gender selection
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Gender")
                                .font(.headline)
                                .foregroundColor(.luxuryText)
                            
                            Picker("Gender", selection: $gender) {
                                ForEach(0..<genderOptions.count, id: \.self) { index in
                                    Text(genderOptions[index]).tag(index)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(8)
                            .background(Color.luxuryCardBg)
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.luxuryCardBg.opacity(0.5))
                        )
                        
                        // Weight section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Weight")
                                .font(.headline)
                                .foregroundColor(.luxuryText)
                            
                            HStack {
                                // Unit toggle
                                Picker("Unit", selection: $weightUnit) {
                                    Text("lbs").tag(0)
                                    Text("kg").tag(1)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 100)
                                
                                Spacer()
                                
                                // Value
                                HStack {
                                    Slider(value: $weight, in: weightUnit == 0 ? 50...400 : 20...180, step: 1)
                                        .tint(.luxuryAccent)
                                    
                                    Text("\(Int(weight)) \(weightUnit == 0 ? "lbs" : "kg")")
                                        .frame(width: 70, alignment: .trailing)
                                        .foregroundColor(.luxuryText)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.luxuryCardBg.opacity(0.5))
                        )
                        
                        // Height section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Height")
                                .font(.headline)
                                .foregroundColor(.luxuryText)
                            
                            Toggle("Use Metric (cm)", isOn: $useMetric)
                                .foregroundColor(.luxuryText)
                                .padding(.vertical, 5)
                            
                            if useMetric {
                                // Centimeters
                                HStack {
                                    Slider(value: $heightCm, in: 120...220, step: 1)
                                        .tint(.luxuryAccent)
                                    
                                    Text("\(Int(heightCm)) cm")
                                        .frame(width: 70, alignment: .trailing)
                                        .foregroundColor(.luxuryText)
                                }
                            } else {
                                // Feet and inches
                                HStack(spacing: 15) {
                                    // Feet picker
                                    VStack {
                                        Text("Feet")
                                            .font(.caption)
                                            .foregroundColor(.luxuryText.opacity(0.8))
                                        
                                        Picker("Feet", selection: $heightFeet) {
                                            ForEach(1...7, id: \.self) { feet in
                                                Text("\(feet)").tag(feet)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(height: 100)
                                        .clipped()
                                        .background(Color.luxuryCardBg)
                                        .cornerRadius(8)
                                    }
                                    
                                    // Inches picker
                                    VStack {
                                        Text("Inches")
                                            .font(.caption)
                                            .foregroundColor(.luxuryText.opacity(0.8))
                                        
                                        Picker("Inches", selection: $heightInches) {
                                            ForEach(0...11, id: \.self) { inches in
                                                Text("\(inches)").tag(inches)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(height: 100)
                                        .clipped()
                                        .background(Color.luxuryCardBg)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.luxuryCardBg.opacity(0.5))
                        )
                        
                        // Fitness level
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Fitness Level")
                                .font(.headline)
                                .foregroundColor(.luxuryText)
                            
                            Picker("Fitness Level", selection: $fitnessLevel) {
                                Text("Beginner").tag(1)
                                Text("Intermediate").tag(2)
                                Text("Advanced").tag(3)
                            }
                            .pickerStyle(.segmented)
                            .padding(8)
                            .background(Color.luxuryCardBg)
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.luxuryCardBg.opacity(0.5))
                        )
                        
                        // Preferred workout type
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Preferred Workout Type")
                                .font(.headline)
                                .foregroundColor(.luxuryText)
                            
                            Picker("Workout Type", selection: $preferredWorkoutType) {
                                ForEach(0..<workoutTypes.count, id: \.self) { index in
                                    Text(workoutTypes[index]).tag(index)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(8)
                            .background(Color.luxuryCardBg)
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.luxuryCardBg.opacity(0.5))
                        )
                        
                        // Excluded exercises
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Exclude Exercises")
                                .font(.headline)
                                .foregroundColor(.luxuryText)
                            
                            ForEach(commonExercises, id: \.self) { exercise in
                                Toggle(exercise, isOn: Binding(
                                    get: { excludedExercises.contains(exercise) },
                                    set: { isExcluded in
                                        if isExcluded {
                                            excludedExercises.insert(exercise)
                                        } else {
                                            excludedExercises.remove(exercise)
                                        }
                                    }
                                ))
                                .foregroundColor(.luxuryText)
                                .padding(8)
                                .background(Color.luxuryCardBg.opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.luxuryCardBg.opacity(0.5))
                        )
                        
                        // Fitness targets section
                        PersonalizationSection(title: "Fitness Targets") {
                            VStack(spacing: 15) {
                                // Display current targets
                                if fitnessTargets.isEmpty {
                                    Text("No targets set")
                                        .foregroundColor(.luxuryText.opacity(0.7))
                                        .italic()
                                        .padding(.vertical, 10)
                                } else {
                                    ForEach(fitnessTargets) { target in
                                        TargetProgressView(target: target)
                                    }
                                    .padding(.vertical, 5)
                                }
                                
                                // Add target button
                                Button(action: {
                                    showingAddTargetSheet = true
                                }) {
                                    Label("Add New Target", systemImage: "plus.circle")
                                        .foregroundColor(.luxuryAccent)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.luxuryCardBg)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        
                        // Save button
                        Button(action: {
                            // Save preferences and dismiss
                            savePreferences()
                            dismiss()
                        }) {
                            Text("Save Preferences")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.luxuryAccent)
                                .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30) // Add extra padding at bottom
                }
                .scrollDismissesKeyboard(.immediately) // Dismiss keyboard when scrolling
            }
            .navigationTitle("Personalize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.luxuryAccent)
                }
            }
            .sheet(isPresented: $showingAddTargetSheet) {
                AddTargetView(
                    isPresented: $showingAddTargetSheet,
                    targetType: $newTargetType,
                    targetValue: $newTargetValue,
                    selectedPeriod: $selectedPeriod,
                    onAdd: addNewTarget
                )
            }
        }
    }
    
    private func savePreferences() {
        // Convert height to a consistent format for storage
        let heightInCm: Double
        if useMetric {
            heightInCm = heightCm
        } else {
            // Break down the complex expression
            let feetToCm = Double(heightFeet) * 30.48
            let inchesToCm = Double(heightInches) * 2.54
            heightInCm = feetToCm + inchesToCm
        }
        
        // Convert weight to a consistent format
        let weightInKg = weightUnit == 0 ? weight * 0.453592 : weight
        
        // In a real app, would save these to UserDefaults or other storage
        print("Profile saved: Gender: \(genderOptions[gender]), Weight: \(weightInKg)kg, Height: \(heightInCm)cm")
        print("Fitness preferences: Level \(fitnessLevel), Type: \(workoutTypes[preferredWorkoutType])")
        
        // Save fitness targets
        if let encodedTargets = try? JSONEncoder().encode(fitnessTargets) {
            UserDefaults.standard.set(encodedTargets, forKey: "fitnessTargets")
        }
    }
    
    private func loadSavedTargets() {
        if let savedTargets = UserDefaults.standard.data(forKey: "fitnessTargets"),
           let decodedTargets = try? JSONDecoder().decode([FitnessTarget].self, from: savedTargets) {
            fitnessTargets = decodedTargets
        }
    }
    
    private func addNewTarget() {
        guard let value = Int(newTargetValue), value > 0 else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Calculate end date based on period
        let endDate: Date
        if selectedPeriod == .weekly {
            endDate = calendar.date(byAdding: .day, value: 7, to: today)!
        } else {
            endDate = calendar.date(byAdding: .month, value: 1, to: today)!
        }
        
        let newTarget = FitnessTarget(
            type: newTargetType,
            value: value,
            startDate: today,
            endDate: endDate
        )
        
        fitnessTargets.append(newTarget)
        
        // Reset new target form
        newTargetValue = ""
        showingAddTargetSheet = false
        
        // Save updated targets
        savePreferences()
    }
}

// New view for adding targets
struct AddTargetView: View {
    @Binding var isPresented: Bool
    @Binding var targetType: FitnessTarget.TargetType
    @Binding var targetValue: String
    @Binding var selectedPeriod: PersonalizationView.TargetPeriod
    var onAdd: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.luxuryBackgroundBottom.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Set a New Fitness Target")
                        .font(.headline)
                        .foregroundColor(.luxuryText)
                    
                    // Period selection (weekly/monthly)
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(PersonalizationView.TargetPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Target type selection
                    Picker("Target Type", selection: $targetType) {
                        ForEach(FitnessTarget.TargetType.allCases.filter { 
                            selectedPeriod == .weekly ? 
                                ($0 == .weeklyWorkouts || $0 == .weeklyMinutes) : 
                                ($0 == .monthlyWorkouts || $0 == .monthlyMinutes)
                        }, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.luxuryCardBg)
                    .cornerRadius(10)
                    
                    // Target value input
                    TextField("Target Value", text: $targetValue)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.luxuryCardBg)
                        .cornerRadius(10)
                        .foregroundColor(.luxuryText)
                    
                    Text("Example: 5 workouts or 150 minutes")
                        .font(.caption)
                        .foregroundColor(.luxuryText.opacity(0.7))
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Add") {
                    onAdd()
                }
                .disabled(targetValue.isEmpty)
            )
        }
    }
}

// Section container for personalization view
struct PersonalizationSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.luxuryAccent)
            
            content
        }
        .padding()
        .background(Color.luxuryCardBg.opacity(0.5))
        .cornerRadius(15)
    }
}

// Progress view for targets
struct TargetProgressView: View {
    let target: FitnessTarget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(target.type.rawValue)
                    .font(.headline)
                    .foregroundColor(.luxuryText)
                
                Spacer()
                
                Text(target.timeRemaining)
                    .font(.caption)
                    .foregroundColor(
                        Calendar.current.isDateInToday(target.endDate) ? 
                            .orange : .luxuryText.opacity(0.7)
                    )
            }
            
            Text("\(target.currentProgress) of \(target.value)")
                .font(.subheadline)
                .foregroundColor(.luxuryAccent)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.luxuryCardBg)
                        .frame(width: geometry.size.width, height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(target.isCompleted ? Color.green : Color.luxuryAccent)
                        .frame(width: geometry.size.width * target.progressPercentage, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Completion status
            if target.isCompleted {
                Text("Target achieved!")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.luxuryCardBg.opacity(0.7))
        .cornerRadius(10)
    }
}

// Update WorkoutView to update fitness targets
private func updateFitnessTargets(duration: Int, completed: Bool) {
    guard completed else { return }
    
    // Get saved targets
    if let savedTargets = UserDefaults.standard.data(forKey: "fitnessTargets"),
       var targets = try? JSONDecoder().decode([FitnessTarget].self, from: savedTargets) {
        
        let calendar = Calendar.current
        let today = Date()
        
        // Update relevant targets
        for i in 0..<targets.count {
            // Skip expired targets
            if targets[i].endDate < calendar.startOfDay(for: today) {
                continue
            }
            
            // Update target progress based on type
            switch targets[i].type {
            case .weeklyWorkouts, .monthlyWorkouts:
                targets[i].currentProgress += 1
            case .weeklyMinutes, .monthlyMinutes:
                targets[i].currentProgress += duration
            }
        }
        
        // Save updated targets
        if let encodedTargets = try? JSONEncoder().encode(targets) {
            UserDefaults.standard.set(encodedTargets, forKey: "fitnessTargets")
        }
    }
}

// Add WorkoutHistoryView to display past workouts and streaks
struct WorkoutHistoryView: View {
    let workoutHistory: WorkoutHistoryManager
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Streak")
                        .font(.subheadline)
                        .foregroundColor(.luxuryText.opacity(0.8))
                    
                    Text("\(workoutHistory.currentStreak) days")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.luxuryAccent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Longest Streak")
                        .font(.subheadline)
                        .foregroundColor(.luxuryText.opacity(0.8))
                    
                    Text("\(workoutHistory.longestStreak) days")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.luxuryAccent)
                }
            }
            .padding()
            .background(Color.luxuryCardBg.opacity(0.7))
            .cornerRadius(15)
            
            // Recent workouts list
            VStack(alignment: .leading, spacing: 5) {
                Text("Recent Workouts")
                    .font(.headline)
                    .foregroundColor(.luxuryText)
                    .padding(.leading)
                
                if workoutHistory.completedWorkouts.isEmpty {
                    Text("No workouts completed yet")
                        .foregroundColor(.luxuryText.opacity(0.6))
                        .italic()
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(workoutHistory.completedWorkouts.prefix(7)) { workout in
                                WorkoutHistoryRow(workout: workout)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 220)
                }
            }
            .padding(.vertical)
        }
        .padding()
        .background(Color.luxuryCardBg.opacity(0.3))
        .cornerRadius(15)
    }
}

// Row for displaying a single workout in history
struct WorkoutHistoryRow: View {
    let workout: WorkoutLog
    
    var body: some View {
        HStack {
            // Date of workout
            VStack(alignment: .leading) {
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.luxuryText)
                
                Text(formattedTime)
                    .font(.footnote) // At least 11pt
                    .foregroundColor(.luxuryText.opacity(0.9)) // Increased opacity for better contrast
            }
            
            Spacer()
            
            // Workout stats
            VStack(alignment: .trailing) {
                Text("\(workout.duration) min")
                    .font(.subheadline)
                    .foregroundColor(.luxuryAccent)
                
                HStack(spacing: 4) {
                    Image(systemName: workout.completed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(workout.completed ? .green : .orange)
                    
                    Text(workout.completed ? "Completed" : "Partial")
                        .font(.caption)
                        .foregroundColor(.luxuryText.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.luxuryCardBg.opacity(0.5))
        .cornerRadius(10)
    }
    
    // Format date as "Mon, Feb 26"
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: workout.date)
    }
    
    // Format time as "3:45 PM"
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: workout.date)
    }
}

// Add missing WorkoutPreviewView definition
struct WorkoutPreviewView: View {
    let tabataWorkout: [TabataExercise]
    let timerManager: WorkoutTimerManager
    
    var body: some View {
        VStack {
            // Preview of exercises
            Text("Workout Preview")
                .font(.headline)
                .foregroundColor(.luxuryText)
                .padding(.top)
            
            VStack(spacing: 12) {
                ForEach(tabataWorkout) { exercise in
                    VStack(spacing: 4) {
                        HStack {
                            Text(exercise.name)
                                .foregroundColor(.luxuryText)
                            
                            Spacer()
                            
                            Text("\(exercise.workSeconds)s work")
                                .foregroundColor(.luxuryAccent)
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Spacer()
                            Text("\(exercise.restSeconds)s rest")
                                .foregroundColor(.luxuryText.opacity(0.7))
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.luxuryCardBg.opacity(0.5))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // Start button
            Button(action: {
                timerManager.startWorkout(with: tabataWorkout)
            }) {
                Text("Start Workout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.luxuryAccent)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
}

// Add these custom button styles for consistent appearance
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(height: 50) // Ensure minimum height
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.luxuryAccent)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .padding(.horizontal)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.luxuryAccent)
            .frame(height: 50) // Ensure minimum height
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.luxuryAccent, lineWidth: 2)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}
