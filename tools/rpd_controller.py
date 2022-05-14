#!/usr/bin/python3
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

from encodings import utf_8
import errno, queue, signal, sys, threading, time
from rpd_modules.serial_interface import rpd_serial_interface
from rpd_modules.reg_addr import rpd_reg_addr
from rpd_modules.reg_addr import transaction_type
class rpd_controller:
    def __init__(self):
        self.close_requested = 0
        self.serial_interface = rpd_serial_interface('COM6', 115200, 1)

    def addr_to_frame(self, addr, tran_type ):
        if(isinstance(addr,rpd_reg_addr) and isinstance(tran_type, transaction_type)):
            return {
                "R": addr.value[0]<<1,
                "W": (addr.value[0]<<1) | 1,
            } [tran_type.value]


    def read(self):
        return self.serial_interface.read(1)

    def write(self, tx_byte):
        self.serial_interface.write([tx_byte])

    def write_reg(self, rpd_reg_addr, data):
        self.write(self.addr_to_frame(rpd_reg_addr,transaction_type.W))
        self.write(data)

    def read_reg(self, rpd_reg_addr):
        self.write(self.addr_to_frame(rpd_reg_addr,transaction_type.R))
        print(self.addr_to_frame(rpd_reg_addr,transaction_type.R))
        return self.read()

    def write_CR(self, data):
        self.write_reg(rpd_reg_addr.CR, data)

    def write_DIN(self, data):
        self.write_reg(rpd_reg_addr.DINL, data&0xff)
        self.write_reg(rpd_reg_addr.DINH, (data>>8)&0xff)

    def read_CR(self):
        return self.read_reg(rpd_reg_addr.CR)

    def read_SR(self):
        return self.read_reg(rpd_reg_addr.SR)

    def read_DOUT(self, data):
        doutl = self.read_reg(rpd_reg_addr.DOUTL)
        doutm = self.read_reg(rpd_reg_addr.DOUTM)
        douth = self.read_reg(rpd_reg_addr.DOUTH)
        return (douth << 16) | (doutm << 8) | doutl

if __name__ == "__main__":
    rpd_controller = rpd_controller()
    print("hedsfsllo")
    #arr = (1024).to_bytes()
    #ecg_valueL = bytes([255])

    rpd_controller.write_DIN(8)
    print(rpd_controller.read_SR())
    #time.sleep(5)
    #print(rpd_controller.addr_to_frame(rpd_reg_addr.SR,transaction_type.R))
    #print(rpd_controller.addr_to_frame(rpd_reg_addr.SR,transaction_type.W))

    #print(rpd_controller.addr_to_frame(rpd_reg_addr.DINL,transaction_type.R))
    #print(rpd_controller.addr_to_frame(rpd_reg_addr.DINL,transaction_type.W))


    #for i in range(255):
        #rpd_controller.write([i])
        #time.sleep(1)


