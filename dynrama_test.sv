// DYNamic RAndom Memory Allocator : test environment and testcase
import uvm_pkg::*;
`include "uvm_macros.svh"

`include "dynrama_pkg.sv"

class test_env extends uvm_env;
  `uvm_component_utils(test_env)
  
  dynrama_pkg::dynrama dynrama_i;
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    dynrama_i = dynrama_pkg::dynrama::type_id::create("dynrama", this);
  endfunction: build_phase
endclass: test_env


class sample_test extends uvm_test;
  `uvm_component_utils(sample_test)
  
  test_env env;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = test_env::type_id::create("env", this);
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    dynrama_pkg::dynrama dynrama_i;
    dynrama_pkg::mem_segment alloc_segments[$];
    dynrama_pkg::mem_segment alloc_segment;
    dynrama_pkg::mem_addr_t rand_addr;
    dynrama_pkg::mem_size_t size;
    int alloc_count;
    
    phase.raise_objection(this, $sformatf("%m"));
    dynrama_i = env.dynrama_i;
    `uvm_info(get_type_name(), dynrama_i.convert2string(), UVM_LOW);
    alloc_count = 20;
    
    // allocate random sized buffers
    for(int ii =0; ii < alloc_count; ii++) begin
      size = $urandom_range(1, 4 * 1024);
      rand_addr = dynrama_i.malloc( size );
      `uvm_info(get_type_name(), $sformatf( "alloc: ii = %0d, size = %0d/'h%h, rand_addr = 'h%h", ii, size, size, rand_addr ), UVM_NONE);
      `uvm_info(get_type_name(), dynrama_i.convert2string(), UVM_LOW); 
      alloc_segment = new();
      alloc_segment.init( rand_addr, rand_addr +size -1 );
      alloc_segments.push_back( alloc_segment );
    end // for
    
    // free all previously allocated buffers in random order
    alloc_segments.shuffle();
    foreach (alloc_segments[ii] ) begin
      rand_addr = alloc_segments[ii].start_addr;
      size = alloc_segments[ii].size;
      `uvm_info(get_type_name(), $sformatf( "free: ii = %0d, size = %0d/'h%h, rand_addr = 'h%h", ii, size, size,  rand_addr ), UVM_LOW);
      dynrama_i.free( rand_addr, size );
      `uvm_info(get_type_name(), dynrama_i.convert2string(), UVM_LOW); 
    end // foreach
    
    assert( dynrama_i.free_segments.size() == 1 ) else begin
      `uvm_error(get_type_name(), "( dynrama_i.free_segments.size() == 1 ) check failed!");
    end // assert
    
    assert( dynrama_i.free_segments[0].start_addr == dynrama_i.cfg.start_addr ) else begin
      `uvm_error(get_type_name(), "( dynrama_i.free_segments[0].start_addr == dynrama_i.cfg.start_addr ) check failed!");
    end // assert
    
    assert( dynrama_i.free_segments[0].end_addr == dynrama_i.cfg.end_addr ) else begin
      `uvm_error(get_type_name(), "( dynrama_i.free_segments[0].end_addr == dynrama_i.cfg.end_addr ) check failed!");
    end // assert
    
    phase.drop_objection(this, $sformatf("%m"));
  endtask: run_phase
  
endclass: sample_test


program dynrama_test;
  initial begin
    run_test();
  end // initial
endprogram: dynrama_test
