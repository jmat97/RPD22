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
from enum import Enum


class rpd_reg_addr(Enum):
    CR = b'\x00'
    SR = b'\x01'
    DINL = b'\x02'
    DINH = b'\x03'
    DOUTL = b'\x04'
    DOUTM = b'\x05'
    DOUTH = b'\x06'

class transaction_type(Enum):
    R = "R"
    W = "W"


class SR_field(Enum):
    MA_S_VLD = 7
    MA_L_VLD = 6
    TH_INITED = 5
    ALG_ACTIVE = 4
    TX_FIFO_EMPTY = 3
    TX_FIFO_FULL = 2
    RX_FIFO_EMPTY = 1
    RX_FIFO_FULL = 0

class CR_field(Enum):
    RST = 0x01 << 2
    EN = 0x01 << 1
    SRC_SEL = 0x01 << 0

class sig_src(Enum):
    UART = 0
    ADC = 1

class alg_state(Enum):
    DISABLED = 0
    ENABLED = 1
