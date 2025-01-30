//
//  ContentView.swift
//  WayPointDB iOS
//
//  Created by yniverz on 17.01.25.
//

import SwiftUI
import WebKit
import MapKit
import Charts

struct ContentView: View {
    var body: some View {
        TabView {
//            LocalMapView()
            HomepageView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
//            StatisticsView()
//                .tabItem {
//                    Label("Statistics", systemImage: "chart.bar.xaxis")
//                }
            TrackerSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}


struct StatisticsView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    private var locationHelper: LocationHelper {
        appDelegate.locationHelper
    }
    
    @State private var totalStatistic = TotalStatistic(totalDistanceKm: 0, totalPointsTracked: 0, totalReverseGeocodedPoints: 0, totalCountriesVisited: 0, totalCitiesVisited: 0, yearlyStats: [])
    @State private var isLoading = true
    
    func refreshStatistics() {
        isLoading = true
        let url = URL(string: locationHelper.waypointdbServerHost + "/api/v1/stats?api_key=\(locationHelper.waypointdbServerKey)")!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            isLoading = false
            guard let jsonData = data else { return }
//            print(String(data: data, encoding: .utf8)!)
            
            let decoder = JSONDecoder()

            do {
                totalStatistic = try decoder.decode(TotalStatistic.self, from: jsonData)
//                print(people)
            } catch {
                print(error.localizedDescription)
            }
        }

        task.resume()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if totalStatistic.totalDistanceKm != 0 {
                        HStack {
                            Text("Total Distance")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(totalStatistic.totalDistanceKm)km")
                                .frame(alignment: .trailing)
                        }
                        .font(.system(size: 20, weight: .heavy))
                    }
                    
                    if totalStatistic.totalPointsTracked != 0 {
                        HStack {
                            Text("Total Geopoints")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(totalStatistic.totalPointsTracked)")
                                .frame(alignment: .trailing)
                        }
                        .font(.system(size: 20, weight: .heavy))
                    }
                    
                    if totalStatistic.totalReverseGeocodedPoints != 0 {
                        HStack {
                            Text("Reverse Geocoded")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(totalStatistic.totalReverseGeocodedPoints)")
                                .frame(alignment: .trailing)
                        }
                        .font(.system(size: 20, weight: .heavy))
                    }
                    
                    if totalStatistic.totalCountriesVisited != 0 {
                        HStack {
                            Text("Countries")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(totalStatistic.totalCountriesVisited)")
                                .frame(alignment: .trailing)
                        }
                        .font(.system(size: 20, weight: .heavy))
                    }
                    
                    if totalStatistic.totalCitiesVisited != 0 {
                        HStack {
                            Text("Cities")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(totalStatistic.totalCitiesVisited)")
                                .frame(alignment: .trailing)
                        }
                        .font(.system(size: 20, weight: .heavy))
                    }
                    
                    ForEach(totalStatistic.yearlyStats, id:\.year) { yearStat in
                        Text("\(String(yearStat.year))")
                            .font(.system(size: 30, weight: .heavy))
                            .padding(.top)
                        Chart {
                            let months = yearStat.monthlyDistanceKm
                            
                            BarMark(
                                x: .value("Month", "Jan"),
                                y: .value("Value", months.january)
                            )
                            BarMark(
                                x: .value("Month", "Feb"),
                                y: .value("Value", months.february)
                            )
                            BarMark(
                                x: .value("Month", "Mar"),
                                y: .value("Value", months.march)
                            )
                            BarMark(
                                x: .value("Month", "Apr"),
                                y: .value("Value", months.april)
                            )
                            BarMark(
                                x: .value("Month", "May"),
                                y: .value("Value", months.may)
                            )
                            BarMark(
                                x: .value("Month", "Jun"),
                                y: .value("Value", months.june)
                            )
                            BarMark(
                                x: .value("Month", "Jul"),
                                y: .value("Value", months.july)
                            )
                            BarMark(
                                x: .value("Month", "Aug"),
                                y: .value("Value", months.august)
                            )
                            BarMark(
                                x: .value("Month", "Sep"),
                                y: .value("Value", months.september)
                            )
                            BarMark(
                                x: .value("Month", "Oct"),
                                y: .value("Value", months.october)
                            )
                            BarMark(
                                x: .value("Month", "Nov"),
                                y: .value("Value", months.november)
                            )
                            BarMark(
                                x: .value("Month", "Dec"),
                                y: .value("Value", months.december)
                            )
                        }
                        .frame(height: 200)
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .refreshable(action: { refreshStatistics() })
            .onAppear() {
                if totalStatistic.totalPointsTracked == 0 {
                    refreshStatistics()
                }
            }
            .overlay(
                Group {
                    if isLoading {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                }
            )
        }
    }
}



struct LocalMapView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    private var locationHelper: LocationHelper {
        appDelegate.locationHelper
    }
    
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var requestedPoints: [TrackingPoint] = []
    @State private var requestedCoordinates: [CLLocationCoordinate2D] = []
    @State private var isLoading = false
    
