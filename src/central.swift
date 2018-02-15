d/* Mostly "inspired" by https://medium.com/@shu223/core-bluetooth-snippets-with-swift-9be8524600b2 */
import Foundation
import CoreBluetooth

class CentralMan: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var del: PeripheralDelegate!
    var knownPeripherals = [CBPeripheral]() // List of all peripherals we've encountered
    var peripheralMsgCharacteristics = [String: CBCharacteristic]() // Map between peripherals we've encountered and their msg characteristics
    let messageServiceUUID = CBUUID(string: "b839e0d3-de74-4493-860b-00600deb5e00")
    let messageCharacteristicUUID = CBUUID(string: "fc36344b-bcda-40ca-b118-666ec767ab20")
    
    override init() {
        super.init()
        del = PeripheralDelegate()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager state has changed. This is probably good.")
    }
    func centralManager(_: CBCentralManager, didDiscover: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber){ // Receives result of peripheral scan
        // We've found a peripheral; should we connect?
        var should_connect = false
        if let BUUID = advertisementData[CBAdvertisementDataServiceUUIDsKey] { // if this key exists
            switch BUUID {
            case messageServiceUUID as CBUUID:
                print("Found peripheral with BUUID 'hello'. Connecting.")
                should_connect = true
            case is String:
                print("UUID \(BUUID) found")
            default:
                print("Service UUID that is not string found: \(BUUID)")
            }
        }
        else if let name = advertisementData[CBAdvertisementDataLocalNameKey] {
            switch name {
            case "JasonChasez" as String:
                print("Found JasonChasez. Attempting to connect.")
                should_connect = true
            case is String:
                print("Found peripheral named \(name). Not connecting.")
            default:
                print("Somehow found name that is not string.")
            }
        }
        else {
            print("Found peripheral without name or UUID. No connection attempted.")
        }
        if should_connect == false {
            return
        }
        
        
        didDiscover.delegate = del
        
        centralManager.connect(didDiscover, options: nil)
        
        knownPeripherals.append(didDiscover)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect: CBPeripheral) {
        didConnect.delegate = del
        didConnect.discoverServices([messageServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect: CBPeripheral, error: Error?) {
        print("connection failed")
    }
}


class PeripheralDelegate: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    override init() {
        super.init()
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        if (peripheral.name != nil){
            print("Services have been found for peripheral \(peripheral.name!)")
        }
        else{
            print("Services have been found for peripheral w/o name")
        }
        let services = peripheral.services!
        print("Found \(services.count) services for peripheral \(peripheral)")
        for service in services {
            print("Service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
        
    }
}


