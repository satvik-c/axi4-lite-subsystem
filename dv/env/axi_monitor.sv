class axi_monitor;

    virtual axi4_lite_if.tb_monitor vif;
    mailbox #(axi_txn) mon2scb;
    mailbox mon2scb_rst;
    mailbox #(axi_txn) mon2cov;

    longint cycle_count;
    longint last_accepted_cycle;

    function new(virtual axi4_lite_if.tb_monitor vif, mailbox #(axi_txn) mon2scb, mailbox mon2scb_rst, mailbox #(axi_txn) mon2cov);
        this.vif = vif;
        this.mon2scb = mon2scb;
        this.mon2scb_rst = mon2scb_rst;
        this.mon2cov = mon2cov;
    endfunction

    task monitor_write();
        int awvalid_delay;
        int wvalid_delay;
        longint awvalid_cycle;
        longint wvalid_cycle;

        axi_txn write_txn = new();
        write_txn.is_write = 1;
        
        fork
            begin
                awvalid_delay = 0;

                while (!vif.mon.AWVALID) begin
                    @(vif.mon);
                    awvalid_delay++;
                end
                awvalid_cycle = cycle_count;

                while (!(vif.mon.AWREADY && vif.mon.AWVALID)) begin
                    @(vif.mon);
                end

                write_txn.addr = vif.mon.AWADDR;
                write_txn.prot = vif.mon.AWPROT;
                write_txn.awvalid_delay = awvalid_delay;
            end
            begin
                wvalid_delay = 0;

                while (!vif.mon.WVALID) begin
                    @(vif.mon);
                    wvalid_delay++;
                end
                wvalid_cycle = cycle_count;

                while (!(vif.mon.WREADY && vif.mon.WVALID)) begin
                    @(vif.mon);
                end

                write_txn.wdata = vif.mon.WDATA;
                write_txn.wstrb = vif.mon.WSTRB;
                write_txn.wvalid_delay = wvalid_delay;
            end
        join

        do begin
            @(vif.mon);
        end while (!(vif.mon.BREADY && vif.mon.BVALID));
        write_txn.resp = vif.mon.BRESP;
        write_txn.gap_delay = (awvalid_cycle < wvalid_cycle ? awvalid_cycle : wvalid_cycle) - last_accepted_cycle;

        last_accepted_cycle = cycle_count;

        mon2scb.put(write_txn);
        mon2cov.put(write_txn);
    endtask

    task monitor_read();
        longint arvalid_cycle;

        axi_txn read_txn = new();
        read_txn.is_write = 0;

        while (!vif.mon.ARVALID) begin
            @(vif.mon);
        end
        arvalid_cycle = cycle_count;

        while (!(vif.mon.ARREADY && vif.mon.ARVALID)) begin
            @(vif.mon);
        end
        read_txn.addr = vif.mon.ARADDR;
        read_txn.prot = vif.mon.ARPROT;

        do begin
            @(vif.mon);
        end while (!(vif.mon.RREADY && vif.mon.RVALID));
        read_txn.rdata = vif.mon.RDATA;
        read_txn.resp = vif.mon.RRESP;
        read_txn.gap_delay = arvalid_cycle - last_accepted_cycle;

        last_accepted_cycle = cycle_count;

        mon2scb.put(read_txn);
        mon2cov.put(read_txn);
    endtask

    task run();
        fork
            forever begin
                wait (vif.ARESETn === 1);

                fork : mon_process
                    begin
                        fork
                            forever begin
                                monitor_write();
                            end
                            
                            forever begin
                                monitor_read();
                            end
                        join
                    end
                join
            end

            forever begin
                @(vif.mon);
                cycle_count++;
            end
            
            forever begin
                @(negedge vif.ARESETn);
                disable mon_process;
                mon2scb_rst.put(1);
                last_accepted_cycle = cycle_count;
            end
        join
    endtask

endclass
