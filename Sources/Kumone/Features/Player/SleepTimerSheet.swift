import SwiftUI

/// Sleep timer sheet shown from the now-playing page.
struct SleepTimerSheet: View {
    @EnvironmentObject private var player: PlayerService
    @Environment(\.dismiss) private var dismiss

    let options: [Int] = [5, 10, 15, 30, 60, 90]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(options, id: \.self) { minutes in
                        Button {
                            player.startSleepTimer(minutes: minutes)
                            dismiss()
                        } label: {
                            HStack {
                                Text("\(minutes) 分钟")
                                Spacer()
                                if let end = player.sleepTimerEndDate {
                                    let remaining = end.timeIntervalSinceNow
                                    if remaining < Double(minutes * 60) + 1 {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.accent)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("定时关闭")
                }

                if player.hasSleepTimerActive {
                    Section {
                        Button(role: .destructive) {
                            player.cancelSleepTimer()
                            dismiss()
                        } label: {
                            Text("取消定时")
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Section {
                        if let end = player.sleepTimerEndDate {
                            Text("将在 \(end.formatted(date: .omitted, time: .shortened)) 暂停播放")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("定时关闭")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text("关闭")
                    }
                }
            }
        }
    }
}
