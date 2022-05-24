`timescale 1ns / 1ps

module mitbih_read_to_mem#(
          parameter PATH = "100.csv",
          parameter LENGTH = 21600,
          parameter	DATA_WIDTH = 11
     )();

reg [DATA_WIDTH-1:0] recording_file [0:(LENGTH-1)];

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

endmodule
