// AgenticManager.swift
import Foundation
import FirebaseAuth
import Combine

@MainActor
final class AgenticManager: ObservableObject {
    static let shared = AgenticManager()

    enum StepStatus {
        case pending, running, done, failed(String)
    }

    @Published var stepStatuses: [String: StepStatus] = [:]
    @Published var flaggedResults: [FlaggedMed] = []
    @Published var scheduleResult: [MedicationSchedule] = []
    @Published var checklistResult: [ChecklistItem] = []
    @Published var calendarEventMap: [String: [String]] = [:]
    @Published var exportSummary: String?

    init() {
        stepStatuses = [
            "flag": .pending,
            "schedule": .pending,
            "calendar": .pending,
            "checklist": .pending,
            "export": .pending
        ]
    }

    struct FlaggedMed: Identifiable, Codable {
        var id: String = UUID().uuidString
        var name: String
        var reason: String
        var confidence: Double?
        var uncertain: Bool
        var originalText: String?
    }

    // MARK: - Full flow
    func startFlow(prescription: Prescription) async {
        // reset state
        stepStatuses = stepStatuses.mapValues { _ in .pending }
        flaggedResults = []
        scheduleResult = []
        checklistResult = []
        calendarEventMap = [:]
        exportSummary = nil

        let presId = prescription.id.isEmpty ? UUID().uuidString : prescription.id

        // STEP 1: Flagging
        stepStatuses["flag"] = .running
        do {
            let flaggedMeds = flagUnusualMeds(from: prescription.medications)
            let flagEntries = flaggedMeds.map { med -> FlaggedMed in
                var reasons: [String] = []
                if med.uncertain { reasons.append("uncertain") }
                if let conf = med.confidence, conf < 0.7 { reasons.append("low confidence (\(String(format: "%.2f", conf)))") }
                let blacklist = ["warfarin","heparin","isotretinoin"]
                if blacklist.contains(med.name.lowercased()) { reasons.append("high-risk") }
                let reason = reasons.isEmpty ? "manual review suggested" : reasons.joined(separator: ", ")
                return FlaggedMed(name: med.name, reason: reason, confidence: med.confidence, uncertain: med.uncertain, originalText: med.originalText)
            }
            flaggedResults = flagEntries

            // Persist flags
            let flagsDict = flagEntries.map { f -> [String: Any] in
                var d: [String:Any] = ["id": f.id, "name": f.name, "reason": f.reason, "uncertain": f.uncertain]
                if let c = f.confidence { d["confidence"] = c }
                if let o = f.originalText { d["originalText"] = o }
                return d
            }
            try await FirebaseService.shared.saveFlags(prescriptionId: presId, flags: flagsDict)
            stepStatuses["flag"] = .done
        } catch {
            stepStatuses["flag"] = .failed(error.localizedDescription)
            // stop on failure (optional) or continue — I'll stop here
            return
        }

        // STEP 2: Build schedule
        stepStatuses["schedule"] = .running
        do {
            let schedule = buildMockSchedule(from: prescription.medications)
            scheduleResult = schedule
            try await FirebaseService.shared.saveSchedule(prescriptionId: presId, schedule: schedule)
            stepStatuses["schedule"] = .done
        } catch {
            stepStatuses["schedule"] = .failed(error.localizedDescription)
            return
        }

        // STEP 3: Google Calendar scheduling (will invoke Google Sign-In if needed)
        stepStatuses["calendar"] = .running
        do {
            let createdMap = try await scheduleToGoogleCalendar(prescriptionId: presId, schedule: scheduleResult)
            calendarEventMap = createdMap
            try await FirebaseService.shared.saveScheduleEventIds(prescriptionId: presId, eventMap: createdMap)
            stepStatuses["calendar"] = .done
        } catch {
            stepStatuses["calendar"] = .failed(error.localizedDescription)
            // continue to checklist even if calendar fails? choose to continue:
            // return
        }

        // STEP 4: Checklist
        stepStatuses["checklist"] = .running
        do {
            let checklist = buildChecklist(from: scheduleResult)
            checklistResult = checklist
            try await FirebaseService.shared.saveChecklist(prescriptionId: presId, checklist: checklist)
            stepStatuses["checklist"] = .done
        } catch {
            stepStatuses["checklist"] = .failed(error.localizedDescription)
            // continue
        }

        // STEP 5: Export summary card (prepare text & save)
        stepStatuses["export"] = .running
        do {
            let summary = exportSummaryCard(for: prescription)
            exportSummary = summary
            // You might save it or present share sheet in UI
            stepStatuses["export"] = .done
        } catch {
            stepStatuses["export"] = .failed(error.localizedDescription)
        }
    }

