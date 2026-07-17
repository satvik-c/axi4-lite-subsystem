`timescale 1ns/1ps

module tb_top;

    logic clk;
    logic rst_n;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    axi4_lite_if axi_if(clk, rst_n);

    // Peripheral Pins
    logic miso;
    logic mosi;
    logic sclk;
    logic cs_n;
    logic scl;
    wire sda;
    assign (pull1, pull0) sda = 1'b1;
    logic tx_out;
    logic rx_in;

    // Loopbacks & Pull-ups
    assign miso = mosi;    
    assign rx_in = tx_out; 

    // Simple I2C Slave Model for ACKing
    logic sda_drv;
    assign sda = sda_drv ? 1'b0 : 1'bz;

    initial begin
        sda_drv = 1'b0;
    end

    always begin
        @(negedge sda);
        if (rst_n && scl === 1'b1) begin
            repeat (8) @(posedge scl);
            @(negedge scl);
            sda_drv = 1'b1;

            @(negedge scl);
            sda_drv = 1'b0;

            repeat (8) @(posedge scl);
            @(negedge scl);
            sda_drv = 1'b1;

            @(negedge scl);
            sda_drv = 1'b0;
        end
    end

    axi4_lite_subsystem dut (
        .s_axi(axi_if.slave),
        .miso(miso),
        .mosi(mosi),
        .sclk(sclk),
        .cs_n(cs_n),
        .scl(scl),
        .sda(sda),
        .tx_out(tx_out),
        .rx_in(rx_in)
    );

    initial begin
        static test_smoke t = new(axi_if);
        t.run();
    end

endmodule
