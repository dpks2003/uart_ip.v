// this is a clock or baud rate genrator of the rx the uart ip 
// engineer name - Deepak Sharda 
// Date - 21 jan,2024 11:50 am 

module rx_clock_divider 
#(parameter system_clock = 25000000 ,// Fpga or system oscillator frequency 
  parameter rx_baudrate = 9600 , // define the input baud rate 
  parameter rx_sampling_rate =  16 ) // no of samples for input bit 

  ( input clk, // system closk frequency input 
    output rx_clock // required output clock frequnecy ;
  );

localparam rx_counter_max  = system_clock/(2*rx_baudrate*rx_sampling_rate) ; // maxing value of counter before reset
localparam rx_counter_width = &clog2(rx_counter_max); // no of bits requried for the counter using log of 2

reg [rx_counter_width-1:0] rx_counter ; // counter register for rx goes max to rx_counter_max 

initial begin
    rx_clock = 1'b0;  // intializing the clock value as zero 
end

always @ (posedge clk) begin
    if (rx_counter == rx_counter_max[rx_counter_width-1:0]) begin
        rx_counter <= 0;
        rx_clk      <= ~rx_Clk;
    end else begin
        rx_counter <= rx_counter + 1'b1;
    end


    
end


endmodule
