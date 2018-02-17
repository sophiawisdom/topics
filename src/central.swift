/* Mostly "inspired" by https://medium.com/@shu223/core-bluetooth-snippets-with-swift-9be8524600b2 */
import Foundation
import CoreBluetooth

class CentralMan: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var del: PeripheralDelegate!
    var connectedUsers = [user]() // List of all peripherals we've encountered
    let messageServiceUUID = CBUUID(string: "b839e0d3-de74-4493-860b-00600deb5e00")
    let messageCharacteristicUUID = CBUUID(string: "fc36344b-bcda-40ca-b118-666ec767ab20")
    
    override init() {
        super.init()
        del = PeripheralDelegate()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    }
    func centralManager(_: CBCentralManager, didDiscover: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber){ // Receives result of peripheral scan
        // We've found a peripheral; should we connect?
        var should_connect = false
        if let BUUID = advertisementData[CBAdvertisementDataServiceUUIDsKey] { // if this key exists
            switch BUUID {
            case messageServiceUUID as CBUUID:
                print("Found peripheral with correct messageServiceUUID. Connecting.")
                should_connect = true
            case is NSMutableArray:
                let UUIDArr = BUUID as! NSMutableArray
                let broadcastUUID = UUIDArr[0] as! CBUUID
                if broadcastUUID == messageServiceUUID {
                    print("Found messageServiceUUID UUID. Advertising_data: \(advertisementData)")
                    should_connect = true
                }
                else {
                    if #available(OSX 10.10, *){
                        print("Encountered peripheral with UUID \(broadcastUUID.uuidString)")
                    
                    }
                    else {
                        print("Encountered peripheral with UUID \(broadcastUUID)")
                    }
                }
            case is String:
                print("UUID \(BUUID) found")
            default:
                print("advert has incorrect UUID \(advertisementData)")
            }
        }
        else if let name = advertisementData[CBAdvertisementDataLocalNameKey] {
            switch name {
            case "JasonChasez" as String:
                print("Found JasonChasez. Attempting to connect.")
                should_connect = true
            case is String:
                print("Found peripheral named \(name) with advertisement data \(advertisementData)")
            default:
                print("Somehow found name that is not string.")
            }
        }
        if should_connect == false {
            return
        }
        
        let name = advertisementData[CBAdvertisementDataLocalNameKey]
        
        let usr = user(name: name as! String, lastSeen: nil, peripheral: didDiscover) // should fail if they don't have name
        
        didDiscover.delegate = del
        
        centralManager.connect(didDiscover, options: nil)
        
        connectedUsers.append(usr)
        
        print("Connected to user with name \(usr.name)")
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
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor: CBService, error: Error?){
        
    }
}


