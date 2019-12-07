/**
 *    bsg_ramulator_hbm.cpp
 *
 *
 */


#include <iostream>
#include <vector>
#include <map>
#ifdef SV_TEST
#include "svdpi.h"
#endif
#include "HBM.h"
#include "Controller.h"
#include "Config.h"
#include "Memory.h"
#include "StatType.h"
#include "Statistics.h"

#define NUM_CHANNEL 8
#define STRINGIFY(x) #x
#define STRING_PATH(x) STRINGIFY(x)


using namespace std;
using namespace ramulator;


static HBM* _hbm;
static vector<Controller<HBM>*> _ctrls;
static Config _configs(STRING_PATH(HBM_CONFIG_PATH));
static Memory<HBM, Controller>* _memory;

static bool _read_done[NUM_CHANNEL];
static long _read_done_addr[NUM_CHANNEL];


// Init
//
extern "C" void init_hbm()
{
  cout << "[RAMULATOR] Initializing HBM..." << endl;
  cout << "[RAMULATOR] org = " << _configs["org"]  << endl;
  cout << "[RAMULATOR] speed = " << _configs["speed"]  << endl;
  cout << "[RAMULATOR] channels = " << _configs.get_channels()  << endl;
  cout << "[RAMULATOR] ranks = " << _configs.get_ranks()  << endl;
  
  for (int i = 0; i < NUM_CHANNEL; i++)
  {
    _read_done_addr[i] = 0;
    _read_done[i] = false;
  }

  //Stats::statlist.output("HBM.stats");
  _configs.add("trace_type", "DRAM");
  _configs.add("mapping", "defaultmapping");
  _configs.set_core_num(1);

  _hbm = new HBM(_configs["org"], _configs["speed"]);
  _hbm->set_channel_number(_configs.get_channels());
  _hbm->set_rank_number(_configs.get_ranks());

  for (int c = 0; c < _configs.get_channels(); c++)
  {
    DRAM<HBM>* channel = new DRAM<HBM>(_hbm, HBM::Level::Channel);
    channel->id = c;
    channel->regStats("");
    Controller<HBM>* ctrl = new Controller<HBM>(_configs, channel);
    _ctrls.push_back(ctrl);
  }

  _memory = new Memory<HBM>(_configs, _ctrls); 
  
}


// Send Write Request
extern "C" bool send_write_req(long addr)
{
  //cout << "send_write_req" << "," << addr << endl;
  //cout << "channels = " << _configs.get_channels() << endl;
  Request req(addr, Request::Type::WRITE);
  return _memory->send(req);
}


// Send Read Request
extern "C" bool send_read_req(long addr)
{
  auto read_complete = [](Request& r) {
    int ch = r.addr_vec[0];
    _read_done[ch] = true;
    _read_done_addr[ch] = r.addr;
  };
   
  Request req(addr, Request::Type::READ, read_complete);
  return _memory->send(req);
}


// is read done this cycle?
extern "C" bool get_read_done(int ch)
{
  return _read_done[ch];
}

// Get read addr.
extern "C" long get_read_done_addr(int ch)
{
  return _read_done_addr[ch];
}

// Tick
extern "C" void tick()
{
  for (int i = 0; i < NUM_CHANNEL; i++)
    _read_done[i] = false;

  _memory->tick();
}


// Finish
extern "C" void finish_hbm()
{
  _memory->finish();
  delete _memory; 
}
