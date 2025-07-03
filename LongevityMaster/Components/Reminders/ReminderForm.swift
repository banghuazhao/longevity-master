//
// Created by Banghua Zhao on 01/01/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import Dependencies
import SharingGRDB

@Observable
@MainActor
class ReminderFormViewModel: HashableObject {
    var reminder: Reminder.Draft
    let onSave: ((Reminder.Draft) -> Void)?

    let isEdit: Bool
    
    init(
        reminder: Reminder.Draft,
        onSave: ((Reminder.Draft) -> Void)? = nil
    ) {
        self.reminder = reminder
        self.onSave = onSave
        self.isEdit = reminder.id != nil
    }
    
    func onTapSaveReminder()  {
        onSave?(reminder)
    }
}

struct ReminderFormView: View {
    @State var viewModel: ReminderFormViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    DatePicker("Time", selection: $viewModel.reminder.time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                }
                .navigationTitle(
                    viewModel.isEdit
                    ? "Edit Reminder"
                    : "New Reminder"
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .appRectButtonStyle()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.onTapSaveReminder()
                            dismiss()
                        } label: {
                            Text(viewModel.isEdit ? "Update" : "Save")
                                .appRectButtonStyle()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }
    
    ReminderFormView(
        viewModel: ReminderFormViewModel(
            reminder: Reminder.Draft(Reminder(id: 0))
        )
    )
}
