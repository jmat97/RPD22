# Copyright (C) 2021  AGH University of Science and Technology
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

if {($argc != 1) || ([lindex $argv 0] ni {"arty" "basys"})} {
    puts "usage: vivado -mode tcl -source [info script] -tclargs \[arty|basys\]"
    exit 1
}

set part xc7a35tcpg236-1
set top_module top_rpm_basys_3


create_project hpsd build -part ${part} -force

read_verilog -sv {

    rtl/clkgen_xil7series.sv
    rtl/pmc_stub.sv
    rtl/prim_clock_gating.sv
    rtl/reset_generator.sv
    rtl/top_rpm_basys_3.sv

    ../rtl/abs_diff.sv
    ../rtl/alg_core.sv
    ../rtl/alg_fsm.sv
    ../rtl/counter_fsm.sv
    ../rtl/extremum_detector.sv
    ../rtl/maximum_hold.sv
    ../rtl/moving_avg.sv
    ../rtl/qrs_detector.sv
    ../rtl/sample_mgmt.sv
    ../rtl/misc/edge_detector.sv
    ../rtl/misc/circular_buffer.sv

}

read_xdc constraints/basys_3.xdc

set_property top ${top_module} [current_fileset]
update_compile_order -fileset sources_1

launch_runs synth_1 -jobs 8
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
exit
