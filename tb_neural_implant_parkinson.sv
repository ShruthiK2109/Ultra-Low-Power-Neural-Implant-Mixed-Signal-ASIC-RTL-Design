`timescale 1ns/1ps

module tb_neural_implant;

    logic adc_clk = 0, sys_clk = 0;
    always #5  adc_clk = ~adc_clk;
    always #10 sys_clk = ~sys_clk;

    logic adc_rst_n, sys_rst_n;
    logic [11:0] adc_sample;
    logic [3:0]  adc_channel;
    logic adc_valid;

    logic data_valid;
    logic [31:0] data_out;

    neural_implant_top dut (
        .adc_clk(adc_clk),
        .adc_rst_n(adc_rst_n),
        .adc_sample(adc_sample),
        .adc_channel(adc_channel),
        .adc_valid(adc_valid),

        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .data_valid(data_valid),
        .data_out(data_out)
    );

    initial begin
        adc_rst_n = 0;
        sys_rst_n = 0;
        adc_valid = 0;
        adc_sample = 0;
        adc_channel = 0;

        #50;
        adc_rst_n = 1;
        sys_rst_n = 1;

        repeat (20) begin
            @(posedge adc_clk);
            adc_valid  <= 1;
            adc_sample <= $random;
            adc_channel<= $random;
        end

        adc_valid <= 0;

        #500;
        $display("Simulation completed successfully");
        $finish;
    end

    always @(posedge sys_clk) begin
        if (data_valid)
            $display("DATA OUT: %h", data_out);
    end

endmodule
