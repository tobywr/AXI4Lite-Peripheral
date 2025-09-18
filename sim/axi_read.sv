module axi_read (
    input logic axi_clk,
    input logic rst_n,

    input logic [31:0] ARADDR,
    input logic ARVALID,
    output logic ARREADY,

    output logic [31:0] RDATA,
    input logic RREADY,
    output logic RVALID,
    output logic [1:0] RRESP,

    output logic [31:0] addr_out, //address to read from
    output logic read_req, //read request pulse
    input logic [31:0] data_in,
    input logic data_ready
);
    
    //internal signals
    
    logic ar_handshake_complete;
    logic read_in_progress;
    logic [31:0] captured_addr;

    always_ff @(posedge axi_clk or negedge rst_n ) begin : address_read_handshake
        if(!rst_n) begin
            ARREADY <= 1'b0;
            addr_out <= 32'b0;
            read_req <= 1'b0;
            ar_handshake_complete <= 1'b0;
            captured_addr <= 32'b0;
        end else if(ARVALID && !ARREADY && !ar_handshake_complete) begin
            ARREADY <= 1'b1;
            captured_addr <= ARADDR; //capture address
            addr_out <= ARADDR;
            ar_handshake_complete <= 1'b1;
            read_req <= 1'b1;
        end else begin
            ARREADY <= 1'b0;
            read_req <= 1'b0;
        end
    end

    //read data handshake

    always_ff @( posedge axi_clk or negedge rst_n ) begin : read_data_handshake
        if(!rst_n) begin
            RVALID <= 1'b0;
            RDATA <= 32'b0;
            RRESP <= 2'b00;
            read_in_progress <= 1'b0;
        end else if(ar_handshake_complete && !read_in_progress) begin
            read_in_progress <= 1'b1;
            //wait for memory to provide data
        end else if(read_in_progress && data_ready && !RVALID) begin
            RDATA <= data_in;
            RRESP <= 2'b00;
            RVALID <= 1'b1;
        end else if(RVALID && RREADY) begin //read data accepted by master
            RVALID <= 1'b0;
            read_in_progress <= 1'b0;
            ar_handshake_complete <= 1'b0;
        end
    end



endmodule