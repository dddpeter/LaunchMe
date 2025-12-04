import XCTest
@testable import LaunchMe

final class LaunchpadViewModelTests: XCTestCase {
  
  // MARK: - Properties
  
  var viewModel: LaunchpadViewModel!
  var mockAppDiscoveryService: MockAppDiscoveryService!
  var mockFolderService: MockFolderService!
  var mockToastManager: MockToastManager!
  
  // MARK: - Setup & Teardown
  
  override func setUp() {
    super.setUp()
    
    mockAppDiscoveryService = MockAppDiscoveryService()
    mockFolderService = MockFolderService()
    mockToastManager = MockToastManager()
    
    viewModel = LaunchpadViewModel(
      appDiscoveryService: mockAppDiscoveryService,
      folderService: mockFolderService,
      toastManager: mockToastManager
    )
  }
  
  override func tearDown() {
    viewModel = nil
    mockAppDiscoveryService = nil
    mockFolderService = nil
    mockToastManager = nil
    
    super.tearDown()
  }
  
  // MARK: - Tests
  
  func testLoadInitialData() async {
    // Given
    let expectedApps = [AppItem.placeholder]
    let expectedFolders = [FolderItem.sampleFolders[0]]
    
    mockAppDiscoveryService.appsToReturn = expectedApps
    mockFolderService.foldersToReturn = expectedFolders
    
    // When
    viewModel.loadInitialData()
    
    // Wait for async operation
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
    
    // Then
    XCTAssertEqual(viewModel.apps.count, expectedApps.count)
    XCTAssertEqual(viewModel.folders.count, expectedFolders.count)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.loadingError)
  }
  
  func testLoadInitialDataWithError() async {
    // Given
    let expectedError = NSError(domain: "TestError", code: 1, userInfo: nil)
    
    mockAppDiscoveryService.errorToThrow = expectedError
    
    // When
    viewModel.loadInitialData()
    
    // Wait for async operation
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
    
    // Then
    XCTAssertTrue(viewModel.apps.isEmpty || viewModel.apps == AppItem.placeholders())
    XCTAssertTrue(viewModel.folders.isEmpty)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNotNil(viewModel.loadingError)
    XCTAssertTrue(mockToastManager.showErrorCalled)
  }
  
  func testCreateFolder() {
    // Given
    let folderName = "Test Folder"
    let initialFolderCount = viewModel.folders.count
    
    // When
    viewModel.createFolder(named: folderName)
    
    // Then
    XCTAssertEqual(viewModel.folders.count, initialFolderCount + 1)
    XCTAssertEqual(viewModel.folders.last?.name, folderName)
    XCTAssertTrue(mockToastManager.showSuccessCalled)
    XCTAssertTrue(mockFolderService.saveFoldersCalled)
  }
  
  func testCreateFolderWithEmptyName() {
    // Given
    let initialFolderCount = viewModel.folders.count
    
    // When
    viewModel.createFolder(named: "")
    viewModel.createFolder(named: "   ")
    
    // Then
    XCTAssertEqual(viewModel.folders.count, initialFolderCount)
    XCTAssertFalse(mockToastManager.showSuccessCalled)
    XCTAssertFalse(mockFolderService.saveFoldersCalled)
  }
  
  func testRenameFolder() {
    // Given
    let folder = FolderItem(name: "Original Name", appBundleIdentifiers: [])
    viewModel.folders.append(folder)
    
    let newName = "Renamed Folder"
    
    // When
    viewModel.renameFolder(id: folder.id, to: newName)
    
    // Then
    XCTAssertEqual(viewModel.folders.first?.name, newName)
    XCTAssertTrue(mockToastManager.showSuccessCalled)
    XCTAssertTrue(mockFolderService.saveFoldersCalled)
  }
  
  func testDeleteFolder() {
    // Given
    let folder = FolderItem(name: "Test Folder", appBundleIdentifiers: [])
    viewModel.folders.append(folder)
    viewModel.activeFolderID = folder.id
    
    let initialFolderCount = viewModel.folders.count
    
    // When
    viewModel.deleteFolder(id: folder.id)
    
    // Then
    XCTAssertEqual(viewModel.folders.count, initialFolderCount - 1)
    XCTAssertNil(viewModel.activeFolderID)
    XCTAssertTrue(mockFolderService.saveFoldersCalled)
  }
  
  func testAddAppToFolder() {
    // Given
    let app = AppItem.placeholder
    let folder = FolderItem(name: "Test Folder", appBundleIdentifiers: [])
    viewModel.folders.append(folder)
    
    // When
    viewModel.addApp(app, to: folder.id)
    
    // Then
    XCTAssertTrue(viewModel.folders.first?.appBundleIdentifiers.contains(app.bundleIdentifier) == true)
    XCTAssertTrue(mockToastManager.showSuccessCalled)
    XCTAssertTrue(mockFolderService.saveFoldersCalled)
  }
  
  func testRemoveAppFromFolder() {
    // Given
    let app = AppItem.placeholder
    let folder = FolderItem(name: "Test Folder", appBundleIdentifiers: [app.bundleIdentifier])
    viewModel.folders.append(folder)
    
    // When
    viewModel.removeApp(app, from: folder.id)
    
    // Then
    XCTAssertFalse(viewModel.folders.first?.appBundleIdentifiers.contains(app.bundleIdentifier) == true)
    XCTAssertTrue(mockFolderService.saveFoldersCalled)
  }
  
  func testToggleVisibility() {
    // Given
    XCTAssertFalse(viewModel.isVisible)
    
    // When
    let shouldShow = viewModel.toggleVisibility()
    
    // Then
    XCTAssertTrue(shouldShow)
    XCTAssertTrue(viewModel.isAnimating)
    
    // When - toggle again
    let shouldHide = viewModel.toggleVisibility()
    
    // Then
    XCTAssertFalse(shouldHide)
    XCTAssertTrue(viewModel.isAnimating)
  }
  
  func testSearchActive() {
    // Given
    viewModel.searchViewModel.query = ""
    
    // When
    viewModel.searchViewModel.query = "test"
    
    // Then
    XCTAssertTrue(viewModel.isSearchActive)
  }
  
  func testGridItems() {
    // Given
    let app = AppItem.placeholder
    let folder = FolderItem(name: "Test Folder", appBundleIdentifiers: [app.bundleIdentifier])
    
    viewModel.apps = [app]
    viewModel.folders = [folder]
    
    // When
    let gridItems = viewModel.gridItems
    
    // Then
    XCTAssertEqual(gridItems.count, 1) // Only folder should appear (app is inside folder)
    
    if case .folder(let folderItem) = gridItems.first {
      XCTAssertEqual(folderItem.name, folder.name)
    } else {
      XCTFail("Expected folder item")
    }
  }
  
  func testUngroupedApps() {
    // Given
    let app1 = AppItem.placeholder
    let app2 = AppItem(bundleIdentifier: "test.app2", displayName: "Test App 2", bundleURL: URL(fileURLWithPath: "/Applications"), categories: [], icon: nil)
    let folder = FolderItem(name: "Test Folder", appBundleIdentifiers: [app1.bundleIdentifier])
    
    viewModel.apps = [app1, app2]
    viewModel.folders = [folder]
    
    // When
    let ungroupedApps = viewModel.ungroupedApps
    
    // Then
    XCTAssertEqual(ungroupedApps.count, 1)
    XCTAssertEqual(ungroupedApps.first?.bundleIdentifier, app2.bundleIdentifier)
  }
}