    func refreshData() {
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startString = dateFormatter.string(from: startDate)
        let endString = dateFormatter.string(from: endDate)
        
        print(startString)
        
        let url = URL(string: locationHelper.waypointdbServerHost + "/api/v1/points?api_key=\(locationHelper.waypointdbServerKey)&start_at\(startString)T13:00:00Z=&end_at=\(endString)T13:00:00Z&per_page=1000")!
        print(url)

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let jsonData = data else {
                isLoading = false
                return
            }
//            print(String(data: jsonData, encoding: .utf8)!)
            
            let decoder = JSONDecoder()

            do {
                print(jsonData.count)
                requestedPoints = try decoder.decode([TrackingPoint].self, from: jsonData)
                requestedCoordinates = requestedPoints.map( { CLLocationCoordinate2D(latitude: Double($0.latitude)!, longitude: Double($0.longitude)!) } )
                print(requestedCoordinates.count)
            } catch {
                print(error.localizedDescription)
            }
            isLoading = false
        }

        task.resume()
    }
    
    var body: some View {
        VStack {
            Map() {
                MapPolyline(coordinates: requestedCoordinates)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 5, lineJoin: .round))
                    .mapOverlayLevel(level: .aboveLabels)
            }
            HStack {
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .frame(width: 100)
                    .onChange(of: startDate) {
                        refreshData()
                    }
                Label("", systemImage: "chevron.right")
                    .padding(.horizontal)
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .frame(width: 120)
                    .onChange(of: endDate) {
                        refreshData()
                    }
            }
            .padding(.top, 1)
            .padding(.bottom, 8)
            .padding(.horizontal)
            .onAppear() {
                if requestedPoints.isEmpty {
                    refreshData()
                }
            }
        }
        .overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        )
    }
}



struct HomepageView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    var locationHelper: LocationHelper {
        appDelegate.locationHelper
    }
    
    var body: some View {
        if locationHelper.waypointdbServerHost.isEmpty {
            Text("Please add a Server Host in the Settings first.")
        } else {
            WebView(url: locationHelper.waypointdbServerHost)
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        // A container view that holds the toolbar and WKWebView
        let containerView = UIView()
        
        // Create the toolbar at the top
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        // Create Back and Forward buttons using SF Symbols
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.goBack)
        )
        
        let forwardButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.right"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.goForward)
        )
        
        // Create a fixed space between the back and forward buttons
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = 20
        
        // Create a flexible space to push the reload button to the right
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // Create a Reload button
        let reloadButton = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: context.coordinator,
            action: #selector(Coordinator.reloadPage)
        )
        
        // Initially disable Back/Forward until we know the web view's state
        backButton.isEnabled = false
        forwardButton.isEnabled = false
        
        // Assign references to the coordinator
        context.coordinator.backButton = backButton
        context.coordinator.forwardButton = forwardButton
        
        // Add the items to the toolbar
        toolbar.items = [backButton, fixedSpace, forwardButton, flexibleSpace, reloadButton]
        
        // Create the WKWebView
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Observe URL changes via KVO
        context.coordinator.observeWebView(webView)
        
        // Add subviews
        containerView.addSubview(toolbar)
        containerView.addSubview(webView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Toolbar at the top
            toolbar.topAnchor.constraint(equalTo: containerView.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Web view fills the remaining space
            webView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        // Load the initial URL
        if let url = URL(string: url) {
            webView.load(URLRequest(url: url))
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No dynamic updates for this example
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        
        // Keep references to the toolbar items so we can enable/disable them
        weak var backButton: UIBarButtonItem?
        weak var forwardButton: UIBarButtonItem?
        
        // Keep a reference to the WKWebView itself
        private(set) weak var webView: WKWebView?
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        // MARK: - Observe WebView
        func observeWebView(_ webView: WKWebView) {
            self.webView = webView
            
            // Observe changes to the 'url' property
            webView.addObserver(
                self,
                forKeyPath: #keyPath(WKWebView.url),
                options: [.new],
                context: nil
            )
        }
        
        deinit {
            // Remove observer to avoid crashes
            webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
        }
        
        // KVO callback
        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            guard keyPath == #keyPath(WKWebView.url),
                  let webView = object as? WKWebView else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                return
            }
            
            // Whenever the URL changes (including JS changes), update button states.
            updateNavigationButtonsState(for: webView)
        }
        
        // MARK: - Button Actions
        @objc func goBack() {
            webView?.goBack()
            updateNavigationButtonsState(for: webView!)
        }
        
        @objc func goForward() {
            webView?.goForward()
            updateNavigationButtonsState(for: webView!)
        }
        
        @objc func reloadPage() {
            webView?.reload()
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            updateNavigationButtonsState(for: webView)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateNavigationButtonsState(for: webView)
        }
        
        // MARK: - Helper
        private func updateNavigationButtonsState(for webView: WKWebView) {
            backButton?.isEnabled = webView.canGoBack
            forwardButton?.isEnabled = webView.canGoForward
        }
    }
}


