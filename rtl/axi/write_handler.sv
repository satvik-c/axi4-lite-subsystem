module write_handler
#(
    // ========================================================
    // PARAMETERS
    // ========================================================

    // Internal localparams
    localparam AW_WIDTH = 12 + 3,
    localparam W_WIDTH  = 32 + 4
)(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic        clk,
    input  logic        rst_n,

    // AXI Write Address Channel
    input  logic [11:0] AWADDR,
    input  logic [2:0]  AWPROT,
    output logic        AWREADY,
    input  logic        AWVALID,

    // AXI Write Data Channel
    input  logic [31:0] WDATA,
    input  logic [3:0]  WSTRB,
    output logic        WREADY,
    input  logic        WVALID,

    // AXI Write Response Channel
    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY,

    // Register Write Interface
    output logic         wr_commit,
    output logic [11:0]  wr_addr_long,
    output logic [31:0]  wdata,
    output logic [3:0]   wstrb,
    input  logic         slverr,
    input  logic         wr_dcerr
);

    // ========================================================
    // FSM STATES TYPEDEF
    // ========================================================

    typedef enum logic [1:0] {
        W_IDLE,
        W_WAIT_DATA,
        W_WAIT_ADDR,
        W_RESP
    } write_state_t;


    // ========================================================
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // FSM States
    write_state_t current_state;
    write_state_t next_state;

    // Write Address Skid Buffer Interface
    logic                aw_down_valid;
    logic                aw_down_ready;
    logic [AW_WIDTH-1:0] aw_down_data;

    // Write Address Channel Split
    logic [2:0] aw_prot;

    // Write Data Skid Buffer Interface
    logic               w_down_valid;
    logic               w_down_ready;
    logic [W_WIDTH-1:0] w_down_data;


    // ========================================================
    // WRITE ADDRESS SKID BUFFER
    // ========================================================

    // Split buffered address channel back into address and prot
    assign {wr_addr_long, aw_prot} = aw_down_data;

    skid_buffer #(
        .WIDTH(AW_WIDTH)
    ) aw_skid (
        .clk(clk),
        .rst_n(rst_n),
        .up_valid(AWVALID),
        .up_ready(AWREADY),
        .up_data({AWADDR, AWPROT}),
        .down_valid(aw_down_valid),
        .down_ready(aw_down_ready),
        .down_data(aw_down_data)
    );


    // ========================================================
    // WRITE DATA SKID BUFFER
    // ========================================================

    // Split buffered data channel back into data and strobes
    assign {wdata, wstrb} = w_down_data;

    skid_buffer #(
        .WIDTH(W_WIDTH)
    ) w_skid (
        .clk(clk),
        .rst_n(rst_n),
        .up_valid(WVALID),
        .up_ready(WREADY),
        .up_data({WDATA, WSTRB}),
        .down_valid(w_down_valid),
        .down_ready(w_down_ready),
        .down_data(w_down_data)
    );


    // ========================================================
    // FSM
    // ========================================================

    // Sequential state register for the FSM
    always_ff @(posedge clk) begin
        if (!rst_n) current_state <= W_IDLE;
        else        current_state <= next_state;
    end

    // Next-state transition combinational logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            W_IDLE: begin
                if (aw_down_valid && w_down_valid) next_state = W_RESP;
                else if (aw_down_valid)            next_state = W_WAIT_DATA;
                else if (w_down_valid)             next_state = W_WAIT_ADDR;
            end
            W_WAIT_DATA: if (w_down_valid)  next_state = W_RESP;
            W_WAIT_ADDR: if (aw_down_valid) next_state = W_RESP;
            W_RESP:      if (BREADY)        next_state = W_IDLE;
            default: ;
        endcase
    end

    // Output control signals combinational logic
    always_comb begin
        wr_commit     = 1'b0;
        aw_down_ready = 1'b0;
        w_down_ready  = 1'b0;
        BVALID        = 1'b0;
        case (current_state)
            W_IDLE: begin
                aw_down_ready = 1'b1;
                w_down_ready  = 1'b1;
                BVALID        = 1'b0;
                if (aw_down_valid && w_down_valid) wr_commit = 1'b1;
            end
            W_WAIT_DATA: begin
                aw_down_ready = 1'b0;
                w_down_ready  = 1'b1;
                BVALID        = 1'b0;
                if (w_down_valid) wr_commit = 1'b1;
            end
            W_WAIT_ADDR: begin
                aw_down_ready = 1'b1;
                w_down_ready  = 1'b0;
                BVALID        = 1'b0;
                if (aw_down_valid) wr_commit = 1'b1;
            end
            W_RESP: begin
                aw_down_ready = 1'b0;
                w_down_ready  = 1'b0;
                BVALID        = 1'b1;
            end
            default: ;
        endcase
    end


    // ========================================================
    // DATAPATH
    // ========================================================

    // Capture write response on commit
    always_ff @(posedge clk) begin
        if (!rst_n) BRESP <= 2'b00;
        else if (wr_commit) begin
            if (slverr)        BRESP <= 2'b10;
            else if (wr_dcerr) BRESP <= 2'b11;
            else               BRESP <= 2'b00;
        end
    end

endmodule
