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

package uart_pkg;


/**
 * Patterns used for address decoding (memory map)
 */

parameter   UART_CR_OFFSET = 0;      /* Control Reg offset */
parameter   UART_SR_OFFSET = 1;      /* Status Reg offset */
parameter   UART_DINL_OFFSET = 2;    /*Input Data Low Reg offset */
parameter   UART_DINH_OFFSET = 3;    /*Input Data High Reg offset */
parameter   UART_DOUTL_OFFSET = 4;   /*Output Data Low Reg offset */
parameter   UART_DOUTM_OFFSET = 5;   /*Output Data Mid Reg offset */
parameter   UART_DOUTH_OFFSET = 6;   /*Output Data High Reg offset */

/**
 * User defined types
 */

typedef enum {
    CR = UART_CR_OFFSET,/* Control Reg offset */
    SR = UART_SR_OFFSET,/* Status Reg offset */
    DINL = UART_DINL_OFFSET,/*Input Data Low Reg offset */
    DINH = UART_DINH_OFFSET,/*Input Data High Reg offset */
    DOUTL = UART_DOUTL_OFFSET,/*Output Data Low Reg offset */
    DOUTM = UART_DOUTM_OFFSET,/*Output Data Middle Reg offset */
    DOUTH = UART_DOUTH_OFFSET/*Output Data High Reg offset */
} reg_rwaddr;


typedef struct packed {
    logic       rst;
    logic       en;
    logic       src_sel;
} uart_cr_t;

typedef struct packed {
    logic       ma_s_vld;
    logic       ma_l_vld;
    logic       th_inited;
    logic       alg_active;
    logic       tx_fifo_empty;
    logic       tx_fifo_full;
    logic       rx_fifo_empty;
    logic       rx_fifo_full;
} uart_sr_t;

typedef struct packed {
    logic [7:0]  in_data_l;
} uart_dinl_t;

typedef struct packed {
    logic [2:0]  in_data_h;
} uart_dinh_t;

typedef struct packed {
    logic [7:0]  out_data_l;
} uart_doutl_t;

typedef struct packed {
    logic [7:0]  out_data_m;
} uart_doutm_t;

typedef struct packed {
    logic [2:0]  out_data_h;
} uart_douth_t;

typedef struct packed {
    logic  in_data_vld;
} uart_in_data_vld;

typedef struct packed {
    uart_cr_t  cr;
    uart_sr_t  sr;
    uart_dinl_t dinlr;
    uart_dinh_t dinhr;
    uart_doutl_t doutlr;
    uart_doutm_t doutmr;
    uart_douth_t douthr;
    uart_in_data_vld din_vld;
} uart_regs_t;

endpackage
