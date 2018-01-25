
import Foundation
import CoreBluetooth

class CentralBoye: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate:self, queue:nil)
        let service_uuid = CBUUID(string: "a495ff20-c5b1-4b44-b512-1370f02d74de")
        centralManager.scanForPeripherals(withServices:nil, options: nil)
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state: \(central.state)")
    }
    func centralManager(central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        RSSI: NSNumber){ // Receives result of peripheral scan
        print("peripheral: \(peripheral)")
    }
}

var cls = CentralBoye()
