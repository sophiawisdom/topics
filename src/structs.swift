import Foundation
import CoreBluetooth

struct user {
    let name: String // Name that they broadcast with
    var lastSeen: Int64
    var firstSeen: Int64? // same as before since they first came around. This is an identifier.
    var peripheral: CBPeripheral?
    
    
    init(name: String, firstSeen: Int64?, peripheral: CBPeripheral?) { // Names can only be 8 letters long
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

func data_to_user(_ data: NSData) -> user {
    let firstSeen = data.bytes.load(as:Int64.self)

    let range = NSMakeRange(8,data.length-8)
    let name = String(data: data.subdata(with: range), encoding: .utf8)!
    
    return user(name:name,firstSeen: firstSeen ,peripheral: nil)
}

func testUserData(){
    let testUser = user(name: "testUser", firstSeen: getTime(), peripheral:nil)
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
extension message: Hashable {
    
    var hashValue: Int {
        return sendingUser.hashValue + receivingUser.hashValue + messageText.hashValue + timeSent.hashValue
    }
    
    static func == (first: message, second: message) -> Bool {
        let usr = (first.sendingUser == second.sendingUser) && (first.receivingUser == second.receivingUser)
        let msg = first.messageText == second.messageText
        let time = first.timeSent == second.timeSent
        return usr && msg && time // Maybe this is too time inefficient?
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

func getCharacteristic(_ peripheral:CBPeripheral, characteristicUUID: CBUUID) -> CBCharacteristic {
    var writeCharacteristic: CBCharacteristic!
    var service_to_write: CBService! // To find the write characteristic you have to find the service
    for service in peripheral.services! {
        if (service.uuid == identifierServiceUUID){
            service_to_write = service
        }
    }
    if (service_to_write == nil){ // didn't find one
        print("Not able to find message service")
        return writeCharacteristic
    }
    
    for characteristic in service_to_write.characteristics! {
        if (characteristic.uuid == characteristicUUID){
            writeCharacteristic = characteristic
        }
    }
    return writeCharacteristic
}

func send_message(_ otherUser:user,messageText:String){
    let msg = message(sendingUser:selfUser,receivingUser:otherUser,messageText:messageText,timeSent:getTime())
    if (otherUser.peripheral == nil) { // Have to route message to them instead of direct send
        print("You tried to send a message to \(otherUser) but they have no peripheral. This probably means they are a user we are connected through by an intermediary. Messaging is not implemented yet.")
        for user in central_man.connectedUsers {
            let characteristic = getCharacteristic(user.peripheral!, characteristicUUID: messageWriteOtherCharacteristicUUID)
            user.peripheral!.writeValue(msg.message_to_data() as Data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    let characteristic = getCharacteristic(otherUser.peripheral!, characteristicUUID: messageWriteDirectCharacteristicUUID)
    
    otherUser.peripheral!.writeValue(msg.message_to_data() as Data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    
}

func updateUserList(){ // Separate thread that runs and tries to continuously update
    print("update_user_list called")
    var lastAsked = [user: Int64]() // don't ask more than every 10 seconds
    while (true){
        
        for usr in central_man.connectedUsers { // for each peripheral connected to
            if (usr.firstSeen == 0){
                usleep(100000)
                continue
            }
            
//            print("Just started updateUserList loop for user \(user.firstSeen)")
            
            if let lastAskedUser = lastAsked[usr] {
                if (lastAskedUser - getTime()) < 1000 {
                    continue
                }
            }
            else {
                lastAsked[usr] = getTime()
            }
//            print("Got through optionals")
            
            let peripheral = usr.peripheral!
            print("Getting services: \(peripheral.services!)")
            let service = peripheral.services![0]
            
//            print("Got past initialization")
            
            var userCharacteristic: CBCharacteristic?
            for characteristic in service.characteristics! {
                if characteristic.uuid == userReadCharacteristicUUID {
                    userCharacteristic = characteristic
                }
            }
            
//            print("Found characteristic")
            
            if userCharacteristic == nil {
                print("While trying to update user list from \(usr), was unable to find userReadCharacteristic")
                continue
            }
            
 //           print("Reading value")
            
            peripheral.readValue(for: userCharacteristic!) // Calls peripheralDelegate when value is read
            lastAsked[usr] = getTime()
        }
        usleep(100000)
    }
}

func start_advertising(_ periph_man: PeripheralMan!){
    
    var firstSeenn = selfUser.firstSeen
    let firstSeen = NSData(bytes: &firstSeenn, length:4) as Data
    
    let messageWriteDirectCharacteristic = CBMutableCharacteristic(type: messageWriteDirectCharacteristicUUID, properties: [.write], value: nil, permissions: [.writeable])
    let userReadCharacteristic = CBMutableCharacteristic(type: userReadCharacteristicUUID, properties: [.read], value: nil, permissions: [.readable])
    let getInitialUserCharacteristic = CBMutableCharacteristic(type: getInitialUserCharacteristicUUID, properties: [.read], value: firstSeen, permissions: [.readable])
    let messageWriteOtherCharacteristic = CBMutableCharacteristic(type: messageWriteOtherCharacteristicUUID, properties: [.write], value: nil, permissions: [.writeable])
    let identifierService = CBMutableService(type:identifierServiceUUID, primary:true)
    
    
    identifierService.characteristics = [messageWriteDirectCharacteristic, userReadCharacteristic, getInitialUserCharacteristic ,messageWriteOtherCharacteristic] // The insight is that the characteristics are just headers
    let advertisementData: [String : Any] = [CBAdvertisementDataServiceUUIDsKey:[identifierServiceUUID]] // Name doesn't matter
    print("Advertising with data \(advertisementData)")
    if(periph_man.peripheralManager.state == .poweredOn) { //just prints out what state the peripheral is in, if it's not on something is probably going wrong
        if(!periph_man.peripheralManager.isAdvertising) {
            periph_man.peripheralManager.removeAllServices() //?
            periph_man.peripheralManager.add(identifierService)
            usleep(100000)
            periph_man.peripheralManager.startAdvertising(advertisementData)
            while (!periph_man.peripheralManager.isAdvertising){
                usleep(10000)
            }
        }
        if (!periph_man.peripheralManager.isAdvertising){
            print("Something went wrong. Peripheral manager is not advertising.")
        } // Expect it to be advertising
        
    }
    else {
        print("PeripheralManager state is not powered on. Perhaps your bluetooth is off.")
    }
}

func receiveMessage(_ msg: message){
    
    if (msg.receivingUser == selfUser) {
        print("\(msg.sendingUser.name): \(msg.messageText)") // more processing later
        return
    }
    else {
        print("receiving user: \(msg.receivingUser) self user: \(selfUser) sending user: \(msg.sendingUser)")
//        print("receiveMessage called on message sent by \(msg.sendingUser) to \(msg.receivingUser). This is a bug and should not happen.")
    }
}

let name = Host.current().localizedName ?? ""
let selfUser = user(name: name, firstSeen: getTime(), peripheral: nil)
var allUsers = [user]()
var firstSeenToUser = [Int64: user]()
var recentMessages: Set<message> = []
