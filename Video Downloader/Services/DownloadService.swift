import Foundation
import LoadifyEngine

protocol DownloadServiceDelegate: AnyObject {
    func downloadService(_ service: DownloadService, didUpdateProgress progress: Double)
    func downloadService(_ service: DownloadService, didFinishWithLocation location: URL)
    func downloadService(_ service: DownloadService, didFailWithError error: Error)
    func downloadService(_ service: DownloadService, didUpdateStatus status: String)
}

class DownloadService: NSObject {
    
    weak var delegate: DownloadServiceDelegate?
    
    private let client = LoadifyClient()
    private let fallbackHosts = Constants.API.cobaltHosts
    private var backgroundSession: URLSession?
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: Constants.Config.backgroundSessionIdentifier)
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        config.waitsForConnectivity = true
        config.networkServiceType = .responsiveData
        config.httpMaximumConnectionsPerHost = Constants.Config.httpMaximumConnectionsPerHost
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        
        self.backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    
    func startDownload(url: String, quality: String) async {
        delegate?.downloadService(self, didUpdateStatus: Constants.Messages.analyzingLink)
        delegate?.downloadService(self, didUpdateProgress: 0.0)
        
        do {
            // Try LoadifyEngine first
            let details = try await client.fetchVideoDetails(for: url)
            delegate?.downloadService(self, didUpdateStatus: Constants.Messages.downloadingFrom.replacingOccurrences(of: "%s", with: details.platform.rawValue))
            
            guard let videoURL = URL(string: details.video.url) else {
                throw URLError(.badURL)
            }
            
            startBackgroundDownload(from: videoURL)
        } catch {
            print("DEBUG: Engine Error: \(error)")
            delegate?.downloadService(self, didUpdateStatus: Constants.Messages.engineIssueFallback)
            await tryFallbackAPI(url: url, quality: quality)
        }
    }
    
    private func tryFallbackAPI(url: String, quality: String) async {
        for host in fallbackHosts {
            let paths = Constants.API.apiEndpoints
            for path in paths {
                let endpoint = host + path
                do {
                    let displayHost = host.replacingOccurrences(of: "https://", with: "")
                    delegate?.downloadService(self, didUpdateStatus: Constants.Messages.connectingTo.replacingOccurrences(of: "%s", with: displayHost))
                    
                    let downloadLink = try await fetchFromCobalt(endpoint: endpoint, videoUrl: url, quality: quality)
                    
                    delegate?.downloadService(self, didUpdateStatus: Constants.Messages.downloadingFile)
                    guard let dlURL = URL(string: downloadLink) else { continue }
                    
                    startBackgroundDownload(from: dlURL)
                    return 
                } catch {
                    print("DEBUG: Fallback to \(endpoint) failed: \(error)")
                    continue
                }
            }
        }
        
        delegate?.downloadService(self, didFailWithError: NSError(domain: "DownloadService", code: -1, userInfo: [NSLocalizedDescriptionKey: Constants.Messages.allServicesUnavailable]))
    }
    
    private func fetchFromCobalt(endpoint: String, videoUrl: String, quality: String) async throws -> String {
        guard let apiUrl = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = Constants.API.httpMethodPost
        request.timeoutInterval = Constants.Config.requestTimeout
        
        request.addValue(Constants.API.applicationJson, forHTTPHeaderField: Constants.API.contentTypeHeader)
        request.addValue(Constants.API.applicationJson, forHTTPHeaderField: Constants.API.acceptHeader)
        
        let body: [String: Any] = [
            Constants.API.bodyKeyUrl: videoUrl,
            Constants.API.bodyKeyVideoQuality: quality,
            Constants.API.bodyKeyDownloadMode: Constants.API.downloadModeTunnel,
            Constants.API.bodyKeyVCodec: Constants.API.vCodecH264,
            Constants.API.bodyKeyAFormat: Constants.API.aFormatMp3,
            Constants.API.bodyKeyFilenameStyle: Constants.API.filenameStylePretty
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == Constants.Config.defaultStatusCode else {
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(FallbackAPIResponse.self, from: data)
        
        if let downloadUrl = apiResponse.url, !downloadUrl.isEmpty { return downloadUrl }
        
        if let status = apiResponse.status, status == Constants.API.statusError {
            throw NSError(domain: Constants.Config.errorDomain, code: Constants.Config.errorCode, userInfo: [NSLocalizedDescriptionKey: apiResponse.text ?? "Unknown API Error"])
        }
        
        throw URLError(.fileDoesNotExist)
    }
    
    private func startBackgroundDownload(from url: URL) {
        let task = backgroundSession?.downloadTask(with: url)
        task?.resume()
    }
}

extension DownloadService: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        delegate?.downloadService(self, didUpdateProgress: progress)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        let destinationURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        do {
            try fileManager.moveItem(at: location, to: destinationURL)
            delegate?.downloadService(self, didUpdateProgress: Constants.Config.maxDownloadProgress)
            delegate?.downloadService(self, didFinishWithLocation: destinationURL)
        } catch {
            delegate?.downloadService(self, didFailWithError: error)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            delegate?.downloadService(self, didFailWithError: error)
        }
    }
}

struct FallbackAPIResponse: Codable {
    let status: String?
    let url: String?
    let text: String?
}
