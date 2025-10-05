import AppKit
import Defaults
import Foundation

enum GestureDelegator {
    // Called for every two-finger swipe gesture anywhere
    static func windowTwoFingerSwiped(flick: TwoFingerFlickAccumulator) {
        if let swipedWindow = WindowUtil.getWindowByID(id: flick.windowNumber) {
            // A window that we're tracking was swiped

            guard
                let windowTopLeft = try? swipedWindow.axElement.position(),
                let windowSize = try? swipedWindow.axElement.size()
            else {
                print("swiped window had nil position or size")
                return
            }

            let mouseScreen = NSScreen.screenContainingMouse(flick.startLocation)
            let mouseLocationInScreen = DockObserver.nsPointFromCGPoint(flick.startLocation, forScreen: mouseScreen)

            let locationInWindow = NSPoint(x: mouseLocationInScreen.x - windowTopLeft.x, y: mouseLocationInScreen.y - windowTopLeft.y)

            let titleBarHeight: CGFloat = 30
            let titleFrame = NSRect(x: 0, y: 0, width: windowSize.width, height: titleBarHeight)

            if titleFrame.contains(locationInWindow), Defaults[.enableTitleSwipes] {
                windowTitleTwoFingerSwiped(flick: flick, swipedWindow: swipedWindow)
            }
        } else {
            // The background, dock, etc were swiped. Future features likely pick up from here
        }
    }

    // After some processing, we've determined that a title-bar was two-finger swiped
    private static func windowTitleTwoFingerSwiped(flick: TwoFingerFlickAccumulator, swipedWindow: WindowInfo) {
        let mouseScreen = NSScreen.screenContainingMouse(flick.startLocation)

        let hasOption = flick.originalEvent.modifierFlags.contains(.option)

        var resizeAction: WindowPaneAction = .none
        if hasOption {
            switch flick.flickDirection {
            case .left:
                resizeAction = .halfLeft
            case .right:
                resizeAction = .halfRight
            case .up:
                resizeAction = .halfTop
            case .down:
                resizeAction = .halfBottom
            default:
                break
            }
        } else {
            switch flick.flickDirection {
            // I think left/right are supposed to send the window to another space
            case .up:
                resizeAction = .maximize
            case .down:
                resizeAction = .restore
            default:
                break
            }
        }

        if resizeAction != .none {
            WindowUtil.performWindowPaneAction(window: swipedWindow, action: resizeAction, screen: mouseScreen)
        }
    }
}
