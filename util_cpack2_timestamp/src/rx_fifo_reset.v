`timescale 1ns / 1ps

// Reset the ADC-to-DMA XPM FIFO in its write-clock domain. XPM requires reset
// deassertion to be synchronous to wr_clk, so retain reset for five complete
// ADC clock edges after configuration or an AD9361 clock reset. The upstream
// axi_ad9361 reset is itself held through at least five ADC clock edges. This
// serial delay has no per-bit reset or enable and therefore maps to one SRL
// instead of creating a new flip-flop control set on the slice-full Z7010.
module rx_fifo_reset (
    input reset,
    input clk,
    output fifo_reset
);
    (* shreg_extract = "yes", srl_style = "srl" *)
    reg [4:0] reset_delay = 5'b11111;

    always @(posedge clk) begin
        reset_delay <= {reset_delay[3:0], reset};
    end

    assign fifo_reset = reset | reset_delay[4];
endmodule
