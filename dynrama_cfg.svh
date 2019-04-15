`ifndef _INC_DYNRAMA_CFG_SVH_
`define _INC_DYNRAMA_CFG_SVH_

// DYNamic RAndom Memory Allocator : configuration class
class dynrama_cfg extends uvm_object;
    
  // memory start address, default : 0
  mem_addr_t start_addr = '0;
    
  // memory end address, default : last addr for the given addr width
  mem_addr_t end_addr = '1;

  function new(string name);
    super.new(name);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);    
  endfunction: new
  
endclass: dynrama_cfg

`endif // _INC_DYNRAMA_CFG_SVH_