// MARK: - Mock Classes

class MockAppDiscoveryService: AppDiscoveryServicing {
  
  var appsToReturn: [AppItem] = []
  var errorToThrow: Error?
  
  func discoverApplications() async throws -> [AppItem] {
    if let error = errorToThrow {
      throw error
    }
    return appsToReturn
  }
}

class MockFolderService: FolderPersistenceServicing {
  
  var foldersToReturn: [FolderItem] = []
  var saveFoldersCalled = false
  
  func loadFolders() async throws -> [FolderItem] {
    return foldersToReturn
  }
  
  func saveFolders(_ folders: [FolderItem]) async throws {
    saveFoldersCalled = true
  }
}

class MockToastManager: ToastManager {
  
  var showSuccessCalled = false
  var showErrorCalled = false
  var showInfoCalled = false
  var showWarningCalled = false
  
  override func showSuccess(_ message: String) {
    showSuccessCalled = true
    super.showSuccess(message)
  }
  
  override func showError(_ message: String) {
    showErrorCalled = true
    super.showError(message)
  }
  
  override func showInfo(_ message: String) {
    showInfoCalled = true
    super.showInfo(message)
  }
  
  override func showWarning(_ message: String) {
    showWarningCalled = true
    super.showWarning(message)
  }
}

// MARK: - AppItem Extension

extension AppItem {
  static let placeholder = AppItem(
    bundleIdentifier: "test.app",
    displayName: "Test App",
    bundleURL: URL(fileURLWithPath: "/Applications"),
    categories: [],
    icon: nil
  )
}