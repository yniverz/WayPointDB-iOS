[![License: NCPUL](https://img.shields.io/badge/license-NCPUL-blue.svg)](./LICENSE.md)

# WayPointDB-iOS

An iOS WayPointDB high density companion app written in Swift.  
This App is intended to be used with the (self hosted) [WayPointDB](https://github.com/yniverz/WayPointDB) Location Timeline service.

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yniverz/WayPointDB-iOS
   cd WayPointDB-iOS
   ```
2. **Open the project**:
   - Open `WayPointDB-iOS.xcodeproj` in Xcode.

3. **Select a Simulator or a connected device**:
   - In Xcode, choose a device or simulator from the scheme selector at the top.

4. **Build and Run**:
   - Press `Cmd + R` to build and run the app.

## Configuration
To use this app with your own WayPointDB instance, you need to enter the hostname and API key in the settings. To get an API key, refer to the [WayPointDB](https://github.com/yniverz/WayPointDB) documentation.

## Location Tracking

This app uses Core Location to track user location in the background. Make sure to enable location permissions in iOS settings when prompted by the app. The key feature of this app is its high density of tracking points. It will automatically detect when the user starts moving and begin tracking every GPS fix until the user stops again.

---

As Apple requires any developer to publicly display their full government name when publishing an app, I will currently not be publishing this app in the App Store.
This project uses a logo based on the design by [FeePik](https://www.flaticon.com/authors/freepik).
