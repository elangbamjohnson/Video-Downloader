
import XCTest
@testable import Video_Downloader

@MainActor
final class ContentViewModelTests: XCTestCase {
    
    var sut: ContentViewModel! // System Under Test
    var mockService: MockDownloadService!

    override func setUp() {
        super.setUp()
        mockService = MockDownloadService()
        // Inject the mock!
        sut = ContentViewModel(downloadService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    func test_startProcess_updatesUIState() async {
        // 1. Arrange
        sut.url = "https://instagram.com/reel/test"

        // 2. Act
        sut.startProcess()
        
        // Give the actor a chance to process the sync assignment if needed
        await Task.yield()

        // 3. Assert
        XCTAssertTrue(sut.isDownloading, "isDownloading should be true after starting process")
        XCTAssertTrue(mockService.startDownloadCalled, "startDownload should have been called on the service")
    }

    func test_checkClipboard_detectsInstagramLink() {
        // 1. Arrange
        let testURL = "https://www.instagram.com/reels/xyz/"
        
        // 2. Act
        sut.checkClipboard(explicitString: testURL)
        
        // 3. Assert
        XCTAssertTrue(sut.showSuggestion, "showSuggestion should be true for Instagram links")
        XCTAssertEqual(sut.detectedURL, testURL, "detectedURL should match the input URL")
        XCTAssertTrue(sut.detectedPlatform.contains("Instagram"), "detectedPlatform should contain 'Instagram'")
        }

        func test_urlValidation_detectsValidUrls() {
        // Valid Instagram
        sut.url = "https://www.instagram.com/reels/xyz/"
        XCTAssertTrue(sut.isUrlValid)

        // Valid Facebook
        sut.url = "https://fb.watch/xyz"
        XCTAssertTrue(sut.isUrlValid)

        // Invalid URL
        sut.url = "https://google.com"
        XCTAssertFalse(sut.isUrlValid)

        // Empty URL
        sut.url = ""
        XCTAssertFalse(sut.isUrlValid)
        }
        

    func test_serviceFailure_updatesStateToError() async {
        //1. Arrange
        mockService.shouldSucceed = false
        sut.url = "https://instagram.com/error"
        
        //2. Act
        sut.startProcess()
        
        // Wait for the async failure to propagate through the delegate
        // Using a short sleep because delegates are async-adjacent
        try? await Task.sleep(nanoseconds: 100_000_000) //0.1s
        
        //3. Assert
        XCTAssertFalse(sut.isDownloading)
        XCTAssertTrue(sut.showAlert)
        XCTAssertEqual(sut.alertMessage, "Mock Failure")
           
    }
}
