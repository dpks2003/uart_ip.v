// engineer name - Deepak Sharda 
// Date - 23 jan,2024 : 23:36


module tx_top
 // these are parameter from rx_clock can be over written from here 
 #(parameter system_clock = 25000000 ,// Fpga or system oscillator frequency 
   parameter tx_baudrate = 9600 , // define the input baud rate 
   parameter stop_bit_count = 1 ) // no of samples for input bit 

   ( input[7:0] tx_input, 
    //wire tx_clock, // will define this as wire as have the same keword for the output also)
    input tx_enable,
    output tx_done,
    output tx_busy,
    output tx_output ,

    // from rx_clock
    input clk // system closk frequency input 
    // output reg rx_clock // required output clock frequnecy ;
   );

wire tx_clock; // this wire is for connecting the boaud rate clock 

// intiance of the clock
tx_clock_divider #(.system_clock(system_clock),
            .tx_baudrate(tx_baudrate))
    clockuse (.clk(clk),
            .tx_clock(tx_clock));

uart_tx fsmuse (.tx_input(tx_input),
               .tx_clock(tx_clock),
               .tx_enable(tx_enable),
               .tx_done(tx_done),
               .tx_busy(tx_busy),
               .tx_output(tx_output)); 


endmodule