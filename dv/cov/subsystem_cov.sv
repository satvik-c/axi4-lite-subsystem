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

    covergroup cg_subsystem with function sample(axi_txn txn, arrival_order_e order, spacing_e space);

        cp_txn_type : coverpoint txn.is_write {
            bins read = { 0 };
            bins write = { 1 };
        }

        cp_reg_hitmap : coverpoint txn.addr {
            bins spi[] = { 12'h000, 12'h004, 12'h008, 12'h00C, 12'h010 };
            bins i2c[] = { 12'h100, 12'h104, 12'h108, 12'h10C, 12'h110, 12'h114 };
            bins uart[] = { 12'h200, 12'h204, 12'h208, 12'h20C, 12'h210 };
        }

        cp_wstrb : coverpoint txn.wstrb {
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

        cp_response : coverpoint txn.resp {
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

    function new (mailbox #(axi_txn) mon2cov);
        this.mon2cov = mon2cov;
        cg_subsystem = new();
    endfunction

    function void print();
        $display("==============================================");
        $display(" Functional Coverage Report");
        $display("==============================================");
        $display(" Overall coverage  : %0.2f%%", cg_subsystem.get_coverage());
        $display("----------------------------------------------");
        $display(" Coverpoints");
        $display("----------------------------------------------");
        $display("   cp_txn_type      : %0.2f%%", cg_subsystem.cp_txn_type.get_coverage());
        $display("   cp_reg_hitmap    : %0.2f%%", cg_subsystem.cp_reg_hitmap.get_coverage());
        $display("   cp_wstrb         : %0.2f%%", cg_subsystem.cp_wstrb.get_coverage());
        $display("   cp_arrival_order : %0.2f%%", cg_subsystem.cp_arrival_order.get_coverage());
        $display("   cp_spacing       : %0.2f%%", cg_subsystem.cp_spacing.get_coverage());
        $display("   cp_response      : %0.2f%%", cg_subsystem.cp_response.get_coverage());
        $display("----------------------------------------------");
        $display(" Crosses");
        $display("----------------------------------------------");
        $display("   cx_type_reg      : %0.2f%%", cg_subsystem.cx_type_reg.get_coverage());
        $display("   cx_reg_wstrb     : %0.2f%%", cg_subsystem.cx_reg_wstrb.get_coverage());
        $display("   cx_type_resp     : %0.2f%%", cg_subsystem.cx_type_resp.get_coverage());
        $display("   cx_order_resp    : %0.2f%%", cg_subsystem.cx_order_resp.get_coverage());
        $display("   cx_spacing_type  : %0.2f%%", cg_subsystem.cx_spacing_type.get_coverage());
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
        forever begin
            axi_txn txn;
            arrival_order_e order;
            spacing_e space;

            mon2cov.get(txn);
            classify(txn, order, space);

            cg_subsystem.sample(txn, order, space);
        end
    endtask

endclass
