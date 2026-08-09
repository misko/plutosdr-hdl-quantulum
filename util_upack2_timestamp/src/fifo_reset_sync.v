`timescale 1ns / 1ps

// Generate a deterministic XPM FIFO reset in the FIFO write-clock domain.
// XPM requires reset deassertion to be synchronous to wr_clk.  The source
// reset is a level from the DAC clock domain, so synchronize it first and hold
// reset for four complete write-clock cycles after configuration or reset.
module fifo_reset_sync (
    input source_reset,
    input source_clk,
    input fifo_wr_clk,
    output fifo_reset
);
    // Register the reset level in its source domain before the two-flop CDC.
    // Vivado reports CDC-10 when source-domain combinational reset logic feeds
    // the destination synchronizer directly.
    reg source_reset_reg = 1'b0;
    wire source_reset_sync;
    reg [4:0] reset_hold = 5'b11111;

    always @(posedge source_clk) begin
        source_reset_reg <= source_reset;
    end

    cdc_sync_bits sync_source_reset (
        .clk_out(fifo_wr_clk),
        .reset(1'b0),
        .bits_in(source_reset_reg),
        .bits_out(source_reset_sync)
    );

    always @(posedge fifo_wr_clk) begin
        if (source_reset_sync) begin
            reset_hold <= 5'b11111;
        end else begin
            reset_hold <= {reset_hold[3:0], 1'b0};
        end
    end

    assign fifo_reset = |reset_hold;
endmodule
