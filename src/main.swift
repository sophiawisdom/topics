import Foundation
import CoreBluetooth

let messageServiceUUID = CBUUID(string: "b839e0d3-de74-4493-860b-00600deb5e00")
let messageCharacteristicUUID = CBUUID(string: "fc36344b-bcda-40ca-b118-666ec767ab20")
let central_man = CentralMan()

var queue: DispatchQueue!
if #available(OSX 10.10, *) {
    queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
} else {
    print("DispatchQueue not available on your version of MacOSX. Please update to 10.10 or greater.")
}

central_man.centralManager = CBCentralManager(delegate: central_man, queue: queue)

while (!(central_man.centralManager.state == .poweredOn)){ // wait until it powers on
    usleep(1000)
}

print("Central Manager powered on")
central_man.centralManager.scanForPeripherals(withServices:nil)

func send_message(_ peripheral:CBPeripheral,central:CentralMan,message:String){
    
    let data = message.data(using: .utf8)!
    
    var service_to_write: CBService! // getting the write characteristic
    for service in peripheral.services! {
        if (service.uuid == messageServiceUUID){
            service_to_write = service
        }
    }
    if (service_to_write == nil){
        print("Not able to find message service")
        return
    }
    
    var characteristic_to_write: CBCharacteristic!
    for characteristic in service_to_write.characteristics! {
        if (characteristic.uuid == messageCharacteristicUUID){
            characteristic_to_write = characteristic
        }
    }
    if (characteristic_to_write == nil){
        print("Not able to find message characteristic")
        return
    }
    
    
    characteristic_to_write = characteristic_to_write!
    peripheral.writeValue(data, for: characteristic_to_write, type: CBCharacteristicWriteType.withResponse)
    
}
usleep(5000000)
print("Done waiting.")
var to_send = ""
while (true){
    to_send = readLine()!
    print("Sending message \(to_send) to peripheral \(central_man.knownPeripherals[0])")
    send_message(central_man.knownPeripherals[0], central: central_man, message: to_send)
}
