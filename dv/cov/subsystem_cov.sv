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

    mailbox #(axi_txn) mon2cov;
    mailbox #(spi_txn) spi2cov;
    mailbox #(i2c_txn) i2c2cov;

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

        cx_type_reg     : cross cp_txn_type, cp_reg_hitmap;
        cx_reg_wstrb    : cross cp_reg_hitmap, cp_wstrb;
        cx_type_resp    : cross cp_txn_type, cp_response;
        cx_order_resp   : cross cp_arrival_order, cp_response;
        cx_spacing_type : cross cp_spacing, cp_txn_type;
        
    endgroup

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
    

    function new (mailbox #(axi_txn) mon2cov, mailbox #(spi_txn) spi2cov, mailbox #(i2c_txn) i2c2cov);
        this.mon2cov = mon2cov;
        this.spi2cov = spi2cov;
        this.i2c2cov = i2c2cov;
        cg_axi = new();
        cg_spi = new();
        cg_i2c = new();
    endfunction

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
        $display("==============================================");
    endfunction

    function void classify(input axi_txn txn, output arrival_order_e order, output spacing_e space);
        if (txn.awvalid_delay < txn.wvalid_delay) order = ADDR_FIRST;
        else if (txn.awvalid_delay > txn.wvalid_delay) order = DATA_FIRST;
        else order = CONCURRENT;

        if (txn.gap_delay == 0) space = BACK_TO_BACK;
        else space = GAPPED;
    endfunction

    task run();
        fork
            forever begin
                axi_txn txn_axi;
                arrival_order_e order;
                spacing_e space;
                
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
        join
    endtask

endclass
