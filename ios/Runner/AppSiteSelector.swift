import Flutter
import UIKit
import FamilyControls
import SwiftUI
import ManagedSettings

class AppSiteSelectorView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var selection = FamilyActivitySelection()
    private var channel: FlutterMethodChannel
    private var hostingController: UIHostingController<FamilyActivityPickerWrapper>?
    private var parentViewController: UIViewController?
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView()
        channel = FlutterMethodChannel(name: "app_site_selector", binaryMessenger: messenger)
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
            if let jsonString = String(data: encoded, encoding: .utf8), !jsonString.isEmpty, jsonString != "null" {
                // Attempt to extract the "data" field from the JSON object
                if let jsonObject = try? JSONSerialization.jsonObject(with: encoded, options: []) as? [String: Any],
                   let dataString = jsonObject["data"] as? String,
                   !dataString.isEmpty {
                    return dataString
                }
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

        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod("onSelectionChanged", arguments: ["apps": apps, "sites": sites])
        }
    }
}

// Wrapper view to handle selection changes
struct FamilyActivityPickerWrapper: View {
    @State var selection: FamilyActivitySelection
    var onSelectionChanged: (FamilyActivitySelection) -> Void
    
    var body: some View {
        FamilyActivityPicker(selection: $selection)
            .onChange(of: selection) { newValue in
                onSelectionChanged(newValue)
            }
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
