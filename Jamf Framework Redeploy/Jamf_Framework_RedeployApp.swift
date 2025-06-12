//
//  Jamf_Framework_RedeployApp.swift
//  Jamf Framework Redeploy
//
//  Created by Richard Mallion on 09/01/2023.
//

import SwiftUI

@main
struct Jamf_Framework_RedeployApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                    minWidth: 600, maxWidth: .infinity,
                    minHeight: 400, maxHeight: .infinity)

        }
        .windowResizability(.contentMinSize)
    }
}
