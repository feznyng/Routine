import Flutter
import UIKit
import FamilyControls
import SwiftUI
import ManagedSettings

class AppSiteSelectorView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var selection: FamilyActivitySelection
    private var channel: FlutterMethodChannel
    private var hostingController: UIHostingController<FamilyActivityPickerWrapper>?
    private var parentViewController: UIViewController?
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Optional<Any>?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView()
        channel = FlutterMethodChannel(name: "app_site_selector_\(viewId)", binaryMessenger: messenger)
        
        // Initialize selection with creation params
        selection = FamilyActivitySelection()
        
        if let params = args as? [String: Any] {
            print("params: \(params)")
            if let apps = params["apps"] as? [String] {
                print("apps: \(apps)")
                selection.applicationTokens = Set(apps.compactMap { appId in
                    if let data = appId.data(using: .utf8) {
                        print("raw data \(data)")
                        if let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                            print("successfully created token \(data)")
                            return token
                        }
                        print("failed to create token from \(appId)")
                        return nil
                    }
                    print("failed to create token from \(appId)")
                    return nil
                })
            }
            
            if let sites = params["sites"] as? [String] {
                selection.webDomainTokens = Set(sites.compactMap { siteId in
                    if let data = siteId.data(using: .utf8) {
                        return try? JSONDecoder().decode(WebDomainToken.self, from: data)
                    }
                    return nil
                })
            }

            if let categories: [String] = params["categories"] as? [String] {
                selection.categoryTokens = Set(categories.compactMap { categoryId in
                    if let data = categoryId.data(using: .utf8) {
                        return try? JSONDecoder().decode(ActivityCategoryToken.self, from: data)
                    }
                    return nil
                })
            }
        }
        
        super.init()
        
        // Find the parent view controller
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
           let rootViewController = window.rootViewController {
            parentViewController = rootViewController
        }
        
        createNativeView(frame: frame)
        
        // Request authorization when initializing
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            } catch {
                print("Failed to request authorization: \(error)")
            }
        }
    }
    
    func view() -> UIView {
        return _view
    }
    
    private func createNativeView(frame: CGRect) {
        _view.frame = frame
        _view.backgroundColor = .systemBackground
        
        let wrapper = FamilyActivityPickerWrapper(selection: selection) { [weak self] newSelection in
            self?.handleSelectionChange(newSelection)
        }
        
        hostingController = UIHostingController(rootView: wrapper)
        if let hostingController = hostingController {
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            parentViewController?.addChild(hostingController)
            _view.addSubview(hostingController.view)
            hostingController.didMove(toParent: parentViewController)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: _view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
        }
    }
    
    private func processToken<T>(_ token: Token<T>, encoder: JSONEncoder) -> String? {
        // Try encoding with JSONEncoder
        do {
            let encoded = try encoder.encode(token)
            print("encoded \(encoded)")
            if let jsonString = String(data: encoded, encoding: .utf8), !jsonString.isEmpty, jsonString != "null" {
                print("jsonString \(jsonString)")
                return jsonString
            }
        } catch {
            print("JSONEncoder failed for token of type \(type(of: token)): \(error)")
        }
        
        print("Unable to process token of type \(type(of: token))")
        return nil
    }
    
    private func handleSelectionChange(_ newSelection: FamilyActivitySelection) {
        let encoder = JSONEncoder()
        let apps = newSelection.applicationTokens.compactMap { token -> String? in
            return processToken(token, encoder: encoder)
        }
        let sites = newSelection.webDomainTokens.compactMap { token -> String? in
            return processToken(token, encoder: encoder)
        }
        let categories = newSelection.categoryTokens.compactMap { token -> String? in
            return processToken(token, encoder: encoder)
        }

        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod("onSelectionChanged", arguments: [
                "apps": apps, 
                "sites": sites,
                "categories": categories
            ])
        }
    }
}

// Wrapper view to handle selection changes
struct FamilyActivityPickerWrapper: View {
    @State var selection: FamilyActivitySelection
    @State private var showWebsiteTab: Bool = false
    @State private var websiteInput: String = ""
    @State private var blockedWebsites: [String] = []
    var onSelectionChanged: (FamilyActivitySelection) -> Void
    
