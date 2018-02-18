/* Mostly "inspired" by https://medium.com/@shu223/core-bluetooth-snippets-with-swift-9be8524600b2 */

import Foundation
import CoreBluetooth

class PeripheralMan: NSObject, CBPeripheralManagerDelegate {
    var peripheralManager: CBPeripheralManager!
    
    

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    {
    }
    

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?)
    {
        if let error = error {
            print("Failed… error: \(error)")
            return
        }
    }

    func peripheralManager(peripheral: CBPeripheralManager, didAdd service: CBService, error: NSError?)
    {
        if let error = error {
            print("error: \(error)")
            return
        }

        print("service: \(service)")
    }
    func peripheralManager(_: CBPeripheralManager, didReceiveRead: CBATTRequest){
        let characteristic = didReceiveRead.characteristic
        if (characteristic.uuid == userReadCharacteristicUUID){
            let users = central_man.connectedUsers
            let responseData = NSMutableData(length: 0)! // length=0 because we will be appending
            for user in users {
                let userData = user.user_to_data()
                var userLength = Int32(userData.length) // var so we can reference memory location
                responseData.append(NSData(bytes: &userLength, length:4) as Data)
                responseData.append(userData as Data)
            }
            didReceiveRead.value = responseData as Data
            peripheralManager.respond(to: didReceiveRead, withResult: CBATTError.Code.success)
        }
        else if (characteristic.uuid == getFirstSeenCharacteristicUUID){
            
            var firstSeenn = selfUser.firstSeen
            let firstSeen = NSData(bytes: &firstSeenn, length:4) as Data
            didReceiveRead.value = firstSeen
            
            peripheralManager.respond(to: didReceiveRead, withResult: CBATTError.Code.success)
        }
        else {
            print("Received read request for characteristic other than userReadCharacteristic: \(characteristic)")
            peripheralManager.respond(to: didReceiveRead, withResult: CBATTError.Code.attributeNotFound)
        }
    }
    
    func peripheralManager(_: CBPeripheralManager, didReceiveWrite: [CBATTRequest]) { // In respond to write request
        let msg = data_to_message(_: didReceiveWrite[0].value! as NSData)
        print("User \(msg.sendingUser.name) sent me (\(msg.receivingUser.name)) a message: \(msg.messageText)")
        peripheralManager.respond(to: didReceiveWrite[0], withResult: CBATTError.Code.success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
    }

}

func start_advertising(_ periph_man: PeripheralMan!){
    
    var firstSeenn = selfUser.firstSeen
    let firstSeen = NSData(bytes: &firstSeenn, length:4) as Data
    
    let messageWriteCharacteristic = CBMutableCharacteristic(type: messageWriteCharacteristicUUID, properties: [.write], value: nil, permissions: [.writeable])
    let userReadCharacteristic = CBMutableCharacteristic(type: userReadCharacteristicUUID, properties: [.read], value: nil, permissions: [.readable])
    let getFirstSeenCharacteristic = CBMutableCharacteristic(type: getFirstSeenCharacteristicUUID, properties: [.read], value: firstSeen, permissions: [.readable])
    let identifierService = CBMutableService(type:identifierServiceUUID, primary:true)
    
    
    identifierService.characteristics = [messageWriteCharacteristic, userReadCharacteristic, getFirstSeenCharacteristic] // The insight is that the characteristics are just headers
    let advertisementData: [String : Any] = [CBAdvertisementDataLocalNameKey : name.prefix(8),CBAdvertisementDataServiceUUIDsKey:[identifierServiceUUID]]
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





