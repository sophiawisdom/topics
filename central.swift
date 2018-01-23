
import Foundation
import CoreBluetooth

sdfg
class CentralBoye: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral
    
    init() {
        let blah = CBUUID(string: "a495ff20-c5b1-4b44-b512-1370f02d74de")
    }
    func centralManagerDidUpdateState(central: CBCentralManager) {
        print("state: \(central.state)")
    }
}
