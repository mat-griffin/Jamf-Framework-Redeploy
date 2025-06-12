//
//  BulkRedeployView.swift
//  Jamf Framework Redeploy
//
//  Created by Claude Code on 12/06/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct BulkRedeployView: View {
    @StateObject private var csvHandler = CSVHandler()
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isProcessing = false
    
    let jamfURL: String
    let userName: String
    let password: String
    
    var body: some View {
        VStack(spacing: 20) {
            
            HStack {
                Button("Import CSV") {
                    showingFilePicker = true
                }
                .disabled(isProcessing)
                
                Spacer()
                
                if !csvHandler.computers.isEmpty {
                    Text("\(csvHandler.computers.count) computers loaded")
                        .foregroundColor(.secondary)
                }
            }
            
            if !csvHandler.computers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    
                    HStack {
                        Button(isProcessing ? "Processing..." : "Start Bulk Redeploy") {
                            Task {
                                await startBulkRedeploy()
                            }
                        }
                        .disabled(isProcessing || jamfURL.isEmpty || userName.isEmpty || password.isEmpty)
                        
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        
                        Spacer()
                        
                        Button("Reset Status") {
                            csvHandler.resetStatus()
                        }
                        .disabled(isProcessing)
                    }
                    
                    if csvHandler.totalCount > 0 {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Progress: \(csvHandler.processedCount) / \(csvHandler.totalCount)")
                                Spacer()
                                Text("\(Int((Double(csvHandler.processedCount) / Double(csvHandler.totalCount)) * 100))%")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            ProgressView(value: Double(csvHandler.processedCount), total: Double(csvHandler.totalCount))
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(csvHandler.computers) { computer in
                                ComputerRowView(computer: computer)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 300)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No computers loaded")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Import a CSV file to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.csv],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                try csvHandler.loadComputers(from: url)
                showAlert(title: "Import Successful", message: "Loaded \(csvHandler.computers.count) computer(s) from CSV.")
            } catch {
                showAlert(title: "Import Error", message: error.localizedDescription)
            }
            
        case .failure(let error):
            showAlert(title: "File Selection Error", message: error.localizedDescription)
        }
    }
    
    private func startBulkRedeploy() async {
        guard !jamfURL.isEmpty, !userName.isEmpty, !password.isEmpty else {
            showAlert(title: "Configuration Error", message: "Please ensure Jamf URL, username, and password are configured.")
            return
        }
        
        isProcessing = true
        csvHandler.isProcessing = true
        csvHandler.resetStatus()
        
        let jamfPro = JamfProAPI()
        
        let (authToken, _) = await jamfPro.getToken(jssURL: jamfURL, clientID: userName, secret: password)
        
        guard let authToken else {
            showAlert(title: "Authentication Error", message: "Could not authenticate with Jamf Pro. Please check your credentials.")
            isProcessing = false
            csvHandler.isProcessing = false
            return
        }
        
        for computer in csvHandler.computers {
            csvHandler.updateComputerStatus(computer.id, status: .inProgress)
            
            let (computerID, computerResponse) = await jamfPro.getComputerID(
                jssURL: jamfURL,
                authToken: authToken.access_token,
                serialNumber: computer.serialNumber
            )
            
            guard let computerID, computerResponse == 200 else {
                csvHandler.updateComputerStatus(
                    computer.id,
                    status: .failed,
                    error: "Computer not found"
                )
                continue
            }
            
            let redeployResponse = await jamfPro.redeployJamfFramework(
                jssURL: jamfURL,
                authToken: authToken.access_token,
                computerID: computerID
            )
            
            if redeployResponse == 202 {
                csvHandler.updateComputerStatus(computer.id, status: .completed)
            } else {
                csvHandler.updateComputerStatus(
                    computer.id,
                    status: .failed,
                    error: "Redeploy command failed"
                )
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        isProcessing = false
        csvHandler.isProcessing = false
        
        let successCount = csvHandler.computers.filter { $0.status == .completed }.count
        let failCount = csvHandler.computers.filter { $0.status == .failed }.count
        
        showAlert(
            title: "Bulk Redeploy Complete",
            message: "Successfully processed \(successCount) computers. Failed: \(failCount)"
        )
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct ComputerRowView: View {
    let computer: ComputerRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(computer.serialNumber)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                
                if let computerName = computer.computerName {
                    Text(computerName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let notes = computer.notes {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                StatusBadge(status: computer.status)
                
                if let error = computer.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
    }
}

struct StatusBadge: View {
    let status: ComputerRecord.DeploymentStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption)
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(statusColor.opacity(0.2))
        .foregroundColor(statusColor)
        .cornerRadius(12)
    }
    
    private var statusIcon: String {
        switch status {
        case .pending:
            return "clock"
        case .inProgress:
            return "arrow.clockwise"
        case .completed:
            return "checkmark.circle"
        case .failed:
            return "xmark.circle"
        }
    }
    
    private var statusText: String {
        switch status {
        case .pending:
            return "Pending"
        case .inProgress:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return .gray
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

struct BulkRedeployView_Previews: PreviewProvider {
    static var previews: some View {
        BulkRedeployView(
            jamfURL: "https://example.jamfcloud.com",
            userName: "testuser",
            password: "testpass"
        )
        .frame(width: 600, height: 500)
    }
}