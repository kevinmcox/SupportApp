//
//  AppUpdatesView.swift
//  Support
//
//  Created by Jordy Witteman on 21/10/2023.
//

import os
import SwiftUI

struct AppUpdatesView: View {
    
    // Access AppDelegate
    @EnvironmentObject private var appDelegate: AppDelegate
        
    // Get computer info from functions in class
    @EnvironmentObject var computerinfo: ComputerInfo
    
    // Get user info from functions in class
    @EnvironmentObject var userinfo: UserInfo
    
    // Get App Catalog information
    @EnvironmentObject var appCatalogController: AppCatalogController
    
    // Make UserDefaults easy to use
    let defaults = UserDefaults.standard
        
    // Dark Mode detection
    @Environment(\.colorScheme) var colorScheme
    
    // Set the custom color for all symbols depending on Light or Dark Mode.
    var customColor: String {
        if colorScheme == .light && defaults.string(forKey: "CustomColor") != nil {
            return preferences.customColor
        } else if colorScheme == .dark && defaults.string(forKey: "CustomColorDarkMode") != nil {
            return preferences.customColorDarkMode
        } else {
            return preferences.customColor
        }
    }
    
    // Get preferences or default values
    @StateObject var preferences = Preferences()
            
    var body: some View {
        
        Group {
            
            HStack {
                
                Button(action: {
                    appCatalogController.showAppUpdates.toggle()
                }) {
                    Ellipse()
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.2) : .black.opacity(0.1))
                        .overlay(
                            Image(systemName: "chevron.backward")
                        )
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                
                Text(NSLocalizedString("APP_UPDATES", comment: ""))
                    .font(.system(.headline, design: .rounded))
                
                Spacer()
                
                if appCatalogController.updateDetails.count > 0 {
                    Button(action: {
                        for app in appCatalogController.updateDetails {
                            Task {
                                await updateApp(bundleID: app.id)
                            }
                        }
                        
                        // Check app updates again
                        appCatalogController.getAppUpdates()
                    }) {
                        Text(NSLocalizedString("UPDATE_ALL", comment: ""))
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.regular)
                            .padding(.vertical, 4)
                            .padding(.horizontal)
                            .background(colorScheme == .dark ? .white.opacity(0.2) : .black.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(appCatalogController.appsUpdating.isEmpty ? false : true)
                }
                
            }

            Divider()
                .padding(2)
            
            if appCatalogController.updateDetails.count > 0 {
                
                ForEach(appCatalogController.updateDetails, id: \.self) { update in
                    
                    HStack {
                        
                        if let icon = update.icon {
                            
                            AsyncImage(url: URL(string: icon)) { phase in
                                switch phase {
                                case .empty:
                                    Image(systemName: "app.dashed")
                                        .font(.system(size: 30))
                                        .foregroundStyle(.secondary)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .failure(_):
                                    Image(systemName: "exclamationmark.circle")
                                        .font(.system(size: 30))
                                        .foregroundStyle(.secondary)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 40, height: 40)
                            
                        }
                        
                        VStack(alignment: .leading) {
                            
                            Text(update.name ?? "")
                                .font(.system(.headline, design: .rounded))
                            
                            Text(update.version ?? "")
                                .foregroundColor(.secondary)
                                .font(.system(.subheadline, design: .rounded))
                            
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await updateApp(bundleID: update.id)
                            }
                            
                            // Check app updates again
                            appCatalogController.getAppUpdates()
                        }) {
                            if appCatalogController.appsUpdating.contains(update.id) {
                                Ellipse()
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.2) : .black.opacity(0.1))
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(0.5)
                                    )
                                    .frame(width: 26, height: 26)
                                    .padding(.leading, 10)
                            } else {
                                Ellipse()
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.2) : .black.opacity(0.1))
                                    .overlay(
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                    )
                                    .frame(width: 26, height: 26)
                                    .padding(.leading, 10)
                            }
                        }
                        .buttonStyle(.plain)
                        
                    }
                    
                }
                
            } else {
                
                VStack(alignment: .center, spacing: 20) {
                    
//                    Spacer()
                    
                    Text(NSLocalizedString("ALL_APPS_UP_TO_DATE", comment: ""))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.medium)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color(NSColor(hex: "\(customColor)") ?? NSColor.controlAccentColor))
                    
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .unredacted()
    }
    
    // MARK: - Function to update app using App Catalog
    func updateApp(bundleID: String) async {
        
        // Command to update app
        let command = "/usr/local/bin/catalog --install \(bundleID) --update-action"
        
        // Add bundle ID to apps currently updating
        appCatalogController.appsUpdating.append(bundleID)
        
        do {
            try ExecutionService.executeScript(command: command) { exitCode in
                
                if exitCode == 0 {
                    appCatalogController.logger.log("App \(bundleID) successfully updated")
                } else {
                    appCatalogController.logger.error("Failed to update app \(bundleID)")
                }
                
                // Stop update spinner
                if appCatalogController.appsUpdating.contains(bundleID) {
                    if let index = appCatalogController.appsUpdating.firstIndex(of: bundleID) {
                        DispatchQueue.main.async {
                            appCatalogController.appsUpdating.remove(at: index)
                        }
                    }
                }
                
                // Temporarily drop app from updates array so it will not show once completed. Then we check updates again to verify the update was really successful
                if appCatalogController.updateDetails.contains(where: { $0.id == bundleID } ) {
                    if let index = appCatalogController.updateDetails.firstIndex(where: { $0.id == bundleID } ) {
                        DispatchQueue.main.async {
                            appCatalogController.updateDetails.remove(at: index)
                        }
                    }
                }
//                
//                // Check app updates again
//                appCatalogController.getAppUpdates()
                
            }
        } catch {
            appCatalogController.logger.log("Failed to update app \(bundleID)")
            
            // Stop update spinner
            if appCatalogController.appsUpdating.contains(bundleID) {
                if let index = appCatalogController.appsUpdating.firstIndex(of: bundleID) {
                    DispatchQueue.main.async {
                        appCatalogController.appsUpdating.remove(at: index)
                    }
                }
            }
            
            // Check app updates again
            appCatalogController.getAppUpdates()
        }
        
    }
    
}
