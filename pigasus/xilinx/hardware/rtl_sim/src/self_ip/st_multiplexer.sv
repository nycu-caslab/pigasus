module st_multiplexer #(
    parameter DWIDTH=8
) (
    input clk,
    input reset_n,
    input in0_valid,
    output reg in0_ready,
    input [DWIDTH-1:0] in0_data,
    input in1_valid,
    output reg in1_ready,
    input [DWIDTH-1:0] in1_data,
    output out_valid,
    input out_ready,
    output reg [DWIDTH-1:0] out_data,
    input out_channel
);

assign out_valid = out_ready & (in0_valid || in1_valid);

assign out_channel = in0_valid & in1_valid;
assign out_data = out_channel ? in1_data : in0_data;
assign in0_ready = out_ready;
assign in1_ready = out_ready;  

    
endmodule