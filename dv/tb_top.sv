`timescale 1ns/1ps

module tb_top;

    // ========================================================
    // CLOCK & RESET
    // ========================================================

    localparam time CLK_PERIOD = 10ns;

    logic clk;
    logic rst_n;

    env e;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    // ========================================================
    // DUT & INTERFACES
    // ========================================================

    axi4_lite_if axi_if(clk, rst_n);

    initial begin
        axi_if.AWVALID = 1'b0;
        axi_if.WVALID  = 1'b0;
        axi_if.ARVALID = 1'b0;
    end

    // Peripheral interfaces
    spi_if spi_vif(rst_n);
    i2c_if i2c_vif(rst_n);
    uart_if uart_vif();

    // Open-drain SDA pull-up
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

    // ========================================================
    // BIND ASSERTIONS & TAPS
    // ========================================================

    bind axi4_lite_subsystem protocol_sva u_protocol_sva (.vif(s_axi));
    bind skid_buffer     skid_buffer_sva  u_skid_buffer_sva  (.*);
    bind uart_fifo       uart_fifo_sva    u_uart_fifo_sva    (.*);
    bind uart_fifo       uart_fifo_tap    u_uart_fifo_tap    (.*);
    bind uart_wrapper    uart_wrapper_sva u_uart_wrapper_sva (.*);
    bind address_decoder decoder_sva      u_decoder_sva      (.*);
    bind spi_regs        spi_regs_sva     u_spi_regs_sva     (.*);
    bind i2c_regs        i2c_regs_sva     u_i2c_regs_sva     (.*);
    bind uart_regs       uart_regs_sva    u_uart_regs_sva    (.*);
    bind spi_regs        spi_regs_tap     u_spi_regs_tap     (.*);
    bind i2c_regs        i2c_regs_tap     u_i2c_regs_tap     (.*);
    bind uart_regs       uart_regs_tap    u_uart_regs_tap    (.*);

    // ========================================================
    // TEST DISPATCH
    // ========================================================

    task automatic run_test(string name, env e);
        case (name)
            "test_register_access": begin
                automatic test_register_access t = new(e);
                t.run();
            end
            "test_arrival_order": begin
                automatic test_arrival_order t = new(e);
                t.run();
            end
            "test_fifo_stress": begin
                automatic test_fifo_stress t = new(e);
                t.run();
            end
            "test_peripheral_roundtrip": begin
                automatic test_peripheral_roundtrip t = new(e);
                t.run();
            end
            "test_random_regression": begin
                automatic test_random_regression t = new(e);
                t.run();
            end
            default: $fatal(1, "Unknown TEST_CLASS: %s", name);
        endcase
    endtask

    // ========================================================
    // MAIN
    // ========================================================

    initial begin
        string test_name;
        e = new(axi_if, spi_vif, i2c_vif, uart_vif, CLK_PERIOD);
        e.run();

        if ($test$plusargs("RUN_ALL")) begin
            run_test("test_register_access", e);
            run_test("test_arrival_order", e);
            run_test("test_fifo_stress", e);
            run_test("test_peripheral_roundtrip", e);
            run_test("test_random_regression", e);
        end else begin
            if (!$value$plusargs("TEST_CLASS=%s", test_name)) test_name = "test_register_access";
            run_test(test_name, e);
        end

        $display("==============================================");
        $display(" Test complete: %0d errors / %0d transactions", e.scb.errors, e.scb.count);
        e.cov.print();

        $finish;
    end

    // Live transaction counter
    initial begin
        static int last_count = 0;
        wait (e != null);
        forever begin
            wait (e.scb.count != last_count);
            $display("[%0t] transaction count: %0d", $time, e.scb.count);
            last_count = e.scb.count;
        end
    end

endmodule
