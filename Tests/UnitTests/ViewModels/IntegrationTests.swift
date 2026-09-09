import XCTest
@testable import PersonalAssistant

final class SyncEngineTests: XCTestCase {
    func testEnqueueCreatesPendingRecord() {
        let engine = SyncEngine()
        let id = UUID()
        engine.enqueueChange(entityName: "Task", entityID: id)
        XCTAssertTrue(engine.syncQueue.contains { $0.entityID == id })
        XCTAssertTrue(engine.syncQueue.contains { $0.syncStatus == .pending })
    }

    func testConflictResolutionKeepLocal() {
        let engine = SyncEngine()
        let id = UUID()
        engine.enqueueChange(entityName: "Task", entityID: id)
        engine.resolveConflict(entityName: "Task", entityID: id, keepLocal: true)
        XCTAssertTrue(engine.syncQueue.contains { $0.entityID == id && $0.syncStatus == .pending })
    }

    func testConflictResolutionKeepServer() {
        let engine = SyncEngine()
        let id = UUID()
        engine.enqueueChange(entityName: "Task", entityID: id)
        engine.resolveConflict(entityName: "Task", entityID: id, keepLocal: false)
        XCTAssertTrue(engine.syncQueue.contains { $0.entityID == id && $0.syncStatus == .synced })
    }
}

final class SecureTokenStoreTests: XCTestCase {
    func testTokenRoundTripAndDelete() throws {
        let store = SecureTokenStore.shared
        let token = "test-token-\(UUID().uuidString)"
        try store.storeAuthToken(token)
        let read = try store.readAuthToken()
        XCTAssertEqual(read, token)
        try store.deleteAuthToken()
        let after = try store.readAuthToken()
        XCTAssertNil(after)
    }

    func testDeleteWhenEmptyDoesNotThrow() throws {
        let store = SecureTokenStore.shared
        try store.deleteAuthToken()
    }
}

final class AppDeepLinkTests: XCTestCase {
    func testOpenLinkParses() throws {
        let url = URL(string: "personalassistant://open")!
        guard let link = AppDeepLink(url: url) else {
            return XCTFail("Expected a valid deep link")
        }
        if case .openApp = link {} else { XCTFail("Expected .openApp") }
    }

    func testStartFocusLinkParses() throws {
        let url = URL(string: "personalassistant://start")!
        guard let link = AppDeepLink(url: url) else {
            return XCTFail("Expected a valid deep link")
        }
        if case .startFocus = link {} else { XCTFail("Expected .startFocus") }
    }

    func testUnknownSchemeRejected() {
        let url = URL(string: "https://example.com/open")!
        XCTAssertNil(AppDeepLink(url: url))
    }
}