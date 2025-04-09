//
//  Models.swift
//  DaWarIch Companion
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
    let countries: [String]
    let cities: [[String]]
    let monthlyDistanceKm: MonthlyDistance
}

struct TotalStatistic: Decodable {
    static func defaultValue() -> TotalStatistic {
        .init(
            totalDistanceKm: 0,
            totalPointsTracked: 0,
            totalReverseGeocodedPoints: 0,
            totalCountriesVisited: 0,
            totalCitiesVisited: 0,
            countries: [],
            cities: [],
            yearlyStats: [],
            MIN_COUNTRY_VISIT_DURATION_FOR_STATS: "",
            MIN_CITY_VISIT_DURATION_FOR_STATS: ""
        )
    }
    
    let totalDistanceKm: Int
    let totalPointsTracked: Int
    let totalReverseGeocodedPoints: Int
    let totalCountriesVisited: Int
    let totalCitiesVisited: Int
    let countries: [String]
    let cities: [[String]]
    let yearlyStats: [YearlyStatistic]
    let MIN_COUNTRY_VISIT_DURATION_FOR_STATS: String
    let MIN_CITY_VISIT_DURATION_FOR_STATS: String
}





struct MonthStatistic: Decodable {
    let month: Int
    let totalDistanceKm: Int
    let totalCountriesVisited: Int
    let totalCitiesVisited: Int
    let countries: [String]
    let cities: [[String]]
    let dailyDistanceKm: [Int]
}


struct YearStatistic: Decodable {
    static func defaultValue() -> YearStatistic {
        .init(
            totalDistanceKm: 0,
            totalPointsTracked: 0,
            totalReverseGeocodedPoints: 0,
            totalCountriesVisited: 0,
            totalCitiesVisited: 0,
            countries: [],
            cities: [],
            monthlyStats: [],
            MIN_COUNTRY_VISIT_DURATION_FOR_STATS: "",
            MIN_CITY_VISIT_DURATION_FOR_STATS: ""
        )
    }
            
    
    let totalDistanceKm: Int
    let totalPointsTracked: Int
    let totalReverseGeocodedPoints: Int
    let totalCountriesVisited: Int
    let totalCitiesVisited: Int
    let countries: [String]
    let cities: [[String]]
    let monthlyStats: [MonthStatistic]
    let MIN_COUNTRY_VISIT_DURATION_FOR_STATS: String
    let MIN_CITY_VISIT_DURATION_FOR_STATS: String
}
