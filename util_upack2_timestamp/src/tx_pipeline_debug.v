`timescale 1ns / 1ps

// Retain one-bit evidence that each TX pipeline boundary has been active.
// Each DAC-domain bit is monotonic after configuration, so independent
// two-flop synchronization into the DMA/register domain is safe.
module tx_pipeline_debug (
    input dma_clk,
    input dac_clk,
    input [7:0] dma_events,
    input [7:0] dac_events,
    output reg [7:0] dma_sticky = 8'h00,
    output wire [7:0] dac_sticky_dma
);
    reg [7:0] dac_sticky = 8'h00;

    always @(posedge dma_clk) begin
        dma_sticky <= dma_sticky | dma_events;
    end

    always @(posedge dac_clk) begin
        dac_sticky <= dac_sticky | dac_events;
    end

    cdc_sync_bits #(
        .NUM_BITS(8)
    ) sync_dac_sticky_to_dma (
        .clk_out(dma_clk),
        .reset(1'b0),
        .bits_in(dac_sticky),
        .bits_out(dac_sticky_dma)
    );
endmodule
