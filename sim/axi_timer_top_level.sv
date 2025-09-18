module axi_timer_top (
    input logic axi_clk,
    input logic rst_n,

    input logic [31:0] AWADDR,
    input logic AWVALID,
    output logic AWREADY,

    input logic [31:0] WDDATA,
    input logic [3:0] WDSTRB,
    input logic WDVALID,
    output logic WDREADY,

    output logic [1:0] BRESP,
    output logic BVALID,
    input logic BREADY,

    input logic [31:0] ARADDR,
    input logic ARVALID,
    output logic ARREADY,

    output logic [31:0] RDATA,
    output logic [1:0] RRESP,
    output logic RVALID,
    input logic RREADY
);

  // internal registers
  logic [31:0] control_reg;
  logic [31:0] prescaler_reg;
  logic [31:0] counter_reg;

  // internal connection
  logic [31:0] counter_wire;
  logic [31:0] wr_addr;
  logic [31:0] wr_data;
  logic        wr_en;

  // internal logic for read
  logic [31:0] rd_addr;
  logic        rd_req;

  // read MUX
  logic [31:0] read_mux;

  // initializing timer
  timer_core u_timer_core (
      .axi_clk,  //implicit connections
      .rst_n,
      .enable(control_reg[0]),
      .reset_counter(control_reg[1]),
      .prescaler(prescaler_reg),
      .counter(counter_wire)
  );

  // initializing axi_write
  axi_write u_axi_write (
      .axi_clk,
      .rst_n,
      .AWADDR,
      .AWVALID,
      .AWREADY,
      .WDDATA,
      .WDSTRB,
      .WDVALID,
      .WDREADY,
      .BRESP,
      .BVALID,
      .BREADY,
      .data_out  (wr_data),
      .addr_out  (wr_addr),
      .data_valid(wr_en)
  );

  // write interface
  always_ff @(posedge axi_clk or negedge rst_n) begin
    if (!rst_n) begin
      control_reg   <= 32'd0;
      prescaler_reg <= 32'd0;
    end else if (wr_en) begin
      case (wr_addr[3:0])
        4'h0: control_reg <= wr_data;
        4'h4: prescaler_reg <= wr_data;
        default: ;  // do nothing for other addresses
      endcase
    end
  end

  // read MUX
  // cpu picks which reg it wants to read (prescaler, count etc.)
  always_comb begin
    case (rd_addr[3:0])
      4'h0: read_mux = control_reg;
      4'h4: read_mux = prescaler_reg;
      4'h8: read_mux = counter_wire;
      default: read_mux = 32'd0;
    endcase
  end

  // initializing axi_read
  axi_read u_axi_read (
      .axi_clk,
      .rst_n,
      .ARADDR,
      .ARVALID,
      .ARREADY,
      .RDATA,
      .RREADY,
      .RVALID,
      .RRESP,
      .addr_out(rd_addr),
      .read_req(rd_req),
      .data_in(read_mux),
      .data_ready(1'b1)  // always ready for this example
  );

endmodule
