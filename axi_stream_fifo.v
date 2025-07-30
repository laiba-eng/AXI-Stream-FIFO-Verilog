module axi_stream_fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16,
    parameter USER_WIDTH = 1,
    parameter DEST_WIDTH = 4,
    parameter ID_WIDTH = 4
)(
    input wire aclk,
    input wire aresetn,  
    
    // AXI4-Stream Slave Interface (Input)
    input wire [DATA_WIDTH-1:0]    s_axis_tdata,
    input wire [DATA_WIDTH/8-1:0]  s_axis_tstrb,
    input wire [DATA_WIDTH/8-1:0]  s_axis_tkeep,
    input wire                     s_axis_tlast,
    input wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input wire [ID_WIDTH-1:0]      s_axis_tid,
    input wire [USER_WIDTH-1:0]    s_axis_tuser,
    input wire                     s_axis_tvalid,
    output wire                    s_axis_tready,
    
    // AXI4-Stream Master Interface (Output)
    output reg [DATA_WIDTH-1:0]    m_axis_tdata,
    output reg [DATA_WIDTH/8-1:0]  m_axis_tstrb,
    output reg [DATA_WIDTH/8-1:0]  m_axis_tkeep,
    output reg                     m_axis_tlast,
    output reg [DEST_WIDTH-1:0]    m_axis_tdest,
    output reg [ID_WIDTH-1:0]      m_axis_tid,
    output reg [USER_WIDTH-1:0]    m_axis_tuser,
    output reg                     m_axis_tvalid,
    input wire                     m_axis_tready,
    
    // Status
    output wire [$clog2(DEPTH):0]  fifo_count,
    output wire                    fifo_full,
    output wire                    fifo_empty
);

    // Calculate total width of stored data
    localparam TOTAL_WIDTH = DATA_WIDTH + 
                           (DATA_WIDTH/8) +     // tstrb
                           (DATA_WIDTH/8) +     // tkeep  
                           1 +                  // tlast
                           DEST_WIDTH +         // tdest
                           ID_WIDTH +           // tid
                           USER_WIDTH;          // tuser

    // FIFO Memory and Pointers
    reg [TOTAL_WIDTH-1:0] fifo_mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] count;
    
    // Initialize memory to prevent X states
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            fifo_mem[i] = 0;  // Initialize all memory locations
        end
    end
    
    // Internal signals
    wire write_enable, read_enable;
    wire [TOTAL_WIDTH-1:0] write_data, read_data;
    
    // AXI4-Stream Handshake Logic
    assign write_enable = s_axis_tvalid & s_axis_tready;
    assign read_enable = m_axis_tvalid & m_axis_tready;
    
    // Pack input data
    assign write_data = {
        s_axis_tuser,
        s_axis_tid,
        s_axis_tdest,
        s_axis_tlast,
        s_axis_tkeep,
        s_axis_tstrb,
        s_axis_tdata
    };
    
    // Ready signal - can accept data when not full
    assign s_axis_tready = !fifo_full;
    
    // Unpack output data - READ FROM MEMORY, NOT WIRE
    assign read_data = fifo_mem[rd_ptr];
    
    // FIFO Control Logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Initialize ALL registers during reset
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            m_axis_tvalid <= 0;
            
            // Initialize ALL output registers to prevent X states
            m_axis_tdata <= 0;
            m_axis_tstrb <= 0;
            m_axis_tkeep <= 0;
            m_axis_tlast <= 0;
            m_axis_tdest <= 0;
            m_axis_tid <= 0;
            m_axis_tuser <= 0;
        end else begin
            // Write Operation
            if (write_enable) begin
                fifo_mem[wr_ptr] <= write_data;
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
            end
            
            // Read Operation - Update output registers
            if (!m_axis_tvalid || read_enable) begin
                if (count > 0 || write_enable) begin
                    // Unpack data from FIFO memory
                    {m_axis_tuser,
                     m_axis_tid,
                     m_axis_tdest,
                     m_axis_tlast,
                     m_axis_tkeep,
                     m_axis_tstrb,
                     m_axis_tdata} <= read_data;
                    
                    // Advance read pointer only if actually reading
                    if (m_axis_tvalid && read_enable) begin
                        rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
                    end
                    
                    m_axis_tvalid <= 1;
                end else begin
                    m_axis_tvalid <= 0;
                    // Keep outputs stable when no valid data
                end
            end
            
            // Update count
            case ({write_enable, read_enable && m_axis_tvalid})
                2'b10: count <= count + 1;      // Write only
                2'b01: count <= count - 1;      // Read only
                2'b11: count <= count;          // Both (no change)
                default: count <= count;        // No operation
            endcase
        end
    end
    
    // Status signals
    assign fifo_count = count;
    assign fifo_full = (count == DEPTH);
    assign fifo_empty = (count == 0);
    
endmodule

