import Foundation
import AppKit
import Combine
import SwiftUI

enum ScheduledTaskType: String, CaseIterable, Codable {
    case cleanJunk = "Clean System Junk"
    case emptyTrash = "Empty Trash"
    case freeRAM = "Free RAM"
    case findDuplicates = "Find Duplicates"
    case scanLargeFiles = "Scan Large Files"
    
    var icon: String {
        switch self {
        case .cleanJunk: return "trash.slash"
        case .emptyTrash: return "trash"
        case .freeRAM: return "memorychip"
        case .findDuplicates: return "doc.on.doc"
        case .scanLargeFiles: return "doc.text.magnifyingglass"
        }
    }
    
    var color: Color {
        switch self {
        case .cleanJunk: return .orange
        case .emptyTrash: return .red
        case .freeRAM: return .mint
        case .findDuplicates: return .cyan
        case .scanLargeFiles: return .indigo
        }
    }
}

enum ScheduleFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case onStartup = "On Startup"
}

struct ScheduledTask: Identifiable, Codable {
    let id: UUID
    var name: String
    var taskType: ScheduledTaskType
    var frequency: ScheduleFrequency
    var isEnabled: Bool
    var lastRun: Date?
    var nextRun: Date?
    
    init(id: UUID = UUID(), name: String, taskType: ScheduledTaskType, frequency: ScheduleFrequency, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.taskType = taskType
        self.frequency = frequency
        self.isEnabled = isEnabled
        self.lastRun = nil
        self.nextRun = Self.calculateNextRun(frequency: frequency, from: Date())
    }
    
    static func calculateNextRun(frequency: ScheduleFrequency, from date: Date) -> Date? {
        let calendar = Calendar.current
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .onStartup:
            return nil
        }
    }
}

class SchedulerManager: ObservableObject {
    @Published var tasks: [ScheduledTask] = []
    @Published var statusMessage = "No scheduled tasks"
    @Published var showingAddTask = false
    @Published var executionLog: [String] = []
    
    private var checkTimer: Timer?
    
    init() {
        loadTasks()
        startScheduler()
    }
    
    func startScheduler() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkAndExecuteTasks()
        }
    }
    
    func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "scheduledTasks"),
           let decoded = try? JSONDecoder().decode([ScheduledTask].self, from: data) {
            tasks = decoded
            updateStatusMessage()
        }
    }
    
    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "scheduledTasks")
        }
        updateStatusMessage()
    }
    
    func addTask(_ task: ScheduledTask) {
        tasks.append(task)
        saveTasks()
    }
    
    func removeTask(_ task: ScheduledTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func toggleTask(_ task: ScheduledTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isEnabled.toggle()
            saveTasks()
        }
    }
    
    func executeTaskNow(_ task: ScheduledTask) {
        executeTask(task)
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].lastRun = Date()
            tasks[index].nextRun = ScheduledTask.calculateNextRun(frequency: task.frequency, from: Date())
            saveTasks()
        }
    }
    
    private func checkAndExecuteTasks() {
        let now = Date()
        
        for task in tasks where task.isEnabled {
            if let nextRun = task.nextRun, now >= nextRun {
                executeTask(task)
                
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index].lastRun = now
                    tasks[index].nextRun = ScheduledTask.calculateNextRun(frequency: task.frequency, from: now)
                }
            }
        }
        
        saveTasks()
    }
    
    private func executeTask(_ task: ScheduledTask) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        let logEntry = "[\(timestamp)] Executed: \(task.name)"
        
        DispatchQueue.main.async {
            self.executionLog.insert(logEntry, at: 0)
            if self.executionLog.count > 50 {
                self.executionLog.removeLast()
            }
        }
        
        // Execute the actual task
        switch task.taskType {
        case .cleanJunk:
            // Trigger system junk cleanup
            NotificationCenter.default.post(name: NSNotification.Name("ExecuteCleanJunk"), object: nil)
        case .emptyTrash:
            // Empty trash
            NotificationCenter.default.post(name: NSNotification.Name("ExecuteEmptyTrash"), object: nil)
        case .freeRAM:
            // Free RAM
            NotificationCenter.default.post(name: NSNotification.Name("ExecuteFreeRAM"), object: nil)
        case .findDuplicates:
            // Find duplicates
            NotificationCenter.default.post(name: NSNotification.Name("ExecuteFindDuplicates"), object: nil)
        case .scanLargeFiles:
            // Scan large files
            NotificationCenter.default.post(name: NSNotification.Name("ExecuteScanLargeFiles"), object: nil)
        }
    }
    
    private func updateStatusMessage() {
        let enabledCount = tasks.filter { $0.isEnabled }.count
        if enabledCount == 0 {
            statusMessage = "No active scheduled tasks"
        } else {
            statusMessage = "\(enabledCount) active task\(enabledCount == 1 ? "" : "s")"
        }
    }
    
    deinit {
        checkTimer?.invalidate()
    }
}
