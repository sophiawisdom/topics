/* Mostly "inspired" by https://medium.com/@shu223/core-bluetooth-snippets-with-swift-9be8524600b2 */
import Foundation
import CoreBluetooth

class CentralMan: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
//    var peripheral: CBPeripheral!
    var known_peripherals = [CBPeripheral]() // List of all peripherals we've encountered
    let service_uuid = CBUUID(string: "a495ff20-c5b1-4b44-b512-1370f02d74de")
    
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate:self, queue:nil)
        
        centralManager.scanForPeripherals(withServices:nil, options: nil)
        print("CentralMan init sequence completed, now scanning for peripherals.")
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state: \(central.state)")
    }
    func centralManager(central: CBCentralManager,
                        didDiscoverPeripheral peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        RSSI: NSNumber!){ // Receives result of peripheral scan
        print("peripheral: \(peripheral)")
        print("Found a peripheral")
        known_peripherals.append(peripheral)
    }
}