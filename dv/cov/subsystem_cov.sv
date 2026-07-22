// ========================================================
// Functional coverage model sampling AXI, SPI, I2C, UART, and FIFO transactions
// ========================================================

// Classifications derived from AXI timing for functional coverage
typedef enum {
    ADDR_FIRST,
    DATA_FIRST,
    CONCURRENT
} arrival_order_e;

typedef enum {
    BACK_TO_BACK,
    GAPPED
} spacing_e;

class subsystem_cov;

    import regs_pkg::*;


    // ========================================================
    // HANDLES
    // ========================================================

    mailbox #(axi_txn) mon2cov;
    mailbox #(spi_txn) spi2cov;
    mailbox #(i2c_txn) i2c2cov;
    mailbox #(uart_rx_txn) rx2cov;
    mailbox #(uart_tx_txn) tx2cov;

    logic fifo_seen_full;


    // ========================================================
    // COVERGROUPS
    // ========================================================

    // AXI transaction shape: type, register, strobes, arrival order, response
    covergroup cg_axi with function sample(axi_txn txn_axi, arrival_order_e order, spacing_e space);

        cp_txn_type : coverpoint txn_axi.is_write {
            bins read = { 0 };
            bins write = { 1 };
        }

        cp_reg_hitmap : coverpoint txn_axi.addr {
            bins spi[] = { 12'h000, 12'h004, 12'h008, 12'h00C, 12'h010 };
            bins i2c[] = { 12'h100, 12'h104, 12'h108, 12'h10C, 12'h110, 12'h114 };
            bins uart[] = { 12'h200, 12'h204, 12'h208, 12'h20C, 12'h210 };
        }

        cp_wstrb : coverpoint txn_axi.wstrb {
            bins single_byte[] = { 4'b0001, 4'b0010, 4'b0100, 4'b1000 };
            bins zeros[] = { 4'b0000 };
            bins ones[] = { 4'b1111 };
            bins multi_byte[] = { 4'b0011, 4'b1100 };
        }

        cp_arrival_order : coverpoint order {
            bins addr_first = { ADDR_FIRST };
            bins data_first = { DATA_FIRST };
            bins concurrent = { CONCURRENT };
        }

        cp_spacing : coverpoint space {
            bins back_to_back = { BACK_TO_BACK };
            bins gapped = { GAPPED };
        }

        cp_response : coverpoint txn_axi.resp {
            bins okay = { 2'b00 };
            bins slverr = { 2'b10 };
            bins decerr = { 2'b11 };
        }

        cp_spi_rxvalid_observed : coverpoint txn_axi.rdata[SPI_STATUS_RXVALID]
            iff (!txn_axi.is_write && txn_axi.addr[11:8] == 4'h0 && txn_axi.addr[7:2] == SPI_STATUS) {
            bins clear = { 0 };
            bins seen  = { 1 };
        }

        cp_i2c_rxvalid_observed : coverpoint txn_axi.rdata[I2C_STATUS_RXVALID]
            iff (!txn_axi.is_write && txn_axi.addr[11:8] == 4'h1 && txn_axi.addr[7:2] == I2C_STATUS) {
            bins clear = { 0 };
            bins seen  = { 1 };
        }

        cp_i2c_nack_observed : coverpoint txn_axi.rdata[I2C_STATUS_NACK]
            iff (!txn_axi.is_write && txn_axi.addr[11:8] == 4'h1 && txn_axi.addr[7:2] == I2C_STATUS) {
            bins clear = { 0 };
            bins seen  = { 1 };
        }

        cp_uart_rxvalid_observed : coverpoint txn_axi.rdata[UART_STATUS_RXVALID]
            iff (!txn_axi.is_write && txn_axi.addr[11:8] == 4'h2 && txn_axi.addr[7:2] == UART_STATUS) {
            bins clear = { 0 };
            bins seen  = { 1 };
        }

        cp_uart_rxoverrun_observed : coverpoint txn_axi.rdata[UART_STATUS_RXOVERRUN]
            iff (!txn_axi.is_write && txn_axi.addr[11:8] == 4'h2 && txn_axi.addr[7:2] == UART_STATUS) {
            bins clear = { 0 };
            bins seen  = { 1 };
        }

        cp_uart_rxperr_observed : coverpoint txn_axi.rdata[UART_STATUS_RXPERR]
            iff (!txn_axi.is_write && txn_axi.addr[11:8] == 4'h2 && txn_axi.addr[7:2] == UART_STATUS) {
            bins clear = { 0 };
            bins seen  = { 1 };
        }

        cx_type_reg     : cross cp_txn_type, cp_reg_hitmap;
        cx_reg_wstrb    : cross cp_reg_hitmap, cp_wstrb;
        cx_type_resp    : cross cp_txn_type, cp_response {
            ignore_bins read_slverr = binsof(cp_txn_type.read) && binsof(cp_response.slverr);
        }
        cx_order_resp   : cross cp_arrival_order, cp_response;
        cx_spacing_type : cross cp_spacing, cp_txn_type;

    endgroup

    // SPI: clock polarity/phase and MOSI/MISO data patterns
    covergroup cg_spi with function sample(spi_txn txn_spi);

        cp_cpol : coverpoint txn_spi.cpol {
            bins zero = { 0 };
            bins one = { 1 };
        }

        cp_cpha : coverpoint txn_spi.cpha {
            bins zero = { 0 };
            bins one = { 1 };
        }

        cp_mosi : coverpoint txn_spi.mosi_expected {
            bins zeros = { 8'h00 };
            bins ones = { 8'hFF };
            bins alt1 = { 8'h55 };
            bins alt2 = { 8'hAA };
            bins others = default;
        }

        cp_miso : coverpoint txn_spi.miso {
            bins zeros = { 8'h00 };
            bins ones = { 8'hFF };
            bins alt1 = { 8'h55 };
            bins alt2 = { 8'hAA };
            bins others = default;
        }

        cx_cpol_cpha : cross cp_cpol, cp_cpha;
        cx_cpha_mosi : cross cp_cpha, cp_mosi {
            ignore_bins skip_others = binsof(cp_mosi.others);
        }
        cx_cpha_miso : cross cp_cpha, cp_miso {
            ignore_bins skip_others = binsof(cp_miso.others);
        }

    endgroup

    // I2C: direction, ACK/NACK, and TX/RX data patterns
    covergroup cg_i2c with function sample(i2c_txn txn_i2c);

        cp_rw_n : coverpoint txn_i2c.rw_n_expected {
            bins write = { 0 };
            bins read = { 1 };
        }

        cp_ack : coverpoint txn_i2c.nack {
            bins ack = { 0 };
            bins nack = { 1 };
        }

        cp_txdata : coverpoint txn_i2c.txdata_expected iff (!txn_i2c.rw_n_sampled) {
            bins zeros = { 8'h00 };
            bins ones = { 8'hFF };
            bins alt1 = { 8'h55 };
            bins alt2 = { 8'hAA };
            bins others = default;
        }

        cp_rxdata : coverpoint txn_i2c.rxdata iff (txn_i2c.rw_n_sampled) {
            bins zeros = { 8'h00 };
            bins ones = { 8'hFF };
            bins alt1 = { 8'h55 };
            bins alt2 = { 8'hAA };
            bins others = default;
        }

        cx_rw_n_ack : cross cp_rw_n, cp_ack;

    endgroup

    // UART RX: parity mode, stop bits, and parity-error injection
    covergroup cg_rx with function sample(uart_rx_txn txn_rx);

        cp_parity : coverpoint {txn_rx.parity_en, txn_rx.parity_mode} {
            wildcard bins none = { 2'b0? };
            bins even = { 2'b10 };
            bins odd = { 2'b11 };
        }

        cp_stop_bits : coverpoint txn_rx.stop_bits {
            bins one = { 0 };
            bins two = { 1 };
        }

        cp_perr : coverpoint txn_rx.inject_perr iff (txn_rx.parity_en) {
            bins no_error = { 0 };
            bins error = { 1 };
        }

        cx_parity_stop : cross cp_parity, cp_stop_bits;

    endgroup

    // UART TX: parity mode, stop bits, and data patterns
    covergroup cg_tx with function sample(uart_tx_txn txn_tx);

        cp_parity : coverpoint {txn_tx.parity_en, txn_tx.parity_mode} {
            wildcard bins none = { 2'b0? };
            bins even = { 2'b10 };
            bins odd = { 2'b11 };
        }

        cp_stop_bits : coverpoint txn_tx.stop_bits {
            bins one = { 0 };
            bins two = { 1 };
        }

        cp_data : coverpoint txn_tx.data_sampled {
            bins zeros = { 8'h00 };
            bins ones = { 8'hFF };
            bins alt1 = { 8'h55 };
            bins alt2 = { 8'hAA };
            bins others = default;
        }

        cx_parity_stop : cross cp_parity, cp_stop_bits;

    endgroup

    // UART FIFO: occupancy, event type, and full-to-empty cycle
    covergroup cg_fifo with function sample(uart_fifo_txn txn_fifo, logic complete);

        cp_occupancy : coverpoint txn_fifo.occupancy {
            bins empty = { 0 };
            bins full = { 64 };
            bins intermediate = {[1 : 63]};
        }

        cp_event : coverpoint txn_fifo.event_t {
            bins push = { PUSH };
            bins pop = { POP };
            bins drop = { DROP };
        }

        cp_full_to_empty : coverpoint complete {
            bins not_complete = { 0 };
            bins complete = { 1 };
        }

    endgroup


    // ========================================================
    // CONSTRUCTION
    // ========================================================

    function new(mailbox #(axi_txn) mon2cov,
                 mailbox #(spi_txn) spi2cov,
                 mailbox #(i2c_txn) i2c2cov,
                 mailbox #(uart_rx_txn) rx2cov,
                 mailbox #(uart_tx_txn) tx2cov);
        this.mon2cov = mon2cov;
        this.spi2cov = spi2cov;
        this.i2c2cov = i2c2cov;
        this.rx2cov = rx2cov;
        this.tx2cov = tx2cov;

        cg_axi = new();
        cg_spi = new();
        cg_i2c = new();
        cg_rx = new();
        cg_tx = new();
        cg_fifo = new();
    endfunction


    // ========================================================
    // REPORT
    // ========================================================

    function void print();
        $display("==============================================");
        $display(" Functional Coverage Report");
        $display(" Overall coverage  : %0.2f%%", $get_coverage());
        $display("==============================================");
        $display(" AXI");
        $display("   cp_txn_type      : %0.2f%%", cg_axi.cp_txn_type.get_coverage());
        $display("   cp_reg_hitmap    : %0.2f%%", cg_axi.cp_reg_hitmap.get_coverage());
        $display("   cp_wstrb         : %0.2f%%", cg_axi.cp_wstrb.get_coverage());
        $display("   cp_arrival_order : %0.2f%%", cg_axi.cp_arrival_order.get_coverage());
        $display("   cp_spacing       : %0.2f%%", cg_axi.cp_spacing.get_coverage());
        $display("   cp_response      : %0.2f%%", cg_axi.cp_response.get_coverage());
        $display("   cx_type_reg      : %0.2f%%", cg_axi.cx_type_reg.get_coverage());
        $display("   cx_reg_wstrb     : %0.2f%%", cg_axi.cx_reg_wstrb.get_coverage());
        $display("   cx_type_resp     : %0.2f%%", cg_axi.cx_type_resp.get_coverage());
        $display("   cx_order_resp    : %0.2f%%", cg_axi.cx_order_resp.get_coverage());
        $display("   cx_spacing_type  : %0.2f%%", cg_axi.cx_spacing_type.get_coverage());
        $display("   cp_spi_rxvalid_observed    : %0.2f%%", cg_axi.cp_spi_rxvalid_observed.get_coverage());
        $display("   cp_i2c_rxvalid_observed    : %0.2f%%", cg_axi.cp_i2c_rxvalid_observed.get_coverage());
        $display("   cp_i2c_nack_observed       : %0.2f%%", cg_axi.cp_i2c_nack_observed.get_coverage());
        $display("   cp_uart_rxvalid_observed   : %0.2f%%", cg_axi.cp_uart_rxvalid_observed.get_coverage());
        $display("   cp_uart_rxoverrun_observed : %0.2f%%", cg_axi.cp_uart_rxoverrun_observed.get_coverage());
        $display("   cp_uart_rxperr_observed    : %0.2f%%", cg_axi.cp_uart_rxperr_observed.get_coverage());
        $display("----------------------------------------------");
        $display(" SPI");
        $display("   cp_cpol          : %0.2f%%", cg_spi.cp_cpol.get_coverage());
        $display("   cp_cpha          : %0.2f%%", cg_spi.cp_cpha.get_coverage());
        $display("   cp_mosi          : %0.2f%%", cg_spi.cp_mosi.get_coverage());
        $display("   cp_miso          : %0.2f%%", cg_spi.cp_miso.get_coverage());
        $display("   cx_cpol_cpha     : %0.2f%%", cg_spi.cx_cpol_cpha.get_coverage());
        $display("   cx_cpha_mosi     : %0.2f%%", cg_spi.cx_cpha_mosi.get_coverage());
        $display("   cx_cpha_miso     : %0.2f%%", cg_spi.cx_cpha_miso.get_coverage());
        $display("----------------------------------------------");
        $display(" I2C");
        $display("   cp_rw_n          : %0.2f%%", cg_i2c.cp_rw_n.get_coverage());
        $display("   cp_ack           : %0.2f%%", cg_i2c.cp_ack.get_coverage());
        $display("   cp_txdata        : %0.2f%%", cg_i2c.cp_txdata.get_coverage());
        $display("   cp_rxdata        : %0.2f%%", cg_i2c.cp_rxdata.get_coverage());
        $display("   cx_rw_n_ack      : %0.2f%%", cg_i2c.cx_rw_n_ack.get_coverage());
        $display("----------------------------------------------");
        $display(" UART RX");
        $display("   cp_parity        : %0.2f%%", cg_rx.cp_parity.get_coverage());
        $display("   cp_stop_bits     : %0.2f%%", cg_rx.cp_stop_bits.get_coverage());
        $display("   cp_perr          : %0.2f%%", cg_rx.cp_perr.get_coverage());
        $display("   cx_parity_stop   : %0.2f%%", cg_rx.cx_parity_stop.get_coverage());
        $display("----------------------------------------------");
        $display(" UART TX");
        $display("   cp_parity        : %0.2f%%", cg_tx.cp_parity.get_coverage());
        $display("   cp_stop_bits     : %0.2f%%", cg_tx.cp_stop_bits.get_coverage());
        $display("   cp_data          : %0.2f%%", cg_tx.cp_data.get_coverage());
        $display("   cx_parity_stop   : %0.2f%%", cg_tx.cx_parity_stop.get_coverage());
        $display("----------------------------------------------");
        $display(" UART FIFO");
        $display("   cp_occupancy     : %0.2f%%", cg_fifo.cp_occupancy.get_coverage());
        $display("   cp_event         : %0.2f%%", cg_fifo.cp_event.get_coverage());
        $display("   cp_full_to_empty : %0.2f%%", cg_fifo.cp_full_to_empty.get_coverage());
        $display("==============================================");
    endfunction


    // ========================================================
    // CLASSIFIERS
    // ========================================================

    function void classify(input axi_txn txn, output arrival_order_e order, output spacing_e space);
        if (txn.awvalid_delay < txn.wvalid_delay) order = ADDR_FIRST;
        else if (txn.awvalid_delay > txn.wvalid_delay) order = DATA_FIRST;
        else order = CONCURRENT;

        if (txn.gap_delay == 0) space = BACK_TO_BACK;
        else space = GAPPED;
    endfunction

    function void full_to_empty(input uart_fifo_txn txn, output logic complete);
        complete = 0;
        if (txn.occupancy == 64) fifo_seen_full = 1;
        if (txn.occupancy == 0 && fifo_seen_full) begin
            complete = 1;
            fifo_seen_full = 0;
        end
    endfunction


    // ========================================================
    // MAIN LOOP
    // ========================================================

    task run();
        fork
            forever begin
                arrival_order_e order;
                spacing_e space;

                axi_txn txn_axi;
                mon2cov.get(txn_axi);
                classify(txn_axi, order, space);
                cg_axi.sample(txn_axi, order, space);
            end

            forever begin
                spi_txn txn_spi;
                spi2cov.get(txn_spi);
                cg_spi.sample(txn_spi);
            end

            forever begin
                i2c_txn txn_i2c;
                i2c2cov.get(txn_i2c);
                cg_i2c.sample(txn_i2c);
            end

            forever begin
                uart_rx_txn txn_rx;
                rx2cov.get(txn_rx);
                cg_rx.sample(txn_rx);
            end

            forever begin
                uart_tx_txn txn_tx;
                tx2cov.get(txn_tx);
                cg_tx.sample(txn_tx);
            end

            forever begin
                logic complete;

                uart_fifo_txn txn_fifo;
                uart_fifo_model::fifo2cov.get(txn_fifo);
                full_to_empty(txn_fifo, complete);
                cg_fifo.sample(txn_fifo, complete);
            end
        join
    endtask

endclass
