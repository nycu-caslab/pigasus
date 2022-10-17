`timescale 1ps/1ps

`define CLK_PERIOD 10000
`define FRONT_CLK_PERIOD 10000
`define BACK_CLK_PERIOD 10000



module tb;

parameter FP_DWIDTH = 512


integer patcnt;
integer cycles;
integer total_cycles;
integer i,j,k;


logic clk;
logic rst;
logic front_clk;
logic front_rst;
logic back_clk;
logic back_rst;


logic [511:0] pkt_payload_golden [0:3];


logic [511:0] in_pkt_data;
logic         in_pkt_valid;
logic         in_pkt_sop;
logic         in_pkt_epo;
logic [5:0]   in_pkt_empty;
logic         in_pkt_ready;
logic         in_pkt_almost_full;

logic [511:0]   piped_pkt_data;
logic           piped_pkt_valid;
logic           piped_pkt_sop;
logic           piped_pkt_eop;
logic [5:0]     piped_pkt_empty;
logic           piped_pkt_almost_full;

logic [511:0]   pkt_fifo_data;
logic           pkt_fifo_valid;
logic           pkt_fifo_ready;
logic           pkt_fifo_sop;
logic           pkt_fifo_eop;
logic [5:0]     pkt_fifo_empty;


logic           in_pkt_fifo_almost_full;
logic [31:0]    in_pkt_csr_readdata;
logic [511:0]   in_pkt_fifo_data;
logic           in_pkt_fifo_valid;
logic           in_pkt_fifo_ready;
logic           in_pkt_fifo_sop;
logic           in_pkt_fifo_eop;
logic [5:0]     in_pkt_fifo_empty;


logic           pkt_shift_ready;
logic           pkt_shift_valid;
logic [511:0]   pkt_shift_data;
logic           pkt_shift_sop;
logic           pkt_shift_eop;
logic [5:0]     pkt_shift_empty;


logic           cdc_pkt_almost_full;
logic [31:0]    cdc_pkt_csr_readdata;
logic           cdc_pkt_valid;
logic [511:0]   cdc_pkt_data;
logic           cdc_pkt_ready;
logic           cdc_pkt_sop;
logic           cdc_pkt_eop;
logic [5:0]     cdc_pkt_empty;

logic                   pkt_adapter_valid;
logic [FP_DWIDTH-1:0]   pkt_adapter_data;
logic                   pkt_adapter_ready;
logic                   pkt_adapter_sop;
logic                   pkt_adapter_eop;
logic [FP_EWIDTH-1:0]   pkt_adapter_empty;

logic           rule_valid;
logic [511:0]   rule_data;
logic           rule_ready;
logic           rule_sop;
logic           rule_eop;
logic [5:0]     rule_empty;

logic           send_payload;
logic           payload_sending;
logic           payload_finished;

logic           ans_received;


initial clk = 1'b0;
initial front_clk = 1'b0;
initial back_clk = 1'b0;

always #(`CLK_PERIOD/2.0) clk = ~clk;
always #(`FRONT_CLK_PERIOD/2.0) front_clk = ~front_clk;
always #(`BACK_CLK_PERIOD/2.0) back_clk = ~back_clk;




//* represent the data
initial begin

    patcnt = 'd0;
    cycles = 'd0;
    total_cycles = 'd0;

    for(patcnt = 0; patcnt < 1; patcnt = patcnt + 1) begin
        //* Create the data
        send_data;
        //* wait finished
        wait(payload_finished);

        while(~ans_received) begin
            total_cycles = total_cycles + 1;
            @(negedge clk);
        end
        repeat(2) @(negedge clk);
        disply_buffer;
    end


end

task send_data; begin

    @(negedge clk)
    send_payload = 'd1;
    @(negedge clk) 
    send_payload = 'd0;
end endtask

task disply_buffer; begin
    for(i=0;i<ans_recv_inst.write_ptr;i=i+1) begin
        $write("[%h]", i);
        for(j=0;j<64;j=j+1) begin
            $write("%8h ", ans_recv_inst.buffer[(j*8)+:8]);
        end
        $write("\n");
    end
end endtask

