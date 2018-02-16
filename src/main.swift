import Foundation
import CoreBluetooth

let periph_man = PeripheralMan()
//let central_man = CentralMan()
//start_advertising(periph_man:periphMan)
start_advertising(periph_man: periph_man)
while (true){
    usleep(100000)
    //print("huH")
}

