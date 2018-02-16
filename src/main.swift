import Foundation
import CoreBluetooth

let messageServiceUUID = CBUUID(string: "b839e0d3-de74-4493-860b-00600deb5e00")
let messageCharacteristicUUID = CBUUID(string: "fc36344b-bcda-40ca-b118-666ec767ab20")
var queue: DispatchQueue!
if #available(OSX 10.10, *) {
    queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
} else {
    print("DispatchQueue not available on your version of MacOSX. Please update to 10.10 or greater.")
}


struct user {
    let name: String
    var lastSeen: Int64 // timestamp since epoch in milliseconds
    let identifier: String?
    func user_to_data() -> NSData {
        let messageData = NSMutableData(length: 0)!
        
        var lastSeenNum = lastSeen
        let lastSeenData = NSData(bytes: &lastSeenNum, length:8)
        messageData.append(lastSeenData as Data)
        
        var isIdentifier:Int8
        if (identifier != nil){
            isIdentifier = Int8(identifier!.utf8.count)
        }
        else {
            isIdentifier = 0
        }
        let isIdentifierData = NSData(bytes: &isIdentifier, length:1) // Bools are int8 behind the scenes
        messageData.append(isIdentifierData as Data)
        if let iden = identifier {
            messageData.append(iden.data(using: .utf8)!)
        }
        messageData.append(name.data(using: .utf8)!)
        
        return messageData
    }
}

let name = Host.current().localizedName ?? ""
let selfUser = user(name: name, lastSeen: 0, identifier: "identifier_self")
let testUser = user(name:"test", lastSeen: 1251231, identifier: "identifier_test")

print("Your computers name is \(name)")

func data_to_user(_ data: NSData) -> user {
    var identifier: String?
    let lastSeen = data.bytes.load(as:Int64.self)
    let isIdentifier = Int(data.bytes.load(fromByteOffset: 8,  as:Int8.self))
    let range = NSMakeRange(9,data.length-9)
    var name = String(data: data.subdata(with: range), encoding: .utf8)!
    print("Total string is \(name)")
    if (isIdentifier != 0){
        identifier = String(name.prefix(isIdentifier))
        name = String(name.suffix(name.count-isIdentifier))
    }
    return user(name:name,lastSeen:lastSeen,identifier:identifier)
    
}
struct message {
    let sendingUser: user
    let receivingUser: user
    let messageText: String // Every text component can be of unlimited length (other than bluetooth limits).
    let timeSent: Int64 // timestamp since epoch in milliseconds
    func message_to_data() -> NSData { // This probably causes a memory leak because I don't know how pointers work
        let messageData = NSMutableData(length: 0)! // Length initialized at 0 because appending is easy
        
        var timeSentInt = Int64(timeSent) // Needed for pointer math
        let timeSentIntData = NSData(bytes: &timeSentInt, length: 8) // int64 take 8 bytes
        messageData.append(timeSentIntData as Data)
        
        
        // Append string lengths
        let sendingUserData = sendingUser.user_to_data()
        var lengthSend = Int32(sendingUserData.length)
        messageData.append(NSData(bytes: &lengthSend, length: 4) as Data)
        
        let receivingUserData = receivingUser.user_to_data()
        var lengthRecv = Int32(receivingUserData.length)
        messageData.append(NSData(bytes: &lengthRecv, length: 4) as Data)
        
        var lengthMsg = Int32(messageText.utf8.count)
        messageData.append(NSData(bytes: &lengthMsg, length: 4) as Data)
        
        
        messageData.append(sendingUserData as Data)
        messageData.append(receivingUserData as Data)
        messageData.append(messageText.data(using: .utf8)!) // append strings
        
        return messageData // Overall structure: two bytes timeSent, three int32s describing how long sending user, receiving user, and message text are, then those texts in that order.
        
    }
}

func data_to_message(_ data: NSData) -> message {
    let bytes = data.bytes
    
    let timeSentInt = bytes.load(as:Int64.self)
    
    let sendLen = Int(bytes.load(fromByteOffset: 8,  as:Int32.self))
    let recvLen = Int(bytes.load(fromByteOffset: 12, as:Int32.self))
    let msgIndex = Int(bytes.load(fromByteOffset:  16, as:Int32.self))
    
//    let string = String(data: data.subdata(with: range), encoding: .utf8)!
    
    var range = NSMakeRange(20,sendLen)
    let sendingUser = data_to_user(data.subdata(with: range) as NSData)
    range = NSMakeRange(20+sendLen,recvLen)
    let receivingUser = data_to_user(data.subdata(with: range) as NSData)
    
    range = NSMakeRange(20+sendLen+recvLen,msgIndex)
    let messageText = String(data: data.subdata(with: range), encoding: .utf8)!
    
    return message(sendingUser: sendingUser, receivingUser: receivingUser, messageText: messageText, timeSent: timeSentInt)
    
}

func send_message(_ peripheral:CBPeripheral,messageText:String){
    let currtime = Int64(NSDate().timeIntervalSince1970 * 1000)
    let otherUser = user(name:peripheral.name!, lastSeen: 0, identifier: "12412")
    let msg = message(sendingUser:selfUser,receivingUser:otherUser,messageText:messageText,timeSent:currtime)
    
    var service_to_write: CBService! // To find the write characteristic you have to find the service
    for service in peripheral.services! {
        if (service.uuid == messageServiceUUID){
            service_to_write = service
        }
    }
    if (service_to_write == nil){
        print("Not able to find message service")
        return
    }
    
    var characteristic_to_write: CBCharacteristic! // And then find the characteristic
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
    peripheral.writeValue(msg.message_to_data() as Data, for: characteristic_to_write, type: CBCharacteristicWriteType.withResponse)
    
}

var msg = message(sendingUser: selfUser, receivingUser: testUser, messageText: "Test message!", timeSent: 235235)
print("Message originally is \(msg)")
var msgData = msg.message_to_data()
print("Message -> data is \(msgData)")
var msgRedux = data_to_message(msgData)
print("Message -> data -> Message is \(msgRedux)")

let central_man = CentralMan()
let periph_man = PeripheralMan()

central_man.centralManager = CBCentralManager(delegate: central_man, queue: queue)
start_advertising(periph_man: periph_man) // better way to do this - block somewhere else

while (!(central_man.centralManager.state == .poweredOn)){ // wait until it powers on
    usleep(1000)
}

central_man.centralManager.scanForPeripherals(withServices:nil)

while (central_man.connectedUsers.count == 0){
    usleep(1000)
}
var to_send: String
print("SENDING TEXT TO \(central_man.connectedUsers[0].name!)")
while (true){
    to_send = readLine()!
    print("Sending message \(to_send) to peripheral \(central_man.connectedUsers[0].name!)")
    send_message(central_man.connectedUsers[0], messageText: to_send)
}
