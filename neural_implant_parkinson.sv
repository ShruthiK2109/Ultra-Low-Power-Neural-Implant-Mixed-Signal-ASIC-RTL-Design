//=========================================================
// Neural Implant Data Acquisition RTL
// Mixed-signal ASIC backend (Digital)
//=========================================================
`timescale 1ns/1ps

module neural_implant_top #(
    parameter SAMPLE_W   = 12,
    parameter TS_W       = 16,
    parameter CH_W       = 4,
    parameter FIFO_DEPTH = 16
)(
    // ADC clock domain
    input  logic                 adc_clk,
    input  logic                 adc_rst_n,
    input  logic [SAMPLE_W-1:0]  adc_sample,
    input  logic [CH_W-1:0]      adc_channel,
    input  logic                 adc_valid,

    // System clock domain
    input  logic                 sys_clk,
    input  logic                 sys_rst_n,

    output logic                 data_valid,
    output logic [SAMPLE_W+TS_W+CH_W-1:0] data_out
);

    // ===============================
    // ADC CLOCK DOMAIN
    // ===============================
    logic [TS_W-1:0] timestamp;

    always_ff @(posedge adc_clk or negedge adc_rst_n) begin
        if (!adc_rst_n)
            timestamp <= '0;
        else if (adc_valid)
            timestamp <= timestamp + 1'b1;
    end

    logic [SAMPLE_W+TS_W+CH_W-1:0] fifo_wdata;
    assign fifo_wdata = {adc_channel, timestamp, adc_sample};

    // ===============================
    // ASYNC FIFO
    // ===============================
    logic fifo_full, fifo_empty;
    logic fifo_wr_en = adc_valid && !fifo_full;
    logic fifo_rd_en;

    async_fifo #(
        .DATA_W (SAMPLE_W+TS_W+CH_W),
        .DEPTH  (FIFO_DEPTH)
    ) u_fifo (
        .wr_clk   (adc_clk),
        .wr_rst_n (adc_rst_n),
        .wr_en    (fifo_wr_en),
        .wdata    (fifo_wdata),
        .full     (fifo_full),

        .rd_clk   (sys_clk),
        .rd_rst_n (sys_rst_n),
        .rd_en    (fifo_rd_en),
        .rdata    (data_out),
        .empty    (fifo_empty)
    );

    // ===============================
    // SYSTEM CLOCK DOMAIN
    // ===============================
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            fifo_rd_en <= 1'b0;
            data_valid <= 1'b0;
        end else begin
            fifo_rd_en <= !fifo_empty;
            data_valid <= !fifo_empty;
        end
    end

endmodule


//=========================================================
// ASYNC FIFO WITH GRAY POINTER CDC
//=========================================================
module async_fifo #(
    parameter DATA_W = 32,
    parameter DEPTH  = 16
)(
    input  logic              wr_clk,
    input  logic              wr_rst_n,
    input  logic              wr_en,
    input  logic [DATA_W-1:0] wdata,
    output logic              full,

    input  logic              rd_clk,
    input  logic              rd_rst_n,
    input  logic              rd_en,
    output logic [DATA_W-1:0] rdata,
    output logic              empty
);

    localparam ADDR_W = $clog2(DEPTH);

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    logic [ADDR_W:0] wptr_bin, rptr_bin;
    logic [ADDR_W:0] wptr_gray, rptr_gray;

    logic [ADDR_W:0] wptr_gray_sync, rptr_gray_sync;

    // -------------------------------
    // WRITE DOMAIN
    // -------------------------------
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wptr_bin  <= '0;
            wptr_gray <= '0;
        end else if (wr_en && !full) begin
            mem[wptr_bin[ADDR_W-1:0]] <= wdata;
            wptr_bin  <= wptr_bin + 1'b1;
            wptr_gray <= (wptr_bin >> 1) ^ wptr_bin;
        end
    end

    // Sync read pointer into write clock
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            rptr_gray_sync <= '0;
        else
            rptr_gray_sync <= rptr_gray;
    end

    assign full = (wptr_gray == {~rptr_gray_sync[ADDR_W:ADDR_W-1],
                                  rptr_gray_sync[ADDR_W-2:0]});

    // -------------------------------
    // READ DOMAIN
    // -------------------------------
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rptr_bin  <= '0;
            rptr_gray <= '0;
        end else if (rd_en && !empty) begin
            rdata     <= mem[rptr_bin[ADDR_W-1:0]];
            rptr_bin  <= rptr_bin + 1'b1;
            rptr_gray <= (rptr_bin >> 1) ^ rptr_bin;
        end
    end

    // Sync write pointer into read clock
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            wptr_gray_sync <= '0;
        else
            wptr_gray_sync <= wptr_gray;
    end

    assign empty = (wptr_gray_sync == rptr_gray);

endmodule
