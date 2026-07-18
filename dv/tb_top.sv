`timescale 1ns/1ps

module tb_top;

    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    axi4_lite_if axi_if(clk, rst_n);

    initial begin
        axi_if.AWVALID = 1'b0;
        axi_if.WVALID  = 1'b0;
        axi_if.ARVALID = 1'b0;
    end

    // Peripheral Pins
    logic miso;
    logic mosi;
    logic sclk;
    logic cs_n;
    logic scl;
    wire sda;
    logic tx_out;
    logic rx_in;

    // Loopbacks & Pull-ups
    assign miso = mosi;
    assign rx_in = tx_out;
    assign (pull1, pull0) sda = 1'b1;

    // Simple I2C Slave Model for ACKing
    logic sda_drv;
    assign sda = sda_drv ? 1'b0 : 1'bz;

    initial begin
        sda_drv = 1'b0;

        forever begin
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

    bind axi4_lite_subsystem protocol_sva u_protocol_sva (.vif(s_axi));
    bind skid_buffer     skid_buffer_sva  u_skid_buffer_sva  (.*);
    bind uart_fifo       uart_fifo_sva    u_uart_fifo_sva    (.*);
    bind uart_wrapper    uart_wrapper_sva u_uart_wrapper_sva (.*);
    bind address_decoder decoder_sva      u_decoder_sva      (.*);
    bind spi_regs        spi_regs_sva     u_spi_regs_sva     (.*);
    bind i2c_regs        i2c_regs_sva     u_i2c_regs_sva     (.*);
    bind uart_regs       uart_regs_sva    u_uart_regs_sva    (.*);

    initial begin
        static test_smoke t = new(axi_if);
        t.run();

        $display("==============================================");
        $display(" Test complete: %0d errors / %0d transactions", t.e.scb.errors, t.e.scb.count);
        t.e.cov.print();

        $finish;
    end

endmodule
