/* Mostly "inspired" by https://medium.com/@shu223/core-bluetooth-snippets-with-swift-9be8524600b2 */
import Foundation
import CoreBluetooth

class CentralMan: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var del: PeripheralDelegate!
    var knownPeripherals = [CBPeripheral]() // List of all peripherals we've encountered
    var peripheralMsgCharacteristics = [String: CBCharacteristic]() // Map between peripherals we've encountered and their msg characteristics
    
    override init() {
        super.init()
        del = PeripheralDelegate()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager state has changed. This is probably good.")
    }
    func centralManager(_: CBCentralManager, didDiscover: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber){ // Receives result of peripheral scan
        
        centralManager.connect(didDiscover, options: nil)
        
        didDiscover.delegate = del
        
        
        knownPeripherals.append(didDiscover)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect: CBPeripheral) {
        print("connected")
        didConnect.discoverServices(nil)
    }
    
    func sendMessage(_ central: CBCentralManager,peripheral: CBPeripheral, messageText: String){
        // Do the peripheral objects keep a record of what characteristics we need?
        let data = messageText.data(using: .utf8) // When sending messages we need the type to be a byte buffer
        let characteristic = peripheralMsgCharacteristics[peripheral.name!]
        peripheral.writeValue(data!, for: characteristic!, type: CBCharacteristicWriteType.withoutResponse) // Ask for response or not?
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect: CBPeripheral, error: Error?) {
        print("connection failed")
    }
}


class PeripheralDelegate: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    override init() {
        super.init()
        print("hi")
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        let services = peripheral.services
        print("Found \(services!.count) services! :\(services!) for peripheral \(peripheral)")
    }
}