    var body: some View {
        VStack {
            // Tab selection at the top
            Picker("Mode", selection: $showWebsiteTab) {
                Text("Apps & Categories").tag(false)
                Text("Websites").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top)
            
            if showWebsiteTab {
                // Website blocking view
                VStack(alignment: .leading) {
                    Text("Blocked Websites")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    HStack {
                        TextField("Enter a website (e.g., facebook.com)", text: $websiteInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                        
                        Button(action: addWebsite) {
                            Image(systemName: "plus")
                        }
                        .disabled(websiteInput.isEmpty)
                    }
                    .padding(.horizontal)
                    
                    if blockedWebsites.isEmpty {
                        Text("No sites blocked")
                            .italic()
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                                ForEach(blockedWebsites, id: \.self) { site in
                                    HStack {
                                        Text(site)
                                        Spacer()
                                        Button(action: {
                                            removeWebsite(site)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                        }
                    }
                    
                    Spacer()
                }
            } else {
                // Original FamilyActivityPicker view
                FamilyActivityPicker(selection: $selection)
                    .onChange(of: selection) { newValue in
                        onSelectionChanged(newValue)
                    }
            }
        }
        .onAppear {
            // Load existing websites from selection
            loadExistingWebsites()
        }
    }
    
    private func addWebsite() {
        var site = websiteInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Basic URL cleanup
        if site.hasPrefix("http://") { site = String(site.dropFirst(7)) }
        if site.hasPrefix("https://") { site = String(site.dropFirst(8)) }
        if site.hasPrefix("www.") { site = String(site.dropFirst(4)) }
        
        if !site.isEmpty && !blockedWebsites.contains(site) {
            blockedWebsites.append(site)
            websiteInput = ""
            
            // Automatically update web domain tokens
            updateWebDomainTokens()
        }
    }
    
    private func removeWebsite(_ site: String) {
        blockedWebsites.removeAll { $0 == site }
        
        // Automatically update web domain tokens
        updateWebDomainTokens()
    }
    
    private func loadExistingWebsites() {
        // Try to extract domain names from existing WebDomainTokens
        let existingDomains = selection.webDomainTokens
        
        // Clear existing blocked websites
        blockedWebsites.removeAll()
        
        // Attempt to extract domain names using the description property
        for token in existingDomains {
            if let domainString = extractDomainFromToken(token) {
                blockedWebsites.append(domainString)
            }
        }
        
        print("Loaded \(blockedWebsites.count) existing websites")
    }
    
    private func extractDomainFromToken(_ token: WebDomainToken) -> String? {
        // This is a best-effort approach to extract the domain name from a WebDomainToken
        // WebDomainToken doesn't provide direct access to the domain name
        
        // Try using the description which might contain the domain
        let description = String(describing: token)
        
        // Look for patterns like "domain.com" in the description
        // This is a simplified approach and may not work in all cases
        if let regex = try? NSRegularExpression(pattern: "[a-zA-Z0-9][-a-zA-Z0-9]*\\.[a-zA-Z0-9][-a-zA-Z0-9]*(\\.[a-zA-Z0-9][-a-zA-Z0-9]*)*", options: []) {
            let nsString = description as NSString
            let matches = regex.matches(in: description, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first {
                return nsString.substring(with: match.range)
            }
        }
        
        return nil
    }
    
    private func updateWebDomainTokens() {
        // Create WebDomainTokens for each domain in blockedWebsites
        var newWebDomainTokens = Set<WebDomainToken>()
        
        for domain in blockedWebsites {
            // Create a WebDomainToken for the domain
            // This is a simplified approach - in a real implementation,
            // you would need to handle token creation more robustly
            if let token = AuthorizationCenter.shared.authorizationStatus == .approved ? try? WebDomainToken(from: domain as! Decoder) : nil {
                newWebDomainTokens.insert(token)
            }
        }
        
        // Update the selection with the new tokens
        var updatedSelection = selection
        updatedSelection.webDomainTokens = newWebDomainTokens
        selection = updatedSelection
        
        // Notify about the selection change
        onSelectionChanged(selection)
    }
}

class AppSiteSelectorFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return AppSiteSelectorView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
