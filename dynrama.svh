`ifndef _INC_DYNRAMA_SVH_
`define _INC_DYNRAMA_SVH_

typedef class mem_segment; // forward declaration, class defined later in the same file.

// DYNamic RAndom Memory Allocator : model
//  - implements malloc() and free() API methods
class dynrama extends uvm_component;
  `uvm_component_utils(dynrama)
   
  dynrama_cfg cfg; // config
  
  mem_segment free_segments[$];  // free segments queue
  mem_segment alloc_segments[$];  // allocated segments queue

  
  // -- base class methods --
  extern function new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern virtual function string convert2string();

  // -- malloc() API method
  //   - retuns the start addr of randomly allocated memory buffer of the given size
  extern function mem_addr_t malloc(input mem_size_t size);
  
  // -- free() API method
  //   - frees the previously allocated memory buffer at start_addr 
  //   - size must match previously allocated memory buffer size, otherwise error is reported.
  extern function void free(input mem_addr_t start_addr, mem_size_t size);
    
  // -- helper methods --
  // merge_free_segments() method is not intended to be used outside of this class
  extern local function void merge_free_segments();
endclass: dynrama

    
  // -- new method
  function dynrama::new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new
  
    
  // -- build_phase method
  function void dynrama::build_phase(uvm_phase phase);
    mem_segment free_segment;
    
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    super.build_phase(phase);
    
    if(!uvm_config_db#(dynrama_cfg)::get(this, "", "cfg", cfg)) begin
      `uvm_info(get_type_name(), "Creating default dynrama_cfg ...", UVM_LOW);
      cfg = new("dynrama_cfg");
      // randomize required to initialize free segments
      if( !cfg.randomize() ) begin
        `uvm_error(get_type_name(), "cfg randomize failed!");
      end // if 
    end // if

    // initialize free segments queue
    free_segment = new();
    free_segment.init(cfg.start_addr, cfg.end_addr);
    free_segments.push_back( free_segment ); 
  endfunction: build_phase
  
  
  // -- convert2string method
  function string dynrama::convert2string();
    string str;
    str = "Free memory segments: \n";
    foreach( free_segments[ii] ) begin
      str = { str, $sformatf("    %3d : start_addr = 'h%h, end_addr = 'h%h, size = %0d/'h%h\n", ii, free_segments[ii].start_addr, free_segments[ii].end_addr, free_segments[ii].size, free_segments[ii].size) };
    end // foreach
    return str;
  endfunction: convert2string
  
  
    // -- malloc() API method
  function mem_addr_t dynrama::malloc(input mem_size_t size);
    mem_segment valid_segments[$];
    mem_segment sel_segment, free_segment, alloc_segment;
    int valid_idx, free_idx;
    
    // locate all valid free segments for the given size
    valid_segments = this.free_segments.find( seg ) with (
      seg.end_addr - seg.start_addr > size -1
    );
    
    // check if valid segments not empty
    if( valid_segments.size() == 0 ) begin
      `uvm_error(get_type_name(), $sformatf("malloc: valid segments not found!, size = %0d/'h%h\n %s", size, size, this.convert2string()));
    end else begin
    
      // pick a random free seqment from valid segements
      valid_idx = $urandom_range(0, valid_segments.size() -1);
      sel_segment = valid_segments[valid_idx];
    
      if ( ! std::randomize( malloc ) with {
                 malloc inside { [sel_segment.start_addr : sel_segment.end_addr -size +1] };
             } ) begin
        `uvm_error(get_type_name(), "std::randomize( malloc ) failed!");
      end // if
    
      // locate and delete the selected segment
      foreach( this.free_segments[ii] ) begin
        //`uvm_info(get_type_name(), $sformatf("malloc: ii = %0d, Searching for matched segment...", ii), UVM_HIGH);
        if( sel_segment.start_addr == free_segments[ii].start_addr ) begin
          `uvm_info(get_type_name(), $sformatf("malloc: ii = %0d, Found matched segment.", ii), UVM_HIGH);
          free_idx = ii;
          this.free_segments.delete(ii);
          break;
        end // if
      end // foreach
    
      // add post alloc free segments back
      if(malloc == sel_segment.start_addr) begin // add remaining free segment at the end
        free_segment = new();
        free_segment.init( sel_segment.start_addr +size, sel_segment.end_addr );
        free_segments.insert(free_idx, free_segment );
      end else if( malloc == sel_segment.end_addr -size +1 ) begin // add remaining free segment at the start
        free_segment = new();
        free_segment.init( sel_segment.start_addr, sel_segment.end_addr -size );
        free_segments.insert(free_idx, free_segment );
      end else begin  // add remaining free segments at the start and end
        free_segment = new();
        free_segment.init( sel_segment.start_addr, malloc -1 );
        free_segments.insert(free_idx, free_segment );

        free_segment = new();
        free_segment.init( malloc +size, sel_segment.end_addr );
        free_segments.insert(free_idx +1, free_segment );
      end // if
    
      // update allocated segments
      alloc_segment = new();
      alloc_segment.init( malloc, malloc + size -1 );
      this.alloc_segments.push_back( alloc_segment );
    end // if 
  endfunction: malloc
  

    // free() API method
  function void dynrama::free(input mem_addr_t start_addr, mem_size_t size);
    mem_segment alloc_segment;
    int alloc_idx;
    
    // locate and delete the allocated segment
    alloc_idx = -1;
    foreach( this.alloc_segments[ii] ) begin
      //`uvm_info(get_type_name(), $sformatf("free: ii = %0d, Searching for allocated segment...", ii), UVM_HIGH);
      if( start_addr == alloc_segments[ii].start_addr ) begin
        `uvm_info(get_type_name(), $sformatf("free: ii = %0d, Found allocated segment.", ii), UVM_HIGH);
        alloc_segment = alloc_segments[ii];
        alloc_idx = ii;
        this.alloc_segments.delete(ii);
        break;
      end // if
    end // foreach
    
    if( alloc_idx < 0 ) begin
      `uvm_error(get_type_name(), $sformatf("free: start_addr 'h%h not found in alloc_segments!", start_addr));
    end else if( alloc_segment.size != size ) begin
      `uvm_error(get_type_name(), $sformatf("free: alloc size mismatch! expected = %0d, received = %0d", alloc_segment.size, size));
    end else begin 
      // locate and add the free segment
      foreach( this.free_segments[ii] ) begin
        //`uvm_info(get_type_name(), $sformatf("free: ii = %0d, Searching for matched segment...", ii), UVM_HIGH);
        if( start_addr < this.free_segments[ii].start_addr ) begin
          `uvm_info(get_type_name(), $sformatf("free: ii = %0d, Found matched segment.", ii), UVM_HIGH);
          this.free_segments.insert(ii, alloc_segment );
          break;
        end // if
      end // foreach
      merge_free_segments();
    end // if
  endfunction: free
  
    
  // -- merge continous free segments helper method
  function void dynrama::merge_free_segments();
    for(int ii =0; ii < this.free_segments.size() -1; ii += 0 ) begin
      if( this.free_segments[ii].end_addr +1 == this.free_segments[ii +1].start_addr ) begin
        this.free_segments[ii].update( this.free_segments[ii +1].end_addr );
        this.free_segments.delete( ii +1 );
      end else begin
        ii++;
      end // if
    end // foreach
  endfunction: merge_free_segments
  

    
  // memory segment class type
  class mem_segment extends uvm_object;
    `uvm_object_utils(mem_segment)
    
    mem_addr_t start_addr; // memory segment start addr
    mem_addr_t end_addr;   // memory segment end addr
    mem_size_t size; // memory segment size - auto computed 
    
    // -- new method
    function new(string name = "mem_segment");
      super.new(name);
      `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new
    
    // initialize start and end addrs
    function void init(mem_addr_t start_addr, mem_addr_t end_addr);
      this.start_addr = start_addr;
      this.end_addr = end_addr;
      size = this.end_addr - this.start_addr +1;
    endfunction: init

    // update end addr
    function void update(mem_addr_t end_addr);
      this.end_addr = end_addr;
      size = this.end_addr - this.start_addr +1;
    endfunction: update
  endclass: mem_segment
    
`endif // _INC_DYNRAMA_SVH_
