//
//  ContentView.swift
//  Jamf Framework Redeploy
//
//  Created by Richard Mallion on 09/01/2023.
//

import SwiftUI

struct ContentView: View {
    
    @State private var jamfURL = ""
    @State private var userName = ""
    @State private var password = ""
    @State private var savePassword = false
    @State private var serialNumber = ""

    @State private var buttonDisabled = false

    @State private var showAlert = false

    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    @State private var selectedTab = 0
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        
        VStack(spacing: 0) {
            // Menu Section
            HStack(spacing: 16) {
                // Mode Selection
                HStack(spacing: 8) {
                    Button(action: { selectedTab = 0 }) {
                        HStack(spacing: 6) {
                            Image(systemName: "desktopcomputer")
                            Text("Single Computer")
                        }
                        .foregroundColor(selectedTab == 0 ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedTab == 0 ? Color.accentColor : Color.clear)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { selectedTab = 1 }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.grid.3x3")
                            Text("Bulk Operations")
                        }
                        .foregroundColor(selectedTab == 1 ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedTab == 1 ? Color.accentColor : Color.clear)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // Dark Mode Toggle
                Button(action: { 
                    isDarkMode.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        Text(isDarkMode ? "Dark" : "Light")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .bottom
            )
            
            VStack(alignment: .leading) {
                Group {
                    if selectedTab == 0 {
                        SingleRedeployView(
                            jamfURL: $jamfURL,
                            userName: $userName,
                            password: $password,
                            savePassword: $savePassword,
                            serialNumber: $serialNumber,
                            buttonDisabled: $buttonDisabled,
                            showAlert: $showAlert,
                            alertMessage: $alertMessage,
                            alertTitle: $alertTitle
                        )
                    } else {
                        BulkRedeployView(
                            jamfURL: jamfURL,
                            userName: userName,
                            password: password
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            let defaults = UserDefaults.standard
            userName = defaults.string(forKey: "userName") ?? ""
            jamfURL = defaults.string(forKey: "jamfURL") ?? ""
            savePassword = defaults.bool(forKey: "savePassword" )
            if savePassword  {
                let credentialsArray = Keychain().retrieve(service: "co.uk.mallion.Jamf-Framework-Redeploy")
                if credentialsArray.count == 2 {
                    userName = credentialsArray[0]
                    password = credentialsArray[1]
                }
            }
        }
    }
}

struct SingleRedeployView: View {
    @Binding var jamfURL: String
    @Binding var userName: String
    @Binding var password: String
    @Binding var savePassword: Bool
    @Binding var serialNumber: String
    @Binding var buttonDisabled: Bool
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    @Binding var alertTitle: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Jamf Server URL
            HStack(alignment: .center) {
                Text("Jamf Server URL:")
                    .frame(width: 120, alignment: .trailing)
                TextField("https://your-jamf-server.com", text: $jamfURL)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: jamfURL) { newValue in
                        let defaults = UserDefaults.standard
                        defaults.set(jamfURL , forKey: "jamfURL")
                        updateAction()
                    }
            }
            // Client ID
            HStack(alignment: .center) {
                Text("Client ID:")
                    .frame(width: 120, alignment: .trailing)
                TextField("Your Jamf Pro admin user name", text: $userName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: userName) { newValue in
                        let defaults = UserDefaults.standard
                        defaults.set(userName , forKey: "userName")
                        updateAction()
                    }
            }
            // Secret
            HStack(alignment: .center) {
                Text("Secret:")
                    .frame(width: 120, alignment: .trailing)
                SecureField("Your password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: password) { newValue in
                        if savePassword {
                            DispatchQueue.global(qos: .background).async {
                                Keychain().save(service: "co.uk.mallion.Jamf-Framework-Redeploy", account: userName, data: password)
                            }
                        } else {
                            DispatchQueue.global(qos: .background).async {
                                Keychain().save(service: "co.uk.mallion.Jamf-Framework-Redeploy", account: userName, data: "")
                            }
                        }
                        updateAction()
                    }
            }
            // Save Password Checkbox
            HStack(alignment: .center) {
                Text("")
                    .frame(width: 120, alignment: .trailing)
                HStack {
                    Toggle(isOn: $savePassword) {
                        Text("Save Password")
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .onChange(of: savePassword) { newValue in
                        let defaults = UserDefaults.standard
                        defaults.set(savePassword, forKey: "savePassword")
                        if savePassword {
                            DispatchQueue.global(qos: .background).async {
                                Keychain().save(service: "co.uk.mallion.Jamf-Framework-Redeploy", account: userName, data: password)
                            }
                        } else {
                            DispatchQueue.global(qos: .background).async {
                                Keychain().save(service: "co.uk.mallion.Jamf-Framework-Redeploy", account: userName, data: "")
                            }
                        }
                    }
                    Spacer()
                }
            }
            // Serial Number
            HStack(alignment: .center) {
                Text("Serial Number:")
                    .frame(width: 120, alignment: .trailing)
                TextField("Mac Serial Number", text: $serialNumber)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: serialNumber) { newValue in
                        updateAction()
                    }
            }
            // Redeploy Button
            HStack {
                Spacer()
                Button("Redeploy") {
                    Task {
                        await redploy()
                    }
                }
                .disabled(buttonDisabled)
            }
        }
        .padding()
        .onAppear {
            updateAction()
        }
        .alert(isPresented: $showAlert,
               content: {
            showCustomAlert()
        })
    }
    
    func updateAction() {
        if jamfURL.validURL && !userName.isEmpty && !password.isEmpty && !serialNumber.isEmpty {
            buttonDisabled = false
        } else {
            buttonDisabled = true
        }
    }
    
    func showCustomAlert() -> Alert {
        return Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
                )
    }

    func redploy() async {
        let jamfPro = JamfProAPI()
        
        let (authToken, _) = await jamfPro.getToken(jssURL: jamfURL, clientID: userName, secret: password)
        guard let authToken else {
            alertMessage = "Could not authenticate. Please check the url and authentication details"
            alertTitle = "Authentication Error"
            showAlert = true
            return
        }
        
        
        //1.0.2 Change
        let (computerID, computerResponse) = await jamfPro.getComputerID(jssURL: jamfURL, authToken: authToken.access_token, serialNumber: serialNumber)
        
        guard let computerID else {
            alertMessage = "Could not find this computer, please check the serial number."
            alertTitle = "Computer Record"
            showAlert = true
            return
        }
        
        guard let computerResponse, computerResponse == 200  else {
            alertMessage = "Could not find this computer, please check the serial number."
            alertTitle = "Computer Record"
            showAlert = true
            return
        }

        let redeployResponse = await jamfPro.redeployJamfFramework(jssURL: jamfURL, authToken: authToken.access_token, computerID: computerID)
        
        guard let redeployResponse, redeployResponse == 202  else {
            alertMessage = "Could not queue the redeploy the Jamf Managment Framework."
            alertTitle = "Redeployment"
            showAlert = true
            return
        }

        alertMessage = "Command successfully queued to redeploy the Jamf Managment Framework."
        alertTitle = "Redeployment"
        showAlert = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


extension String {
    var validURL: Bool {
        get {
//            let regEx = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
            let regEx = "^((http|https)://)[-a-zA-Z0-9@:%._\\+~#?&//=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%._\\+~#?&//=]*)$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
            return predicate.evaluate(with: self)
        }
    }
}

