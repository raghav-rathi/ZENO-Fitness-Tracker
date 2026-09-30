import Foundation
#if os(iOS)
import CoreMotion
#endif

/// Whether the app may read the iPhone's own step count, as CoreMotion reports it.
enum PhoneStepAccess: Equatable, Sendable {
    /// No step-counting hardware to ask: the Mac, the Simulator, or a device without a motion coprocessor.
    case unavailable
    /// Never asked. The first pedometer query shows the system Motion & Fitness prompt.
    case notDetermined
    /// The wearer said no, or has Fitness Tracking switched off in Settings.
    case denied
    /// Fitness Tracking is off system-wide, or Screen Time / device management blocks it. The app cannot
    /// grant it; only Settings can.
    case restricted
    case authorized
}

/// One pedometer reading over a window.
struct PedometerReading: Equatable, Sendable {
    let start: Date
    let end: Date
    let steps: Int
    /// Metres, when this iPhone estimates distance (nil, not 0, when it does not).
    let distanceM: Double?
    /// Floors climbed, when the phone has a barometer-backed floor counter.
    let floorsUp: Int?
}

/// The iPhone's motion coprocessor, through CoreMotion's `CMPedometer`.
///
/// The coprocessor counts steps whether or not any app is running, and CoreMotion keeps about seven days of
/// that history on the device. So the app never has to be awake to COUNT: it only has to read the history
/// before it ages out (the backfill in `StepsService`), and it reads the running total live while it is on
/// screen. Nothing here persists anything; that is the service's job.
///
/// Distinct from `WorkoutPedometer`, which reads one finished workout window and has its own instance.
/// macOS has no `CMPedometer`, so there every entry point reports `.unavailable` or nil.
///
/// `@unchecked Sendable`: the only state is the `CMPedometer`, whose query and update calls are made from
/// the service's tasks and whose completion handlers CoreMotion invokes on its own queue.
final class PhonePedometer: @unchecked Sendable {
    #if os(iOS)
    private let pedometer = CMPedometer()
    #endif

    /// Where authorisation stands right now. Cheap; safe to call from anywhere.
    static var access: PhoneStepAccess {
        #if DEBUG
        if let forced = debugForcedAccess { return forced }
        #endif
        #if os(iOS)
        guard CMPedometer.isStepCountingAvailable() else { return .unavailable }
        switch CMPedometer.authorizationStatus() {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
        #else
        return .unavailable
        #endif
    }

    #if DEBUG
    /// DEBUG harness: `--demo-steps-access notDetermined|denied|restricted` pins the reported access, so the
    /// Steps screen's access card can be seen on a Simulator, which has no pedometer to ask.
    private static let debugForcedAccess: PhoneStepAccess? = {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--demo-steps-access"), i + 1 < args.count else { return nil }
        switch args[i + 1] {
        case "notDetermined": return .notDetermined
        case "denied": return .denied
        case "restricted": return .restricted
        default: return nil
        }
    }()
    #endif

    /// The phone's reading over `[from, to]`, or nil when it cannot be counted: no hardware, access denied,
    /// a window older than CoreMotion keeps, or any other query error. Never a fabricated zero. On a fresh
    /// install the first call is what shows the Motion & Fitness prompt, and it completes once the wearer
    /// has answered it.
    func query(from: Date, to: Date) async -> PedometerReading? {
        #if os(iOS)
        guard from < to, CMPedometer.isStepCountingAvailable() else { return nil }
        return await withCheckedContinuation { (cont: CheckedContinuation<PedometerReading?, Never>) in
            pedometer.queryPedometerData(from: from, to: to) { data, _ in
                cont.resume(returning: data.map(PhonePedometer.reading))
            }
        }
        #else
        return nil
        #endif
    }

    /// Stream the running total counted since `from` (local midnight). Each update carries the whole
    /// day-so-far, not a delta, so a dropped update loses nothing. The handler runs on CoreMotion's queue.
    func startLive(from: Date, onUpdate: @escaping @Sendable (PedometerReading) -> Void) {
        #if os(iOS)
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: from) { data, _ in
            guard let data else { return }
            onUpdate(PhonePedometer.reading(data))
        }
        #endif
    }

    func stopLive() {
        #if os(iOS)
        pedometer.stopUpdates()
        #endif
    }

    #if os(iOS)
    private static func reading(_ data: CMPedometerData) -> PedometerReading {
        let distance = data.distance?.doubleValue
        return PedometerReading(
            start: data.startDate,
            end: data.endDate,
            steps: max(0, data.numberOfSteps.intValue),
            distanceM: distance.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil },
            floorsUp: data.floorsAscended.map { max(0, $0.intValue) })
    }
    #endif
}
