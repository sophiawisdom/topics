import Foundation
import CoreBluetooth

//let periph_man = PeripheralMan()
let central_man = CentralMan()
usleep(500000)
var queue: DispatchQueue!
if #available(OSX 10.10, *) {
    queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
} else {
    print("DispatchQueue not available on your version of MacOSX. Please update to 10.10 or greater.")
}
//periph_man.peripheralManager = CBPeripheralManager(delegate: periph_man, queue: queue)
central_man.centralManager = CBCentralManager(delegate: central_man, queue: queue)


let properties: CBCharacteristicProperties = [.notify, .read, .write]
let permissions: CBAttributePermissions = [.readable, .writeable]
let standInUUID = CBUUID(string: "0x1800") //these UUIDS probably need to be changed
let serviceUUID = CBUUID(string: "0BFD338A-8BE2-444A-B584-DC39E9B5CAF2")
let otherUUID = CBUUID(string: "4C56FC1E-33AB-4BBC-89E0-55145826DA5F")
let someCharacteristic = CBMutableCharacteristic(type: standInUUID, properties: properties, value: nil, permissions: permissions)
let someService = CBMutableService(type:serviceUUID, primary:true)

someService.characteristics = [someCharacteristic]
let advertisementData: [String : Any] = [CBAdvertisementDataLocalNameKey : "JasonChase", CBAdvertisementDataServiceUUIDsKey : ["a495ff20-c5b1-4b44-b512-1370f02d74de"]]// probably the right format, thank apple for their definitely helpful documentation

/*if(periph_man.peripheralManager.state == .poweredOn) { //just prints out what state the peripheral is in, if it's not on something is probably going wrong
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
 
 }*/



var ids: [CBUUID] = [standInUUID]

if(central_man.centralManager.state == .poweredOn) {
    central_man.centralManager.scanForPeripherals(withServices: [standInUUID])
}
else {
    print("CentralManager state is not powered on. Perhaps your bluetooth is off.")
}

while (true){
    usleep(100000)
    //print("huH")
}

