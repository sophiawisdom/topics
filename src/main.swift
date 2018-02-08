import Foundation
import CoreBluetooth

let periph_man = PeripheralMan()
let central_man = CentralMan()
start_advertising()

while (true){
    usleep(10000)
}
