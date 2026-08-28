`timescale 1ns / 1ps

module tx_pipeline_debug_tb;
    reg dma_clk = 1'b0;
    reg dac_clk = 1'b0;
    reg [7:0] dma_events = 8'h00;
    reg [7:0] dac_events = 8'h00;
    wire [7:0] dma_sticky;
    wire [7:0] dac_sticky_dma;

    tx_pipeline_debug uut (
        .dma_clk(dma_clk),
        .dac_clk(dac_clk),
        .dma_events(dma_events),
        .dac_events(dac_events),
        .dma_sticky(dma_sticky),
        .dac_sticky_dma(dac_sticky_dma)
    );

    always #2 dma_clk = ~dma_clk;
    always #7 dac_clk = ~dac_clk;

    initial begin
        repeat (3) @(posedge dma_clk);
        dma_events <= 8'ha5;
        @(posedge dma_clk);
        dma_events <= 8'h00;

        @(posedge dac_clk);
        dac_events <= 8'h5a;
        @(posedge dac_clk);
        dac_events <= 8'h00;

        repeat (8) @(posedge dma_clk);
        if (dma_sticky !== 8'ha5 || dac_sticky_dma !== 8'h5a) begin
            $display("FAIL: first sticky sample dma=%h dac=%h", dma_sticky, dac_sticky_dma);
            $finish(1);
        end

        // Cleared event inputs must not clear prior evidence.
        repeat (4) @(posedge dma_clk);
        if (dma_sticky !== 8'ha5 || dac_sticky_dma !== 8'h5a) begin
            $display("FAIL: evidence was not sticky dma=%h dac=%h", dma_sticky, dac_sticky_dma);
            $finish(1);
        end

        dma_events <= 8'h5a;
        @(posedge dma_clk);
        dma_events <= 8'h00;
        @(posedge dac_clk);
        dac_events <= 8'ha5;
        @(posedge dac_clk);
        dac_events <= 8'h00;
        repeat (8) @(posedge dma_clk);

        if (dma_sticky !== 8'hff || dac_sticky_dma !== 8'hff) begin
            $display("FAIL: accumulated evidence dma=%h dac=%h", dma_sticky, dac_sticky_dma);
            $finish(1);
        end

        $display("PASS: sticky TX pipeline diagnostics");
        $finish;
    end
endmodule
