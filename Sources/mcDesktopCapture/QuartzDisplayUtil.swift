//
//  QuartzDisplayUtil.swift
//  
//
//  Created by fuziki on 2021/09/25.
//

import Foundation

class QuartzDisplayUtil {
    private struct DisplayInfo {
        let name: String
        let vendorID: Int
        let productID: Int
        let serialNumber: Int
    }
    private static var displayInfoList: [DisplayInfo] {
        var ret: [DisplayInfo] = []

        var iterator = io_iterator_t()
        let matching = IOServiceMatching("IODisplayConnect")
        let res = IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iterator)
        defer {
            IOObjectRelease(iterator)
        }
        guard res == KERN_SUCCESS, iterator != 0 else { return ret }

        while true {
            let object: io_object_t = IOIteratorNext(iterator)
            if object == 0 { break }
            let info = IODisplayCreateInfoDictionary(object, IOOptionBits(kIODisplayOnlyPreferredName))
                .takeRetainedValue() as? [String: Any] ?? [:]
            print("object: \(object)\ninfo: \(info)")
            if let productName = info[kDisplayProductName] as? [String: String],
               let name = productName.values.first,
               let vendor = info[kDisplayVendorID] as? Int,
               let product = info[kDisplayProductID] as? Int {
                let serial = info[kDisplaySerialNumber] as? Int ?? 0
                let info = DisplayInfo(name: name, vendorID: vendor, productID: product, serialNumber: serial)
                ret.append(info)
                print("name: \(name), vendor: \(vendor), product: \(product), serial: \(serial)")
            }
        }
        return ret
    }

    private static var onlineDisplayList: [CGDirectDisplayID] {
        let maxDisplays: UInt32 = 32
        var onlineDisplays = [CGDirectDisplayID](repeating: CGDirectDisplayID(0), count: Int(maxDisplays))
        var displayCount: UInt32 = 0
        let res = CGGetOnlineDisplayList(maxDisplays, &onlineDisplays, &displayCount)
        guard res == .success else {
            print("error: \(res)")
            return []
        }
        return Array(onlineDisplays.prefix(Int(displayCount)))
    }

    public struct DisplayProperty: Codable {
        let id: CGDirectDisplayID
        let name: String
        let vendorNumber: Int
        let modelNumber: Int
        let serialNumber: Int
    }

    public static var displayList: [DisplayProperty] {
        let infoList = Self.displayInfoList
        return onlineDisplayList.map { (id: CGDirectDisplayID) -> DisplayProperty in
            for info in infoList {
                if id.vendorNumber == info.vendorID,
                   id.modelNumber == info.productID,
                   id.serialNumber == info.serialNumber {
                    return DisplayProperty(id: id,
                                           name: info.name,
                                           vendorNumber: info.vendorID,
                                           modelNumber: info.productID,
                                           serialNumber: info.serialNumber)
                }
            }
            return DisplayProperty(id: id,
                                   name: "unknown",
                                   vendorNumber: 0,
                                   modelNumber: 0,
                                   serialNumber: 0)
        }
    }
}

extension CGDirectDisplayID {
    var vendorNumber: Int {
        return Int(CGDisplayVendorNumber(self))
    }
    var modelNumber: Int {
        return Int(CGDisplayModelNumber(self))
    }
    var serialNumber: Int {
        return Int(CGDisplaySerialNumber(self))
    }
}
