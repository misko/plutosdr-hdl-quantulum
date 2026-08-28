`timescale 1ns / 1ps

module timestamp_check_pipeline_tb;
    reg dma_clk = 1'b0;
    reg dac_clk = 1'b0;
    reg reset = 1'b0;
    reg [63:0] timestamp = 64'd100;
    reg [31:0] timestamp_every = 32'd4;
    wire [31:0] discarded_block_count;
    reg s_axis_valid = 1'b0;
    wire s_axis_ready;
    reg s_axis_xfer_req = 1'b0;
    reg [63:0] s_axis_data = 64'd0;
    wire m_axis_valid;
    wire [63:0] m_axis_data;

    always #5 dma_clk = ~dma_clk;
    always #7 dac_clk = ~dac_clk;

    util_upack2_timestamp uut (
        .dma_clk(dma_clk),
        .dac_clk(dac_clk),
        .reset(reset),
        .reset_upack(),
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

    integer i;
    initial begin
        // CDC conversion is independently tested. Pin its DMA-domain result
        // here so this test isolates the timestamp decision handshake.
        force uut.timestamp_dma = 64'd100;
        repeat (12) @(posedge dma_clk);
        @(negedge dma_clk);
        s_axis_xfer_req = 1'b1;
        s_axis_valid = 1'b1;
        s_axis_data = 64'd100;

        // A timestamp word must not be accepted through a combinational
        // 64-bit comparison. It is evaluated, registered, then accepted.
        #1;
        if (s_axis_ready !== 1'b0) begin
            $error("timestamp word was ready before its decision was registered");
            $finish;
        end
        @(posedge dma_clk);
        #1;
        if (s_axis_ready !== 1'b1) begin
            $error("valid timestamp was not ready after one evaluation cycle");
            $finish;
        end
        @(posedge dma_clk);
        #1;
        if (discarded_block_count !== 32'd0) begin
            $error("valid timestamp incremented discard count: %0d", discarded_block_count);
            $finish;
        end

        // Consume the four payload words which return the timestamp counter
        // to its request state.
        for (i = 0; i < 4; i = i + 1) begin
            @(negedge dma_clk);
            s_axis_data = 64'h12340000 + i;
            @(posedge dma_clk);
        end

        // An invalid timestamp follows the same registered handshake and is
        // counted exactly once when accepted.
        @(negedge dma_clk);
        s_axis_data = 64'd0;
        #1;
        if (s_axis_ready !== 1'b0) begin
            $error("invalid timestamp bypassed the registered decision");
            $finish;
        end
        @(posedge dma_clk);
        #1;
        if (s_axis_ready !== 1'b1) begin
            $error("invalid timestamp was not accepted after evaluation");
            $finish;
        end
        if (uut.timestamp_decision_discard !== 1'b1) begin
            $error("invalid timestamp was classified as valid (dma timestamp %0d)", uut.timestamp_dma);
            $finish;
        end
        @(posedge dma_clk);
        #1;
        if (discarded_block_count !== 32'd1) begin
            $error("invalid timestamp count is %0d, expected 1", discarded_block_count);
            $finish;
        end

        // The entire interval associated with the rejected timestamp must be
        // accepted from DMA but suppressed from the FIFO.
        for (i = 0; i < 4; i = i + 1) begin
            @(negedge dma_clk);
            s_axis_data = 64'hbad00000 + i;
            #1;
            if (s_axis_ready !== 1'b1 || uut.fifo_wr_en !== 1'b0) begin
                $error("rejected interval payload was not discarded");
                $finish;
            end
            @(posedge dma_clk);
        end

        // A subsequent valid timestamp replaces the persistent discard state
        // and allows its payload into the FIFO.
        @(negedge dma_clk);
        s_axis_data = 64'd100;
        #1;
        if (s_axis_ready !== 1'b0) begin
            $error("replacement timestamp bypassed registered evaluation");
            $finish;
        end
        @(posedge dma_clk);
        #1;
        if (s_axis_ready !== 1'b1) begin
            $error("replacement timestamp was not accepted after evaluation");
            $finish;
        end
        @(posedge dma_clk);
        @(negedge dma_clk);
        s_axis_data = 64'h12345678;
        #1;
        if (s_axis_ready !== 1'b1 || uut.fifo_wr_en !== 1'b1) begin
            $error("valid replacement timestamp did not restore FIFO writes");
            $finish;
        end
        @(posedge dma_clk);

        // Timestamp-disabled IQ remains a zero-stall transparent path and
        // cannot affect the diagnostic count.
        @(negedge dma_clk);
        timestamp_every = 32'd0;
        s_axis_data = 64'hffffffffffffffff;
        #1;
        if (s_axis_ready !== 1'b1) begin
            $error("transparent IQ path stalled while timestamping was disabled");
            $finish;
        end
        repeat (4) @(posedge dma_clk);
        #1;
        if (discarded_block_count !== 32'd1) begin
            $error("disabled timestamping changed discard count: %0d", discarded_block_count);
            $finish;
        end

        $display("PASS: registered timestamp check and transparent disabled path");
        $finish;
    end
endmodule
