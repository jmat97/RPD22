`timescale 1ns / 1ps

module mitbih_read#(
          parameter PATH = "100.csv",
          parameter LENGTH = 21600,
          parameter	DATA_WIDTH = 11,
          parameter CTR_WIDTH = 24
     )(
     input logic clk,
     input logic nrst,
     input logic signal_req,
     output logic [DATA_WIDTH-1:0] signal_out,
     output logic [CTR_WIDTH-1:0] counter,
     output logic signal_valid
);

reg [DATA_WIDTH-1:0] recording_file [0:LENGTH], buffer;
logic [CTR_WIDTH-1:0] counter_nxt;


/**
 * Local variables and signals
 */

event recording_saved;


initial

assign buffer = recording_file[counter_nxt];

initial begin
     int fd;
     int bytes_read,matched_items;
     int sample_num;
     int sample;
     string str;
  fd = $fopen(PATH, "r");
  if (fd == 0) begin
    $display("data_file handle was NULL");
    $finish;
  end
  while (!$feof(fd)) begin
          bytes_read = $fgets(str, fd);
          if (bytes_read !=0) begin
               matched_items = $sscanf(str, "%d,%d",sample_num,sample);
               if (matched_items==2) begin
                    //$display("sample[%d]:%d",sample_num, sample);
                    recording_file[sample_num] = sample;
               end
          end
  end
  $fclose(fd);
  $display("end of initial block");
end

initial begin
     counter = 0;
     forever begin
          @(negedge clk) begin
               if(signal_req & (counter<LENGTH)) begin
                    signal_valid <= 1'b1;
                    signal_out <= recording_file[counter];
                    counter <= counter + 1;
               end
               else begin
                    signal_valid <= 1'b0;
                    signal_out <= signal_out;
                    counter <= counter;
               end
          end
     end
end
/*

always_ff@ (posedge clk) begin
     if (!nrst) begin
          signal_out <= '0;
          signal_valid <= 1'b0;
          counter <= '0;
     end
     else begin
          if(signal_req) begin
               signal_out <= buffer;
               signal_valid <= 1'b1;
               counter <= counter_nxt;
          end
          else begin
               signal_out <= '0;
               signal_valid <= '0;
               counter <= counter_nxt;
          end
     end
end



always_comb begin
     if(!nrst) begin
          counter_nxt = '0;
     end
     else begin
          if(signal_req) begin
               counter_nxt = counter++;
          end
          else begin
               counter_nxt = counter_nxt;
          end
     end
end
*/

endmodule

