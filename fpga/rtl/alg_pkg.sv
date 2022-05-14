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

parameter   DATA_WIDTH = 11;        /* Width of input data */
parameter   CTR_WIDTH = 22;         /* Width of sample counter */
parameter   N_SHORT = 16;           /* Length of moving average short */
parameter   N_LONG  = 32;           /* Length of moving average long */
parameter   DATA_OFFSET = 1024;     /* Offset location of zero centerline */
parameter   DATA_FIFO_SIZE = 650000;/* SIze of incoming data FIFO */
/**
 * User defined types
 */



endpackage
