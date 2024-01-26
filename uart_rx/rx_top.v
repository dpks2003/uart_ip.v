// engineer name - Deepak Sharda 
// Date - 23 jan,2024 : 23:36


module rx_top
 // these are parameter from rx_clock can be over written from here 
 #(parameter system_clock = 25000000 ,// Fpga or system oscillator frequency 
   parameter rx_baudrate = 9600 , // define the input baud rate 
   parameter rx_sampling_rate =  16 ) // no of samples for input bit 

   (input rx_input, 
     //rx_clock, // will define this as wire as have the same keword for the output also)
    input rx_enable,
    output rx_done,
    output rx_busy,
    output rx_error,
    output [7:0] rx_output ,

    // from rx_clock
    input clk // system closk frequency input 
    // output reg rx_clock // required output clock frequnecy ;
   );

wire rx_clock; // this wire is for connecting the boaud rate clock 

// intiance of the clock
rx_clock_divider #(.system_clock(system_clock),
            .rx_baudrate(rx_baudrate),
            .rx_sampling_rate(rx_sampling_rate))
    clockuse (.clk(clk),
            .rx_clock(rx_clock));

uart_rx fsmuse (.rx_input(rx_input),
               .rx_clock(rx_clock),
               .rx_enable(rx_enable),
               .rx_done(rx_done),
               .rx_busy(rx_busy),
               .rx_error(rx_error),
               .rx_output(rx_output)); 


endmodule