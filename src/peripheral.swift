/* Mostly "inspired" by https://medium.com/@shu223/core-bluetooth-snippets-with-swift-9be8524600b2 */

import Foundation
import CoreBluetooth

class PeripheralMan: NSObject, CBPeripheralManagerDelegate {
    var peripheralManager: CBPeripheralManager!
    
    

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    {
        print("PeripherManager state has changed to \(peripheral.state)")
    }
    

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager,
                                             error: Error?)
    {
        print("Peripheral Manager state changed. This is probably good.")
        if let error = error {
            print("Failed… error: \(error)")
            return
        }
    }

    func peripheralManager(peripheral: CBPeripheralManager, didAdd service: CBService, error: NSError?)
    {
        if let error = error {
            print("error: \(error)")
            return
        }

        print("service: \(service)")
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
    if (periph_man.peripheralManager.state == .poweredOn){
        print("Peripheral manager powered on")
    }
    else {
        print("Peripheral manager not powered on")
    }
    
    let properties: CBCharacteristicProperties = [.notify, .read, .write]
    let permissions: CBAttributePermissions = [.readable, .writeable]
    let standInUUID = CBUUID(string: "00001801-0000-1000-8000-00805f9b34fb") //these UUIDS probably need to be changed
    let serviceUUID = CBUUID(string: "a495ff20-c5b1-4b44-b512-1370f02d74de")
    let someCharacteristic = CBMutableCharacteristic(type: standInUUID, properties: properties, value: nil, permissions: permissions)
    let someService = CBMutableService(type:serviceUUID, primary:true)
    
    someService.characteristics = [someCharacteristic]
    let advertisementData: [String : Any] = [CBAdvertisementDataLocalNameKey : "JasonChase", CBAdvertisementDataServiceUUIDsKey : ["a495ff20-c5b1-4b44-b512-1370f02d74de"]]// probably the right format, thank apple for their definitely helpful documentation
    
    if(periph_man.peripheralManager.state == .poweredOn) { //just prints out what state the peripheral is in, if it's not on something is probably going wrong
        if(!periph_man.peripheralManager.isAdvertising) {
            periph_man.peripheralManager.add(someService)
            periph_man.peripheralManager.startAdvertising(advertisementData)
            while (!periph_man.peripheralManager.isAdvertising){
                usleep(10000)
            }
        }
        if (!periph_man.peripheralManager.isAdvertising){
            print("Something went wrong. Peripheral manager is not advertising.")
        }
        else{
            print("Peripheral Manager has begun advertising")
        }
        
    }
    else {
        print("PeripheralManager state is not powered on. Perhaps your bluetooth is off.")
    }
}