payload_generator #(
    .DATA_WIDTH (512),
    .E_WIDTH (9),
    .PAYLOAD_LEN (3),
    .SEED (2022)
) payload_gen_inst(
    .clk                (clk),
    .rst_n              (~rst),    
    .payload_sending    (payload_sending),          
    .payload_finished   (payload_finished),        
    .payload_valid      (send_payload),    
    .in_ready           (in_pkt_ready),
    .out_data           (in_pkt_data),
    .out_valid          (in_pkt_valid),
    .out_sop            (in_pkt_sop),
    .out_eop            (in_pkt_eop),
    .out_empty          (in_pkt_empty)
);






pkt_almost_full_nogap #(
    .DWIDTH(512),
    .EWIDTH(6),
    .NUM_PIPES(2)
) pkt_almost_full_inst (
    .clk                    (clk),
    .rst                    (rst),
    .in_data                (in_pkt_data),
    .in_valid               (in_pkt_valid),
    .in_ready               (in_pkt_ready),
    .in_sop                 (in_pkt_sop),
    .in_eop                 (in_pkt_eop),
    .in_empty               (in_pkt_empty),
    .out_data               (piped_pkt_data),
    .out_valid              (piped_pkt_valid),
    .out_almost_full        (piped_pkt_almost_full),
    .out_sop                (piped_pkt_sop),
    .out_eop                (piped_pkt_eop),
    .out_empty              (piped_pkt_empty)
);


unified_pkt_fifo  #(
    .FIFO_NAME        ("[fast_pattern] in_pkt_FIFO"),
    .MEM_TYPE         ("M20K"),
    .DUAL_CLOCK       (0),
    .USE_ALMOST_FULL  (1),
    .FULL_LEVEL       (470),
    .SYMBOLS_PER_BEAT (64),
    .BITS_PER_SYMBOL  (8),
    .FIFO_DEPTH       (512)
) in_pkt_fifo (
    .in_clk            (clk),
    .in_reset          (rst),
    .out_clk           (),
    .out_reset         (),
    .in_data           (piped_pkt_data),
    .in_valid          (piped_pkt_valid),
    .in_ready          (),
    .in_startofpacket  (piped_pkt_sop),
    .in_endofpacket    (piped_pkt_eop),
    .in_empty          (piped_pkt_empty),
    .out_data          (in_pkt_fifo_data),
    .out_valid         (in_pkt_fifo_valid),
    .out_ready         (in_pkt_fifo_ready),
    .out_startofpacket (in_pkt_fifo_sop),
    .out_endofpacket   (in_pkt_fifo_eop),
    .out_empty         (in_pkt_fifo_empty),
    .fill_level        (in_pkt_csr_readdata),
    .almost_full       (in_pkt_fifo_almost_full),
    .overflow          ()
);


unified_pkt_fifo  #(
    .FIFO_NAME        ("[fast_pattern] in_pkt_cdc_FIFO"),
    .MEM_TYPE         ("M20K"),
    .DUAL_CLOCK       (1),
    .USE_ALMOST_FULL  (1),
    .FULL_LEVEL       (450),
    .SYMBOLS_PER_BEAT (64),
    .BITS_PER_SYMBOL  (8),
    .FIFO_DEPTH       (512)
) in_pkt_cdc (
    .in_clk            (clk),
    .in_reset          (rst),
    .out_clk           (front_clk),
    .out_reset         (front_rst),
    .in_data           (in_pkt_fifo_data),
    .in_valid          (in_pkt_fifo_valid),
    .in_ready          (in_pkt_fifo_ready),
    .in_startofpacket  (in_pkt_fifo_sop),
    .in_endofpacket    (in_pkt_fifo_eop),
    .in_empty          (in_pkt_fifo_empty),
    .out_data          (cdc_pkt_data),
    .out_valid         (cdc_pkt_valid),
    .out_ready         (cdc_pkt_ready),
    .out_startofpacket (cdc_pkt_sop),
    .out_endofpacket   (cdc_pkt_eop),
    .out_empty         (cdc_pkt_empty),
    .fill_level        (cdc_pkt_csr_readdata),
    .almost_full       (cdc_pkt_almost_full),
    .overflow          ()
);



