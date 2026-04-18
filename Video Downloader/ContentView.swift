//
//  ContentView.swift
//  Video Downloader
//
//  Created by Johnson on 17/04/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(colors: [.blue.opacity(0.1), .white], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header Section
                        VStack(spacing: 12) {
                            Image(systemName: "icloud.and.arrow.down")
                                .font(.system(size: 60))
                                .foregroundStyle(.blue.gradient)
                                .padding(.top, 20)
                            
                            Text("Video Downloader")
                                .font(.largeTitle.bold())
                            
                            Text("Fast, High Quality, No Ads")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Input Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Enter Video URL")
                                .font(.headline)
                                .padding(.leading, 4)
                            
                            TextField("Paste link from Instagram or Facebook", text: $viewModel.url)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                            
                            HStack {
                                Text("Quality Preference")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Picker("Quality", selection: $viewModel.selectedQuality) {
                                    ForEach(viewModel.qualities, id: \.self) { quality in
                                        Text(quality.uppercased()).tag(quality)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.blue)
                            }
                            .padding(.horizontal, 4)
                        }
                        .padding(.horizontal)
                        
                        // Action Section
                        VStack(spacing: 15) {
                            Button(action: viewModel.startProcess) {
                                Group {
                                    if viewModel.isDownloading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        HStack {
                                            Image(systemName: "arrow.down.circle.fill")
                                            Text("Download Video")
                                        }
                                        .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(viewModel.url.isEmpty || viewModel.isDownloading ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                            .disabled(viewModel.url.isEmpty || viewModel.isDownloading)
                            .padding(.horizontal)
                            
                            if viewModel.isDownloading {
                                VStack(spacing: 8) {
                                    ProgressView(value: viewModel.downloadProgress, total: 1.0)
                                        .progressViewStyle(.linear)
                                        .tint(.blue)
                                    
                                    Text(viewModel.statusMessage)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .scale))
                            } else if !viewModel.statusMessage.isEmpty {
                                Text(viewModel.statusMessage)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(viewModel.statusMessage.contains("Error") ? .red : .green)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(viewModel.statusMessage.contains("Error") ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                        
                        // Platform Support Info
                        VStack(spacing: 15) {
                            Text("Supported Platforms")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 25) {
                                PlatformIcon(name: "Instagram", icon: "camera.fill")
                                PlatformIcon(name: "Facebook", icon: "f.circle.fill")
                            }
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
}

struct PlatformIcon: View {
    let name: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue.opacity(0.8))
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
