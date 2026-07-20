`timescale 1ns/1ps

module tb_top;

    localparam time CLK_PERIOD = 10ns;

    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
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
    spi_if spi_vif();
    i2c_if i2c_vif();
    uart_if uart_vif();

    // Loopbacks & Pull-ups
    assign (pull1, pull0) i2c_vif.sda = 1'b1;

    axi4_lite_subsystem dut (
        .s_axi(axi_if.slave),
        .miso(spi_vif.miso),
        .mosi(spi_vif.mosi),
        .sclk(spi_vif.sclk),
        .cs_n(spi_vif.cs_n),
        .scl(i2c_vif.scl),
        .sda(i2c_vif.sda),
        .tx_out(uart_vif.tx_out),
        .rx_in(uart_vif.rx_in)
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
        static test_smoke t = new(axi_if, spi_vif, i2c_vif, uart_vif, CLK_PERIOD);
        t.run();

        $display("==============================================");
        $display(" Test complete: %0d errors / %0d transactions", t.e.scb.errors, t.e.scb.count);
        t.e.cov.print();

        $finish;
    end

endmodule
