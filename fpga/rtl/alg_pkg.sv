/**
 * Copyright (C) 2020  AGH University of Science and Technology
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package alg_pkg;


/**
 * Patterns used for address decoding (memory map)
 */

parameter   DATA_WIDTH = 11;            /* Width of input data */
parameter   CTR_WIDTH = 22;             /* Width of sample counter */
parameter   NAVG_SHORT = 16;               /* Length of moving average short */
parameter   NAVG_LONG  = 32;               /* Length of moving average long */
parameter   DATA_OFFSET = 1024;         /* Offset location of zero centerline */
parameter   DIN_FIFO_SIZE = 256;     /* Size of input data FIFO */
parameter   DOUT_FIFO_SIZE = 100;       /* Size of output data FIFO */
parameter   ACQUISITION_RATE = 360;     /* Freguency of ADC data acquisition */
parameter   SYSTEM_CLK = 100_000_000;   /* System clock */
/**
 * User defined types
 */

typedef enum logic  {
    ECG_SRC_UART = 1'b0,
    ECG_SRC_ADC = 1'b1
} ecg_src;

typedef logic [DATA_WIDTH-1:0]  ecg_sample;
typedef logic [CTR_WIDTH-1:0]   sample_num;


typedef struct packed {
    logic [7:0]  in_data_l;
} uart_dinl_t;

endpackage
