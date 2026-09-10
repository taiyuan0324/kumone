import Foundation
import SwiftUI

/// Simple in-memory log store that captures print output for in-app viewing.
enum AppLogStore {
    static let shared = AppLogStore()
    
    private static let maxLogs = 500
    private static let logLock = NSLock()
    private static var _logs: [(time: String, message: String)] = []
    private static var observers: [() -> Void] = []
    
    static var logs: [(time: String, message: String)] {
        logLock.lock(); defer { logLock.unlock() }
        return _logs
    }
    
    static func append(_ message: String) {
        logLock.lock()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        _logs.append((formatter.string(from: Date()), message))
        if _logs.count > maxLogs {
            _logs.removeFirst(_logs.count - maxLogs)
        }
        let snapshot = _logs
        logLock.unlock()
        
        // Notify observers on main thread
        DispatchQueue.main.async {
            for observer in observers {
                observer()
            }
        }
    }
    
    static func addObserver(_ observer: @escaping () -> Void) {
        logLock.lock()
        observers.append(observer)
        logLock.unlock()
    }
    
    static func clear() {
        logLock.lock()
        _logs.removeAll()
        logLock.unlock()
    }
}

/// View to display app logs.
struct AppLogView: View {
    @State private var logs: [(time: String, message: String)] = []
    
    var body: some View {
        List {
            ForEach(Array(logs.enumerated()), id: \.offset) { index, log in
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.time)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                    Text(log.message)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle("播放日志")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { AppLogStore.clear() }) {
                    Text("清除")
                }
            }
        }
        .onAppear {
            logs = AppLogStore.shared.logs
            AppLogStore.shared.addObserver {
                logs = AppLogStore.shared.logs
            }
        }
    }
}
