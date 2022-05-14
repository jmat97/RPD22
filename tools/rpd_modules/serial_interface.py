# Copyright (C) 2020  AGH University of Science and Technology
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

import errno, serial, sys
import serial.tools.list_ports

class rpd_serial_interface():
    def __init__(self, port='/dev/ttyS4', baudrate=115200, timeout=1):
        try:
            self.serial_port = serial.Serial(port, baudrate, timeout=timeout, stopbits=serial.STOPBITS_TWO)
        except serial.SerialException:
            plist = list(serial.tools.list_ports.comports())
            print('error: Port {} can\'t be opened.'.format(port))
            for i in range(len(plist)):
                print(plist[i])
            sys.exit(errno.EIO)

    def write(self, data):
        self.serial_port.write(data)

    def read(self, len):
        return self.serial_port.read(len)


    #def write_byte(self, data_byte):
        #self.serial_port.write(data_byte)



