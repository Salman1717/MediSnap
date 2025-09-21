import Foundation
import FirebaseFirestore

// Enhanced prescription model that includes all related data
struct CompletePrescription: Identifiable {
    let id: String
    let date: Date
    let medications: [Medication]
    let userId: String
    let status: String?
    let createdAt: Date?
    let lastUpdated: Date?
    
    // Related data (not Codable, loaded separately)
    var schedule: [MedicationSchedule]?
    var safetyInfo: SafetyResponse?
    var calendarEventIds: [String: [String]]?
    var flags: [[String: Any]]?
    
    // Initialize from basic Prescription
    init(from prescription: Prescription, status: String? = nil, createdAt: Date? = nil, lastUpdated: Date? = nil) {
        self.id = prescription.id
        self.date = prescription.date
        self.medications = prescription.medications
        self.userId = prescription.userId ?? ""
        self.status = status
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        
        // Initialize optional data as nil
        self.schedule = nil
        self.safetyInfo = nil
        self.calendarEventIds = nil
        self.flags = nil
    }
    
    // Full initializer
    init(id: String, date: Date, medications: [Medication], userId: String, status: String? = nil, createdAt: Date? = nil, lastUpdated: Date? = nil, schedule: [MedicationSchedule]? = nil, safetyInfo: SafetyResponse? = nil, calendarEventIds: [String: [String]]? = nil, flags: [[String: Any]]? = nil) {
        self.id = id
        self.date = date
        self.medications = medications
        self.userId = userId
        self.status = status
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.schedule = schedule
        self.safetyInfo = safetyInfo
        self.calendarEventIds = calendarEventIds
        self.flags = flags
    }
}

// Model for loading schedule data from Firestore
struct FirestoreScheduleItem: Codable {
    let medId: String
    let name: String
    let reminders: [TimeInterval]
    
    func toMedicationSchedule(with medication: Medication) -> MedicationSchedule {
        return MedicationSchedule(
            med: medication,
            reminders: reminders.map { Date(timeIntervalSince1970: $0) }
        )
    }
}
