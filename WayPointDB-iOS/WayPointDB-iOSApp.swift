//
//  WayPointDB-iOSApp.swift
//  WayPointDB iOS
//
//  Created by yniverz on 17.01.25.
//

import SwiftUI

@main
struct WayPointDB_iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(appDelegate)
        }
    }
}
