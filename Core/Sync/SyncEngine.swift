import Foundation
import SwiftData

protocol SyncEngineProtocol: ObservableObject {
    func startListening() async
    func stopListening()
    func enqueueChange(entityName: String, entityID: UUID)
    func resolveConflict(entityName: String, entityID: UUID, keepLocal: Bool)
}

@MainActor
final class SyncEngine: ObservableObject, SyncEngineProtocol {
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published var syncQueue: [SyncRecord] = []

    private var syncTask: Task<Void, Never>?

    func startListening() async {
        guard AppConfiguration.isCloudSyncAvailable else { return }
        syncTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }
                await self.performSync()
                try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
            }
        }
    }

    func stopListening() {
        syncTask?.cancel()
        syncTask = nil
    }

    func enqueueChange(entityName: String, entityID: UUID) {
        let record = SyncRecord(entityName: entityName, entityID: entityID)
        syncQueue.append(record)
    }

    func resolveConflict(entityName: String, entityID: UUID, keepLocal: Bool) {
        guard let index = syncQueue.firstIndex(where: {
            $0.entityName == entityName && $0.entityID == entityID
        }) else { return }
        if keepLocal {
            syncQueue[index].syncStatus = .pending
        } else {
            syncQueue[index].syncStatus = .synced
        }
    }

    private func performSync() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            lastSyncDate = Date()
            syncQueue.removeAll { $0.syncStatus == .pending }
        } catch {}
    }
}