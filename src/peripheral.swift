/* Mostly "inspired" by https://medium.com/@shu223/core-bluetooth-snippets-with-swift-9be8524600b2 */

import Foundation
import CoreBluetooth

class PeripheralMan: NSObject, CBPeripheralManagerDelegate {
    var peripheralManager: CBPeripheralManager!
    
    override init() {
        super.init()
        
        let properties: CBCharacteristicProperties = [.notify, .read, .write]
        let permissions: CBAttributePermissions = [.readable, .writeable]
        let standInUUID = CBUUID(string: "a495ff20-c5b1-4b44-b512-1370f02d74de")
        let advertisementData = [CBAdvertisementDataLocalNameKey: "Test Device"]
        
        
        
        let someCharacteristic = CBMutableCharacteristic(type: standInUUID, properties: properties, value: nil, permissions: permissions)
        let someService = CBMutableService(type:standInUUID, primary:true)
        someService.characteristics = [someCharacteristic]
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        peripheralManager.add(someService)
        peripheralManager.startAdvertising(advertisementData)
        
        print("Ready to go")

    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    {
        print("state: \(peripheral.state)")
    }


    func peripheralManagerDidStartAdvertising(_ error:NSError?)
    {
        if let error = error {
            print("Failed… error: \(error)")
            return
        }
        print("Succeeded!")
    }

}