    // MARK: - Helpers (reuse earlier pieces)

    func flagUnusualMeds(from meds: [Medication]) -> [Medication] {
        let threshold = 0.7
        let blacklist = ["warfarin","heparin","isotretinoin"]
        return meds.filter {
            ($0.confidence ?? 1.0) < threshold || $0.uncertain || blacklist.contains($0.name.lowercased())
        }
    }

    func buildMockSchedule(from meds: [Medication]) -> [MedicationSchedule] {
        meds.map { med in
            let now = Date()
            var times: [Date] = []
            if let freq = med.frequency?.lowercased() {
                if freq.contains("twice") || freq.contains("2") {
                    times = [Calendar.current.date(byAdding: .hour, value: 1, to: now)!,
                             Calendar.current.date(byAdding: .hour, value: 12, to: now)!]
                } else {
                    times = [Calendar.current.date(byAdding: .hour, value: 1, to: now)!]
                }
            } else {
                times = [Calendar.current.date(byAdding: .hour, value: 1, to: now)!]
            }
            return MedicationSchedule(med: med, reminders: times)
        }
    }

    func buildChecklist(from schedule: [MedicationSchedule]) -> [ChecklistItem] {
        schedule.map { sch in
            ChecklistItem(medName: sch.med.name, scheduledTimes: sch.reminders)
        }
    }

    // Google Calendar scheduling helper (reuses your GoogleSignInHelper & GoogleCalendarService)
    func scheduleToGoogleCalendar(prescriptionId: String, schedule: [MedicationSchedule]) async throws -> [String: [String]] {
        // prompt Google sign-in when needed (this will present UI)
        let signInHelper = GoogleSignInHelper()
        let tokens = try await signInHelper.signIn()
        let accessToken = tokens.accessToken

        var map: [String: [String]] = [:]

        for sch in schedule {
            var eventIds: [String] = []
            for reminder in sch.reminders {
                // build RFC3339 timestamps
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let start = iso.string(from: reminder)
                let end = iso.string(from: Calendar.current.date(byAdding: .minute, value: 15, to: reminder) ?? Date())

                let event: [String: Any] = [
                    "summary": "Take \(sch.med.name)",
                    "description": "Medication reminder for \(sch.med.name) — Dose: \(sch.med.dosage ?? "-")",
                    "start": ["dateTime": start],
                    "end": ["dateTime": end],
                    "reminders": ["useDefault": false, "overrides": [["method":"popup","minutes":0]]],
                    "extendedProperties": ["shared": ["medId": sch.med.id, "prescriptionId": prescriptionId]]
                ]

                let resp = try await GoogleCalendarService.shared.insertEvent(accessToken: accessToken, event: event)
                if let id = resp["id"] as? String { eventIds.append(id) }
            }
            map[sch.id] = eventIds
        }
        return map
    }

    // Export summary
    func exportSummaryCard(for prescription: Prescription) -> String {
        var card = "📝 Prescription Summary — \(DateFormatter.localizedString(from: prescription.date, dateStyle: .medium, timeStyle: .none))\n\n"
        for med in prescription.medications {
            card += "• \(med.name) \(med.dosage ?? "") | \(med.frequency ?? "") | \(med.duration ?? "")\n"
        }
        return card
    }
}
