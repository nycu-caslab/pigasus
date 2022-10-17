/**
    Color bit FIFO
*/
module FIFO #(
    parameter DEPTH = 1024,
    parameter WIDTH = 8,
    parameter ALMOST_FULL_TH = 1020,
    parameter ALMOST_EMPTY_TH = 4,
) (
    input clk,
    input rst_n,
    input we, //* write enable
    input [WIDTH-1:0] wdata,
    input re, //* read enable
    output [WIDTH-1:0] rdata,

    //* state interface
    output empty,
    output full,
    output almost_full,
    output almost_empty
);



reg [WIDTH-1:0] buffer [DEPTH-1:0];


reg                     wcolor;
reg [$clog2(DEPTH)-1:0] wptr;
reg                     rcolor;
reg [$clog2(DEPTH)-1:0] rptr;

reg [$clog2(DEPTH)-1:0] fill_cnt;


wire w_commit = (wen && !full);
wire r_commit = (ren && !full);


assign empty = (wcolor == rcolor) && (wptr == rptr);
assign full  = (wcolor != rcolor) && (wptr == rptr);

assign almost_full = (fill_cnt >= ALMOST_FULL_TH);
assign almost_empty = (fill_cnt <= ALMOST_EMPTY_TH);


always @(posedge clk) begin
    if(w_commit) begin
        buffer[wptr] <= wdata;
    end

    if(r_commit) begin
        buffer[rptr] <= rdata;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wptr <= 'd0;
    end else begin
        if(wen && !full) begin
            wptr <= wptr + 'd1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wcolor <= 1'b0;
    end else begin
        wcolor <= (wptr == DEPTH-1) ? ~wcolor : wcolor;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rptr <= 'd0;
    end else begin
        if(ren && !empty) begin
            rptr <= rptr + 'd1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rcolor <= 1'b0;
    end else begin
        rcolor <= (rptr == DEPTH-1) ? ~rcolor : rcolor;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fill_cnt <= 'd0;
    end else begin
        if(ren && wen) begin
            fill_cnt <= fill_cnt;
        end else if(wen && !full) begin
            fill_cnt <= fill_cnt + 'd1;
        end else if(ren && !empty) begin
            fill_cnt <= fill_cnt - 'd1;
        end
    end
end




endmodule