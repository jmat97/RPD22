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
