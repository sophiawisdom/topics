/* Mostly "inspired" by https://medium.com/@shu223/core-bluetooth-snippets-with-swift-9be8524600b2 */
import Foundation
import CoreBluetooth

class CentralMan: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var del: PeripheralDelegate!
    var connectedUsers = [user]() // List of all peripherals we've encountered
    var peripheralUsers = [CBPeripheral: user]()
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
        if let UUID = advertisementData[CBAdvertisementDataServiceUUIDsKey] { // if this key exists
            switch UUID {
            case messageServiceUUID as CBUUID:
                print("Found peripheral with correct messageServiceUUID. Connecting.")
                should_connect = true
            case is NSMutableArray:
                let UUIDArr = UUID as! NSMutableArray
                let broadcastUUID = UUIDArr[0] as! CBUUID
                if broadcastUUID == identifierServiceUUID {
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
                print("UUID \(UUID) found")
            default:
                print("advert has incorrect UUID \(advertisementData)")
            }
        }
        if should_connect == false {
            return
        }
        
        let name = advertisementData[CBAdvertisementDataLocalNameKey]
        
        if (name == nil){
            print("Found user with correct message service UUID, but without name. This is not acceptable.")
            return
        }
        
        let usr = user(name: name as! String, firstSeen: 0, peripheral: didDiscover) // should fail if they don't have name
        
        didDiscover.delegate = del
        centralManager.connect(didDiscover, options: nil)
        
        connectedUsers.append(usr)
        peripheralUsers[peripheral] = usr
        allUsers.append(usr)
        
        print("Connected to user with name \(usr.name)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect: CBPeripheral) { // When someone is connected to
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
        let characteristics = didDiscoverCharacteristicsFor.characteristics!
        for characteristic in characteristics {
            if characteristic.uuid == getFirstSeenCharacteristicUUID {
                peripheral.readValue(for: characteristic)
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor: CBCharacteristic, error: Error?) {
        
        if didUpdateValueFor.uuid == getFirstSeenCharacteristicUUID { // This should happen more or less immediately, or at least as soon as possible.
            print("got getFirstSeenCharacteristicUUID value. Value == \(didUpdateValueFor.value!)")
            var usr = central_man.peripheralUsers[peripheral]!
            let value = didUpdateValueFor.value! as NSData // data type, have to convert to int
            usr.firstSeen = value.bytes.load(as:Int64.self)
            firstSeenToUser[usr.firstSeen!] = usr
        }
        
        else if didUpdateValueFor.uuid == userReadCharacteristicUUID { // Sending us their user list to update
            let data = didUpdateValueFor.value! as NSData
            var users = [user]()
            var offset = 0
            
            while (offset < data.length) {
                let length = Int(data.bytes.load(fromByteOffset: offset, as:Int32.self))
                offset += 4
                let range = NSMakeRange(offset,length)
                users.append(data_to_user(data.subdata(with: range) as NSData)) // If length is set wrong or if we read text data as int, then this will crash the program
                offset += length
            }
            
            for usr in users {
                var otherUser = firstSeenToUser[usr.firstSeen!]
                if (otherUser == nil) {
                    print("Found new user \(usr)")
                    firstSeenToUser[usr.firstSeen!] = usr
                    allUsers.append(usr)
                }
                else {
                    otherUser!.lastSeen = getTime()
                }
            }
        }
    }
}

