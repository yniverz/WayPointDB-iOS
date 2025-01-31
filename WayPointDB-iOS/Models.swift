//
//  Models.swift
//  WayPointDB iOS
//
//  Created by yniverz on 17.01.25.
//

import Foundation
import CoreLocation

struct LocationItem: Codable, Hashable {
    var time: Double
    var lat: Double
    var lng: Double
    var horAcc: Double
    var alt: Double
    var altAcc: Double
    var floor: Int
    var hdg: Double
    var hdgAcc: Double
    var spd: Double
    var spdAcc: Double
    
    var date: Date {
        Date(timeIntervalSince1970: time)
    }
    
    var coordinates: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    var location: CLLocation {
        CLLocation(latitude: lat, longitude: lng)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(time)
    }

    static func == (lhs: LocationItem, rhs: LocationItem) -> Bool {
        return lhs.time == rhs.time && lhs.lat == rhs.lat && lhs.lng == rhs.lng
    }
    
    static let allZero = LocationItem(time: 0, lat: 0, lng: 0, horAcc: 0, alt: 0, altAcc: 0, floor: 0, hdg: 0, hdgAcc: 0, spd: 0, spdAcc: 0)
}


struct TrackingPoint: Decodable {
    var altitude: Float
    var longitude: String
    var velocity: String
    var vertical_accuracy: Float
    var accuracy: Float
    var timestamp: Int
    var latitude: String
    var city: String?
    var country: String?
}


struct MonthlyDistance: Decodable {
    let january: Int
    let february: Int
    let march: Int
    let april: Int
    let may: Int
    let june: Int
    let july: Int
    let august: Int
    let september: Int
    let october: Int
    let november: Int
    let december: Int
}

struct YearlyStatistic: Decodable {
    let year: Int
    let totalDistanceKm: Int
    let totalCountriesVisited: Int
    let totalCitiesVisited: Int
    let monthlyDistanceKm: MonthlyDistance
}

struct TotalStatistic: Decodable {
    let totalDistanceKm: Int
    let totalPointsTracked: Int
    let totalReverseGeocodedPoints: Int
    let totalCountriesVisited: Int
    let totalCitiesVisited: Int
    let yearlyStats: [YearlyStatistic]
}


struct GpsBatch: Encodable {
    let gps_data: [GpsData]
}

struct GpsData: Encodable {
    let timestamp: Double
    let latitude: Double
    let longitude: Double
    let horizontal_accuracy: Double
    let altitude: Double
    let vertical_accuracy: Double
    let heading: Double
    let heading_accuracy: Double
    let speed: Double
    let speed_accuracy: Double
}
