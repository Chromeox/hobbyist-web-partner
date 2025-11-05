import SwiftUI
import Speech
import AVFoundation

struct VoiceSearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var animationScale: CGFloat = 1.0
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    Task {
                        await viewModel.startVoiceSearch()
                        dismiss()
                    }
                }
            
            VStack(spacing: 32) {
                // Title
                Text("Voice Search")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                // Voice visualization
                VStack(spacing: 24) {
                    // Microphone button with animation
                    ZStack {
                        // Outer pulse rings
                        if viewModel.isListeningForVoice {
                            ForEach(0..<3) { index in
                                Circle()
                                    .stroke(BrandConstants.Colors.primary.opacity(0.3), lineWidth: 2)
                                    .frame(width: 200 + CGFloat(index * 40), height: 200 + CGFloat(index * 40))
                                    .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                                    .opacity(pulseAnimation ? 0 : 1)
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(index) * 0.2),
                                        value: pulseAnimation
                                    )
                            }
                        }
                        
                        // Main microphone circle
                        Button {
                            Task {
                                await viewModel.startVoiceSearch()
                            }
                        } label: {
                            Image(systemName: viewModel.isListeningForVoice ? "mic.fill" : "mic")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 120)
                                .background(
                                    Circle()
                                        .fill(viewModel.isListeningForVoice ? BrandConstants.Colors.primary : BrandConstants.Colors.primary.opacity(0.8))
                                        .shadow(color: BrandConstants.Colors.primary.opacity(0.3), radius: 20, x: 0, y: 0)
                                )
                                .scaleEffect(animationScale)
                        }
                        .onAppear {
                            if viewModel.isListeningForVoice {
                                startListeningAnimation()
                            }
                        }
                        .onChange(of: viewModel.isListeningForVoice) { _, isListening in
                            if isListening {
                                startListeningAnimation()
                            } else {
                                stopListeningAnimation()
                            }
                        }
                    }
                    
                    // Status text
                    VStack(spacing: 8) {
                        if viewModel.isListeningForVoice {
                            Text("Listening...")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        } else {
                            Text("Tap to speak")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        if let error = viewModel.voiceSearchError {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Voice search text preview
                    if !viewModel.voiceSearchText.isEmpty {
                        VStack(spacing: 8) {
                            Text("You said:")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("\"\(viewModel.voiceSearchText)\"")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
                // Action buttons
                HStack(spacing: 24) {
                    if viewModel.isListeningForVoice {
                        Button {
                            Task {
                                await viewModel.startVoiceSearch() // This will stop if already listening
                            }
                        } label: {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                            )
                        }
                    }
                    
                    Button("Cancel") {
                        if viewModel.isListeningForVoice {
                            Task {
                                await viewModel.startVoiceSearch() // Stop listening
                            }
                        }
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                
                // Voice search tips
                VStack(alignment: .leading, spacing: 8) {
                    Text("Voice Search Tips:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• \"Find pottery classes\"")
                        Text("• \"Show me cooking workshops\"")
                        Text("• \"Photography classes in Kitsilano\"")
                        Text("• \"Free yoga sessions\"")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
            }
            .padding(.horizontal, 32)
        }
        .onDisappear {
            // Clean up if view disappears while listening
            if viewModel.isListeningForVoice {
                Task {
                    await viewModel.startVoiceSearch()
                }
            }
        }
    }
    
    private func startListeningAnimation() {
        pulseAnimation = true
        
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            animationScale = 1.1
        }
    }
    
    private func stopListeningAnimation() {
        pulseAnimation = false
        
        withAnimation(.easeOut(duration: 0.3)) {
            animationScale = 1.0
        }
    }
}

// MARK: - Voice Search Permissions View

struct VoiceSearchPermissionsView: View {
    let onRequestPermission: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
            
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "mic.slash")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
                
                // Title and description
                VStack(spacing: 12) {
                    Text("Voice Search Unavailable")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("To use voice search, please enable microphone access in Settings")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                        onDismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(BrandConstants.Colors.primary)
                    )
                    
                    Button("Maybe Later") {
                        onDismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Voice Search Button Component

struct VoiceSearchButton: View {
    @ObservedObject var viewModel: SearchViewModel
    @State private var showingVoiceSearch = false
    @State private var showingPermissions = false
    
    var body: some View {
        Button {
            if speechRecognitionAvailable {
                showingVoiceSearch = true
            } else {
                showingPermissions = true
            }
        } label: {
            Image(systemName: viewModel.isListeningForVoice ? "mic.fill" : "mic")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(viewModel.isListeningForVoice ? .white : BrandConstants.Colors.primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(viewModel.isListeningForVoice ? BrandConstants.Colors.primary : Color(.systemGray6))
                )
                .scaleEffect(viewModel.isListeningForVoice ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isListeningForVoice)
        }
        .fullScreenCover(isPresented: $showingVoiceSearch) {
            VoiceSearchView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showingPermissions) {
            VoiceSearchPermissionsView(
                onRequestPermission: {
                    // Request permission handled by the settings redirect
                },
                onDismiss: {
                    showingPermissions = false
                }
            )
        }
    }
    
    private var speechRecognitionAvailable: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized &&
        AVAudioSession.sharedInstance().recordPermission == .granted
    }
}

// MARK: - Compact Voice Search Component

struct CompactVoiceSearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    let onComplete: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // Recording indicator
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .opacity(viewModel.isListeningForVoice ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.isListeningForVoice)
                
                Text(viewModel.isListeningForVoice ? "Listening..." : "Tap mic to speak")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Voice input display
            if !viewModel.voiceSearchText.isEmpty {
                Text("\"\(viewModel.voiceSearchText)\"")
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
            
            // Controls
            HStack {
                Button {
                    Task {
                        await viewModel.startVoiceSearch()
                    }
                } label: {
                    Image(systemName: viewModel.isListeningForVoice ? "mic.fill" : "mic")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(viewModel.isListeningForVoice ? .white : BrandConstants.Colors.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(viewModel.isListeningForVoice ? BrandConstants.Colors.primary : Color(.systemGray6))
                        )
                }
                
                Spacer()
                
                if !viewModel.voiceSearchText.isEmpty {
                    Button("Use") {
                        onComplete(viewModel.voiceSearchText)
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(BrandConstants.Colors.primary)
                    )
                }
                
                Button("Cancel") {
                    if viewModel.isListeningForVoice {
                        Task {
                            await viewModel.startVoiceSearch()
                        }
                    }
                    dismiss()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

#Preview {
    VoiceSearchView(viewModel: SearchViewModel())
}