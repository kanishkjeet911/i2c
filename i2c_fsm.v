module fsm(
input          clk,
input          reset,
input          on, //this is the switch button
input          ack,
input          start_bit,
input          rd_wr,
output reg     load_A,
output reg     shift_A,
output reg     load_d,
output reg     shift_d,
output reg     [1:0]sel_mux,
output reg     tri_en,
output reg     demux_sel,
output reg     shift_d_slave

);


parameter idle         = 4'b0000;
parameter start        = 4'b0001;
parameter address      = 4'b0010;
parameter ack_address  = 4'b0011;
parameter recieve_data = 4'b0100;
parameter ack_rd       = 4'b0101;
parameter send_data    = 4'b0110;
parameter ack_sd       = 4'b0111;
parameter stop         = 4'b1000;

reg [3:0]state ;
reg [3:0]next_state;
reg [3:0]count;
reg [3:0]bit_count;

//-----------------------------combinational part--------------------------------//


always @ (start_bit , rd_wr, ack,posedge clk)
begin
case(state)
idle:
     begin
	    if(on)
		  
		     next_state <= start;	   
	 end
	 
start:
     begin
	     if( count <4'd4 && start_bit)
		    count <= count + 1;
		  
		 if(count == 4'd4)
		     begin
			  sel_mux     <= 2'b00;
     		  next_state  <= address ;
		      count       <= 4'd0;
			  tri_en      <= 1'b1;
		     end
	
	 end


address:
     begin
	      
	          
		   bit_count <= bit_count + 1;  
		   
		   if (bit_count == 4'd1)
		     load_A <= 1;
		   else if ( bit_count == 4'd2)
		     begin
			   load_A     <= 1'bz;
			   shift_A    <= 1'b1;
			   sel_mux    <= 2'b01;
			   tri_en     <= 1'b1; //since we have to send the address now
			 			 
			 end
	       
		 /* if( count == 4'd0 )
		    begin
			   load_A <= 1;
			   count  <= count + 1;
			end
		 else if (count == 2 && bit_count < 4'd8)
		    begin
			   load_A     <= 1'bz;
			   shift_A    <= 1'b1;
			   sel_mux    <= 2'b01;
			   tri_en     <= 1'b1; //since we have to send the address now
			  
			end*/
	    
		  else if (bit_count == 4'd10)
		     begin
			     next_state <= ack_address;
			     bit_count  <= 4'd0;
				 count      <= 2'b0;
			 
			 end
		
	 	 
	 end


ack_address :
     begin
	     load_A    <= 1'bz;
		 shift_A   <= 1'bz;
		 demux_sel <= 1'b1;  // setting demux to send ack to fsm not data from the reciever
		 
         if(!ack)
		  next_state <= start;
		 
		 else if(ack && rd_wr)
		  next_state <= recieve_data;
		  
         else if(ack && !rd_wr)
          next_state <= send_data;

     end

recieve_data:

     begin
	     if((count >= 4'd0 ) && (count < 4'd8))
		    begin
			   count         <= count + 1;
			   
			   demux_sel     <= 1'b0; // recieving the data
			   shift_d_slave <= 1'b1;
			   tri_en        <= 1'b0;
			end
         else if (count == 4'd8)
		    begin
			   next_state  <= ack_rd ;
			   count       <= 4'd0;
			end
     end

ack_rd:

     begin
	     tri_en        <= 1'b1;
         sel_mux       <= 2'b00; // sending the start bit as acknowledgement for the reciever that the data has been recieved
         shift_d_slave <= 1'bz;
		 demux_sel     <= 1'bz ;
		 next_state    <= stop ;
		 
     end
	 
send_data:

    begin
	    
		    bit_count <= bit_count + 1; //for counting the number of the data send over the line
		if (bit_count == 4'd1 )
		     begin
			     load_d  <= 1'b1;
				 shift_d <= 1'bz;
				 
			 end
		 else if (bit_count == 4'd2)
		     begin
                 load_d  <= 1'bz;
				 shift_d <= 1'b1;
				 count   <= 4'd0;
				 tri_en  <= 1'b1;
				 sel_mux <= 2'b10;
			 			 
			 end
	     else if( bit_count == 4'd10)
		     begin
			     next_state <= ack_sd ;
			     bit_count  <= 4'd0;
			 end
	
	
	end

ack_sd:

     begin
	 
	     demux_sel <= 1'b1;
		 tri_en    <= 1'bz;
		 if(ack)
		   next_state <= stop;
		 else if (!ack)
		   next_state <= send_data;
		    
	 
	 end
	 
stop :

     begin
	     tri_en     <= 1'b1;
		 sel_mux    <= 2'b11;
		 next_state <= idle;
	 
	 
	 
	 end
	 
endcase	 
end

//------------------------------------end of combinational part -----------------------------------------//



//-------------------------------sequential part-------------------------------------------------------//


always @ (posedge clk )
begin
    if(!reset)
	  begin
	     state         <= idle;
		 load_A        <= 1'bz; 
		 shift_A       <= 1'bz;
         load_d        <= 1'bz;
         shift_d       <= 1'bz;
         sel_mux       <=2'bzz;
         tri_en        <= 1'bz;
         demux_sel     <= 1'bz;
         shift_d_slave <= 1'bz;
		 count         <= 4'd0;
		 bit_count     <= 4'd0;
		 next_state    <= idle;
	  
	  end
	  
	 else
	   state <= next_state;


end
endmodule























