import Foundation
import CoreBluetooth

struct user {
    let name: String
    var lastSeen: Int64 // timestamp since epoch in milliseconds
    var identifier: String?
    let peripheral: CBPeripheral?
    
    
    init(name: String, lastSeen: Int64?, peripheral: CBPeripheral?) {
        if (lastSeen == nil){
            self.lastSeen = Int64(NSDate().timeIntervalSince1970 * 1000)
        }
        else {
            self.lastSeen = lastSeen!
        }
        self.name = name
        self.peripheral = peripheral
        if (peripheral != nil){
            if #available(OSX 10.13,*){
                self.identifier = peripheral!.identifier.uuidString
            }
            else {
            }
        }
    }
    
    func user_to_data() -> NSData {
        let messageData = NSMutableData(length: 0)!
        
        var lastSeenNum = lastSeen
        let lastSeenData = NSData(bytes: &lastSeenNum, length:8)
        messageData.append(lastSeenData as Data)
        
        messageData.append(name.data(using: .utf8)!)
        
        return messageData
    }
}

extension user: Hashable {
    var hashValue: Int {
        return name.hashValue + lastSeen.hashValue
    }
    
    static func == (first: user, second: user) -> Bool {
        return (first.name == second.name) && (first.lastSeen == second.lastSeen)
    }
}
let name = Host.current().localizedName ?? ""
let selfUser = user(name: name, lastSeen: nil, peripheral: nil)


func data_to_user(_ data: NSData) -> user {
    let lastSeen = data.bytes.load(as:Int64.self)
    let range = NSMakeRange(8,data.length-8)
    let name = String(data: data.subdata(with: range), encoding: .utf8)!
    return user(name:name,lastSeen:lastSeen,peripheral: nil)
    
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
    
    var range = NSMakeRange(20,sendLen)
    let sendingUser = data_to_user(data.subdata(with: range) as NSData)
    range = NSMakeRange(20+sendLen,recvLen)
    let receivingUser = data_to_user(data.subdata(with: range) as NSData)
    
    range = NSMakeRange(20+sendLen+recvLen,msgIndex)
    let messageText = String(data: data.subdata(with: range), encoding: .utf8)!
    
    return message(sendingUser: sendingUser, receivingUser: receivingUser, messageText: messageText, timeSent: timeSentInt)
    
}

func send_message(_ otherUser:user,messageText:String){
    let currtime = Int64(NSDate().timeIntervalSince1970 * 1000)
    var peripheral = otherUser.peripheral
    if (peripheral == nil) {
        print("You tried to send a message to \(otherUser) but they have no peripheral. This probably means they are a user we are connected through by an intermediary. Messaging is not implemented yet.")
        return
    }
    peripheral = peripheral!
    
    let msg = message(sendingUser:selfUser,receivingUser:otherUser,messageText:messageText,timeSent:currtime)
    
    var service_to_write: CBService! // To find the write characteristic you have to find the service
    for service in peripheral!.services! {
        if (service.uuid == identifierServiceUUID){
            service_to_write = service
        }
    }
    if (service_to_write == nil){ // didn't find one
        print("Not able to find message service")
        return
    }
    
    var characteristic_to_write: CBCharacteristic! // And then find the characteristic
    for characteristic in service_to_write.characteristics! {
        if (characteristic.uuid == messageWriteCharacteristicUUID){
            characteristic_to_write = characteristic
        }
    }
    if (characteristic_to_write == nil) { // didn't find one
        print("Not able to find message characteristic")
        return
    }
    characteristic_to_write = characteristic_to_write!
    
    peripheral!.writeValue(msg.message_to_data() as Data, for: characteristic_to_write, type: CBCharacteristicWriteType.withResponse)
    
}