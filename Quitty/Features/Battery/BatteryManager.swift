import Foundation
import Combine
import IOKit.ps

class BatteryManager: ObservableObject {
    @Published var chargePercent: Int = 0
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    @Published var cycleCount: Int = 0
    @Published var health: Int = 100
    @Published var temperature: Double = 0
    @Published var timeRemaining: String = ""
    @Published var maxCapacity: Int = 0
    @Published var designCapacity: Int = 0
    @Published var currentCapacity: Int = 0
    @Published var powerSource: String = "Unknown"
    @Published var hasBattery: Bool = true

    init() {
        refresh()
    }

    func refresh() {
        // IOKit power source info
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
              !sources.isEmpty else {
            DispatchQueue.main.async { self.hasBattery = false }
            return
        }

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source as CFTypeRef)?.takeUnretainedValue() as? [String: Any] else { continue }

            DispatchQueue.main.async {
                self.hasBattery = true
                self.chargePercent = info[kIOPSCurrentCapacityKey] as? Int ?? 0
                self.maxCapacity = info[kIOPSMaxCapacityKey] as? Int ?? 100
                self.isCharging = (info[kIOPSIsChargingKey] as? Bool) ?? false
                self.powerSource = (info[kIOPSPowerSourceStateKey] as? String) ?? "Unknown"
                self.isPluggedIn = self.powerSource == kIOPSACPowerValue

                if let timeToEmpty = info[kIOPSTimeToEmptyKey] as? Int, timeToEmpty > 0 {
                    let hours = timeToEmpty / 60
                    let minutes = timeToEmpty % 60
                    self.timeRemaining = "\(hours)h \(minutes)m remaining"
                } else if let timeToFull = info[kIOPSTimeToFullChargeKey] as? Int, timeToFull > 0 {
                    let hours = timeToFull / 60
                    let minutes = timeToFull % 60
                    self.timeRemaining = "\(hours)h \(minutes)m until full"
                } else if self.isCharging {
                    self.timeRemaining = "Calculating..."
                } else if self.isPluggedIn && self.chargePercent >= 100 {
                    self.timeRemaining = "Fully charged"
                } else {
                    self.timeRemaining = ""
                }
            }
        }

        // SMC data via IOKit for cycle count and health
        refreshSMCData()
    }

    private func refreshSMCData() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != IO_OBJECT_NULL else { return }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else { return }

        DispatchQueue.main.async {
            self.cycleCount = dict["CycleCount"] as? Int ?? 0
            self.designCapacity = dict["DesignCapacity"] as? Int ?? 0
            // NominalChargeCapacity is actual max capacity in mAh (MaxCapacity is percentage)
            let actualMaxCap = dict["NominalChargeCapacity"] as? Int ?? dict["AppleRawMaxCapacity"] as? Int ?? 0
            self.currentCapacity = dict["AppleRawCurrentCapacity"] as? Int ?? dict["CurrentCapacity"] as? Int ?? 0

            if self.designCapacity > 0 && actualMaxCap > 0 {
                self.health = min(100, (actualMaxCap * 100) / self.designCapacity)
            }

            if let temp = dict["Temperature"] as? Int {
                self.temperature = Double(temp) / 100.0
            }
        }
    }
}
