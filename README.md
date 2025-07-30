# AXI-Stream-FIFO-Verilog
Verilog implementation of a parameterized AXI4-Stream FIFO with full handshaking and flow control. Includes RTL diagram, X-safe memory initialization, and support for tdata, tvalid, tready, and other AXI signals.

# Features

- **AXI4-Stream protocol compliant** (`tvalid`, `tready`, `tdata`, `tkeep`, `tstrb`, `tlast`, `tdest`, `tid`, `tuser`)
- **Parameterized widths and depth** — `DATA_WIDTH`, `DEPTH`, `ID_WIDTH`, etc.
- **Synchronous operation** with a single clock (`aclk`) and active-low reset (`aresetn`)
- **X-safe memory initialization** to prevent undefined simulation states
- **Status signals**: `fifo_full`, `fifo_empty`, and `fifo_count`
- **Modular, reusable, and synthesizable** Verilog RTL
- **Clean testbench structure** for verification

# Architectural Overview
The AXI4-Stream FIFO serves as a buffering stage between AXI-compliant master and slave modules. It provides temporary storage using a circular memory array with independent read and write pointers. The FIFO ensures data integrity and protocol compliance while managing backpressure gracefully.

# Data Flow Summary
- **Slave Side**:
  - Accepts data on `s_axis_*` when `s_axis_tvalid && s_axis_tready`
  - Packs data and sideband signals into a single wide word (`write_data`)
- **FIFO Core**:
  - Circular buffer `fifo_mem[]`
  - Pointers: `wr_ptr`, `rd_ptr`
  - Counter: `count`
- **Master Side**:
  - Unpacks data from `read_data`
  - Provides valid output on `m_axis_*` when ready

  # RTL Diagram
  <img width="500" height="500" alt="FIFO RTL" src="https://github.com/user-attachments/assets/b62ccc36-cce7-4cfc-af96-6a035ce3a058" />

  # Simulation
  <img width="500" height="500" alt="Screenshot 2025-07-30 071706" src="https://github.com/user-attachments/assets/ad47900f-2a69-4a79-ba35-ed7877431a8b" />

