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
        print("diddiscover called")
        if let BUUID = advertisementData[CBAdvertisementDataServiceUUIDsKey] { // if this key exists
            switch BUUID {
            case "hello" as String:
                print("Got em")
            default:
                print("ServiceUUIDS other than 'hello'")
            }
        }
        else if let name = advertisementData[CBAdvertisementDataLocalNameKey] {
            switch name {
            case "JasonChase" as String:
                print("Found Local Name Jason Chase")
            default:
                print("Found peripheral without UUIDS and with name but name not Jason Chase. Name was bad")
            }
        }
        
        
        didDiscover.delegate = del
        
        centralManager.connect(didDiscover, options: nil)
        
        
        
        
        knownPeripherals.append(didDiscover)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect: CBPeripheral) {
        print("Connected to peripheral")
        didConnect.delegate = del
        didConnect.discoverServices(nil)
        var num_waits = 0
        while didConnect.services == nil{
            usleep(1000)
            num_waits += 1
            if (num_waits > 1 && (num_waits%1000 == 0)){
                print("Waiting for didConnect.services to be non-nil")
            }
        }
        var have_message_service = false
        print("Peripheral has \(didConnect.services!.count) services")
        for service in didConnect.services! {
            print("Service discovered on peripheral: \(service)")
            if (service.uuid == messageServiceUUID){
                have_message_service = true
                print("Found message service UUID on peripheral")
            }
        }
        if (have_message_service == true){
            
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
        print("peripheral func")
        let services = peripheral.services
        print("Found \(services!.count) services! :\(services!) for peripheral \(peripheral)")
    }
}


