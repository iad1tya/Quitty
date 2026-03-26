import SwiftUI

struct SchedulerView: View {
    @ObservedObject var manager: SchedulerManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.brown)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scheduled Tasks")
                            .font(.title2.bold())
                        Text(manager.statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Button("Add Task") {
                        manager.showingAddTask = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Text("\(manager.tasks.count) total tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Tasks List
            if manager.tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No scheduled tasks")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Click 'Add Task' to automate maintenance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(manager.tasks) { task in
                            ScheduledTaskRow(
                                task: task,
                                onToggle: {
                                    manager.toggleTask(task)
                                },
                                onExecute: {
                                    manager.executeTaskNow(task)
                                },
                                onRemove: {
                                    manager.removeTask(task)
                                }
                            )
                        }
                        
                        if !manager.executionLog.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Execution Log")
                                    .font(.headline)
                                    .padding(.top, 16)
                                
                                ForEach(manager.executionLog.prefix(10), id: \.self) { log in
                                    Text(log)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .sheet(isPresented: $manager.showingAddTask) {
            AddTaskSheet(manager: manager)
        }
    }
}

struct ScheduledTaskRow: View {
    let task: ScheduledTask
    let onToggle: () -> Void
    let onExecute: () -> Void
    let onRemove: () -> Void
    @State private var showingRemoveConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: .constant(task.isEnabled))
                .toggleStyle(.checkbox)
                .labelsHidden()
                .onTapGesture { onToggle() }
            
            Image(systemName: task.taskType.icon)
                .font(.system(size: 24))
                .foregroundColor(task.taskType.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.system(size: 14, weight: .medium))
                
                HStack(spacing: 8) {
                    Text(task.frequency.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    if let lastRun = task.lastRun {
                        Text("• Last: \(lastRun, style: .relative)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    if let nextRun = task.nextRun {
                        Text("• Next: \(nextRun, style: .relative)")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            Button("Run Now") {
                onExecute()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button(action: { showingRemoveConfirmation = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Remove Task")
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal)
        .opacity(task.isEnabled ? 1.0 : 0.5)
        .alert("Remove Task?", isPresented: $showingRemoveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) { onRemove() }
        }
    }
}

struct AddTaskSheet: View {
    @ObservedObject var manager: SchedulerManager
    @Environment(\.dismiss) var dismiss
    
    @State private var taskName = ""
    @State private var selectedType: ScheduledTaskType = .cleanJunk
    @State private var selectedFrequency: ScheduleFrequency = .daily
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Scheduled Task")
                .font(.title2.bold())
            
            Form {
                TextField("Task Name", text: $taskName)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Task Type", selection: $selectedType) {
                    ForEach(ScheduledTaskType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.rawValue)
                        }
                        .tag(type)
                    }
                }
                
                Picker("Frequency", selection: $selectedFrequency) {
                    ForEach(ScheduleFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Add Task") {
                    let task = ScheduledTask(
                        name: taskName.isEmpty ? selectedType.rawValue : taskName,
                        taskType: selectedType,
                        frequency: selectedFrequency
                    )
                    manager.addTask(task)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(taskName.isEmpty && selectedType == .cleanJunk)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
