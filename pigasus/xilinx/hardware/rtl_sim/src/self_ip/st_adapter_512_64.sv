module st_adapter_512_64(
    input clk,
    input reset_n,
    input in_valid,
    output reg in_ready,
    input [512-1:0] in_data,
    input in_startofpacket,
    input in_endofpacket,
    output reg in_empty,

    output out_valid,
    input out_ready,
    output reg [64-1:0] out_data,
    output reg out_startofpacket,
    output reg out_endofpacket,
    input out_empty

);


reg [2-1:0] cur_st;// 0 can't accept // 1 accept
reg [512-1:0]data_buffer;
reg [4-1:0]counter;
wire [64-1:0]  passing_data[0:8-1];
genvar  i;

always @(posedge clk ) begin
    data_buffer <= (in_ready & in_valid) ? in_data : data_buffer;
end



generate 
    for( i = 0 ; i < 8 ; i = i + 1 )begin
        assign passing_data[i] = data_buffer[64*i +: 64];
    end
endgenerate



always @(posedge clk or negedge reset_n) begin
    if(!reset_n)begin
         cur_st <= 2'd0;    
    end 
    else begin
        case(cur_st)
            2'd0:
                cur_st <= ( in_valid && in_ready ) ? 2'd1 : 2'd0 ;
            2'd1:
                cur_st <= ( counter == 7 ) ? 2'd0 : cur_st;

        endcase

    end
end


always @(posedge clk or negedge reset_n) begin
    if(!reset_n )begin
        in_ready <= 0;
    end
    else begin
        if(cur_st == 2'd0  ) in_ready <= ( in_valid && in_ready ) ? in_ready : 1'd1 ; 
        else begin
            in_ready <= ( in_valid && in_ready ) ? 1'd0 : in_ready;
        end
    end

end




always @(posedge clk or negedge reset_n) begin
    if(!reset_n || cur_st == 2'd0)begin
        counter <= 0;
    end
    else begin
        counter <= (cur_st == 2'd1) ? counter + 1 : counter;

    end

end


assign out_valid = ( cur_st == 2'd1 && counter <= 4'd7 );
assign out_data = (counter <= 4'd7 )? passing_data[counter] : 'd0;

endmodule