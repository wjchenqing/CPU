`include "defines.v"

module ctrl(
    input   wire        rst_in,
    input   wire        stallreq_from_id,
    input   wire        stallreq_from_ex,
    output  reg[5:0]    stall,              //1 stands for can  continue.
);

    always @ (*) begin
        if (rst_in == `RstEnable )  begin
            stall <= 6'b000000;
        end else if (stallreq_from_ex == `Stop ) begin
            stall <= 6'b001111;
        end else if (stallreq_from_id == `Stop ) begin
            stall <= 6'b000111;
        end else begin
            stall <= 6'b000000;
        end
    end

endmodule : ctrl