//Use conditional generate
generate
    if(FP_DWIDTH==64)begin
        st_adapter_512_64 data_adapter_inst (
            .clk                    (front_clk),
            .reset_n                (!front_rst),
            .in_data                (cdc_pkt_data),
            .in_valid               (cdc_pkt_valid),
            .in_ready               (cdc_pkt_ready),
            .in_startofpacket       (cdc_pkt_sop),
            .in_endofpacket         (cdc_pkt_eop),
            .in_empty               (cdc_pkt_empty),
            .out_data               (pkt_adapter_data),
            .out_valid              (pkt_adapter_valid),
            .out_ready              (pkt_adapter_ready),
            .out_startofpacket      (pkt_adapter_sop),
            .out_endofpacket        (pkt_adapter_eop),
            .out_empty              (pkt_adapter_empty)
        );
    end else if(FP_DWIDTH==128)begin
        st_adapter_512_128 data_adapter_inst (
            .clk                    (front_clk),
            .reset_n                (!front_rst),
            .in_data                (cdc_pkt_data),
            .in_valid               (cdc_pkt_valid),
            .in_ready               (cdc_pkt_ready),
            .in_startofpacket       (cdc_pkt_sop),
            .in_endofpacket         (cdc_pkt_eop),
            .in_empty               (cdc_pkt_empty),
            .out_data               (pkt_adapter_data),
            .out_valid              (pkt_adapter_valid),
            .out_ready              (pkt_adapter_ready),
            .out_startofpacket      (pkt_adapter_sop),
            .out_endofpacket        (pkt_adapter_eop),
            .out_empty              (pkt_adapter_empty)
        );
    end else if(FP_DWIDTH==256)begin
        st_adapter_512_256 data_adapter_inst (
            .clk                    (front_clk),
            .reset_n                (!front_rst),
            .in_data                (cdc_pkt_data),
            .in_valid               (cdc_pkt_valid),
            .in_ready               (cdc_pkt_ready),
            .in_startofpacket       (cdc_pkt_sop),
            .in_endofpacket         (cdc_pkt_eop),
            .in_empty               (cdc_pkt_empty),
            .out_data               (pkt_adapter_data),
            .out_valid              (pkt_adapter_valid),
            .out_ready              (pkt_adapter_ready),
            .out_startofpacket      (pkt_adapter_sop),
            .out_endofpacket        (pkt_adapter_eop),
            .out_empty              (pkt_adapter_empty)
        );
    end else if (FP_DWIDTH==512) begin
        assign pkt_adapter_data  = cdc_pkt_data;
        assign pkt_adapter_valid = cdc_pkt_valid;
        assign pkt_adapter_sop   = cdc_pkt_sop;
        assign pkt_adapter_eop   = cdc_pkt_eop;
        assign pkt_adapter_empty = cdc_pkt_empty;
        assign cdc_pkt_ready     = pkt_adapter_ready;
    end
endgenerate



string_matcher string_matcher_inst (
    .front_clk              (front_clk),
    .front_rst              (front_rst),
    .back_clk               (back_clk),
    .back_rst               (back_rst),
    .in_pkt_data            (pkt_adapter_data),
    .in_pkt_valid           (pkt_adapter_valid),
    .in_pkt_sop             (pkt_adapter_sop),
    .in_pkt_eop             (pkt_adapter_eop),
    .in_pkt_empty           (pkt_adapter_empty),
    .in_pkt_ready           (pkt_adapter_ready),
    .out_usr_data           (rule_data),
    .out_usr_valid          (rule_valid),
    .out_usr_ready          (rule_ready),
    .out_usr_eop            (rule_eop),
    .out_usr_sop            (rule_sop),
    .out_usr_empty          (rule_empty)
);

ans_receiver #(
    .DATA_WIDTH (512),
    .E_WIDTH (9)
) ans_recv_inst (
    .clk               (clk),         
    .rst_n             (~rst),         
    .reset_ptr         (1'b0),             
    .payload_finished  (ans_received),                     
    .in_data           (rule_data),             
    .in_valid          (rule_valid),             
    .in_sop            (rule_sop),         
    .in_eop            (rule_eop),         
    .in_empty          (rule_empty),             
    .in_ready          (rule_ready)           
);



endmodule



module payload_generator #(
    parameter DATA_WIDTH = 512,
    parameter E_WIDTH    = 9,
    parameter PAYLOAD_LEN = 3,
    parameter SEED = 2022
) (
    input                   clk,
    input                   rst_n,
    output                  payload_sending,
    output                  payload_finished,
    input                   payload_valid,
    input                   in_ready,
    output [DATA_WIDTH-1:0] out_data,
    output                  out_valid,
    output                  out_sop,
    output                  out_eop,
    output [E_WIDTH-1:0]    out_empty
);


