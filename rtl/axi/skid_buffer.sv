module skid_buffer
#(
    // ========================================================
    // PARAMETERS
    // ========================================================

    parameter WIDTH = 32
)(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic                    clk,
    input  logic                    rst_n,

    // Upstream Interface
    input  logic                    up_valid,
    output logic                    up_ready,
    input  logic [WIDTH-1:0]        up_data,

    // Downstream Interface
    output logic                    down_valid,
    input  logic                    down_ready,
    output logic [WIDTH-1:0]        down_data
);

    // ========================================================
    // FSM STATES TYPEDEF
    // ========================================================

    typedef enum logic [1:0] {
        EMPTY,
        BUSY,
        FULL
    } skid_state_t;


    // ========================================================
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // FSM States
    skid_state_t current_state;
    skid_state_t next_state;

    // Control Signals
    logic load_down_data;
    logic load_skid_data;
    logic transfer_skid;

    // Buffer Registers
    logic [WIDTH-1:0] skid_data;


    // ========================================================
    // FSM
    // ========================================================

    // Sequential state transition
    always_ff @(posedge clk) begin
        if (!rst_n) current_state <= EMPTY;
        else        current_state <= next_state;
    end

    // Next-state transition combinational logic
    always_comb begin
        next_state     = current_state;
        load_down_data = 1'b0;
        load_skid_data = 1'b0;
        transfer_skid  = 1'b0;

        case (current_state)
            EMPTY: begin
                if (up_valid) begin
                    next_state     = BUSY;
                    load_down_data = 1'b1;
                end
            end

            BUSY: begin
                if (up_valid && down_ready) begin
                    load_down_data = 1'b1;
                end else if (!up_valid && down_ready) begin
                    next_state = EMPTY;
                end else if (up_valid && !down_ready) begin
                    next_state     = FULL;
                    load_skid_data = 1'b1;
                end
            end

            FULL: begin
                if (down_ready) begin
                    next_state    = BUSY;
                    transfer_skid = 1'b1;
                end
            end

            default: begin
                next_state     = EMPTY;
                load_down_data = 1'b0;
                load_skid_data = 1'b0;
                transfer_skid  = 1'b0;
            end
        endcase
    end

    // Output logic depending on current state
    always_comb begin
        case (current_state)
            EMPTY: begin
                up_ready   = 1'b1;
                down_valid = 1'b0;
            end

            BUSY: begin
                up_ready   = 1'b1;
                down_valid = 1'b1;
            end

            FULL: begin
                up_ready   = 1'b0;
                down_valid = 1'b1;
            end

            default: begin
                up_ready   = 1'b0;
                down_valid = 1'b0;
            end
        endcase
    end


    // ========================================================
    // DATAPATH REGISTER UPDATES
    // ========================================================

    // Datapath register updates
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            down_data <= '0;
            skid_data <= '0;
        end else begin
            if (load_down_data) down_data <= up_data;
            if (load_skid_data) skid_data <= up_data;
            if (transfer_skid)  down_data <= skid_data;
        end
    end

`ifdef FORMAL

    // W1 [assert] The input skid buffers do not accept new upstream data when in the FULL state.

    initial assume (!rst_n);

    // assume master's VALID stays high until skid buffer's READY handshake
    always @(posedge clk) begin
        if (rst_n && $past(rst_n) && $past(up_valid) && !$past(up_ready)) begin
            assume (up_valid);
            assume (up_data == $past(up_data));
        end
    end

    // assert that FSM only enters defined states
    always @(posedge clk) begin
        if (rst_n) assert (current_state == EMPTY || current_state == BUSY || current_state == FULL);
    end

    // assert that skid buffer's READY never goes high when it's full
    always @(posedge clk) begin
        if (rst_n) assert (!(current_state == FULL && up_ready));
    end

    // assert that skid buffer's VALID stays high until slave's READY handshake
    always @(posedge clk) begin
        if (rst_n && $past(rst_n) && $past(down_valid) && !$past(down_ready)) begin
            assert (down_valid);
            assert (down_data == $past(down_data));
        end
    end

    // assign arbitrary tag to incoming data
    (* anyconst *) logic [WIDTH-1:0] f_tag;
    logic                            f_down_has_tag;
    logic                            f_skid_has_tag;

    // tagging data loaded to down_data or skid_data or transferred
    always @(posedge clk) begin
        if (!rst_n) begin
            f_down_has_tag <= 1'b0;
            f_skid_has_tag <= 1'b0;
        end else begin
            if (load_down_data)     f_down_has_tag <= (up_data == f_tag);
            else if (transfer_skid) f_down_has_tag <= f_skid_has_tag;

            if (load_skid_data)     f_skid_has_tag <= (up_data == f_tag);
            else if (transfer_skid) f_skid_has_tag <= 1'b0;
        end
    end

    // assert that every tagged data == arbitrary f_tag
    always @(posedge clk) begin
        if (rst_n) begin
            if (f_down_has_tag) assert (down_data == f_tag);
            if (f_skid_has_tag) assert (skid_data == f_tag);
        end
    end

    // assert that either down_data or skid_data is tagged 1 clk after skid buffer's handshake
    always_ff @(posedge clk) begin
        if (rst_n && $past(rst_n)) begin
            if ($past(up_valid && up_ready && (up_data == f_tag))) begin
                assert (f_down_has_tag || f_skid_has_tag);
            end
        end
    end

    // cover that FSM enters full, exits full, and loads data into skid_data
    always @(posedge clk) begin
        cover (current_state == FULL);
        cover (current_state == FULL && transfer_skid);
        cover (f_skid_has_tag);
    end

`endif

endmodule
