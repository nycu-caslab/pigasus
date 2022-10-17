`include "fifo.sv"


module fifo_wrapper_infill_mlab #(
    parameter SYMBOL_PER_BEATS = 1,
    parameter BITS_PER_SYMBOL = 20,
    parameter FIFO_DEPTH = 1024,
    parameter USE_PACKET = 1
) (
    input                           clk,
    input                           rst_n,
    input                           in_valid,
    output                          in_ready,
    input [BITS_PER_SYMBOL*SYMBOL_PER_BEATS-1:0]     in_data,
    input                           in_sop,
    input                           in_eop,
    output                          in_empty,

    output                          out_valid,
    input                           out_ready,
    output [BITS_PER_SYMBO*SYMBOL_PER_BEATSL-1:0]    out_data,
    output                          out_sop,
    output                          out_eop,
    output                          out_empty
);





wire in_fire;
wire out_fire;
reg  in_st;


//* FIFO interface
wire fifo_we;
wire [BITS_PER_SYMBO*SYMBOL_PER_BEATSL-1:0] fifo_wdata;
wire fifo_re;
wire [BITS_PER_SYMBO*SYMBOL_PER_BEATSL-1:0] fifo_rdata;
wire fifo_empty;
wire fifo_full;
wire fifo_almost_full;
wire fifo_alsmost_empty;

//* FIFO packet
wire                                        fifo_pkt_we;
wire [1:0] fifo_pkt_wdata;
wire                                        fifo_pkt_re;
wire [1:0] fifo_pkt_rdata;
wire                                        fifo_pkt_empty;
wire                                        fifo_pkt_full;
wire                                        fifo_pkt_almost_full;
wire                                        fifo_pkt_alsmost_empty;


assign in_fire = in_valid && in_ready;
assign out_fire = out_valid && out_ready;

assign in_ready = !(fifo_full);
assign in_empty = fifo_empty;

FIFO #(
    .DEPTH(FIFO_DEPTH),
    .WIDTH(BITS_PER_SYMBO*SYMBOL_PER_BEATSL),
    .ALMOST_FULL_TH(FIFO_DEPTH-20),
    .ALMOST_EMPTY_TH(1)
)
fifo_data (
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .we             (fifo_we        ),
    .wdata          (fifo_wdata     ),
    .re             (fifo_re        ),
    .rdata          (fifo_rdata     ),
    .empty          (fifo_empty     ),
    .full           (fifo_full      ),
    .almost_full    (fifo_almost_full   ),
    .almost_empty   (fifo_alsmost_empty )
);

FIFO #(
    .DEPTH(FIFO_DEPTH),
    .WIDTH(2),
    .ALMOST_FULL_TH(FIFO_DEPTH-20),
    .ALMOST_EMPTY_TH(1)
)
fifo_pkt (
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .we             (fifo_pkt_we        ),
    .wdata          (fifo_pkt_wdata     ),
    .re             (fifo_pkt_re        ),
    .rdata          (fifo_pkt_rdata     ),
    .empty          (fifo_pkt_empty     ),
    .full           (fifo_pkt_full      ),
    .almost_full    (fifo_pkt_almost_full   ),
    .almost_empty   (fifo_pkt_alsmost_empty )
);



assign fifo_we  = (in_fire);
assign fifo_wdata = in_data;
assign fifo_re  = (out_fire);
assign fifo_pkt_we = in_fire;
assign fifo_pkt_wdata = in_fire ? {in_eop, in_sop} : 2'd0;
assign fifo_pkt_re = out_fire;

assign out_sop = out_fire ? fifo_pkt_rdata[0] : 1'b0;
assign out_eop = out_fire ? fifo_pkt_rdata[1] : 1'b0;
assign out_valid = !fifo_empty;
assign out_data = (fifo_rdata);
assign out_empty = fifo_empty;



endmodule