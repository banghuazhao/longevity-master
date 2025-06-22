//
// Created by Banghua Zhao on 22/06/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import Dependencies

enum WeekDays: Int, CaseIterable {
    case mon = 2
    case tue = 3
    case wed = 4
    case thu = 5
    case fri = 6
    case sat = 7
    case sun = 1
    
    var title: String {
        switch self {
        case .mon:
            "Mon"
        case .tue:
            "Tue"
        case .wed:
            "Wed"
        case .thu:
            "Thu"
        case .fri:
            "Fri"
        case .sat:
            "Sat"
        case .sun:
            "Sun"
        }
    }
}

struct HabitFormView: View {
    @State var viewModel: HabitFormViewModel
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "list.bullet.clipboard.fill")
                        TextField("New habit name", text: $viewModel.habit.name)
                        Button(action: {}) {
                            Text("Gallery")
                                .cornerRadius(8)
                        }
                    }
                    
                    HStack(spacing: 10) {
                        HStack{
                            Image(systemName: "folder.fill.badge.person.crop")
                            Text("Category")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        Picker("Category", selection: $viewModel.habit.category) {
                            ForEach(HabitCategory.allCases, id: \.self) { habitCategory in
                                Text(habitCategory.title)
                                    .tag(habitCategory.rawValue)
                            }
                        }

                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack{
                            HStack{
                                Image(systemName: "clock.fill")
                                Text("Frequency")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                            Picker("Frequency", selection: $viewModel.habit.frequency) {
                                ForEach(HabitFrequency.allCases, id: \.self) { habitFrequency in
                                    Text(habitFrequency.title)
                                        .tag(habitFrequency.rawValue)
                                }
                            }
                        }
                        
                        switch viewModel.habit.frequency {
                        case .fixedDaysInWeek:
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible()), count: 7)
                            ) {
                                ForEach(WeekDays.allCases, id: \.self) { weekDay in
                                    Button(action: { viewModel.toggleWeekDay(weekDay) }) {
                                        VStack(spacing: 8) {
                                            Text(weekDay.title)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                            if viewModel.hasSelectedWeekDay(weekDay) {
                                                Image(systemName: "checkmark.circle.fill")
                                            }
                                        }
                                        .padding(8)
                                    }
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        case .fixedDaysInMonth:
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible()), count: 7)
                            ) {
                                ForEach(1...28, id: \.self) { monthDay in
                                    Button(action: { viewModel.toggleMonthDay(monthDay) }) {
                                        VStack(spacing: 8) {
                                            Text("\(monthDay)")
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                        }
                                        .padding(8)
                                    }
                                    .background(
                                        viewModel.hasSelectedMonthDay(monthDay) ?
                                        Color.green.opacity(0.1) :
                                            Color.gray.opacity(0.1)
                                    )
                                    .cornerRadius(8)
                                }
                            }
                        case .nDaysEachWeek:
                            HStack {
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { viewModel.habit.nDaysPerWeek },
                                    set: { viewModel.onSelectNDays($0) }
                                )) {
                                    ForEach(1...7, id: \.self) { nDays in
                                        if nDays == 1 {
                                            Text("\(nDays) day")
                                                .tag(nDays)
                                        } else {
                                            Text("\(nDays) days")
                                                .tag(nDays)
                                        }
                                    }
                                }
                            }
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(Color.gray)
                                    .font(.caption)
                                if viewModel.habit.nDaysPerWeek == 1 {
                                    Text("After being completed on \(viewModel.habit.nDaysPerWeek) day, the habit will not show up again this week.")
                                        .foregroundStyle(Color.gray)
                                        .font(.caption)
                                } else {
                                    Text("After being completed on \(viewModel.habit.nDaysPerWeek) days, the habit will not show up again this week.")
                                        .foregroundStyle(Color.gray)
                                        .font(.caption)
                                }
                            }
                        case .nDaysEachMonth:
                            HStack {
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { viewModel.habit.nDaysPerMonth },
                                    set: { viewModel.onSelectNDays($0) }
                                )) {
                                    ForEach(1...28, id: \.self) { nDays in
                                        if nDays == 1 {
                                            Text("\(nDays) day")
                                                .tag(nDays)
                                        } else {
                                            Text("\(nDays) days")
                                                .tag(nDays)
                                        }
                                    }
                                }
                            }
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(Color.gray)
                                    .font(.caption)
                                if viewModel.habit.nDaysPerMonth == 1 {
                                    Text("After being completed on \(viewModel.habit.nDaysPerWeek) day, the habit will not show up again this month.")
                                        .foregroundStyle(Color.gray)
                                        .font(.caption)
                                } else {
                                    Text("After being completed on \(viewModel.habit.nDaysPerWeek) days, the habit will not show up again this month.")
                                        .foregroundStyle(Color.gray)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    HStack{
                        HStack{
                            Image(systemName: "clock.fill")
                            Text("Habit Icon")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    
                    ZStack {
                        Circle()
                            .stroke(
                                viewModel.habit.borderColor,
                                style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                            )
                            .background(
                                Circle()
                                    .fill(Color(hex: viewModel.habit.color))
                            )
                            .frame(width: 60, height: 60)
                        
                        Text(viewModel.habit.icon)
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: viewModel.habit.color))
                    }
                }
                .padding()
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        
                    }
                }
            }
            .onChange(of: viewModel.habit.frequency) { _, _ in
                viewModel.onChangeOfHabitFrequency()
            }
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    
    HabitFormView(
        viewModel: HabitFormViewModel(
            habit: Habit.Draft(
                Habit(
                    id: 1,
                    frequency: .nDaysEachWeek
                )
            )
        )
    )
}
