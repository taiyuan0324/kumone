import Foundation
import SwiftUI

/// Simple in-memory log store that captures print output for in-app viewing.
enum AppLogStore {
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
                Menu {
                    Button {
                        UIPasteboard.general.string = logs.map { "\($0.time)  \($0.message)" }.joined(separator: "\n")
                    } label: {
                        Label("复制全部日志", systemImage: "doc.on.doc")
                    }
                    Button(role: .destructive) {
                        AppLogStore.clear()
                    } label: {
                        Label("清除日志", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                }
            }
        }
        .onAppear {
            logs = AppLogStore.logs
            AppLogStore.addObserver {
                logs = AppLogStore.logs
            }
        }
    }
}
