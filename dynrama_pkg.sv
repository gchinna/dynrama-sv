
// DYNamic RAndom Memory Allocator : package

`ifndef DYNRAMA_AWIDTH
  `define DYNRAMA_AWIDTH  32  // default addr width : 32 bits - 4GB memory map
`endif

// dynamic memory allocator package includes:
//   * types 
//   * dynrama_cfg config class
//   * dynrama component class
package dynrama_pkg;
  typedef bit [`DYNRAMA_AWIDTH -1 : 0]  mem_addr_t;
  typedef bit [`DYNRAMA_AWIDTH    : 0]  mem_size_t;


  `include "dynrama_cfg.svh"
  `include "dynrama.svh"

endpackage: dynrama_pkg
