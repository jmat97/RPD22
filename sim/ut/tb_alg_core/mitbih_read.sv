`timescale 1ns / 1ps

module mitbih_read#(
          parameter LENGTH = 21600,
          parameter	DATA_WIDTH = 11,
          parameter CTR_WIDTH = 24
     )(
     input string path,
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

assign buffer = recording_file[counter_nxt];

initial begin
     int fd;
     int bytes_read,matched_items;
     int sample_num;
     int sample;
     string str;
     forever begin
        @(posedge nrst);
          fd = $fopen(path, "r");
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
          $display("%s was opened",path);
          $fclose(fd);
          @(negedge nrst);
     end

end

initial begin
     forever begin
          if (!nrst) begin
               @(negedge clk);
               signal_valid <= 1'b0;
               signal_out <= 0;
               counter <=0;
          end
          else begin
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
end

endmodule

