//
//  DoctorDirectoryService.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//
import Foundation
import Combine
import CoreLocation

class DoctorDirectoryService: ObservableObject {
    static let shared = DoctorDirectoryService()
    private init() {}
    
    @Published var nearbyDoctors: [Doctor] = []
    @Published var isLoadingDoctors = false
    
    // Mock data for demonstration - in production, use Google Places API or medical directory API
    private let mockDoctors = [
        Doctor(name: "Dr. Sarah Johnson", specialty: "Cardiology", address: "123 Medical Center Dr", distance: 0.5, phone: "+1-555-0101", rating: 4.8, location: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)),
        Doctor(name: "Dr. Michael Chen", specialty: "Pulmonology", address: "456 Health Plaza", distance: 1.2, phone: "+1-555-0102", rating: 4.7, location: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)),
        Doctor(name: "Dr. Emily Rodriguez", specialty: "Neurology", address: "789 Brain Institute", distance: 2.1, phone: "+1-555-0103", rating: 4.9, location: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)),
        Doctor(name: "Dr. David Wilson", specialty: "Orthopedics", address: "321 Bone & Joint Clinic", distance: 0.8, phone: "+1-555-0104", rating: 4.6, location: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)),
        Doctor(name: "Dr. Lisa Thompson", specialty: "Emergency Medicine", address: "Emergency Department, City Hospital", distance: 0.3, phone: "+1-555-0105", rating: 4.5, location: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)),
        Doctor(name: "Dr. James Brown", specialty: "Internal Medicine", address: "General Medicine Clinic", distance: 1.5, phone: "+1-555-0106", rating: 4.4, location: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)),
        Doctor(name: "Dr. Maria Garcia", specialty: "Radiology", address: "Imaging Center", distance: 0.9, phone: "+1-555-0107", rating: 4.7, location: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)),
        Doctor(name: "Dr. Robert Lee", specialty: "Oncology", address: "Cancer Treatment Center", distance: 2.5, phone: "+1-555-0108", rating: 4.9, location: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777))
    ]
    
    func findDoctors(for specialties: [String], userLocation: CLLocation?) async {
        isLoadingDoctors = true
        
        // Simulate API call delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            // Filter doctors by specialty and sort by distance
            let filteredDoctors = mockDoctors.filter { doctor in
                specialties.contains(doctor.specialty)
            }.sorted { $0.distance < $1.distance }
            
            nearbyDoctors = Array(filteredDoctors.prefix(5)) // Limit to top 5
            isLoadingDoctors = false
        }
    }
}
