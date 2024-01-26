



module uart_tx #(
    parameter stop_bit_count = 1 
) ( input tx_clock,
    input tx_enable,
    input [7:0] tx_input,
    output reg tx_done,
    output reg tx_busy,
    output reg tx_output);

    // state defination 

parameter reset     = 3'b000,
          ideal     = 3'b001,
          start_bit = 3'b010,
          data_bit  = 3'b011,
          stop_bit  = 3'b100;

// reg defination 

reg [2:0] state   = reset; 
reg [7:0] tx_data = 8'b0; // shift register to change parallel input to output 

reg[2:0] tx_bit_index = 3'b0; // index for output 

/* fuction to disable the states and reset everything */

always @ (posedge tx_clock ) begin
    if(! tx_enable) begin
        state <= reset;
    end
end

// state machine transmisiion 
always @ (posedge tx_clock) begin
    case (state)
      
      reset: begin
        
        tx_bit_index <=3'b0;
        tx_busy <= 1'b0;
        tx_done <= 1'b0;
        tx_output <= 1'b1;

        if(tx_enable) begin
            state<= ideal;

        end

      end

      ideal : begin
        if (tx_enable) begin
            tx_data <= tx_input;
            state <= start_bit;
        end
      end

      start_bit :begin
        
        tx_bit_index<= 3'b0;
        tx_busy <= 1'b1;
        tx_done<=1'b0;
        tx_output <= 1'b0;
        state <= data_bit; 
      end


      data_bit : begin
      // @(posedge tx_clock) begin
        tx_data <= {1'b0,tx_data[7:1]};
        tx_output <= tx_data[0];


        tx_bit_index <= tx_bit_index+1'b1;

        if (&tx_bit_index) begin
            
            state <= stop_bit;
        end
      end 

      stop_bit: begin
        tx_done<= 1'b1;
        tx_output<= 1'b1;

        if(tx_enable) begin
            if(tx_done == 1'b0) begin
                tx_data <= tx_input;

                if(stop_bit_count) begin
                    state <= start_bit;

                end
                else begin
                    state <= stop_bit;
                end
            end
            else begin
                tx_done <= 1'b0;
                state <= start_bit;
            end
        end 
        else begin
            state <= reset;
        end
      end

      default : begin
        state <= reset;

      end

    endcase
end




    
endmodule