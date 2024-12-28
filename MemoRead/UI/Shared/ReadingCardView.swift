//
//  ReadingCardView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI

struct ReadingCardView: View {
    let item: ReadingCardModel
    @State private var isCompleted: Bool
    private var type: ReadingCardModel.ReadingCardType

    // MARK: - Initialization
    init(item: ReadingCardModel) {
        self.item = item
        _isCompleted = State(initialValue: item.isCompleted)
        self.type = ReadingCardModel.ReadingCardType(rawValue: item.type)!
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            ReadingCardContentView(item: item)
            actionView
        }
        .padding()
        .cardBorder(isCompleted: isCompleted)
    }

    // MARK: - Subviews
    private var headerView: some View {
        HStack {
            CardTypeLabel(type: self.type)
            Spacer()
            TimeAgoLabel(date: item.createdAt)
        }
    }

    private var actionView: some View {
        HStack {
            Spacer()
            CompleteButton(
                type: self.type,
                isCompleted: $isCompleted,
                action: handleComplete
            )
        }
    }

    // MARK: - Actions
    private func handleComplete() {
        item.content.copyToClipboard()
        isCompleted = true
        item.markAsCompleted()
    }
}

// MARK: - Supporting Views
private struct CardTypeLabel: View {
    let type: ReadingCardModel.ReadingCardType

    var body: some View {
        HStack {
            Image(systemName: type.icon)
            Text(type.name)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
        }
    }
}

private struct TimeAgoLabel: View {
    let date: Date

    var body: some View {
        Text(date.timeAgoDisplay())
            .font(.caption)
            .foregroundColor(.gray)
    }
}

private struct CompleteButton: View {
    let type: ReadingCardModel.ReadingCardType
    @Binding var isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isCompleted {
                    Text("Completed")
                        .foregroundColor(.gray)
                } else if type == .image {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "doc.on.doc")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.leading, 8)
        .disabled(isCompleted)
    }
}

// MARK: - View Modifiers
extension View {
    fileprivate func cardBorder(isCompleted: Bool) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCompleted ? Color.gray : Color.blue, lineWidth: 1)
        )
    }
}

#Preview {
    ReadingCardView(item: ReadingCardModel.sampleCards()[0])
}
