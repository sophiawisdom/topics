/* Mostly "inspired" by https://medium.com/@shu223/core-bluetooth-snippets-with-swift-9be8524600b2 */
import Foundation
import CoreBluetooth

class CentralMan: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var del: PeripheralDelegate!
    var knownPeripherals = [CBPeripheral]() // List of all peripherals we've encountered
    var peripheralMsgCharacteristics = [String: CBCharacteristic]() // Map between peripherals we've encountered and their msg characteristics
    let messageServiceUUID = CBUUID(string: "0x1800")
    
    override init() {
        super.init()
        del = PeripheralDelegate()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager state has changed. This is probably good.")
    }
    func centralManager(_: CBCentralManager, didDiscover: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber){ // Receives result of peripheral scan
        let UUID = advertisementData[CBAdvertisementDataServiceUUIDsKey] as! String
        
        print("Discovered peripheral with UUID \(UUID)")
        if (UUID == "hello"){
            print("Attempting to connect to known UUID")
        }
        else {
            print("UUID unknown. No connection made")
            return
        }
        centralManager.connect(didDiscover, options: nil)
        
        didDiscover.delegate = del
        
        
        knownPeripherals.append(didDiscover)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect: CBPeripheral) {
        print("connected")
        
        didConnect.discoverServices(nil)
        print("Started to discover services")
        sleep(500000)
        var have_message_service = false
        for service in peripheral.services! {
            print("Service discovered on peripheral: \(service)")
            if (service == messageServiceUUID){
                have_message_service = true
                print("Found message service UUID on peripheral")
            }
        }
        
    }
    
    func sendMessage(_ central: CBCentralManager,peripheral: CBPeripheral, messageText: String){
        // Do the peripheral objects keep a record of what characteristics we need?
        let data = messageText.data(using: .utf8)! // When sending messages we need the type to be a byte buffer
        let characteristic = peripheralMsgCharacteristics[peripheral.name!]
        peripheral.writeValue(data, for: characteristic!, type: CBCharacteristicWriteType.withoutResponse) // Ask for response or not?
        
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


