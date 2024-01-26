//this is a clock or baud rate genrator of the tx the uart ip 
// engineer name - Deepak Sharda 
// Date - 21 jan,2024 1:20pm 

module tx_clock_divider 
#(parameter system_clock = 25000000 ,// Fpga or system oscillator frequency 
  parameter tx_baudrate = 9600 )  // define the input baud rate 

  ( input clk, // system closk frequency input 
    output reg tx_clock // required output clock frequnecy ;
   );

localparam tx_counter_max  = system_clock/(2*tx_baudrate) ; // maxing value of counter before reset
localparam tx_counter_width = $clog2(tx_counter_max); // no of bits requried for the counter using log of 2

reg [tx_counter_width-1:0] tx_counter =0;  // counter register for rx goes max to rx_counter_max 

initial begin
    tx_clock = 1'b0;  // intializing the clock value as zero 
end

always @ (posedge clk) begin
    if (tx_counter == tx_counter_max[tx_counter_width-1:0]) begin // comparing if the counter has reached the maximum vlauve
        tx_counter <= 0;   // if yes then resent it to 0
        tx_clock     <= ~ tx_clock; // and change the clock from + to -
    end 
    else begin
        tx_counter <= tx_counter + 1'b1; // otherwise increment the counter 
    end


    
end
endmodule