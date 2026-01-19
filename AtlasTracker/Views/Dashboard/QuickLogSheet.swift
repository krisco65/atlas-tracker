import SwiftUI

struct QuickLogSheet: View {
    let compound: Compound
    let tracked: TrackedCompound
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LogDoseView(onSuccess: {
                onComplete()
                dismiss()
            }, preselectedCompound: compound)
            .navigationTitle("Log \(compound.name ?? "Dose")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
