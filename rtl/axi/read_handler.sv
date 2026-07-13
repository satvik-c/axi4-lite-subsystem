module read_handler
#(
    // ========================================================
    // PARAMETERS
    // ========================================================

    // Internal localparams
    localparam AR_WIDTH = 12 + 3
)(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic        clk,
    input  logic        rst_n,

    // AXI Read Address Channel
    input  logic [11:0] ARADDR,
    input  logic [2:0]  ARPROT,
    input  logic        ARVALID,
    output logic        ARREADY,

    // AXI Read Data Channel
    output logic [31:0] RDATA,
    output logic [1:0]  RRESP,
    output logic        RVALID,
    input  logic        RREADY,

    // Register Read Interface
    output logic         rd_commit,
    output logic [11:0]  rd_addr_long,
    input  logic [31:0]  rdata,
    input  logic         rd_dcerr
);

    // ========================================================
    // FSM STATES TYPEDEF
    // ========================================================

    typedef enum logic {
        R_IDLE,
        R_RESP
    } read_state_t;


    // ========================================================
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // FSM States
    read_state_t current_state;
    read_state_t next_state;

    // Skid Buffer Interface
    logic                ar_down_valid;
    logic                ar_down_ready;
    logic [AR_WIDTH-1:0] ar_down_data;

    // Address Channel Split
    logic [2:0] ar_prot;


    // ========================================================
    // READ ADDRESS SKID BUFFER
    // ========================================================

    // Split buffered address channel back into address and prot
    assign {rd_addr_long, ar_prot} = ar_down_data;

    skid_buffer #(
        .WIDTH(AR_WIDTH)
    ) ar_skid (
        .clk(clk),
        .rst_n(rst_n),
        .up_valid(ARVALID),
        .up_ready(ARREADY),
        .up_data({ARADDR, ARPROT}),
        .down_valid(ar_down_valid),
        .down_ready(ar_down_ready),
        .down_data(ar_down_data)
    );


    // ========================================================
    // FSM
    // ========================================================

    // Sequential state register for the FSM
    always_ff @(posedge clk) begin
        if (!rst_n) current_state <= R_IDLE;
        else        current_state <= next_state;
    end

    // Next-state transition combinational logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            R_IDLE:  if (ar_down_valid) next_state = R_RESP;
            R_RESP:  if (RREADY)        next_state = R_IDLE;
            default: ;
        endcase
    end

    // Output control signals combinational logic
    always_comb begin
        rd_commit     = 1'b0;
        ar_down_ready = 1'b0;
        RVALID        = 1'b0;
        case (current_state)
            R_IDLE: begin
                ar_down_ready = 1'b1;
                RVALID        = 1'b0;
                if (ar_down_valid) rd_commit = 1'b1;
            end
            R_RESP: begin
                ar_down_ready = 1'b0;
                RVALID        = 1'b1;
            end
            default: ;
        endcase
    end


    // ========================================================
    // DATAPATH
    // ========================================================

    // Capture read data and response on commit
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            RDATA <= '0;
            RRESP <= 2'b00;
        end else if (rd_commit) begin
            RDATA <= rdata;
            RRESP <= rd_dcerr ? 2'b11 : 2'b00;
        end
    end

endmodule
