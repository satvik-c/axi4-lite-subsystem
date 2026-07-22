import regs_pkg::*;

// Directed: end-to-end roundtrip through each peripheral across its config space
class test_peripheral_roundtrip;

    // ========================================================
    // FIELDS
    // ========================================================

    env          e;
    axi_txn      txn;
    spi_txn      txn_spi;
    i2c_txn      txn_i2c;
    uart_rx_txn  txn_rx;
    logic [31:0] wdata;

    localparam SPI_CLK_DIV = 10;
    localparam I2C_CLK_DIV = 20;
    localparam BAUD_DIV = 32;

    // ========================================================
    // CONSTRUCTION
    // ========================================================

    function new(env e);
        this.e = e;
    endfunction

    // ========================================================
    // RUN
    // ========================================================

    task run();

        // SPI: across both CPOL/CPHA, transfer a byte and read it back
        for (int i = 0; i <= 1; i++) begin
            for (int j = 0; j <= 1; j++) begin
                txn_spi = new();
                txn_spi.miso = 8'hAA;
                e.test2spi.put(txn_spi);

                wdata = 32'h0;
                wdata[SPI_CFG_CLKDIV_MSB : SPI_CFG_CLKDIV_LSB] = SPI_CLK_DIV;
                wdata[SPI_CFG_CPOL] = i;
                wdata[SPI_CFG_CPHA] = j;
                txn = new(1, 4'h0, SPI_CFG, wdata, 4'hF);
                e.test2drv.put(txn);

                wdata = 32'h0;
                wdata[7:0] = 8'h55;
                txn = new(1, 4'h0, SPI_TXDATA, wdata, 4'hF);
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
            end
        end

        // I2C: across ACK/NACK and read/write, run a transfer and read it back
        for (int i = 0; i <= 1; i++) begin
            for (int j = 0; j <= 1; j++) begin
                txn_i2c = new();
                txn_i2c.nack = i;
                txn_i2c.rxdata = 8'hAA;
                e.test2i2c.put(txn_i2c);

                wdata = 32'h0;
                wdata[I2C_CFG_CLKDIV_MSB : I2C_CFG_CLKDIV_LSB] = I2C_CLK_DIV;
                txn = new(1, 4'h1, I2C_CFG, wdata, 4'hF);
                e.test2drv.put(txn);

                wdata = 32'h0;
                wdata[I2C_ADDR_MSB : I2C_ADDR_LSB] = 7'h59;
                txn = new(1, 4'h1, I2C_ADDR, wdata, 4'hF);
                e.test2drv.put(txn);

                wdata = 32'h0;
                wdata[I2C_CTRL_EN] = 1;
                wdata[I2C_CTRL_RW_N] = j;
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
                wait (txn.done.triggered);
            end
        end

        // UART: across parity/stop-bit config, receive a byte and echo it out
        for (int i = 0; i <= 1; i++) begin
            for (int j = 0; j <= 1; j++) begin
                for (int k = 0; k <= 1; k++) begin
                    wdata = 32'h0;
                    wdata[UART_CFG_BAUDDIV_MSB : UART_CFG_BAUDDIV_LSB] = BAUD_DIV;
                    wdata[UART_CFG_PARITYEN] = i;
                    wdata[UART_CFG_PARITYMODE] = j;
                    wdata[UART_CFG_STOPBITS] = k;
                    txn = new(1, 4'h2, UART_CFG, wdata, 4'hF);
                    e.test2drv.put(txn);

                    wdata = 32'h0;
                    wdata[UART_CTRL_RXEN] = 1;
                    wdata[UART_CTRL_TXEN] = 1;
                    txn = new(1, 4'h2, UART_CTRL, wdata, 4'hF);
                    e.test2drv.put(txn);
                    wait (txn.done.triggered);

                    for (int h = 0; h <= 1; h++) begin
                        txn_rx = new();
                        txn_rx.inject_perr = h;
                        txn_rx.data = 8'h72;
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
                        wait (txn.done.triggered);

                        wdata = 32'h0;
                        wdata[7:0] = txn.rdata[7:0];
                        txn = new(1, 4'h2, UART_TXDATA, wdata, 4'hF);
                        e.test2drv.put(txn);
                    end

                end
            end
        end

        // UART overrun: receive a second byte before the first is read out
        txn_rx = new();
        txn_rx.inject_perr = 0;
        txn_rx.data = 8'h72;
        e.test2rx.put(txn_rx);

        while (1) begin
            #(14 * BAUD_DIV * e.clk_period);

            txn = new(0, 4'h2, UART_STATUS);
            e.test2drv.put(txn);
            wait (txn.done.triggered);
            if (txn.rdata[UART_STATUS_RXVALID] || txn.rdata[UART_STATUS_RXPERR]) break;
        end

        txn_rx = new();
        txn_rx.inject_perr = 0;
        txn_rx.data = 8'h72;
        e.test2rx.put(txn_rx);

        while (1) begin
            #(14 * BAUD_DIV * e.clk_period);

            txn = new(0, 4'h2, UART_STATUS);
            e.test2drv.put(txn);
            wait (txn.done.triggered);
            if (txn.rdata[UART_STATUS_RXOVERRUN]) break;
        end

        txn = new(0, 4'h2, UART_RXDATA);
        e.test2drv.put(txn);
        wait (txn.done.triggered);
    endtask

endclass
