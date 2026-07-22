// ========================================================
// Randomizable AXI4-Lite transaction: address, data, strobes, and handshake delays
// ========================================================

class axi_txn;


    // ========================================================
    // RANDOMIZED FIELDS
    // ========================================================

    // Transaction direction and address/data payload
    rand logic        is_write;
    rand logic [11:0] addr;
    rand logic [2:0]  prot;
    rand logic [31:0] wdata;
    rand logic [3:0]  wstrb;

    // Per-channel handshake stall delays
    rand int          awvalid_delay;
    rand int          wvalid_delay;
    rand int          bready_delay;
    rand int          arvalid_delay;
    rand int          rready_delay;
    rand int          gap_delay;


    // ========================================================
    // CAPTURED RESPONSE
    // ========================================================

    logic [31:0] rdata;
    logic [1:0]  resp;
    event        done;


    // ========================================================
    // CONSTRUCTION
    // ========================================================

    function new(logic is_write = 0, logic [3:0] page = 0, logic [5:0] reg_addr = 0,
                 logic [31:0] wdata = 0, logic [3:0] wstrb = 0, logic [2:0] prot = 0,
                 int awvalid_delay = 0, int wvalid_delay = 0, int bready_delay = 0,
                 int arvalid_delay = 0, int rready_delay = 0, int gap_delay = 0);
        this.is_write      = is_write;
        this.addr          = {page, reg_addr, 2'b00};
        this.wdata         = wdata;
        this.wstrb         = wstrb;
        this.prot          = prot;
        this.awvalid_delay = awvalid_delay;
        this.wvalid_delay  = wvalid_delay;
        this.bready_delay  = bready_delay;
        this.arvalid_delay = arvalid_delay;
        this.rready_delay  = rready_delay;
        this.gap_delay     = gap_delay;
    endfunction


    // ========================================================
    // CONSTRAINTS
    // ========================================================

    // Weight page and offset toward the mapped register space
    constraint addr_range {
        addr[11:8] dist {
            [4'h0 : 4'h2] :/ 70,
            [4'h3 : 4'hF] :/ 30
        };
        addr[7:2] dist {
            [6'h00 : 6'h05] :/ 70,
            [6'h06 : 6'h3F] :/ 30
        };
        addr[1:0] == 2'b00;
    }

    // Bias strobes toward full-word, with partial and empty coverage
    constraint wstrb_range {
        wstrb dist {
            4'b1111 := 60,
            4'b0001 := 5,
            4'b0010 := 5,
            4'b0100 := 5,
            4'b1000 := 5,
            4'b0011 := 5,
            4'b1100 := 5,
            4'b0000 := 5,
            [4'b0000 : 4'b1111] :/ 5
        };
    }

    // Bias data toward corner patterns
    constraint wdata_range {
        wdata dist {
            32'h0000_0000 := 10,
            32'hFFFF_FFFF := 10,
            32'h5555_5555 := 5,
            32'hAAAA_AAAA := 5,
            [32'h0000_0001 : 32'hFFFF_FFFE] :/ 70
        };
    }

    // Bound all handshake delays to [0, 10)
    constraint delay_range {
        awvalid_delay >= 0; awvalid_delay < 10;
        wvalid_delay  >= 0; wvalid_delay  < 10;
        bready_delay  >= 0; bready_delay  < 10;
        arvalid_delay >= 0; arvalid_delay < 10;
        rready_delay  >= 0; rready_delay  < 10;
        gap_delay     >= 0; gap_delay     < 10;
    }

endclass
