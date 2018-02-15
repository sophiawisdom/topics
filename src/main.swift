import Foundation
import CoreBluetooth

//let periph_man = PeripheralMan()
let central_man = CentralMan()
//let periphMan = PeripheralMan()
//start_advertising(periph_man:periphMan)
var queue: DispatchQueue!
if #available(OSX 10.10, *) {
    queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
} else {
    print("DispatchQueue not available on your version of MacOSX. Please update to 10.10 or greater.")
}

central_man.centralManager = CBCentralManager(delegate: central_man, queue: queue)

let standInUUID = CBUUID(string: "0x1800")
//var ids: [CBUUID] = [standInUUID]
while (!(central_man.centralManager.state == .poweredOn)){
    usleep(1000)
}
print("Central Manager powered on")
central_man.centralManager.scanForPeripherals(withServices:nil)

/*func sendMessage(central: CBCentralManager,peripheral: CBPeripheral, messageText: String){
    // Do the peripheral objects keep a record of what characteristics we need?
    let data = messageText.data(using: .utf8)! // When sending messages we need the type to be a byte buffer
    peripheral.writeValue(data, for: characteristic!, type: CBCharacteristicWriteType.withoutResponse) // Ask for response or not?
    
}*/

while (true){
    usleep(100000)
    //print("huH")
}

