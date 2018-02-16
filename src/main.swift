import Foundation
import CoreBluetooth

struct user {
    let name: String
    var lastSeen: NSDate
    let identifier: String?
}
struct message {
    let sendingUser: String // Names respectively. Max length 30 bytes?
    let receivingUser: String
    let messageText: String // Maybe it should be data?
    let timeSent: Int64 // timestamp since epoch in milliseconds
    func message_to_data() -> NSData { // This probably causes a memory leak because I don't know how pointers work
        let messageData = NSMutableData(length: 0)! // Length initialized at 0 because appending is easy
        
        var timeSentInt = Int64(timeSent) // Needed for pointer math
        let timeSentIntData = NSData(bytes: &timeSentInt, length: 8) // doubles take 8 bytes
        messageData.append(timeSentIntData as Data)
        
        
        // Append string lengths
        var lengthSend = Int32(sendingUser.utf8.count)
        messageData.append(NSData(bytes: &lengthSend, length: 4) as Data)
        
        var lengthRecv = Int32(receivingUser.utf8.count)
        messageData.append(NSData(bytes: &lengthRecv, length: 4) as Data)
        
        var lengthMsg = Int32(messageText.utf8.count)
        messageData.append(NSData(bytes: &lengthMsg, length: 4) as Data)
        
        
        messageData.append(sendingUser.data(using: .utf8)!)
        messageData.append(receivingUser.data(using: .utf8)!)
        messageData.append(messageText.data(using: .utf8)!) // append strings
        return messageData
        
    }
}

func data_to_message(_ data: NSData) -> message {
    let bytes = data.bytes
    
    let timeSentInt = bytes.load(as:Int64.self)
    
    let sendIndex = Int(bytes.load(fromByteOffset: 8,  as:Int32.self))
    let recvIndex = Int(bytes.load(fromByteOffset: 12, as:Int32.self)) + sendIndex
    let msgIndex = Int(bytes.load(fromByteOffset:  16, as: Int32.self)) + recvIndex
    let range = NSMakeRange(20,msgIndex) // NSMakeRange is start, step not start, end
    
    let string = String(data: data.subdata(with: range), encoding: .utf8)!
    
    let sendingUser = String(string.prefix(sendIndex))
    var receivingUser = String(string.suffix(msgIndex-sendIndex))
    receivingUser = String(receivingUser.prefix(recvIndex-sendIndex))
    let messageText = String(string.suffix(msgIndex-recvIndex))
    
    return message(sendingUser: sendingUser, receivingUser: receivingUser, messageText: messageText, timeSent: timeSentInt)
    
}

let periph_man = PeripheralMan()
start_advertising(periph_man: periph_man)
while (true){
    usleep(100000)
    //print("huH")
}



/*
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
while (central_man.connectedUsers.count == 0){
    usleep(1000)
}
print("Have found other user to connect to. Typing sends a message to them")
var to_send: String
while (true){
    to_send = readLine()!
    print("Sending message \(to_send) to peripheral \(central_man.connectedUsers[0])")
    send_message(central_man.connectedUsers[0], central: central_man, message: to_send)
}
*/
