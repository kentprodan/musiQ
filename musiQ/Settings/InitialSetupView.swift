import SwiftUI
import AppKit

struct InitialSetupView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @State private var selectedLibraryLocation: URL?
    @State private var selectedMusicLocation: URL?
    @State private var shouldCopyMusic: Bool = false
    @State private var currentStep: Int = 0
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "music.note.house.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Welcome to musiQ")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Let's set up your music library")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Setup Steps
                TabView(selection: $currentStep) {
                    // Step 1: Library Location
                    setupStep1
                        .tag(0)
                    
                    // Step 2: Music Location
                    setupStep2
                        .tag(1)
                    
                    // Step 3: Music Management
                    setupStep3
                        .tag(2)
                    
                    // Step 4: Confirmation
                    setupStep4
                        .tag(3)
                }
                .tabViewStyle(.automatic)
                .frame(maxWidth: 600, maxHeight: 400)
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Spacer()
                    
                    Button(currentStep == 3 ? "Finish Setup" : "Continue") {
                        handleContinue()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canContinue())
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 40)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Setup Steps
    
    private var setupStep1: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Choose Library Location")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("This is where musiQ will store its database, artwork, and optionally your music files.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                if let location = selectedLibraryLocation {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(location.path)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button("Select Library Folder") {
                    selectLibraryLocation()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var setupStep2: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 48))
                    .foregroundColor(.purple)
                
                Text("Choose Music Location")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Where are your music files currently stored?")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                if let location = selectedMusicLocation {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(location.path)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button("Select Music Folder") {
                    selectMusicLocation()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var setupStep3: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: shouldCopyMusic ? "square.and.arrow.down.fill" : "link")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("Music Management")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("How should musiQ handle your music files?")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 16) {
                // Option 1: Copy to library
                Button(action: { shouldCopyMusic = true }) {
                    HStack(spacing: 16) {
                        Image(systemName: shouldCopyMusic ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(shouldCopyMusic ? .blue : .white.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Copy to Library")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Music files will be copied to your library folder. Original files remain untouched.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(shouldCopyMusic ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(shouldCopyMusic ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                
                // Option 2: Read from location
                Button(action: { shouldCopyMusic = false }) {
                    HStack(spacing: 16) {
                        Image(systemName: !shouldCopyMusic ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(!shouldCopyMusic ? .blue : .white.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Read from Current Location")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Keep music in its current location. musiQ will read files directly. (Recommended)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(!shouldCopyMusic ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(!shouldCopyMusic ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var setupStep4: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Ready to Go!")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Review your settings before completing setup")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                SettingSummaryRow(
                    icon: "folder.fill",
                    title: "Library Location",
                    value: selectedLibraryLocation?.path ?? "Not selected"
                )
                
                SettingSummaryRow(
                    icon: "music.note.list",
                    title: "Music Location",
                    value: selectedMusicLocation?.path ?? "Not selected"
                )
                
                SettingSummaryRow(
                    icon: shouldCopyMusic ? "square.and.arrow.down.fill" : "link",
                    title: "Music Management",
                    value: shouldCopyMusic ? "Copy to Library" : "Read from Location"
                )
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func canContinue() -> Bool {
        switch currentStep {
        case 0:
            return selectedLibraryLocation != nil
        case 1:
            return selectedMusicLocation != nil
        case 2:
            return true
        case 3:
            return true
        default:
            return false
        }
    }
    
    private func handleContinue() {
        if currentStep < 3 {
            withAnimation {
                currentStep += 1
            }
        } else {
            completeSetup()
        }
    }
    
    private func selectLibraryLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose where to store musiQ library data"
        panel.prompt = "Select"
        
        if panel.runModal() == .OK {
            selectedLibraryLocation = panel.url
        }
    }
    
    private func selectMusicLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose your music folder"
        panel.prompt = "Select"
        
        if panel.runModal() == .OK {
            selectedMusicLocation = panel.url
        }
    }
    
    private func completeSetup() {
        guard let libraryLocation = selectedLibraryLocation,
              let musicLocation = selectedMusicLocation else {
            errorMessage = "Please complete all setup steps"
            showError = true
            return
        }
        
        // Save settings
        settingsManager.completeInitialSetup(
            libraryLocation: libraryLocation,
            musicLocation: musicLocation,
            shouldCopy: shouldCopyMusic
        )
        
        print("✅ Initial setup completed")
    }
}

// MARK: - Supporting Views

struct SettingSummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    InitialSetupView()
}
