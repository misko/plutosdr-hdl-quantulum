`timescale 1ns / 1ps

// Minimal simulation-only XPM model for tests that exercise the DMA-side
// timestamp control logic. The tested property does not depend on FIFO data.
module xpm_fifo_async #(
    parameter FIFO_MEMORY_TYPE = "block",
    parameter FIFO_READ_LATENCY = 0,
    parameter FIFO_WRITE_DEPTH = 16,
    parameter READ_DATA_WIDTH = 8,
    parameter READ_MODE = "fwft",
    parameter SIM_ASSERT_CHK = 0,
    parameter USE_ADV_FEATURES = "0000",
    parameter WRITE_DATA_WIDTH = 8
) (
    input wr_clk,
    input rst,
    output wr_rst_busy,
    input wr_en,
    input [WRITE_DATA_WIDTH-1:0] din,
    output full,
    input rd_clk,
    output rd_rst_busy,
    output empty,
    input rd_en,
    output [READ_DATA_WIDTH-1:0] dout,
    input sleep
);
    assign wr_rst_busy = 1'b0;
    assign full = 1'b0;
    assign rd_rst_busy = 1'b0;
    assign empty = 1'b1;
    assign dout = {READ_DATA_WIDTH{1'b0}};
endmodule
