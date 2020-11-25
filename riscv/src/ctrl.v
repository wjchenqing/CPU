`include "defines.v"

module ctrl(
    input   wire        rst_in,
    input   wire        stallreq_from_if,
    input   wire        stallreq_from_id,
    input   wire        stallreq_from_ex,
    input   wire        stallreq_from_mem,
    output  reg[5:0]    stall              //1 stands for can  continue.
);

    always @ (*) begin
        if (rst_in == `RstEnable )  begin
            stall <= 6'b000000;
        end else if (stallreq_from_mem == `Stop ) begin
            stall <= 6'b011111;
        end else if (stallreq_from_ex == `Stop ) begin
            stall <= 6'b001111;
        end else if (stallreq_from_id == `Stop ) begin
            stall <= 6'b000111;
        end else if (stallreq_from_if == `Stop ) begin
            stall <= 6'b000011;
        end
        else begin
            stall <= 6'b000000;
        end
    end

endmodule : ctrl