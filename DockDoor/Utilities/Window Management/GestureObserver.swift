import Cocoa

enum FlickDirection {
    case none, left, right, up, down
}

// Class that watches a mouse scroll event and turns it into a flick if it goes far enough
// The physical scroll wheel sends events independently and therefore always triggers
class TwoFingerFlickAccumulator {
    var originalEvent: NSEvent
    var totalDX: CGFloat = 0
    var totalDY: CGFloat = 0
    var flickDirection: FlickDirection = .none

    let minFlickDistance: CGFloat = 20

    init(originalEvent: NSEvent) {
        self.originalEvent = originalEvent
    }

    var windowNumber: Int {
        originalEvent.windowNumber
    }

    // Despite the event saying "locationInWindow" this is location on screen in bottom-left origin coordinates
    var startLocation: NSPoint {
        originalEvent.locationInWindow
    }

    // Return true when triggered
    func accumulate(event: NSEvent) -> Bool {
        guard flickDirection == .none else { return false }

        let isActualScrollWheel = !event.hasPreciseScrollingDeltas

        totalDX += CGFloat(event.scrollingDeltaX)
        totalDY += CGFloat(event.scrollingDeltaY)

        if abs(totalDX) >= minFlickDistance || abs(totalDY) >= minFlickDistance || isActualScrollWheel {
            if abs(totalDX) > abs(totalDY) {
                flickDirection = totalDX > 0 ? .right : .left
            } else {
                flickDirection = totalDY > 0 ? .down : .up
            }
            return true
        }
        return false
    }
}

class GestureObserver {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask = [.scrollWheel]

    private var twoFingerFlickAccumulator: TwoFingerFlickAccumulator?

    init() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event: event)
        }
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func handleScrollWheel(_ event: NSEvent) {
        guard event.momentumPhase.rawValue == 0 else { return }

        let isActualScrollWheel = !event.hasPreciseScrollingDeltas

        if event.phase.contains(.began) || isActualScrollWheel {
            twoFingerFlickAccumulator = TwoFingerFlickAccumulator(originalEvent: event)
        }

        guard let accumulator = twoFingerFlickAccumulator else { return }

        // The accumulator will return triggered up to once for every new scroll event
        let triggered = accumulator.accumulate(event: event)

        if triggered {
            GestureDelegator.windowTwoFingerSwiped(flick: accumulator)
        }
    }

    private func handle(event: NSEvent) {
        switch event.type {
        case .scrollWheel:
            handleScrollWheel(event)
        default:
            break
        }
    }
}
