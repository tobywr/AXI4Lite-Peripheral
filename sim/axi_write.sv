module axi_write (
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

    output logic [31:0] data_out,   //data output
    output logic [31:0] addr_out,   //address output
    output logic        data_valid  // indicates if output data + address are valid.
);
  logic aw_handshake_complete;
  logic w_handshake_complete;
  logic write_complete;

  //write address hanshake : 

  always_ff @(posedge axi_clk or negedge rst_n) begin : Write_Address_Handshake
    if (!rst_n) begin
      addr_out <= 32'b0;
      aw_handshake_complete <= 1'b0;
      AWREADY <= 1'b0;
    end else if (!AWREADY && AWVALID && !aw_handshake_complete) begin
      AWREADY <= 1'b1;
      aw_handshake_complete <= 1'b1;
      addr_out <= AWADDR;  //capture address
    end else begin
      AWREADY <= 1'b0;
    end
  end

  //write data handshake

  always_ff @(posedge axi_clk or negedge rst_n) begin : Write_Data_Handshake
    if (!rst_n) begin
      data_out <= 32'b0;
      w_handshake_complete <= 1'b0;
    end else if (!WDREADY && WDVALID && !w_handshake_complete) begin
      WDREADY <= 1'b1;
      w_handshake_complete <= 1'b1;
      data_out <= WDDATA;  //capture data
    end else begin
      WDREADY <= 1'b0;
    end
  end

  //Write completion + data_valid assertation

  always_ff @(posedge axi_clk or negedge rst_n) begin : Write_Completion
    if (!rst_n) begin
      WDREADY <= 1'b0;
      data_valid <= 1'b0;
      write_complete <= 1'b0;
    end else if (aw_handshake_complete && w_handshake_complete && !write_complete) begin
      data_valid <= 1'b1;
      write_complete <= 1'b1;
    end else begin
      data_valid <= 1'b0;
      if (write_complete) begin
        aw_handshake_complete <= 1'b0;
        w_handshake_complete <= 1'b0;
        write_complete <= 1'b0;
      end
    end
  end

  //Write Response Channel
  always_ff @(posedge axi_clk or negedge rst_n) begin : Write_Response
    if (!rst_n) begin
      BVALID <= 1'b0;
      BRESP  <= 2'b00;
    end else if (write_complete && !BVALID) begin
      BRESP  <= 2'b00;
      BVALID <= 1'b1;
    end else if (BVALID && BREADY) begin
      BVALID <= 1'b0;
    end
  end
  
endmodule
