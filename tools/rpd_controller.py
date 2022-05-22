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
from unittest import case
from rpd_modules.serial_interface import rpd_serial_interface
from rpd_modules.regs import *
import wfdb
import matplotlib.pyplot as plt

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
        self.serial_interface.write(tx_byte)

    def write_reg(self, rpd_reg_addr, data):
        self.write([self.addr_to_frame(rpd_reg_addr,transaction_type.W)])
        self.write(data)

    def read_reg(self, rpd_reg_addr):
        self.write([self.addr_to_frame(rpd_reg_addr,transaction_type.R)])
        return self.read()[0]

    def write_CR(self, data):
        self.write_reg(rpd_reg_addr.CR, data)

    def write_DIN(self, data):
        self.write_reg(rpd_reg_addr.DINL, [data & 0xff])
        self.write_reg(rpd_reg_addr.DINH, [(data>>8) & 0xff])

    def read_CR(self):
        return self.read_reg(rpd_reg_addr.CR)

    def read_SR(self):
        return self.read_reg(rpd_reg_addr.SR)

    def read_DOUT(self):
        doutl = self.read_reg(rpd_reg_addr.DOUTL)
        doutm = self.read_reg(rpd_reg_addr.DOUTM)
        douth = self.read_reg(rpd_reg_addr.DOUTH)
        return (douth << 16) | (doutm << 8) | doutl

    def read_reg_bit(self, reg, field):
        return ((reg & 1 << field) >> field)

    def is_tx_fifo_e(self, status_reg):
        return self.read_reg_bit(status_reg, SR_field.TX_FIFO_EMPTY.value)

    def is_tx_fifo_f(self, status_reg):
        return self.read_reg_bit(status_reg, SR_field.TX_FIFO_FULL.value)

    def is_rx_fifo_e(self, status_reg):
        return self.read_reg_bit(status_reg, SR_field.RX_FIFO_EMPTY.value)

    def is_rx_fifo_f(self, status_reg):
        return self.read_reg_bit(status_reg, SR_field.RX_FIFO_FULL.value)

    def is_alg_active(self, status_reg):
        return self.read_reg_bit(status_reg, SR_field.ALG_ACTIVE.value)

    def is_th_initialised(self, status_reg):
        return self.read_reg_bit(status_reg, SR_field.TH_INITED.value)

    def is_ma_s_vld(self, status_reg):
        return self.read_reg_bit(status_reg, SR_field.MA_S_VLD.value)

    def is_ma_l_vld(self, status_reg):
        return self.read_reg_bit(status_reg, SR_field.MA_L_VLD.value)

    def sel_src(self, signal_src):
        control_reg = self.read_CR()
        if signal_src == sig_src.ADC:
            control_reg = control_reg | CR_field.SRC_SEL.value
        else:
            control_reg = control_reg & ~CR_field.SRC_SEL.value
        self.write_CR([control_reg])

    def sel_alg_state(self, algorithm_state):
        control_reg = self.read_CR()
        if algorithm_state == alg_state.ENABLED:
            control_reg = control_reg | CR_field.EN.value
        else:
            control_reg = control_reg & ~CR_field.EN.value
        self.write_CR([control_reg])

if __name__ == "__main__":
    rpd_controller = rpd_controller()
    print("hedsfsllo")
    #arr = (1024).to_bytes()
    #ecg_valueL = bytes([255])
    rpd_controller.sel_src(sig_src.UART)
    rpd_controller.sel_alg_state(alg_state.ENABLED)
    rpd_controller.sel_alg_state(alg_state.DISABLED)
    #time.sleep(5)
    sr = rpd_controller.read_SR()
    print("{:b}".format(sr))
    print(rpd_controller.is_alg_active(sr))
    print(rpd_controller.is_th_initialised(sr))
    print(rpd_controller.is_tx_fifo_e(sr))
    for i in range(360*4):
        rpd_controller.write_DIN(2047)
        #print(rpd_controller.is_rx_fifo_e(rpd_controller.read_SR()))
    sr = rpd_controller.read_SR()
    print("{:b}".format(sr))
    print(rpd_controller.is_alg_active(sr))
    print(rpd_controller.is_th_initialised(sr))
    print(rpd_controller.is_tx_fifo_e(sr))
    sr = rpd_controller.read_SR()
    print(rpd_controller.read_DOUT())
    print(rpd_controller.is_tx_fifo_e(sr))
    sr = rpd_controller.read_SR()
    print(rpd_controller.read_DOUT())
    print(rpd_controller.is_tx_fifo_e(sr))
    #time.sleep(5)
    #print(rpd_controller.addr_to_frame(rpd_reg_addr.SR,transaction_type.R))
    #print(rpd_controller.addr_to_frame(rpd_reg_addr.SR,transaction_type.W))

    #print(rpd_controller.addr_to_frame(rpd_reg_addr.DINL,transaction_type.R))
    #print(rpd_controller.addr_to_frame(rpd_reg_addr.DINL,transaction_type.W))


    #for i in range(255):
        #rpd_controller.write([i])
        #time.sleep(1)


