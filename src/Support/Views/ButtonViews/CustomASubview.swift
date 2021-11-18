//
//  CustomASubview.swift
//  Support
//
//  Created by Jordy Witteman on 13/11/2021.
//

import SwiftUI

struct CustomASubview: View {
        
    // Get  computer info from functions in class
    @EnvironmentObject var computerinfo: ComputerInfo
    
    // Get preferences or default values
    @StateObject var preferences = Preferences()
    
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
    
    var body: some View {
        
        Item(title: preferences.customItemTitleA, subtitle: preferences.customItemPrefKeyA, linkType: preferences.customItemTypeA, link: preferences.customItemLinkA, image: preferences.customItemSymbolA, symbolColor: Color(NSColor(hex: "\(customColor)") ?? NSColor.controlAccentColor), loading: preferences.customItemLoadingA, hoverEffectEnable: true, hoverView: false, animate: false)
        
    }
}
