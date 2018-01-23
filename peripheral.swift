
import Foundation
import CoreBluetooth

class Wow: NSObject, CBPeripheralManagerDelegate {
    var peripheralManager: CBPeripheralManager!
    var peripheral: CBPeripheral!
    
    func start() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        let advertisementData = [CBAdvertisementDataLocalNameKey: "Test Device"]
        peripheralManager.startAdvertising(advertisementData)
        
        
        let properties: CBCharacteristicProperties = [.notify, .read, .write]
        let permissions: CBAttributePermissions = [.readable, .writeable]
        
        let blah = CBUUID(string: "a495ff20-c5b1-4b44-b512-1370f02d74de")
        let someChar = CBMutableCharacteristic(type:blah, properties:properties
            , value:nil, permissions:permissions)
        let someService = CBMutableService(type:CBUUID(string: "a495ff20-c5b1-4b44-b512-1370f02d74de"), primary:true)
        someService.characteristics = [someChar]
        
        peripheralManager.add(someService)
        
        
        
        print("Hello, World!")

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
var thingy = Wow()
thingy.start()

while(true) {
    
}
