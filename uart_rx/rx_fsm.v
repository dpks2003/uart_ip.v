// engineer name - Deepak Sharda 
// Date - 23 jan,2024 23:36

module uart_rx ( input wire rx_input, 
                 input rx_clock,
                 input rx_enable,
                 output reg rx_done,
                 output reg rx_busy,
                 output reg rx_error,
                 output reg [7:0] rx_output );

reg [2:0] in_reg           = 2'b00 ;  // this register is used in removing metastability of input rx_input signal
reg [2:0] state            = 3'b000;// register to hold the current state value
reg [5:0] out_hold_counter = 5'b0;  // counts the amount of cycle the output should be availabe max 16
reg [4:0] in_hold_reg      = 5'b0;
reg [3:0] in_sample_count  = 4'b0000; // it holds the amount of sample that has been passed for one boud rate cycle here max is 16   
reg [7:0] rx_received_data = 8'b0;  // takes the serieal rx data as input and converts it to a parallel output 
reg [3:0] bit_index        = 3'b0; // index for 8-bit data
wire in_data ;             // this wire connects the input data after passing through in_reg 
wire [3:0] in_prior_hold_reg;  // holds the 4 prior input value
wire [3:0] in_current_hold_reg; // holds current 4 input values

// states for the receiver fsm 
parameter reset    = 3'b000,
          ideal    = 3'b001,
          start_bit= 3'b010,
          data_bit = 3'b011,
          stop_bit = 3'b100,
          ready    = 3'b101;

/* the metastabilty register takes the input data and  Double-register the incoming data: */

always @ (posedge rx_clock) begin
    in_reg <= {in_reg[0],rx_input}; // concatenatig the input data into the lsb of the input register 
end

assign in_data = in_reg[1]; // assign the msb of the regiuster to the input_data wire 

/* enable signal to reset pull it down always high signal */ 

always @(posedge rx_clock) begin
    if (!rx_enable) begin
        state <= reset;
    end
end

// holding the currnet and perious values in the wire for error checking
always@ (posedge rx_clock) begin
    in_hold_reg <= {in_hold_reg [3:1],in_data,in_reg[0]};
    
end
   assign in_prior_hold_reg   = in_hold_reg[4:1];
   assign in_current_hold_reg = in_hold_reg[3:0];

