`timescale 1ns / 1ps

module rx_fifo_reset_tb;
    reg clk = 1'b0;
    reg reset = 1'b1;
    wire fifo_reset;

    rx_fifo_reset uut (
        .reset(reset),
        .clk(clk),
        .fifo_reset(fifo_reset)
    );

    always #5 clk = ~clk;

    task require_reset;
        input expected;
        begin
            #1;
            if (fifo_reset !== expected) begin
                $error("fifo_reset=%b, expected %b", fifo_reset, expected);
                $finish;
            end
        end
    endtask

    integer cycle;
    initial begin
        require_reset(1'b1);

        // Startup reset cannot release until a live ADC clock has observed
        // five consecutive deasserted cycles.
        @(negedge clk);
        reset = 1'b0;
        for (cycle = 0; cycle < 4; cycle = cycle + 1) begin
            @(posedge clk);
            require_reset(1'b1);
        end
        @(posedge clk);
        require_reset(1'b0);

        // A sampling-clock reset immediately rearms the complete hold window.
        @(negedge clk);
        reset = 1'b1;
        @(posedge clk);
        require_reset(1'b1);
        @(negedge clk);
        reset = 1'b0;
        for (cycle = 0; cycle < 4; cycle = cycle + 1) begin
            @(posedge clk);
            require_reset(1'b1);
        end
        @(posedge clk);
        require_reset(1'b0);

        // Reassertion during release restarts, rather than shortens, the hold.
        @(negedge clk);
        reset = 1'b1;
        @(posedge clk);
        require_reset(1'b1);
        @(negedge clk);
        reset = 1'b0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b1;
        @(posedge clk);
        require_reset(1'b1);
        @(negedge clk);
        reset = 1'b0;
        repeat (4) begin
            @(posedge clk);
            require_reset(1'b1);
        end
        @(posedge clk);
        require_reset(1'b0);

        $display("rx_fifo_reset_tb PASSED");
        $finish;
    end
endmodule