struct TrackerSettingsView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    var locationHelper: LocationHelper {
        appDelegate.locationHelper
    }
    
    @State private var waypointdbServerHost = ""
    @State private var waypointdbServerKey = ""
    @State private var trackingActivated = false
    @State private var alwaysHighDensity = false
    @State private var debugNotifications = false
    @State private var selectedMaxBufferSize = 300
    @State private var bufferLength = 0
    @State private var showingInfoSheet = false
    
    private var maxBufferSizes: [Int] = [5, 60, 60*2, 60*5, 60*10]
    
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section("Server Options") {
                        TextField("Host (Include http/s)", text: $waypointdbServerHost)
                            .onChange(of: waypointdbServerHost) {
                                locationHelper.waypointdbServerHost = waypointdbServerHost
                            }
                        TextField("API Key", text: $waypointdbServerKey)
                            .onChange(of: waypointdbServerKey) {
                                locationHelper.waypointdbServerKey = waypointdbServerKey
                            }
                        
                    }
                    Section("Location Options") {
                        Toggle("Tracking Activated", isOn: $trackingActivated)
                            .onChange(of: trackingActivated) {
                                locationHelper.trackingActivated = trackingActivated
                            }
                        
                        Toggle("Always High Density", isOn: $alwaysHighDensity)
                            .onChange(of: alwaysHighDensity) {
                                locationHelper.alwaysHighDensity = alwaysHighDensity
                            }
                        
                        Toggle("Debug Notifications", isOn: $debugNotifications)
                            .onChange(of: debugNotifications) {
                                locationHelper.debugNotifications = debugNotifications
                            }
                        
                        HStack {
                            Text("Buffer length")
                                .frame(alignment: .leading)
                            Text("\(bufferLength)")
                        }
                        
                        Button("Clear Buffer") {
                            locationHelper.clearBuffer()
                        }
                    }
                    Section("Send Options") {
                        Text("Max Databuffer count:")
                        Picker("MaxBuffer", selection: $selectedMaxBufferSize) {
                            ForEach(0..<maxBufferSizes.count, id: \.self) { sizeIndex in
                                Text("\(maxBufferSizes[sizeIndex])")
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedMaxBufferSize) {
                            locationHelper.selectedMaxBufferSize = maxBufferSizes[selectedMaxBufferSize]
                        }
                    }
                }
            }
            .onAppear {
                waypointdbServerHost = locationHelper.waypointdbServerHost
                waypointdbServerKey = locationHelper.waypointdbServerKey
                trackingActivated = locationHelper.trackingActivated
                alwaysHighDensity = locationHelper.alwaysHighDensity
                debugNotifications = locationHelper.debugNotifications
                bufferLength = locationHelper.traceBuffer.count
                // Match the selected index with the stored size
                for index in 0..<maxBufferSizes.count {
                    if maxBufferSizes[index] == locationHelper.selectedMaxBufferSize {
                        selectedMaxBufferSize = index
                        break
                    }
                }
            }
            // Place an info button on the trailing edge of the navigation bar
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingInfoSheet.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            // Show the sheet when the button is tapped
            .sheet(isPresented: $showingInfoSheet) {
                InfoSheetView()
            }
            .navigationTitle("waypointdb")
            .refreshable {
                bufferLength = locationHelper.traceBuffer.count
            }
        }
    }
}

struct InfoSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Information")
                    .font(.title)
                    .fontWeight(.bold)

                Text("• **Server Options**: Configure the server address (HTTP/HTTPS) and your API key for WayPointDB.\n\n• **Location Options**:\n   - Toggle tracking on/off.\n   - Force high-density location updates. This will start continuously getting the location, until you are stationary for a while.\n   - Enable or disable debug notifications.\n\n• **Buffer**: Shows how many location points are stored in memory. You can clear the buffer anytime.\n\n• **Send Options**: Configure how many data points to collect before sending to the server.\n\n\nIcon by FreePik (flaticon.com/authors/freepik)")
                    .font(.body)

                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .padding(.top, 8)
            }
            .padding()
            .navigationTitle("About WayPointDB")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    ContentView().environmentObject(appDelegate)
}
