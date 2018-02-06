/* Mostly "inspired" by https://medium.com/@shu223/core-bluetooth-snippets-with-swift-9be8524600b2 */

import Foundation
import CoreBluetooth

class PeripheralMan: NSObject, CBPeripheralManagerDelegate {
    var peripheralManager: CBPeripheralManager!
    
    

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    {
        //print("PeripherManager state has changed to \(peripheral.state)")
    }
    

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager,
                                             error: Error?)
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

}





