`timescale 1ns / 1ps

// Reset the ADC-to-DMA XPM FIFO in its write-clock domain.  XPM requires
// reset deassertion to be synchronous to wr_clk, so retain reset for five
// complete ADC clock edges after configuration or an AD9361 clock reset.
module rx_fifo_reset (
    input reset,
    input clk,
    output fifo_reset
);
    reg [4:0] reset_hold = 5'b11111;

    always @(posedge clk) begin
        if (reset) begin
            reset_hold <= 5'b11111;
        end else begin
            reset_hold <= {reset_hold[3:0], 1'b0};
        end
    end

    assign fifo_reset = |reset_hold;
endmodule
