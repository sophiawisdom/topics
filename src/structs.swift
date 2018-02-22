import Foundation
import CoreBluetooth

struct user {
    let name: String // Name that they broadcast with
    var lastSeen: Double
    var identifier: String
    var peripheral: CBPeripheral?
    
    
    init(name: String, identifier: String, peripheral: CBPeripheral?) { // Names can only be 8 letters long
        self.identifier = identifier
        self.lastSeen = getTime()
        self.name = name
        self.peripheral = peripheral
    }
    
    func user_to_data() -> NSData {
        let messageData = NSMutableData(length: 0)!
        
        messageData.append(identifier.data(using: .utf8)!)
        messageData.append(name.data(using: .utf8)!)
        
        return messageData
    }
}

func getTime() -> Double {
    return NSDate().timeIntervalSince1970
}

extension user: Hashable {
    
    var hashValue: Int {
        return name.hashValue ^ identifier.hashValue // Originally this was + instead of ^, but this can lead to an overflow if both numbers are large
    }
    
    static func == (first: user, second: user) -> Bool {
            return (first.name == second.name) && (first.identifier == second.identifier)
    }
}

func data_to_user(_ data: NSData) -> user {
    
    let rangeIdentifier = NSMakeRange(0,36)
    let identifier = String(data: data.subdata(with: rangeIdentifier), encoding: .utf8)!
    
    let rangeName = NSMakeRange(36,data.length-36)
    let name = String(data: data.subdata(with: rangeName), encoding: .utf8)!
    
    return user(name:name,identifier: identifier ,peripheral: nil)
}

