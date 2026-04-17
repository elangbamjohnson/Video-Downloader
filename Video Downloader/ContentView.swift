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
            VStack(spacing: 25) {
                Image(systemName: "video.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.blue)
                    .padding(.top, 40)
                
                VStack(alignment: .leading) {
                    Text("Enter Facebook or Instagram URL")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    TextField("https://...", text: $viewModel.url)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                .padding(.horizontal)
                
                if viewModel.isDownloading {
                    VStack {
                        ProgressView(value: viewModel.downloadProgress, total: 1.0)
                            .progressViewStyle(.linear)
                        Text("\(Int(viewModel.downloadProgress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                Button(action: viewModel.startProcess) {
                    if viewModel.isDownloading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Download Video")
                            .fontWeight(.bold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.url.isEmpty || viewModel.isDownloading)
                
                if !viewModel.statusMessage.isEmpty {
                    Text(viewModel.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(viewModel.statusMessage.contains("Error") ? .red : .green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Video Downloader")
            .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
}

#Preview {
    ContentView()
}
