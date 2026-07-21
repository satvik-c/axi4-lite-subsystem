import regs_pkg::*;

class test_random_regression;

    env e;
    axi_txn txn;
    spi_txn txn_spi;
    i2c_txn txn_i2c;
    uart_rx_txn txn_rx;
    logic [31:0] wdata;

    rand int op_select;
    constraint op_dist {
        op_select dist {
            0 := 70,  // access_reg
            1 := 8,   // drive_spi
            2 := 8,   // drive_i2c
            3 := 7,   // drive_rx
            4 := 7    // drive_tx
        };
    }

    localparam NUM_ITERATIONS = 5000;

    localparam SPI_CLK_DIV = 10;
    localparam I2C_CLK_DIV = 20;
    localparam BAUD_DIV = 32;

    function new(env e);
        this.e = e;
    endfunction

    task drive_spi();
        txn_spi = new();
        txn_spi.randomize();
        e.test2spi.put(txn_spi);

        wdata = 32'h0;
        wdata[SPI_CFG_CLKDIV_MSB : SPI_CFG_CLKDIV_LSB] = SPI_CLK_DIV;
        wdata[SPI_CFG_CPOL] = $urandom();
        wdata[SPI_CFG_CPHA] = $urandom();
        txn = new(1, 4'h0, SPI_CFG, wdata, 4'hF);
        e.test2drv.put(txn);

        txn = new();
        txn.randomize() with {
            is_write == 1;
            addr == {4'h0, SPI_TXDATA, 2'h0};
            wstrb == 4'hF;
        };
        e.test2drv.put(txn);

        wdata = 32'h0;
        wdata[SPI_CTRL_EN] = 1;
        wdata[SPI_CTRL_START] = 1;
        txn = new(1, 4'h0, SPI_CTRL, wdata, 4'hF);
        e.test2drv.put(txn);

        while (1) begin
            #(8 * SPI_CLK_DIV * e.clk_period);

            txn = new(0, 4'h0, SPI_STATUS);
            e.test2drv.put(txn);
            wait (txn.done.triggered);
            if (txn.rdata[SPI_STATUS_RXVALID]) break;
        end

        txn = new(0, 4'h0, SPI_RXDATA);
        e.test2drv.put(txn);
        wait (txn.done.triggered);
    endtask

    task drive_i2c();
        txn_i2c = new();
        txn_i2c.randomize();
        e.test2i2c.put(txn_i2c);

        wdata = 32'h0;
        wdata[I2C_CFG_CLKDIV_MSB : I2C_CFG_CLKDIV_LSB] = I2C_CLK_DIV;
        txn = new(1, 4'h1, I2C_CFG, wdata, 4'hF);
        e.test2drv.put(txn);

        wdata = 32'h0;
        wdata[I2C_ADDR_MSB : I2C_ADDR_LSB] = 7'h59;
        txn = new(1, 4'h1, I2C_ADDR, wdata, 4'hF);
        e.test2drv.put(txn);

        txn = new();
        txn.randomize() with {
            is_write == 1;
            addr == {4'h1, I2C_TXDATA, 2'h0};
            wstrb == 4'hF;
        };
        e.test2drv.put(txn);

        wdata = 32'h0;
        wdata[I2C_CTRL_EN] = 1;
        wdata[I2C_CTRL_RW_N] = $urandom();
        wdata[I2C_CTRL_START] = 1;
        txn = new(1, 4'h1, I2C_CTRL, wdata, 4'hF);
        e.test2drv.put(txn);

        while (1) begin
            #(8 * I2C_CLK_DIV * e.clk_period);

            txn = new(0, 4'h1, I2C_STATUS);
            e.test2drv.put(txn);
            wait (txn.done.triggered);
            if (!txn.rdata[I2C_STATUS_BUSY]) break;
        end

        txn = new(0, 4'h1, I2C_RXDATA);
        e.test2drv.put(txn);
        wait(txn.done.triggered);
    endtask

    task drive_rx();
        wdata = 32'h0;
        wdata[UART_CFG_BAUDDIV_MSB : UART_CFG_BAUDDIV_LSB] = BAUD_DIV;
        wdata[UART_CFG_PARITYEN] = $urandom();
        wdata[UART_CFG_PARITYMODE] = $urandom();
        wdata[UART_CFG_STOPBITS] = $urandom();
        txn = new(1, 4'h2, UART_CFG, wdata, 4'hF);
        e.test2drv.put(txn);

        wdata = 32'h0;
        wdata[UART_CTRL_TXEN] = 1;
        wdata[UART_CTRL_RXEN] = 1;
        txn = new(1, 4'h2, UART_CTRL, wdata, 4'hF);
        e.test2drv.put(txn);
        wait (txn.done.triggered);

        txn_rx = new();
        txn_rx.randomize();
        e.test2rx.put(txn_rx);

        while (1) begin
            #(14 * BAUD_DIV * e.clk_period);

            txn = new(0, 4'h2, UART_STATUS);
            e.test2drv.put(txn);
            wait (txn.done.triggered);
            if (txn.rdata[UART_STATUS_RXVALID] || txn.rdata[UART_STATUS_RXPERR]) break;
        end

        txn = new(0, 4'h2, UART_RXDATA);
        e.test2drv.put(txn);
        wait(txn.done.triggered);
    endtask

    task drive_tx();
        wdata = 32'h0;
        wdata[UART_CFG_BAUDDIV_MSB : UART_CFG_BAUDDIV_LSB] = BAUD_DIV;
        wdata[UART_CFG_PARITYEN] = $urandom();
        wdata[UART_CFG_PARITYMODE] = $urandom();
        wdata[UART_CFG_STOPBITS] = $urandom();
        txn = new(1, 4'h2, UART_CFG, wdata, 4'hF);
        e.test2drv.put(txn);

        wdata = 32'h0;
        wdata[UART_CTRL_TXEN] = 1;
        wdata[UART_CTRL_RXEN] = 1;
        txn = new(1, 4'h2, UART_CTRL, wdata, 4'hF);
        e.test2drv.put(txn);
        wait (txn.done.triggered);

        txn = new();
        txn.randomize() with {
            is_write == 1;
            addr == {4'h2, UART_TXDATA, 2'h0};
            wstrb == 4'hF;
        };
        e.test2drv.put(txn);
        wait (txn.done.triggered);
    endtask;

    task access_reg();
        txn = new();
        txn.randomize() with {
            !(addr inside {12'h000, 12'h100});  // SPI_CTRL, I2C_CTRL
        };
        e.test2drv.put(txn);
        wait(txn.done.triggered);
    endtask

    task run();
        repeat (NUM_ITERATIONS) begin
            randomize(op_select);
            case (op_select)
                0: access_reg();
                1: drive_spi();
                2: drive_i2c();
                3: drive_rx();
                4: drive_tx();
            endcase
        end
    endtask

endclass
