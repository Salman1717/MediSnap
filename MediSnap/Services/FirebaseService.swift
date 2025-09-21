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
        
        // Create document data with initial status
        var prescriptionData = try Firestore.Encoder().encode(pres)
        prescriptionData["status"] = PrescriptionStatus.extracted.rawValue
        prescriptionData["createdAt"] = Timestamp(date: Date())
        prescriptionData["lastUpdated"] = Timestamp(date: Date())
        
        try await db.collection("prescriptions").document(pres.id).setData(prescriptionData)
    }
    
    // Save flagged meds
    func saveFlags(prescriptionId: String, flags: [[String: Any]]) async throws {
        try await db.collection("prescriptions").document(prescriptionId)
            .collection("flags").document("flags").setData(["medications": flags])
    }
    
    // Save schedule
    func saveSchedule(prescriptionId: String, schedule: [MedicationSchedule]) async throws {
        // First, ensure the parent prescription document exists
        let prescriptionRef = db.collection("prescriptions").document(prescriptionId)
        let prescriptionDoc = try await prescriptionRef.getDocument()
        
        if !prescriptionDoc.exists {
            throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Prescription document not found"])
        }
        
        let data = schedule.map { sch in
            return [
                "medId": sch.med.id,
                "name": sch.med.name,
                "reminders": sch.reminders.map { $0.timeIntervalSince1970 }
            ]
        }
        
        try await prescriptionRef
            .collection("schedule").document("schedule").setData(["medications": data])
        
        // Update prescription status
        try await updatePrescriptionStatus(prescriptionId: prescriptionId, status: .scheduled)
    }
    
    // Save Google Calendar event IDs
    func saveScheduleEventIds(prescriptionId: String, eventMap: [String: [String]]) async throws {
        try await db.collection("prescriptions").document(prescriptionId)
            .collection("calendarEvents").document("events").setData(["map": eventMap])
    }
    
    
    // NEW: Save safety information
    func saveSafetyInformation(prescriptionId: String, safetyResponse: SafetyResponse) async throws {
        let safetyData: [String: Any] = [
            "generalWarning": safetyResponse.generalWarning,
            "medications": safetyResponse.medications.map { medication in
                return [
                    "medicationName": medication.medicationName,
                    "commonSideEffects": medication.commonSideEffects,
                    "seriousSideEffects": medication.seriousSideEffects,
                    "precautions": medication.precautions,
                    "contraindications": medication.contraindications,
                    "drugInteractions": medication.drugInteractions,
                    "foodInteractions": medication.foodInteractions,
                    "whenToSeekHelp": medication.whenToSeekHelp,
                    "generalAdvice": medication.generalAdvice
                ]
            },
            "createdAt": Timestamp(date: Date()),
            "lastUpdated": Timestamp(date: Date())
        ]
        
        try await db.collection("prescriptions").document(prescriptionId)
            .collection("safety").document("safetyInfo").setData(safetyData)
    }
    
    // NEW: Retrieve safety information
    func getSafetyInformation(prescriptionId: String) async throws -> SafetyResponse? {
        let document = try await db.collection("prescriptions").document(prescriptionId)
            .collection("safety").document("safetyInfo").getDocument()
        
        guard let data = document.data() else { return nil }
        
        let generalWarning = data["generalWarning"] as? String ?? ""
        let medicationsData = data["medications"] as? [[String: Any]] ?? []
        
        let medications = medicationsData.compactMap { medData -> MedicationSafetyInfo? in
            guard let name = medData["medicationName"] as? String else { return nil }
            
            return MedicationSafetyInfo(
                medicationName: name,
                commonSideEffects: medData["commonSideEffects"] as? [String] ?? [],
                seriousSideEffects: medData["seriousSideEffects"] as? [String] ?? [],
                precautions: medData["precautions"] as? [String] ?? [],
                foodInteractions: medData["foodInteractions"] as? [String] ?? [],
                drugInteractions: medData["drugInteractions"] as? [String] ?? [],
                contraindications: medData["contraindications"] as? [String] ?? [],
                whenToSeekHelp: medData["whenToSeekHelp"] as? [String] ?? [],
                generalAdvice: medData["generalAdvice"] as? [String] ?? []
            )
        }
        
        return SafetyResponse(medications: medications, generalWarning: generalWarning)
    }
    
    // NEW: Update prescription status to track completion
    func updatePrescriptionStatus(prescriptionId: String, status: PrescriptionStatus) async throws {
        try await db.collection("prescriptions").document(prescriptionId)
            .setData([
                "status": status.rawValue,
                "lastUpdated": Timestamp(date: Date())
            ], merge: true)
    }
}

