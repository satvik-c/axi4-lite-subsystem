class axi_monitor;

    virtual axi4_lite_if.tb_monitor vif;
    mailbox #(axi_txn) mon2scb;
    mailbox rst_listeners[$];

    function new(virtual axi4_lite_if.tb_monitor vif, mailbox #(axi_txn) mon2scb);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    function void connect_rst(mailbox m);
        rst_listeners.push_back(m);
    endfunction

    task monitor_write();
        axi_txn write_txn = new();
        write_txn.is_write = 1;
        
        fork
            begin
                do begin
                    @(vif.mon);
                end while (!(vif.mon.AWREADY && vif.mon.AWVALID));
                write_txn.addr = vif.mon.AWADDR;
                write_txn.prot = vif.mon.AWPROT;
            end
            begin
                do begin
                    @(vif.mon);
                end while (!(vif.mon.WREADY && vif.mon.WVALID));
                write_txn.wdata = vif.mon.WDATA;
                write_txn.wstrb = vif.mon.WSTRB;
            end
        join

        do begin
            @(vif.mon);
        end while (!(vif.mon.BREADY && vif.mon.BVALID));
        write_txn.resp = vif.mon.BRESP;

        mon2scb.put(write_txn);
    endtask

    task monitor_read();
        axi_txn read_txn = new();
        read_txn.is_write = 0;

        do begin
            @(vif.mon);
        end while (!(vif.mon.ARREADY && vif.mon.ARVALID));
        read_txn.addr = vif.mon.ARADDR;
        read_txn.prot = vif.mon.ARPROT;

        do begin
            @(vif.mon);
        end while (!(vif.mon.RREADY && vif.mon.RVALID));
        read_txn.rdata = vif.mon.RDATA;
        read_txn.resp = vif.mon.RRESP;

        mon2scb.put(read_txn);
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
                @(negedge vif.ARESETn);
                disable mon_process;
                foreach (rst_listeners[i]) rst_listeners[i].put(1);
            end
        join
    endtask

endclass
