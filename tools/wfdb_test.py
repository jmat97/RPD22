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

import wfdb
import matplotlib.pyplot as plt


if __name__ == "__main__":
    path = 'tools/mit_bih_arrhythmia_database/100'
    record = wfdb.rdrecord(path)
    record.adc(inplace=True)

    for i in range(record.sig_len):
        data = record.d_signal[i][0]
        print(data)