// NEW: Enum to track prescription processing status
enum PrescriptionStatus: String, CaseIterable {
    case extracted = "extracted"           // OCR completed, medications extracted
    case scheduled = "scheduled"           // Schedule generated and saved
    case calendarAdded = "calendar_added"  // Added to Google Calendar
    case safetyAnalyzed = "safety_analyzed" // Safety information generated and saved
    case completed = "completed"           // All processing complete
}

extension FirebaseService {
    
    // Fetch complete prescription data with all related subcollections
    func getCompletePrescription(prescriptionId: String) async throws -> CompletePrescription? {
        let prescriptionRef = db.collection("prescriptions").document(prescriptionId)
        let prescriptionDoc = try await prescriptionRef.getDocument()
        
        guard let prescriptionData = prescriptionDoc.data() else {
            return nil
        }
        
        // Parse basic prescription data
        let prescription = try prescriptionDoc.data(as: Prescription.self)
        
        // Load all related subcollections
        async let scheduleTask = loadSchedule(prescriptionId: prescriptionId, medications: prescription.medications)
        async let safetyTask = loadSafetyInfo(prescriptionId: prescriptionId)
        async let calendarTask = loadCalendarEventIds(prescriptionId: prescriptionId)
        
        async let flagsTask = loadFlags(prescriptionId: prescriptionId)
        
        // Wait for all tasks to complete
        let schedule = try? await scheduleTask
        let safetyInfo = try? await safetyTask
        let calendarEventIds = try? await calendarTask
        let flags = try? await flagsTask
        
        // Extract additional fields
        let status = prescriptionData["status"] as? String
        let createdAt = (prescriptionData["createdAt"] as? Timestamp)?.dateValue()
        let lastUpdated = (prescriptionData["lastUpdated"] as? Timestamp)?.dateValue()
        
        return CompletePrescription(
            id: prescription.id,
            date: prescription.date,
            medications: prescription.medications,
            userId: prescription.userId ?? "",
            status: status,
            createdAt: createdAt,
            lastUpdated: lastUpdated,
            schedule: schedule,
            safetyInfo: safetyInfo,
            calendarEventIds: calendarEventIds,
            flags: flags
        )
    }
    
    // Load schedule data
    private func loadSchedule(prescriptionId: String, medications: [Medication]) async throws -> [MedicationSchedule] {
        let scheduleDoc = try await db.collection("prescriptions")
            .document(prescriptionId)
            .collection("schedule")
            .document("schedule")
            .getDocument()
        
        guard let data = scheduleDoc.data(),
              let medicationsData = data["medications"] as? [[String: Any]] else {
            return []
        }
        
        return medicationsData.compactMap { medData in
            guard let name = medData["name"] as? String,
                  let reminders = medData["reminders"] as? [TimeInterval] else {
                return nil
            }
            
            // Find the matching medication
            if let medication = medications.first(where: { $0.name == name }) {
                return MedicationSchedule(
                    med: medication,
                    reminders: reminders.map { Date(timeIntervalSince1970: $0) }
                )
            }
            return nil
        }
    }
    
    // Load safety information
    private func loadSafetyInfo(prescriptionId: String) async throws -> SafetyResponse {
        return try await getSafetyInformation(prescriptionId: prescriptionId) ?? SafetyResponse(medications: [], generalWarning: "No safety information available")
    }
    
    // Load calendar event IDs
    private func loadCalendarEventIds(prescriptionId: String) async throws -> [String: [String]] {
        let calendarDoc = try await db.collection("prescriptions")
            .document(prescriptionId)
            .collection("calendarEvents")
            .document("events")
            .getDocument()
        
        guard let data = calendarDoc.data(),
              let eventMap = data["map"] as? [String: [String]] else {
            return [:]
        }
        
        return eventMap
    }
    
    
    
    // Load flags data
    private func loadFlags(prescriptionId: String) async throws -> [[String: Any]] {
        let flagsDoc = try await db.collection("prescriptions")
            .document(prescriptionId)
            .collection("flags")
            .document("flags")
            .getDocument()
        
        guard let data = flagsDoc.data(),
              let medications = data["medications"] as? [[String: Any]] else {
            return []
        }
        
        return medications
    }
    
    // Fetch all complete prescriptions for a user
    func getCompletePrescriptions(for userId: String) async throws -> [CompletePrescription] {
        let snapshot = try await db.collection("prescriptions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments()
        
        var completePrescriptions: [CompletePrescription] = []
        
        for document in snapshot.documents {
            if let completePrescription = try await getCompletePrescription(prescriptionId: document.documentID) {
                completePrescriptions.append(completePrescription)
            }
        }
        
        return completePrescriptions
    }
}

