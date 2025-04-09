//
//  ContentView.swift
//  WayPointDB-iOS
//
//  Created by yniverz on 09.04.25.
//

import SwiftUI
@preconcurrency import WebKit
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
            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.xaxis")
                }
            TrackerSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}


class Storage {
    static var serverHost: String {
        set {
            UserDefaults.standard.set(newValue, forKey: "serverHost")
        }
        get {
            UserDefaults.standard.string(forKey: "serverHost") ?? ""
        }
    }
    static var serverKey: String {
        set {
            UserDefaults.standard.set(newValue, forKey: "serverKey")
        }
        get {
            UserDefaults.standard.string(forKey: "serverKey") ?? ""
        }
    }
}


struct StatisticsView: View {
    
    @State private var totalStatistic = TotalStatistic.defaultValue()
    @State private var isLoading = true
    @State private var countriesSheetShown = false
    @State private var citiesSheetShown = false
    
    func refreshStatistics() {
        isLoading = true
        let url = URL(string: Storage.serverHost + "/api/v1/account/stats?api_key=\(Storage.serverKey)")!

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
                        .onTapGesture {
                            countriesSheetShown.toggle()
                        }
                    }
                    
                    if totalStatistic.totalCitiesVisited != 0 {
                        HStack {
                            Text("Cities")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(totalStatistic.totalCitiesVisited)")
                                .frame(alignment: .trailing)
                        }
                        .font(.system(size: 20, weight: .heavy))
                        .onTapGesture {
                            citiesSheetShown.toggle()
                        }
                    }
                    
                    ForEach(totalStatistic.yearlyStats, id:\.year) { yearStat in
                        Text("\(String(yearStat.year))")
                            .font(.system(size: 30, weight: .heavy))
                            .padding(.top)
                        NavigationLink(destination: YearStatisticView(year: yearStat.year)) {
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
            .sheet(isPresented: $countriesSheetShown) {
                ScrollView {
                    ForEach(totalStatistic.countries, id: \.self) { country in
                        Text("\(country)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                }
            }
            .sheet(isPresented: $citiesSheetShown) {
                ScrollView {
                    ForEach(totalStatistic.cities, id: \.self) { city in
                        Text("\(city[0]), \(city[1])")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                }
            }
        }
    }
}





struct YearStatisticView: View {
    var year: Int
    
    @State private var totalStatistic = YearStatistic.defaultValue()
    @State private var isLoading = true
    @State private var countriesSheetShown = false
    @State private var citiesSheetShown = false
    
    func refreshStatistics() {
        isLoading = true
        let url = URL(string: Storage.serverHost + "/api/v1/account/stats/\(year)?api_key=\(Storage.serverKey)")!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            isLoading = false
            guard let jsonData = data else { return }
//            print(String(data: data, encoding: .utf8)!)
            
            let decoder = JSONDecoder()

            do {
                totalStatistic = try decoder.decode(YearStatistic.self, from: jsonData)
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
                        .onTapGesture {
                            countriesSheetShown.toggle()
                        }
                    }
                    
                    if totalStatistic.totalCitiesVisited != 0 {
                        HStack {
                            Text("Cities")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(totalStatistic.totalCitiesVisited)")
                                .frame(alignment: .trailing)
                        }
                        .font(.system(size: 20, weight: .heavy))
                        .onTapGesture {
                            citiesSheetShown.toggle()
                        }
                    }
                    
                    ForEach(totalStatistic.monthlyStats, id:\.month) { monthStat in
                        Text("\(String(monthStat.month))")
                            .font(.system(size: 30, weight: .heavy))
                            .padding(.top)
                            Chart {
                                ForEach(Array(monthStat.dailyDistanceKm.enumerated()), id: \.offset) { index, dayStat in
                                    BarMark(
                                        x: .value("Day", index + 1), // The day value as 1, 2, 3, etc.
                                        y: .value("Value", dayStat)
                                    )
                                }
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
            .sheet(isPresented: $countriesSheetShown) {
                ScrollView {
                    ForEach(totalStatistic.countries, id: \.self) { country in
                        Text("\(country)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                }
            }
            .sheet(isPresented: $citiesSheetShown) {
                ScrollView {
                    ForEach(totalStatistic.cities, id: \.self) { city in
                        Text("\(city[0]), \(city[1])")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                }
            }
        }
    }
}





struct LocalMapView: View {
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
        
        let url = URL(string: Storage.serverHost + "/api/v1/account/points?api_key=\(Storage.serverKey)&start_at\(startString)T13:00:00Z=&end_at=\(endString)T13:00:00Z&per_page=1000")!
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
    var body: some View {
        if Storage.serverHost.isEmpty {
            Text("Please add a Server Host in the Settings first.")
        } else {
            WebView(url: Storage.serverHost + "/api/v1/account/login?api_key=\(Storage.serverKey)")
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
        
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            // Check the URL of the navigation request.
            if let url = navigationAction.request.url {
                if url.absoluteString.starts(with: "\(Storage.serverHost)/login") {
                    if let redirectURL = URL(string: Storage.serverHost + "/api/v1/account/login?api_key=\(Storage.serverKey)") {
                        webView.load(URLRequest(url: redirectURL))
                    }
                    // Cancel the original navigation
                    decisionHandler(.cancel)
                    return
                }
            }
            
            // Otherwise allow the navigation to proceed.
            decisionHandler(.allow)
        }
        
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
    @State private var serverHost = ""
    @State private var serverKey = ""
    @State private var showingInfoSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section("Server Options") {
                        TextField("Host (Include http/s)", text: $serverHost)
                            .onChange(of: serverHost) {
                                Storage.serverHost = serverHost
                            }
                        TextField("API Key", text: $serverKey)
                            .onChange(of: serverKey) {
                                Storage.serverKey = serverKey
                            }
                        
                    }
                }
            }
            .onAppear {
                serverHost = Storage.serverHost
                serverKey = Storage.serverKey
                
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
            .navigationTitle("WayPointDB")
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

                Text("• **Server Options**: Configure the server address (HTTP/HTTPS) and your API key for WayPointDB.\n\n")
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
    ContentView()
}
