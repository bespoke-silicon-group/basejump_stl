#ifdef SV_TEST
#include "svdpi.h"
#endif
#include "memory_system.h"
#include <string>
#include <memory>
#include <cassert>
#include <cstdio>
#include <inttypes.h>

#define __stringify(x)                          \
    #x

#define stringify(x)                            \
    __stringify(x)

#define pr_err(fmt, ...)                        \
    fprintf(stderr, "[DRAMSim3] " fmt, ##__VA_ARGS__)

#if defined(DEBUG)
#define pr_dbg(fmt, ...)                        \
    do {fprintf(stdout, "[DRAMSim3] " fmt, ##__VA_ARGS__); fflush(stdout); } while(0)
#else
#define pr_dbg(fmt, ...)
#endif

using namespace::std;
using dramsim3::MemorySystem;
using dramsim3::Config;
using dramsim3::Address;
using addr_t = long long;

static MemorySystem *_memory_system = nullptr;
static bool         *_read_done = nullptr;
static addr_t       *_read_done_addr = nullptr;

static constexpr bool WRITE = true;
static constexpr bool READ  = false;

/**
 * Send a read request to the DRAMSim3 memory system.
 * @param[in] addr An address to read from
 * @return true if the read request was accepted
 */
extern "C" bool bsg_dramsim3_send_read_req(addr_t addr)
{
    Address map = _memory_system->GetConfig()->AddressMapping(addr);
    pr_dbg("0x%010llx : co(%d),ch(%d)\n", addr, map.column, map.channel);
    pr_dbg("sending read request to addr=0x%010llx\n", addr);
    if (_memory_system->WillAcceptTransaction(addr, READ)) {
        _memory_system->AddTransaction(addr, READ);
        return true;
    } else {
        return false;
    }
}

/**
 * Send a write request to the DRAMSim3 memory system.
 * @param[in] addr An address to write to
 * @return true if the write request was accepted
 */
extern "C" bool bsg_dramsim3_send_write_req(addr_t addr)
{
    if (_memory_system->WillAcceptTransaction(addr, WRITE)) {
        _memory_system->AddTransaction(addr, WRITE);
        return true;
    } else {
        return false;
    }
}

/**
 * Execute a single clock tick in the memory system.
 */
extern "C" void bsg_dramsim3_tick()
{
    for (int ch = 0; ch < _memory_system->GetConfig()->channels; ch++) {
        _read_done[ch] = false;
    }
    _memory_system->ClockTick();
}

/**
 * Check if the channel has complete a read request.
 * @param[in] ch The channel to check for completion.
 */
extern "C" bool bsg_dramsim3_get_read_done(int ch)
{
    return _read_done[ch];
}

/**
 * Get the addres of a complete memory request.
 * @param[in] ch The channel to check for an address.
 */
extern "C" addr_t bsg_dramsim3_get_read_done_addr(int ch)
{
    return _read_done_addr[ch];
}


/**
 * Cleanup code for the memory system.
 */
extern "C" void bsg_dramsim3_exit(void)
{
    delete _memory_system;
    delete [] _read_done;
    delete [] _read_done_addr;
}

/**
 * Initialize the memory system.
 * @param[in] num_channels_p RTL parameter for the expected number of channels
 * @param[in] data_width_p   RTL parameter for the expected data width of the memory system (BL * device width)
 * @param[in] size_p         RTL parameter for the exepected size of the memory system in bits
 * @param[in] config_p       The path to the configuration file for the memory system (.ini)
 * @return true if the system was succesfully initialized, otherwise false.
 */
extern "C" bool bsg_dramsim3_init(
    /* for sanity checking */
    int num_channels_p,
    int data_width_p,
    long long size_in_bits_p,
    char *config_p)
{
    string config_dir = stringify(BASEJUMP_STL_DIR) "/imports/DRAMSim3/configs/";
    string config_file = config_dir + std::string(config_p);
    string output_dir(".");

    pr_dbg("config_file='%s'\n", config_file.c_str());
    
    /* initialize book keeping structures */
    _read_done      = new bool [num_channels_p];
    _read_done_addr = new addr_t [num_channels_p];

    for (int i = 0; i < num_channels_p; i++) {
        _read_done[i] = false;
        _read_done_addr[i] = 0;
    }

    /* called when read completes */
    auto read_done  = [](uint64_t addr) {
        int ch = _memory_system->GetConfig()->AddressMapping(addr).channel;
        pr_dbg("read_done called: ch=%d, addr=0x%010" PRIx64 "\n", ch, addr);
        _read_done[ch] = true;
        _read_done_addr[ch] = addr;
    };

    /* called when write completes */
    auto write_done = [](uint64_t addr) {};

    _memory_system = new MemorySystem(config_file, output_dir, read_done, write_done);

    pr_dbg("using clock period %lf ns\n", _memory_system->GetTCK());

    /* sanity check */
    const Config *cfg = _memory_system->GetConfig();

    /* calculate device size */
    long long channels = cfg->channels;
    long long channel_size = cfg->channel_size;
    long long memory_size = channels * channel_size * (1<<23); // channel_size is in MB; convert to bits

    if (cfg->channels != num_channels_p) {
        pr_err("num_channels_p (%d) does not match channels (%d) found in %s\n",
               num_channels_p, cfg->channels, config_p);
        bsg_dramsim3_exit();
        exit(1);
    } else if (cfg->BL * cfg->device_width != data_width_p) {
        pr_err("data_width_p (%d) does not match product of burst length (%d) and device width (%d) found in %s\n",
               data_width_p, cfg->BL, cfg->device_width, config_p);
        bsg_dramsim3_exit();
        exit(1);
    } else if (memory_size != size_in_bits_p) {
        pr_err("size_in_bits_p (%ld) does not match device size (%ld) found in %s\n",
               size_in_bits_p, memory_size, config_p);
        exit(1);
    }
    
    return true;
}

