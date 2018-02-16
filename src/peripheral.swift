/* Mostly "inspired" by https://medium.com/@shu223/core-bluetooth-snippets-with-swift-9be8524600b2 */

import Foundation
import CoreBluetooth

class PeripheralMan: NSObject, CBPeripheralManagerDelegate {
    var peripheralManager: CBPeripheralManager!
    
    

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    {
        print("PeripherManager state has changed to \(peripheral.state)")
    }
    

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?)
    {
        if let error = error {
            print("Failed… error: \(error)")
            return
        }
        print("Peripheral Manager has started advertising")
    }

    func peripheralManager(peripheral: CBPeripheralManager, didAdd service: CBService, error: NSError?)
    {
        if let error = error {
            print("error: \(error)")
            return
        }

        print("service: \(service)")
    }
    
    func peripheralManager(_: CBPeripheralManager, didReceiveWrite: [CBATTRequest]) {
        let msg = data_to_message(_: didReceiveWrite[0].value! as NSData)
        print("User \(msg.sendingUser) sent me (\(msg.receivingUser)) a message: \(msg.messageText)")
        peripheralManager.respond(to: didReceiveWrite[0], withResult: CBATTError.Code.success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
    }

}

func start_advertising(periph_man: PeripheralMan!){
    
    
    var queue: DispatchQueue!
    if #available(OSX 10.10, *) {
        queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
    } else {
        print("DispatchQueue not available on your version of MacOSX. Please update to 10.10 or greater.")
    }
    periph_man.peripheralManager = CBPeripheralManager(delegate: periph_man, queue: queue)
    
    while (!(periph_man.peripheralManager.state == .poweredOn)){
        usleep(1000)
    }
    
    let properties: CBCharacteristicProperties = [.notify, .read, .write]
    let permissions: CBAttributePermissions = [.readable, .writeable]
    let charUUID = CBUUID(string: "fc36344b-bcda-40ca-b118-666ec767ab20") //these UUIDS probably need to be changed
    let serviceUUID = CBUUID(string: "b839e0d3-de74-4493-860b-00600deb5e00")
    let someCharacteristic = CBMutableCharacteristic(type: charUUID, properties: properties, value: nil, permissions: permissions)
    let someService = CBMutableService(type:serviceUUID, primary:true)
    someService.characteristics = [someCharacteristic]
    let advertisementData: [String : Any] = [CBAdvertisementDataLocalNameKey : name.prefix(8),CBAdvertisementDataServiceUUIDsKey:[serviceUUID]]// probably the right format, thank apple for their definitely helpful documentation
    print("Advertising with data \(advertisementData)")
    if(periph_man.peripheralManager.state == .poweredOn) { //just prints out what state the peripheral is in, if it's not on something is probably going wrong
        if(!periph_man.peripheralManager.isAdvertising) {
            periph_man.peripheralManager.removeAllServices()
            periph_man.peripheralManager.add(someService)
            usleep(100000)
            periph_man.peripheralManager.startAdvertising(advertisementData)
            while (!periph_man.peripheralManager.isAdvertising){
                usleep(10000)
            }
        }
        if (!periph_man.peripheralManager.isAdvertising){
            print("Something went wrong. Peripheral manager is not advertising.")
        } // Expect it to be advertising
        
    }
    else {
        print("PeripheralManager state is not powered on. Perhaps your bluetooth is off.")
    }
}





