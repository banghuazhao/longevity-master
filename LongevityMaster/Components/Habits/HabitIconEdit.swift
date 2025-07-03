//
// Created by Banghua Zhao on 26/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SwiftUI

struct HabitIconEditView: View {
    @Binding var color: Int
    @Binding var icon: String
    @State private var category: HabitCategory = .diet
    @State private var showEmojiPicker: Bool = false

    func onSelectColor(_ newColor: Int) {
        color = newColor
    }

    func onSelectIcon(_ newIcon: String) {
        icon = newIcon
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [
                            GridItem(.flexible(minimum: 50, maximum: 100)),
                            GridItem(.flexible(minimum: 50, maximum: 100)),
                        ], spacing: 10) {
                            ColorPicker(
                                "",
                                selection: Binding(
                                    get: { Color(hex: color) },
                                    set: { onSelectColor($0.hexIntWithAlpha) }
                                )
                            )
                            .labelsHidden()

                            ForEach(HabitIconColorDataSource.colors, id: \.self) { colorHex in
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        color == colorHex ? Circle().stroke(Color.black, lineWidth: 2) : nil
                                    )
                                    .onTapGesture {
                                        onSelectColor(colorHex)
                                    }
                            }
                        }
                        .padding()
                    }
                    .frame(maxWidth: 800)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(HabitCategory.allCases, id: \.self) { habitCategory in
                                CategoryFilterButton(
                                    title: habitCategory.briefTitle,
                                    isSelected: category == habitCategory,
                                    action: { category = habitCategory }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 50, maximum: 100)),
                    ], spacing: 10) {
                        Button(action: { showEmojiPicker.toggle() }) {
                            Text(icon)
                                .font(.system(size: 32))
                                .frame(width: 44, height: 44)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        ForEach(
                            HabitIconDataSource.getIcons(for: category)
                            , id: \.self
                        ) { iconNew in
                            Text(iconNew)
                                .font(.system(size: 32))
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(
                                            icon == iconNew ?
                                                Color(hex: color) :
                                                Color.clear
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            icon == iconNew ?
                                                Color.black :
                                                Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    Haptics.vibrateIfEnabled()
                                    onSelectIcon(iconNew)
                                }
                        }
                    }
                    .padding()

                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView(
                selectedEmoji: $icon,
                title: "Choose Habit Icon",
                categoryOrder: [
                    EmojiPickerView.Category.food,
                    EmojiPickerView.Category.activities,
                    EmojiPickerView.Category.objects,
                    EmojiPickerView.Category.animals,
                    EmojiPickerView.Category.smileys
                ]
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    @Previewable @State var color = 0xFFFFFFFF
    @Previewable @State var icon = "🥑"
    
    HabitIconEditView(
        color: $color,
        icon: $icon
        
    )
}
