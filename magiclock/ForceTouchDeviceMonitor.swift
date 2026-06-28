import AppKit
import IOKit
import IOKit.hid

final class ForceTouchDeviceMonitor {
    static let availabilityDidChangeNotification = Notification.Name("ESS_FORCETOUCHAVAILABLE_NOTIFICATIONNAME")
    static let availabilityUserInfoKey = "ESS_ForceTouch_Available"

    private var isCheckingForDevices = false
    private var deviceAvailable = false
    private var hidManager: IOHIDManager?

    func isForceTouchCapableDeviceAvailable() -> Bool {
        isForceTouchCapableDeviceAvailable(updateCachedAvailability: true)
    }

    private func isForceTouchCapableDeviceAvailable(updateCachedAvailability: Bool) -> Bool {
        guard let matchingDictionary = IOServiceMatching(kIOHIDDeviceKey) else {
            register()
            return false
        }

        var iterator = io_iterator_t()
        let status = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDictionary, &iterator)

        guard status == KERN_SUCCESS else {
            NSLog("Searching for devices unsuccessful")
            register()
            return false
        }

        isCheckingForDevices = true
        let result = containsForceTouchDevice(iterator)
        if updateCachedAvailability {
            deviceAvailable = result
        }
        isCheckingForDevices = false

        IOObjectRelease(iterator)
        register()

        return result
    }

    func stop() {
        guard let hidManager else {
            return
        }

        IOHIDManagerUnscheduleFromRunLoop(hidManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerClose(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.hidManager = nil
    }

    private func register() {
        guard hidManager == nil else {
            return
        }

        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        hidManager = manager
        IOHIDManagerSetDeviceMatching(manager, IOServiceMatching(kIOHIDDeviceKey))

        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, deviceMatchingCallback, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, deviceRemovalCallback, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    fileprivate func handleDeviceMatched() {
        guard !isCheckingForDevices && !deviceAvailable else {
            return
        }

        isCheckingForDevices = true
        let available = isForceTouchCapableDeviceAvailable(updateCachedAvailability: false)
        isCheckingForDevices = false

        guard available && !deviceAvailable else {
            return
        }

        deviceAvailable = true
        postAvailabilityChange(true)
    }

    fileprivate func handleDeviceRemoved() {
        guard !isCheckingForDevices && deviceAvailable else {
            return
        }

        isCheckingForDevices = true
        let available = isForceTouchCapableDeviceAvailable(updateCachedAvailability: false)
        isCheckingForDevices = false

        guard !available && deviceAvailable else {
            return
        }

        deviceAvailable = false
        postAvailabilityChange(false)
    }

    private func postAvailabilityChange(_ available: Bool) {
        NotificationCenter.default.post(
            name: Self.availabilityDidChangeNotification,
            object: nil,
            userInfo: [Self.availabilityUserInfoKey: available]
        )
    }

    private func containsForceTouchDevice(_ iterator: io_iterator_t) -> Bool {
        guard IOIteratorIsValid(iterator) != 0 else {
            return false
        }

        var success = false
        var object = IOIteratorNext(iterator)

        while object != 0 {
            if objectSupportsForceTouch(object) {
                success = true
                IOObjectRelease(object)
                break
            }

            var childIterator = io_iterator_t()
            let status = IORegistryEntryGetChildIterator(object, kIOServicePlane, &childIterator)
            if status == KERN_SUCCESS {
                success = containsForceTouchDevice(childIterator)
                IOObjectRelease(childIterator)
            }

            IOObjectRelease(object)

            if success {
                break
            }

            object = IOIteratorNext(iterator)
        }

        return success
    }

    private func objectSupportsForceTouch(_ object: io_object_t) -> Bool {
        var properties: Unmanaged<CFMutableDictionary>?
        let status = IORegistryEntryCreateCFProperties(object, &properties, kCFAllocatorDefault, 0)

        guard status == KERN_SUCCESS, let dictionary = properties?.takeRetainedValue() as? [String: Any] else {
            return false
        }

        guard let multitouchProperties = dictionary["DefaultMultitouchProperties"] as? [String: Any] else {
            return false
        }

        return multitouchProperties["ForceSupported"] as? Bool == true
    }
}

private func deviceMatchingCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    device: IOHIDDevice
) {
    guard let context else {
        return
    }

    Unmanaged<ForceTouchDeviceMonitor>.fromOpaque(context).takeUnretainedValue().handleDeviceMatched()
}

private func deviceRemovalCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    device: IOHIDDevice
) {
    guard let context else {
        return
    }

    Unmanaged<ForceTouchDeviceMonitor>.fromOpaque(context).takeUnretainedValue().handleDeviceRemoved()
}
