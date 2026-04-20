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
                            Image(systemName: Constants.UI.mainAppIcon)
                                .font(.system(size: 60))
                                .foregroundStyle(.blue.gradient)
                                .padding(.top, 20)
                            
                            Text(Constants.UI.appTitle)
                                .font(.largeTitle.bold())
                            
                            Text(Constants.UI.appSubtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Input Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text(Constants.UI.enterUrlTitle)
                                .font(.headline)
                                .padding(.leading, 4)
                            
                            TextField(Constants.UI.urlPlaceholder, text: $viewModel.url)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(Constants.UI.cornerRadiusMedium)
                                .shadow(color: .black.opacity(Constants.UI.shadowOpacity), radius: Constants.UI.shadowRadius, x: 0, y: Constants.UI.shadowY)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                            
                            HStack {
                                Text(Constants.UI.qualityPreferenceTitle)
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
                                            Text(Constants.UI.downloadButtonTitle)
                                        }
                                        .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(viewModel.url.isEmpty || viewModel.isDownloading ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(Constants.UI.cornerRadiusLarge)
                            }
                            .disabled(viewModel.url.isEmpty || viewModel.isDownloading)
                            .padding(.horizontal)
                            
                            if viewModel.isDownloading {
                                VStack(spacing: 8) {
                                    ProgressView(value: viewModel.downloadProgress, total: Constants.Config.maxDownloadProgress)
                                        .progressViewStyle(.linear)
                                        .tint(.blue)

                                    HStack {
                                        Text(viewModel.statusMessage)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(String(format: Constants.UI.progressPercentFormat, Int(viewModel.downloadProgress * 100)))
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .scale))
                            } else if !viewModel.statusMessage.isEmpty {
                                Text(viewModel.statusMessage)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(viewModel.statusMessage.contains(Constants.UI.statusMessageErrorPrefix) ? .red : .green)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(viewModel.statusMessage.contains(Constants.UI.statusMessageErrorPrefix) ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                                    .cornerRadius(Constants.UI.cornerRadiusSmall)
                                    .padding(.horizontal)
                            }
                        }
                        
                        // Platform Support Info
                        VStack(spacing: 15) {
                            Text(Constants.UI.supportedPlatformsTitle)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 25) {
                                PlatformIcon(name: Constants.UI.instagramName, icon: Constants.UI.instagramIcon)
                                PlatformIcon(name: Constants.UI.facebookName, icon: Constants.UI.facebookIcon)
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
                Button(Constants.UI.okButtonTitle, role: .cancel) { }
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
