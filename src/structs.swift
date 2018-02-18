import Foundation
import CoreBluetooth

struct user {
    let name: String // Name that they broadcast with
    var lastSeen: Int64
    var firstSeen: Int64? // same as before since they first came around. This is an identifier.
    let peripheral: CBPeripheral?
    
    
    init(name: String, firstSeen: Int64?, peripheral: CBPeripheral?) {
        self.firstSeen = firstSeen
        self.lastSeen = getTime()
        self.name = name
        self.peripheral = peripheral
    }
    
    func user_to_data() -> NSData {
        let messageData = NSMutableData(length: 0)!
        
        var firstSeenNum = firstSeen
        let firstSeenData = NSData(bytes: &firstSeenNum, length:8)
        messageData.append(firstSeenData as Data)
        
        messageData.append(name.data(using: .utf8)!)
        
        return messageData
    }
}
func getTime() -> Int64 {
    return Int64(NSDate().timeIntervalSince1970 * 1000)
}
extension user: Hashable {
    
    var hashValue: Int {
        if (firstSeen == nil){
            return name.hashValue
        }
        else {
            return name.hashValue + firstSeen!.hashValue
        }
    }
    
    static func == (first: user, second: user) -> Bool {
        if (first.firstSeen == nil || second.firstSeen == nil){
            return (first.name == second.name)
        }
        else{
            return (first.name == second.name) && (first.firstSeen! == second.firstSeen!)
        
        }
    }
}

let name = Host.current().localizedName ?? ""
let selfUser = user(name: name, firstSeen: getTime(), peripheral: nil)
var allUsers = [user]()
var firstSeenToUser = [Int64: user]()

func data_to_user(_ data: NSData) -> user {
    let firstSeen = data.bytes.load(as:Int64.self)

    let range = NSMakeRange(8,data.length-8)
    let name = String(data: data.subdata(with: range), encoding: .utf8)!
    
    return user(name:name,firstSeen: firstSeen ,peripheral: nil)
}

func testUserData(){
    let testUser = user(name: "testUser", firstSeen: 12961, peripheral:nil)
    print("User originally: \(testUser)")
    let data = testUser.user_to_data()
    print("User -> Data: \(data)")
    let usr = data_to_user(data)
    print("User -> Data -> User: \(usr)")
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
    var peripheral = otherUser.peripheral
    if (peripheral == nil) {
        print("You tried to send a message to \(otherUser) but they have no peripheral. This probably means they are a user we are connected through by an intermediary. Messaging is not implemented yet.")
        return
    }
    peripheral = peripheral!
    
    let msg = message(sendingUser:selfUser,receivingUser:otherUser,messageText:messageText,timeSent:getTime())
    
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

func update_user_list(){ // Separate thread that runs and tries to continuously update
    print("update_user_list called")
    var lastAsked = [user: Double]() // don't ask more than every 10 seconds
    while (true){
        for user in central_man.connectedUsers { // for each peripheral connected to
            
            if let lastAskedUser = lastAsked[user] {
                if (lastAskedUser - NSDate().timeIntervalSince1970) < 10 {
                    continue
                }
            }
            
            let peripheral = user.peripheral!
            let service = peripheral.services![0]
            
            var userCharacteristic: CBCharacteristic?
            for characteristic in service.characteristics! {
                if characteristic.uuid == userReadCharacteristicUUID {
                    userCharacteristic = characteristic
                }
            }
            
            if userCharacteristic == nil {
                print("While trying to update user list from \(user), was unable to find userReadCharacteristic")
                continue
            }
            
            peripheral.readValue(for: userCharacteristic!) // Calls peripheralDelegate when value is read
            lastAsked[user] = NSDate().timeIntervalSince1970
        }
        usleep(1000000)
    }
}

func receiveMessage(_ msg: message){
    print("\(msg.sendingUser.name): \(msg.messageText)")
}
