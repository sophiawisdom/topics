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
        receiveMessage(msg)
        peripheralManager.respond(to: didReceiveWrite[0], withResult: CBATTError.Code.success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
    }
}