typedef enum{
    IDLE,
    SET,
    SENDING,
    FINISH
} state_t;

integer i;
logic [1:0] cur_st;

logic [DATA_WIDTH-1:0] payload;
logic [PAYLOAD_LEN-1:0] payload_length;
logic [PAYLOAD_LEN-1:0] payload_cnt;
logic [E_WIDTH-1:0]     empty;     
logic [DATA_WIDTH-1:0] byte_enable;
logic [DATA_WDITH-1:0] mask;
logic [DATA_WIDTH-1:0] zero;


assign zero = 'd0;
assign mask = ~zero;

always@(*) begin
    byte_enable = (mask) >> empty; 
end

assign payload_sending = (cur_st == SENDING);
assign payload_finished = (cur_st = FINISH);

always@(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cur_st <= IDLE;
    end else begin
        case(cur_st)
            IDLE : begin
                if(payload_valid) begin
                    cur_st <= SET;
                end
            end
            SET: begin
                cur_st <= SENDING;
            end
            SENDING : begin
                cur_st <= (payload_cnt == payload_length-'d1) ? FINISH : SENDING;
            end
            FINISH : begin
                cur_st <= (IDLE);
            end
        endcase
    end
end


always@(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        payload_length <= 'd0;
    end else begin
        if(cur_st == SET) begin
            payload_length <= $random(SEED) % 'd7;
        end
    end
end 

always@(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        empty <= 'd0;
    end else begin
        if(cur_st == SET) begin
            empty <= $random(SEED) % (DATA_WIDTH / 8);
        end
    end
end



always@(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        payload_cnt <= 'd0;
    end else begin
        if(cur_st == SENDING) begin
            payload_cnt <= (payload_cnt == payload_length - 'd1) ? 'd0 : (in_ready && out_valid) ? payload_cnt + 'd1 : payload_cnt;
        end else begin
            payload_cnt <= 'd0;
        end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        payload <= 'd0;
    end else begin
        if(cur_st == SENDING) begin
            payload <= (payload_cnt == payload_length - 'd1) ? $random(SEED) & mask : $random(SEED) ;
        end
    end
end 


assign out_valid = (cur_st == SENDING);
assign out_sop = (payload_cnt == 'd0 && cur_st == SENDING);
assign out_eop = (payload_cnt == payload_length-'d1 && cur_st == SENDING);
assign out_empty = empty;
assign out_data = payload;



endmodule

module ans_receiver #(
    parameter DATA_WIDTH = 512,
    parameter E_WIDTH    = 9
) (
    input                   clk,
    input                   rst_n,
    input                   reset_ptr,
    output                  payload_finished,
    input  [DATA_WIDTH-1:0] in_data,
    input                   in_valid,
    input                   in_sop,
    input                   in_eop,
    input  [E_WIDTH-1:0]    in_empty
    output                  in_ready
);


interger i;
logic [DATA_WIDTH-1:0] buffer [1023:0];
logic [E_WIDTH-1:0] write_ptr;
logic [DATA_WIDTH-1:0] zero;
logic [DATA_WIDTH-1:0] mask;

assign zero = 'd0;
assign mask = ~zero;

always@(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for(i=0;i<1024;i=i+1) begin
            buffer[i] <= 'd0;
        end
        write_ptr <= 'd0;
    end else begin
        if(in_valid && in_ready) begin
            write_ptr <= write_ptr +'d1 : write_ptr;
            buffer[write_ptr] <= (in_eop) ? (in_data & (mask >> in_empty)) : in_data;
            write_ptr <= (in_eop) ? 'd0 : write_ptr + 'd1;
        end
    end
end

assign in_ready = (write_ptr != 1023);
assign payload_finished = in_eop;


endmodule


