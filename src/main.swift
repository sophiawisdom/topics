import Foundation
import CoreBluetooth

let central_man = CentralMan()
start_advertising(periph_man: PeripheralMan())

while (true){
    usleep(10000)
}
