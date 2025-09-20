import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()

    private init() {}

    // Save prescription document
    func savePrescription(_ prescription: Prescription) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthenticated"])
        }
        var pres = prescription
        if pres.id.isEmpty { pres.id = UUID().uuidString }
        pres.userId = uid
        let encoded = try Firestore.Encoder().encode(pres)
        try await db.collection("prescriptions").document(pres.id).setData(encoded)
    }

    // Save flagged meds
    func saveFlags(prescriptionId: String, flags: [[String: Any]]) async throws {
        try await db.collection("prescriptions").document(prescriptionId)
            .collection("flags").document("flags").setData(["medications": flags])
    }

    // Save schedule
    func saveSchedule(prescriptionId: String, schedule: [MedicationSchedule]) async throws {
        let data = schedule.map { sch in
            return [
                "medId": sch.med.id,
                "name": sch.med.name,
                "reminders": sch.reminders.map { $0.timeIntervalSince1970 }
            ]
        }
        try await db.collection("prescriptions").document(prescriptionId)
            .collection("schedule").document("schedule").setData(["medications": data])
    }

    // Save Google Calendar event IDs
    func saveScheduleEventIds(prescriptionId: String, eventMap: [String: [String]]) async throws {
        try await db.collection("prescriptions").document(prescriptionId)
            .collection("calendarEvents").document("events").setData(["map": eventMap])
    }

    // Save checklist
    func saveChecklist(prescriptionId: String, checklist: [ChecklistItem]) async throws {
        let data = checklist.map { item in
            return [
                "medName": item.medName,
                "scheduledTimes": item.scheduledTimes.map { $0.timeIntervalSince1970 },
                "taken": item.taken
            ] as [String: Any]
        }
        try await db.collection("prescriptions").document(prescriptionId)
            .collection("checklist").document("checklist").setData(["items": data])
    }
}
