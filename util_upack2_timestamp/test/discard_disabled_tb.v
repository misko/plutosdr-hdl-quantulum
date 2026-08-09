`timescale 1ns / 1ps

module discard_disabled_tb;
    reg dma_clk = 1'b0;
    reg dac_clk = 1'b0;
    reg reset = 1'b1;
    wire reset_upack;
    reg [63:0] timestamp = 64'd0;
    reg [31:0] timestamp_every = 32'd0;
    wire [31:0] discarded_block_count;
    reg s_axis_valid = 1'b0;
    wire s_axis_ready;
    reg s_axis_xfer_req = 1'b0;
    reg [63:0] s_axis_data = 64'd0;
    wire m_axis_valid;
    wire [63:0] m_axis_data;

    always #1 dma_clk = ~dma_clk;
    always #3 dac_clk = ~dac_clk;

    util_upack2_timestamp uut (
        .dma_clk(dma_clk),
        .dac_clk(dac_clk),
        .reset(reset),
        .reset_upack(reset_upack),
        .timestamp(timestamp),
        .timestamp_every(timestamp_every),
        .discarded_block_count(discarded_block_count),
        .s_axis_valid(s_axis_valid),
        .s_axis_ready(s_axis_ready),
        .s_axis_xfer_req(s_axis_xfer_req),
        .s_axis_data(s_axis_data),
        .m_axis_valid(m_axis_valid),
        .m_axis_ready(1'b1),
        .m_axis_data(m_axis_data)
    );

    initial begin
        repeat (4) @(posedge dac_clk);
        reset <= 1'b0;
        timestamp <= 64'd100;
        repeat (20) @(posedge dma_clk);

        // Zero payload data is deliberately older than the synchronized
        // timestamp. With timestamping disabled it is IQ, not a timestamp.
        s_axis_xfer_req <= 1'b1;
        s_axis_valid <= 1'b1;
        repeat (16) @(posedge dma_clk);
        s_axis_valid <= 1'b0;
        s_axis_xfer_req <= 1'b0;
        repeat (2) @(posedge dma_clk);

        if (discarded_block_count !== 32'd0) begin
            $error("discard count changed while timestamping was disabled: %0d", discarded_block_count);
            $fatal(1);
        end
        $display("PASS: disabled timestamping leaves discard count at zero");
        $finish;
    end
endmodule
