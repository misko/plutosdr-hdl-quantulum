`timescale 1ns / 1ps

module fifo_reset_sync_tb;
    reg fifo_wr_clk = 1'b0;
    reg source_reset = 1'b0;
    wire fifo_reset;
    integer high_cycles;

    always #5 fifo_wr_clk = ~fifo_wr_clk;

    fifo_reset_sync dut (
        .source_reset(source_reset),
        .fifo_wr_clk(fifo_wr_clk),
        .fifo_reset(fifo_reset)
    );

    initial begin
        // Configuration-time register initialization must hold reset for four
        // complete write-clock cycles, then release it synchronously.
        repeat (4) begin
            @(posedge fifo_wr_clk);
            #1;
            if (!fifo_reset) $fatal(1, "startup reset released too early");
        end
        @(posedge fifo_wr_clk);
        #1;
        if (fifo_reset) $fatal(1, "startup reset did not release");

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
