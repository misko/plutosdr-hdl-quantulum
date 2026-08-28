`timescale 1ns / 1ps

module cdc_sync_data_closed_tb;
    reg adc_clk = 0;
    reg dma_clk = 0;
    reg [31:0] sample_counter = 32'hfffffff0;
    wire ready;
    wire valid;
    wire [31:0] counter_cpu;
    reg [31:0] history [0:31];
    integer history_index = 0;
    integer valid_count = 0;
    integer i;
    integer found;

    always #7 adc_clk = ~adc_clk;
    always #5 dma_clk = ~dma_clk;

    cdc_sync_data_closed #(.NUM_BITS(32)) dut (
        .clk_in(adc_clk),
        .clk_out(dma_clk),
        .ready(ready),
        .enable(1'b1),
        .bits_in(sample_counter),
        .valid(valid),
        .bits_out(counter_cpu)
    );

    always @(posedge adc_clk) begin
        sample_counter <= sample_counter + 1;
        history[history_index] <= sample_counter;
        history_index <= (history_index + 1) % 32;
    end

    always @(posedge dma_clk) begin
        if (valid) begin
            found = 0;
            for (i = 0; i < 32; i = i + 1)
                if (counter_cpu === history[i])
                    found = 1;
            if (!found)
                $fatal(1, "counter output was not a coherent source sample: %h", counter_cpu);
            valid_count = valid_count + 1;
        end
    end

    initial begin
        for (i = 0; i < 32; i = i + 1)
            history[i] = sample_counter;
        #3000;
        if (valid_count < 20)
            $fatal(1, "too few coherent counter updates: %0d", valid_count);
        $display("PASS: %0d coherent counter updates", valid_count);
        $finish;
    end
endmodule
