//
//  MatchLogView.swift
//  BIOGLOW
//

import SwiftUI

struct MatchLogView: View {
    @Environment(\.dismiss) private var dismiss

    let entries: [MatchLogEntry]
    var canUndo: Bool = false
    var onUndo: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    Text("Changes you make while scoring show up here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(Array(entries.reversed().enumerated()), id: \.element.id) {
                    index,
                    entry in
                    MatchLogRow(entry: entry, latest: index == 0 && onUndo != nil)
                }
            }
            .navigationTitle("Match Log")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    DismissButton {
                        dismiss()
                    }
                }

                if let onUndo {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Undo Last", systemImage: "arrow.uturn.backward") {
                            onUndo()
                        }
                        .disabled(!canUndo)
                    }
                }
            }
        }
    }
}

struct MatchLogRow: View {
    let entry: MatchLogEntry
    var latest: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.clock ?? "No timer")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text(entry.date.formatted(date: .omitted, time: .standard))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 100, alignment: .leading)

            Text(entry.text)
                .font(.subheadline)
                .fontWeight(latest ? .semibold : .regular)
        }
    }
}