// output available counter logic output avialable for 16 cycle 
always @(posedge rx_clock) begin
    if (|out_hold_counter) begin
        out_hold_counter <= out_hold_counter +1 ;
        if (out_hold_counter == 5'b10000)begin
            out_hold_counter <= 5'b0;
            rx_done <= 1'b0;
            rx_output <= 8'b0;
        end
    end
end

// FSM - for the reading of the input data 


always @ (posedge rx_clock)begin
     case (state)
    // we will use case state to define all the stats 
    /* the first state will be the reset state this is the state you
     came back to in case of any error and all the output regestres vaules 
     are assigned zero for a fresh start */

    
        reset :begin
            in_sample_count <= 4'b0000; 
            out_hold_counter <= 5'b00000;
            rx_received_data <= 8'b0;

            rx_busy <= 1'b0;
            rx_done <= 1'b0;

            // checking for error condition 
            /* if enable is high and error is high and in data is low 
            signifies that we are in error condition alredy do we should leave
            as it is*/ 

            if(rx_enable && rx_error && ! in_data) begin
                rx_error <= 1'b1;
            end
            else begin
                rx_error <= 1'b0;
            end
               rx_output <= 8'b0;
               if(rx_enable) begin
                state <= ideal ;
                end
        end // end of reset state

        ideal : begin
            /* this state is for the ideal start of the uart line that is when
             there is no data communication this state moves to start_bit state as 
             soon as it detects a low start bit for 16 sample cycle */

             if(!in_data)begin // start if a low bit is detected
              if(in_sample_count == 4'b0)begin // this signal checks if the low is getting detected for the first time 
                if(&in_prior_hold_reg||rx_done && !rx_error)begin 
                    /* this function checks if the all prior bits are high that is 
                    condition for stop bit and done bit is high ie that the previous comunication is done 
                    and there is no error this shows that a new communication is starting */

                    in_sample_count <=4'b1;
                    rx_error <= 1'b0;
                    
                end
                else begin
                    //this is not a start bit false alarm
                    rx_error <= 1'b1;
                end
              end
                else begin
                    in_sample_count <= in_sample_count + 4'b1;
                    // if not detected for the first time increase the sample count by 1
                    if(in_sample_count == 4'b1100)begin
                        in_sample_count <= 4'b0100; // make the clock value as for becoze we have counted till 
                        // 12 and we gone 4 bits extra in the next bit sample so we are kicking thr counter as 4 
                        rx_busy <= 1'b1;
                        rx_error <= 1'b0;
                        state <= start_bit; // move to start bit becouse we have detected input signal 
                    end
              end   
             end
             else if (|in_sample_count) begin
                /* this block is to clear all the counter if the start bit was a false alarm*/ 
                in_sample_count <= 4'b0;
                rx_received_data <=8'b0;
                rx_error <= 1'b1;
             end
        end

        start_bit : begin
            /* this bit even tho named as start bit it detects the first data bit 
            so it offically the first bit of the lsb of the data 
            ****** furture changes needs to be done and this state to be mearged with the 
            data _bit state ***** */
            in_sample_count <= in_sample_count + 4'b1;

            /* the counter was alredy at 4 from the last state  so when it reaches the 1111 it is in the 
            middle of the first data bit ie at 8 cycles */

            if(& in_sample_count) begin
                rx_received_data [bit_index] <= in_data; // writting the input to the 0 bit -- lsb 
                bit_index <= bit_index + 3'b1; // increaseing the bit values by one 
                rx_output <= 8'b0;
                state <= data_bit;
            end
        end

        data_bit : begin
            /* this state reads the remaing 7 bits and outputs them*/

            in_sample_count <= in_sample_count + 4'b1; 
            if(&in_sample_count) begin // the sample has reached mid of bit 2 and so on for 3,4,..,8
             rx_received_data[bit_index] <= in_data; // dyanamically saving data correspoint to its index
             bit_index <= bit_index + 3'b1; 
             // this opration will be repeated for 7 times

             if(&bit_index)begin
                // we have reached the 8 bit
                state <= stop_bit; // moving in for the stop bit
             end  
            end
        end

        stop_bit : begin

            in_sample_count <= in_sample_count + 4'b1; 

            if(in_sample_count[3])begin // ****
                // the sample count has reaches anywhere between 8 to 15
                if(!in_data) begin
                    rx_output <= rx_received_data;
                // the next start bits is received as soon as the stop bit is sent
                // so this block takes care of that case
                    if (in_sample_count == 4'b1000 && &in_prior_hold_reg) begin
                        //this statement states that only if the 16 cycle of the stop bit has pased and 
                        // all the last 4 bit were high ie its a true stop bit

                        in_sample_count <=4'b0;
                        out_hold_counter <= 5'b1;
                        rx_done <=1'b1;
                        state <= ideal;
                    end
                    
                    else if (&in_sample_count) begin
                        // has reached 16 but the start bit didnot start
                        // it is a error condition

                        in_sample_count <= 4'b0;
                        rx_busy <= 1'b0;
                        rx_error <= 1'b1;
                        rx_received_data <= 8'b0;
                        state <= ideal;
                    end
                end
                else begin
                    if (& in_current_hold_reg) begin
                        // all the last 4 bits received where 1 that is stop bit received

                        in_sample_count <= 4'b0;
                        rx_done <= 1'b1;
                        rx_error <= 1'b0;
                        rx_output <= rx_received_data;
                        state <= ready; // state defined below     
                    end
                    else if (&in_sample_count) begin
                        // 16 sample are completed but stop bit has arrived false stop --error
                        in_sample_count <= 4'b0;
                        rx_error <= 1'b1;
                        state <= ready; // state defined below
                    end
                end 
            
            end 
        end

        ready : begin
            in_sample_count <= in_sample_count + 4'b1; 

            if (!rx_error && !in_data || &in_sample_count) begin
                // to check if this is a start bit 

                if (&in_sample_count) begin
                    // has ready 15 that is one boud cycle or 16 samples

                    if(in_data)begin
                        // if the input data is high ie it was not a start bit 
                        // should move to ideal condition 

                        rx_busy <= 1'b0;
                        rx_received_data <= 8'b0;

                        //waiting start bit to show up 
                    end
                    else begin
                        // in_data is low maybe a start bit we must confirm 

                        in_sample_count <= 4'b1; 
                    end
                    rx_done <= 1'b0;
                    rx_output <= 8'b0;
                    state <= ideal; 
                    // moving eveything to ideal and waiting for new start bit to show up 
                end
                else begin
                    in_sample_count <= 4'b1;
                    out_hold_counter <=  in_sample_count+ 5'b00010;
                    state <= ideal;

                end
            end
            else if (&in_sample_count[3:1]) begin
                // the sample counter is between 111x ie 14 or15 we will use the mext cycle to move 
                // to the reset state 

                if (rx_error || !in_data) begin
                    state <= reset;
                    // its a error condition 
                end
            end
        end
        default: begin
            state <= reset; 
        end
     endcase
end // end fsm always block 
endmodule