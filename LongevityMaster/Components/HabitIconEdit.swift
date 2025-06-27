//
// Created by Banghua Zhao on 26/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class HabitIconEditViewModel: ObservableObject {
    var habit: Habit.Draft
    var selectedColorHex: Int
    var selectedIcon: String
    var selectedCategory: HabitCategory = .diet

    init(habit: Binding<Habit.Draft>) {
        self.habit = habit.wrappedValue
        selectedColorHex = habit.wrappedValue.color
        selectedIcon = habit.wrappedValue.icon
    }
}

struct HabitIconEditView: View {
    @Binding var habit: Habit.Draft
    @State var selectedColorHex: Int
    @State var selectedIcon: String
    @State var selectedCategory: HabitCategory

    init(habit: Binding<Habit.Draft>) {
        _habit = habit
        selectedColorHex = habit.wrappedValue.color
        selectedIcon = habit.wrappedValue.icon
        selectedCategory = habit.wrappedValue.category
    }

    func onSelectColor(_ newColor: Int) {
        habit.color = newColor
        selectedColorHex = newColor
    }

    func onSelectIcon(_ newIcon: String) {
        habit.icon = newIcon
        selectedIcon = newIcon
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
                                    get: { Color(hex: selectedColorHex) },
                                    set: { onSelectColor($0.hexIntWithAlpha) }
                                )
                            )
                            .labelsHidden()

                            ForEach(HabitIconColorDataSource.colors, id: \.self) { colorHex in
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        selectedColorHex == colorHex ? Circle().stroke(Color.black, lineWidth: 2) : nil
                                    )
                                    .onTapGesture {
                                        onSelectColor(colorHex)
                                    }
                            }
                        }
                        .padding()
                    }
                    .frame(maxWidth: 800)

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(HabitCategory.allCases, id: \.self) { category in
                            Text(category.briefTitle).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 50, maximum: 100)),
                    ], spacing: 10) {
                        ForEach(
                            HabitIconDataSource.getIcons(for: selectedCategory)
                            , id: \.self
                        ) { icon in
                            Text(icon)
                                .font(.system(size: 32))
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(
                                            selectedIcon == icon ?
                                                Color(hex: selectedColorHex) :
                                                Color.clear
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedIcon == icon ?
                                                Color.black :
                                                Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    onSelectIcon(icon)
                                }
                        }
                    }
                    .padding()

                    Spacer()
                }
            }
        }
    }
}

#Preview {
    HabitIconEditView(
        habit: .constant(
            Habit.Draft(
                Habit(
                    id: 0,
                    name: "Test"
                )
            )
        )
    )
}
