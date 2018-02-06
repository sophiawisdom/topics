/* Mostly "inspired" by https://medium.com/@shu223/core-bluetooth-snippets-with-swift-9be8524600b2 */
import Foundation
import CoreBluetooth

class CentralMan: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var known_peripherals = [CBPeripheral]() // List of all peripherals we've encountered
    let service_uuid = CBUUID(string: "a495ff20-c5b1-4b44-b512-1370f02d74de")
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager state has changed. This is probably good.")
    }
    func centralManager(_: CBCentralManager, didDiscover: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber){ // Receives result of peripheral scan
        print("peripheral: \(didDiscover)")
        print("Found a peripheral")
        known_peripherals.append(didDiscover)
    }
}