func testUserData(){
    let testUser = user(name: "testUser", identifier: getHardwareUUID(), peripheral:nil)
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
    let timeSent: Double // timestamp since epoch in milliseconds
    func message_to_data() -> NSData { // This probably causes a memory leak because I don't know how pointers work
        let messageData = NSMutableData(length: 0)! // Length initialized at 0 because appending is easy
        
        var timeSentDbl = Double(timeSent) // Needed for pointer math
        let timeSentDblData = NSData(bytes: &timeSentDbl, length: 8) // Double take 8 bytes
        messageData.append(timeSentDblData as Data)
        
        
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
    
    let timeSentDbl = bytes.load(as:Double.self)
    
    let sendLen = Int(bytes.load(fromByteOffset: 8,  as:Int32.self))
    let recvLen = Int(bytes.load(fromByteOffset: 12, as:Int32.self))
    let msgIndex = Int(bytes.load(fromByteOffset:  16, as:Int32.self))
    
    var range = NSMakeRange(20,sendLen)
    let sendingUser = data_to_user(data.subdata(with: range) as NSData)
    range = NSMakeRange(20+sendLen,recvLen)
    let receivingUser = data_to_user(data.subdata(with: range) as NSData)
    
    range = NSMakeRange(20+sendLen+recvLen,msgIndex)
    let messageText = String(data: data.subdata(with: range), encoding: .utf8)!
    
    return message(sendingUser: sendingUser, receivingUser: receivingUser, messageText: messageText, timeSent: timeSentDbl)
    
}

func getCharacteristic(_ peripheral:CBPeripheral, characteristicUUID: CBUUID) throws -> CBCharacteristic {
    var writeCharacteristic: CBCharacteristic!
    var service_to_write: CBService! // To find the write characteristic you have to find the service
    for service in peripheral.services! {
        if (service.uuid == identifierServiceUUID){
            service_to_write = service
        }
    }
    if (service_to_write == nil){ // didn't find one
        print("Not able to find message service")
        throw(messageSendError.servicesNotFound)
    }
    
    for characteristic in service_to_write.characteristics! {
        if (characteristic.uuid == characteristicUUID){
            writeCharacteristic = characteristic
        }
    }
    return writeCharacteristic
}

func sendMessage(_ otherUser:user,messageText:String) throws {
    let msg = message(sendingUser:selfUser,receivingUser:otherUser,messageText:messageText,timeSent:getTime())
    if (otherUser.peripheral == nil) { // Have to route message to them instead of direct send
        print("You tried to send a message to \(otherUser) but they have no peripheral. This probably means they are a user we are connected through by an intermediary. Messaging is not implemented yet.")
        for user in central_man.connectedUsers {
            do {
                let characteristic = try getCharacteristic(user.peripheral!, characteristicUUID: messageWriteOtherCharacteristicUUID)
                user.peripheral!.writeValue(msg.message_to_data() as Data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            }
            catch {} // Do nothing if getting the characteristic fails because we just send it to other users
        }
    }
    else {
        do {
            let characteristic = try getCharacteristic(otherUser.peripheral!, characteristicUUID: messageWriteDirectCharacteristicUUID)
            otherUser.peripheral!.writeValue(msg.message_to_data() as Data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
        catch {
            throw(messageSendError.notConnected)
        }
        
    }
}

func updateUserList(){ // Separate thread that runs and tries to continuously update
    print("update_user_list called")
    var lastAsked = [user: Double]() // don't ask more than every 10 seconds
    while (true){
        
        for usr in central_man.connectedUsers { // for each peripheral connected to
            
//            print("Just started updateUserList loop for user \(usr)")
            
            if let lastAskedUser = lastAsked[usr] {
                if (lastAskedUser - getTime()) < 1 {
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
    
    let messageWriteDirectCharacteristic = CBMutableCharacteristic(type: messageWriteDirectCharacteristicUUID, properties: [.write], value: nil, permissions: [.writeable])
    let userReadCharacteristic = CBMutableCharacteristic(type: userReadCharacteristicUUID, properties: [.read], value: nil, permissions: [.readable])
    let getInitialUserCharacteristic = CBMutableCharacteristic(type: getInitialUserCharacteristicUUID, properties: [.read], value: selfUser.user_to_data() as Data, permissions: [.readable])
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

func randomString(length: Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let len = UInt32(letters.length)
    
    var randomString = ""
    
    for _ in 0 ..< length {
        let rand = arc4random_uniform(len)
        var nextChar = letters.character(at: Int(rand))
        randomString += NSString(characters: &nextChar, length: 1) as String
    }
    
    return randomString
}

func makeDummyUser() -> user{ // for testing purposes
    let name = randomString(length: 10)
    let usr = user(name:name, identifier:getHardwareUUID(), peripheral:nil)
    allUsers.append(usr)
    identifierToUser[usr.identifier] = usr
    print("Generated dummy user \(usr)")
    return usr
}

func receiveMessage(_ msg: message){
    
    if (msg.receivingUser == selfUser) {
        print("\(msg.sendingUser.name): \(msg.messageText)") // more processing later
        if chatHistory[msg.sendingUser] != nil {
            chatHistory[msg.sendingUser]!.append(msg)
        }
        else {
            chatHistory[msg.sendingUser] = [msg]
        }
        return
    }
    else {
        print("receiving user: \(msg.receivingUser) self user: \(selfUser) sending user: \(msg.sendingUser)")
//        print("receiveMessage called on message sent by \(msg.sendingUser) to \(msg.receivingUser). This is a bug and should not happen.")
    }
}

func discoverUser(_ usr: user){
}

func getHardwareUUID() throws -> String {
    
    var uuidRef:        CFUUID?
    var uuidStringRef:  CFString?
    var uuidBytes:      [CUnsignedChar] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    
    var ts = timespec(tv_sec: 0,tv_nsec: 0)
    
    gethostuuid(&uuidBytes, &ts)
    
    uuidRef = CFUUIDCreateWithBytes(
        kCFAllocatorDefault,
        uuidBytes[0],
        uuidBytes[1],
        uuidBytes[2],
        uuidBytes[3],
        uuidBytes[4],
        uuidBytes[5],
        uuidBytes[6],
        uuidBytes[7],
        uuidBytes[8],
        uuidBytes[9],
        uuidBytes[10],
        uuidBytes[11],
        uuidBytes[12],
        uuidBytes[13],
        uuidBytes[14],
        uuidBytes[15]
    )
    
    uuidBytes = []
    
    uuidStringRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef)
    
    if let str = uuidStringRef! as String {
        return str
    }
    else {
        throw
    }
    print("Attempting to get uuidString")
    return uuidStringRef! as String // Let it error out I guess
}

func getSystemSerialNumber(inout uuid: String) -> Bool {
    
    var ioPlatformExpertDevice:             io_service_t?
    var serialNumber:                       CFTypeRef?
    
    
    ioPlatformExpertDevice = IOServiceGetMatchingService(
        kIOMasterPortDefault,
        IOServiceMatching("IOPlatformExpertDevice").takeUnretainedValue()
    )
    
    if (ioPlatformExpertDevice != nil) {
        
        serialNumber = IORegistryEntryCreateCFProperty(
            ioPlatformExpertDevice!,
            "IOPlatformSerialNumber", // println(kIOPlatformSerialNumberKey);
            kCFAllocatorDefault,
            0
            ).takeRetainedValue()
        println(serialNumber);
    }
    
    IOObjectRelease(ioPlatformExpertDevice!)
    
    if (serialNumber != nil) {
        uuid = serialNumber! as NSString
        return true
    }
    
    return false
}

enum messageSendError: Error {
    case notConnected
    case servicesNotFound
    case unknownError
}

enum getUUIDError: Error {
    case notConnected
    case servicesNotFound
    case unknownError
}

var chatHistory = [user:[message]]()
let name = Host.current().localizedName ?? ""
let selfUser = user(name: name, identifier: getHardwareUUID(), peripheral: nil)
var allUsers = [user]()
var identifierToUser = [String: user]()
var recentMessages: Set<message> = []
