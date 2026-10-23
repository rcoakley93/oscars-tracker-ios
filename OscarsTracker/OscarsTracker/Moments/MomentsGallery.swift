import SwiftUI

/// Debug-only screen that triggers each moment (P3-08), reachable from the
/// profile sheet in debug builds. Turn on Reduce Motion to see the fades.
struct MomentsGallery: View {
    @State private var dust = 0
    @State private var ticket = 0
    @State private var envelope: EnvelopeReveal.Outcome??

    var body: some View {
        List {
            Section("Gold dust") {
                Button("Burst") { dust += 1 }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .goldDust(trigger: dust)
                    .moment(.ballotComplete, trigger: dust)
            }
            Section("Ticket stub") {
                Button("Mark Hamnet watched") { ticket += 1 }
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .overlay { TicketStub(title: "Hamnet", trigger: ticket) }
                    .moment(.watched, trigger: ticket)
            }
            Section("Envelope") {
                Button("Correct pick") { envelope = .some(.correct) }
                Button("Wrong pick") { envelope = .some(.wrong) }
                Button("No pick") { envelope = .some(nil) }
            }
        }
        .navigationTitle("Moments")
        .fullScreenCover(isPresented: Binding(get: { envelope != nil }, set: { if !$0 { envelope = nil } })) {
            EnvelopeReveal(category: "Best Picture", winner: "Hamnet", outcome: envelope ?? nil) { envelope = nil }
        }
    }
}

#Preview {
    NavigationStack { MomentsGallery() }.preferredColorScheme(.dark)
}
