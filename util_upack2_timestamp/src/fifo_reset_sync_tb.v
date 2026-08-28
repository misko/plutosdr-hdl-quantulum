`timescale 1ns / 1ps

module fifo_reset_sync_tb;
    reg fifo_wr_clk = 1'b0;
    reg source_clk = 1'b0;
    reg source_clk_enable = 1'b0;
    reg source_reset = 1'b0;
    wire fifo_reset;
    integer high_cycles;

    always #5 fifo_wr_clk = ~fifo_wr_clk;
    always #7 if (source_clk_enable) source_clk = ~source_clk;

    fifo_reset_sync dut (
        .source_reset(source_reset),
        .source_clk(source_clk),
        .fifo_wr_clk(fifo_wr_clk),
        .fifo_reset(fifo_reset)
    );

    initial begin
        // The DMA/write clock can start before the DAC/read clock. Reset must
        // remain asserted indefinitely in that state; otherwise the XPM FIFO
        // read domain never observes the reset sequence.
        repeat (10) begin
            @(posedge fifo_wr_clk);
            #1;
            if (!fifo_reset) $fatal(1, "startup reset released before source clock");
        end

        // Once the source clock is alive and samples deasserted reset, the
        // level crosses to the write domain and reset releases synchronously.
        source_clk_enable = 1'b1;
        high_cycles = 0;
        while (fifo_reset && high_cycles < 16) begin
            @(posedge fifo_wr_clk);
            #1;
            high_cycles = high_cycles + 1;
        end
        if (fifo_reset) $fatal(1, "startup reset did not release after source clock");

        // An asynchronous source-domain pulse must be synchronized, assert
        // reset, hold it for at least four write-clock cycles, and release.
        #2 source_reset = 1'b1;
        repeat (4) @(posedge fifo_wr_clk);
        #1;
        if (!fifo_reset) $fatal(1, "runtime reset was not observed");
        source_reset = 1'b0;

        high_cycles = 0;
        while (fifo_reset && high_cycles < 12) begin
            @(posedge fifo_wr_clk);
            #1;
            high_cycles = high_cycles + 1;
        end
        if (high_cycles < 4) $fatal(1, "runtime reset hold was too short");
        if (fifo_reset) $fatal(1, "runtime reset did not release");

        $display("PASS: deterministic FIFO startup and runtime reset");
        $finish;
    end
endmodule
