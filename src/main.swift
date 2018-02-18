/* TODO
        Implement sending messages between several users:
            Implement spreading user lists around and keeping them fresh
                Implement user pings
                Implement new user procedure
            Implement sending messages
                Implement sending messages around as sender - scattering seeds
                Implement being carrier for a message
                    Not sending more if you've found the right person, not sending same message twice
        Implement actual fucking UI
 */

/* Okay let's trace back the user propogation process
 first a new user starts up and starts advertising
 They are discovered by everyone around them, and when they connect they are added to the list of users and also asked for their firstSeen. This is necessary because firstSeen is effectively an
 identifier, and if everyone just got the time they received the advertisement there wouldn't be agreement on who was around.
 They are then added to the list of people to poll
 */


import Foundation
import CoreBluetooth

let identifierServiceUUID = CBUUID(string: "b839e0d3-de74-4493-860b-00600deb5e00")
let messageWriteCharacteristicUUID = CBUUID(string: "fc36344b-bcda-40ca-b118-666ec767ab20")
let userReadCharacteristicUUID = CBUUID(string: "b8e0fee5-d132-4410-a09f-e584e64a115d")
let getFirstSeenCharacteristicUUID = CBUUID(string: "7ade0d09-f195-4afe-b476-675ee4476ddf")

// Initialize both Central and Peripheral

let central_man = CentralMan()
let periph_man = PeripheralMan()

var queue: DispatchQueue!
if #available(OSX 10.10, *) {
    queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
} else {
    print("This program can only be run on OSX 10.10 or greater. Please update.")
}
central_man.centralManager = CBCentralManager(delegate: central_man, queue: queue)

var queue2: DispatchQueue!
if #available(OSX 10.10, *) {
    queue2 = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
} else {
    print("This program can only be run on OSX 10.10 or greater. Please update.")
}
periph_man.peripheralManager = CBPeripheralManager(delegate: periph_man, queue: queue2)

// This version is slight faster than waiting for each of them in turn. It should be more or less as fast as possible within two milliseconds.

while (!(central_man.centralManager.state == .poweredOn) && !(periph_man.peripheralManager.state == .poweredOn)){
    usleep(1000)
}
if central_man.centralManager.state == .poweredOn {
    central_man.centralManager.scanForPeripherals(withServices:nil)
    while (!(periph_man.peripheralManager.state == .poweredOn)) {
        usleep(1000)
    }
    start_advertising(periph_man)
}
else if periph_man.peripheralManager.state == .poweredOn {
    start_advertising(periph_man)
    while (!(central_man.centralManager.state == .poweredOn)) {
        usleep(1000)
    }
    central_man.centralManager.scanForPeripherals(withServices:nil)
}

central_man.connectedUsers.append(selfUser) // Need to include self for list of users
DispatchQueue.global(qos: .background).async { // Run background thread to update the list of users we have
    
    update_user_list()
    
    DispatchQueue.main.async {
    }
}


while (central_man.connectedUsers.count == 0){
    usleep(1000)
}

let receivingUser = central_man.connectedUsers[0]
print("SENDING TEXT TO \(receivingUser)")

var to_send: String
while (true){
    to_send = readLine()!
    print("Sending message \(to_send) to peripheral \(receivingUser.name)")
    send_message(receivingUser, messageText: to_send)
}
