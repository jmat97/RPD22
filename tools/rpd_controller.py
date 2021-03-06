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
import errno, queue, signal, sys, threading, time, io, csv
from unittest import case
from rpd_modules.serial_interface import rpd_serial_interface
from rpd_modules.regs import *
import wfdb
import matplotlib.pyplot as plt
import numpy as np

class rpd_controller:
    output_res = np.array([], dtype=np.uint32)
    def __init__(self):
        self.close_requested = 0
        self.serial_interface = rpd_serial_interface('COM6', 250000, 1)
        self.alg_reset()
        self.sel_alg_state(alg_state.ENABLED)
        self.sel_src(sig_src.UART)

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
        print("{:02X}{:02X}{:02X}".format(douth, doutm, doutl))
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

    def alg_reset(self):
        control_reg = self.read_CR()
        control_reg = control_reg | CR_field.RST.value
        self.write_CR([control_reg])

    def collect_dout(self):
        sr = self.read_SR()
        while self.is_tx_fifo_e(sr) == 0:
            self.output_res = np.append(self.output_res,  self.read_DOUT())
            sr = self.read_SR()
            if self.is_tx_fifo_e(sr):
                break

    def run_alg(self, record):
        for i in range(record.sig_len):
            self.write_DIN(record.d_signal[i][0])
            if ((i % 100000) ==0):
                self.collect_dout()
        self.collect_dout()

    def report_sr(self, sr):
        print("Algorithm status: {:b}".format(rpd_controller.is_alg_active(sr)))
        print("Threshold status: {:b}".format(rpd_controller.is_th_initialised(sr)))
        print("TX fifo E status: {:b}".format(rpd_controller.is_tx_fifo_e(sr)))

def write_res_to_file(start_time, record):
    with io.open('results/' + start_time + '_{}'.format(record.record_name) +'.csv', mode='w', newline='') as file:
        writer = csv.writer(file)
        for i in range(len(rpd_controller.output_res)):
            writer.writerow([i, rpd_controller.output_res[i]])


if __name__ == "__main__":
    rpd_controller = rpd_controller()
    recordings = [101]

    for j in range(len(recordings)):
        path = 'tools/mit_bih_arrhythmia_database/{}'.format(recordings[j])
        print(path)
        record = wfdb.rdrecord(path)
        record.adc(inplace=True)
        start_time = time.strftime("%Y%m%d%H%M%S")
        rpd_controller.run_alg(record)
        print(rpd_controller.output_res)
        write_res_to_file(start_time,record)


