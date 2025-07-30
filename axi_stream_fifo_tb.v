module axi_stream_fifo_tb;
    localparam DATA_WIDTH = 32;
    localparam DEPTH = 8;
    localparam USER_WIDTH = 4;
    localparam DEST_WIDTH = 4;
    localparam ID_WIDTH = 4;
    
    reg aclk;
    reg aresetn;
    
    // AXI4-Stream Slave Interface (Input)
    reg [DATA_WIDTH-1:0]    s_axis_tdata;
    reg [DATA_WIDTH/8-1:0]  s_axis_tstrb;
    reg [DATA_WIDTH/8-1:0]  s_axis_tkeep;
    reg                     s_axis_tlast;
    reg [DEST_WIDTH-1:0]    s_axis_tdest;
    reg [ID_WIDTH-1:0]      s_axis_tid;
    reg [USER_WIDTH-1:0]    s_axis_tuser;
    reg                     s_axis_tvalid;
    wire                    s_axis_tready;
    
    // AXI4-Stream Master Interface (Output)
    wire [DATA_WIDTH-1:0]    m_axis_tdata;
    wire [DATA_WIDTH/8-1:0]  m_axis_tstrb;
    wire [DATA_WIDTH/8-1:0]  m_axis_tkeep;
    wire                     m_axis_tlast;
    wire [DEST_WIDTH-1:0]    m_axis_tdest;
    wire [ID_WIDTH-1:0]      m_axis_tid;
    wire [USER_WIDTH-1:0]    m_axis_tuser;
    wire                     m_axis_tvalid;
    reg                      m_axis_tready;
    
    // Status
    wire [$clog2(DEPTH):0] fifo_count;
    wire fifo_full, fifo_empty;
    
    // Instantiate DUT
    axi_stream_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .USER_WIDTH(USER_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tstrb(s_axis_tstrb),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tdest(s_axis_tdest),
        .s_axis_tid(s_axis_tid),
        .s_axis_tuser(s_axis_tuser),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tstrb(m_axis_tstrb),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tid(m_axis_tid),
        .m_axis_tuser(m_axis_tuser),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .fifo_count(fifo_count),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty)
    );
    
    // Clock generation
    initial aclk = 0;
    always #5 aclk = ~aclk;  // 100MHz clock
    
    // Test sequence
    initial begin
        // Initialize ALL inputs to known values FIRST
        aresetn = 0;
        s_axis_tdata = 32'h00000000;   // Initialize to known value
        s_axis_tstrb = 4'hF;           // All bytes valid
        s_axis_tkeep = 4'hF;           // All bytes kept
        s_axis_tlast = 0;
        s_axis_tdest = 0;
        s_axis_tid = 0;
        s_axis_tuser = 0;
        s_axis_tvalid = 0;
        m_axis_tready = 0;
        
        // Hold reset for several clock cycles
        #50;
        aresetn = 1;
        #20;  // Allow reset to complete
        
        $display("=== AXI4-Stream FIFO Test Started ===");
        
        // Test 1: Basic write and read with new test values
        $display("\n--- Test 1: Basic Operations ---");
        write_axi_data(32'hDEADC0DE, 4'h1, 1, 4'hA);      // DEADCODE
        write_axi_data(32'hBADC0FFE, 4'h2, 0, 4'hB);      // BADCOFFEE (truncated to 32-bit)
        write_axi_data(32'h12345678, 4'h3, 1, 4'hC);
        
        #50;
        
        // Start reading
        m_axis_tready = 1;
        #100;
        m_axis_tready = 0;
        
        #100;
        $display("\n=== AXI4-Stream FIFO Test Completed ===");
        $finish;
    end
    
    // Task to write AXI data
    task write_axi_data(
        input [31:0] data,
        input [3:0] dest,
        input last,
        input [3:0] user_data
    );
        begin
            @(posedge aclk);
            s_axis_tdata = data;
            s_axis_tdest = dest;
            s_axis_tlast = last;
            s_axis_tuser = user_data;
            s_axis_tvalid = 1;
            
            // Wait for handshake
            wait(s_axis_tready);
            @(posedge aclk);
            s_axis_tvalid = 0;
            
            $display("Written: DATA=0x%h, DEST=%d, LAST=%b, USER=0x%h", 
                     data, dest, last, user_data);
        end
    endtask
    
    // Monitor output
    always @(posedge aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            $display("Read:    DATA=0x%h, DEST=%d, LAST=%b, USER=0x%h, COUNT=%d", 
                     m_axis_tdata, m_axis_tdest, m_axis_tlast, m_axis_tuser, fifo_count);
        end
    end
    
    // Check for X states
    always @(posedge aclk) begin
        if (aresetn) begin  // Only check after reset
            if (^m_axis_tdata === 1'bx && m_axis_tvalid) 
                $display("ERROR: m_axis_tdata has X state at time %0t", $time);
            if (^m_axis_tvalid === 1'bx) 
                $display("ERROR: m_axis_tvalid has X state at time %0t", $time);
        end
    end
    
endmodule
