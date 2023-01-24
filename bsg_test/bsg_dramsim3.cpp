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

class BSGDRAMSim3 {
public:
    static constexpr bool WRITE = true;
    static constexpr bool READ  = false;

    BSGDRAMSim3(int num_channels_p, char *config_p):
        _read_done(num_channels_p, 0),
        _read_done_addr(num_channels_p, 0),
        _write_done(num_channels_p, 0),
        _write_done_addr(num_channels_p, 0)
        {

            // construct path to the configuration file
            string config_dir = stringify(BASEJUMP_STL_DIR) "/imports/DRAMSim3/configs/";
            string config_file = config_dir + std::string(config_p);
            string output_dir(".");

            pr_dbg("config_file='%s'\n", config_file.c_str());

            /* called when read completes */
            auto read_done  = [this](uint64_t addr) {
                int ch = _memory_system->GetConfig()->AddressMapping(addr).channel;
                pr_dbg("read_done called: ch=%d, addr=0x%010" PRIx64 "\n", ch, addr);
                if (_read_done[ch]) {
                    pr_dbg("WARNING: read done called twice in the same cycle. ch=%d\n", ch);
                }
                _read_done[ch]++;
                _read_done_addr[ch] = addr;
            };

            /* called when write completes */
            auto write_done = [this](uint64_t addr) {
                int ch = _memory_system->GetConfig()->AddressMapping(addr).channel;
                pr_dbg("write_done called: ch=%d, addr=0x%010" PRIx64 "\n", ch, addr);
                _write_done[ch] = true;
                _write_done_addr[ch] = addr;
            };

            _memory_system = std::unique_ptr<MemorySystem>(new MemorySystem(config_file, output_dir, read_done, write_done));
        }

    ////////////////
    // Validation //
    ////////////////
    bool isValid(int num_channels_p,
                 int data_width_p,
                 long long size_in_bits_p,
                 int num_columns_p,
                 char *config_p) const {

        pr_dbg("using clock period %lf ns\n", _memory_system->GetTCK());
        /* sanity check */
        const Config *cfg = _memory_system->GetConfig();

        pr_dbg("ro_pos=%d\n", cfg->ro_pos);
        pr_dbg("ra_pos=%d\n", cfg->ra_pos);
        pr_dbg("bg_pos=%d\n", cfg->bg_pos);
        pr_dbg("ba_pos=%d\n", cfg->ba_pos);
        pr_dbg("ch_pos=%d\n", cfg->ch_pos);
        pr_dbg("co_pos=%d\n", cfg->co_pos);

        /* calculate device size */
        long long channels = cfg->channels;
        long long channel_size = cfg->channel_size;
        long long memory_size = channels * channel_size * (1<<23); // channel_size is in MB; convert to bits

        if (cfg->channels != num_channels_p) {
            pr_err("num_channels_p (%d) does not match channels (%d) found in %s\n",
                   num_channels_p, cfg->channels, config_p);
            return false;
        } else if (cfg->BL * cfg->bus_width != data_width_p) {
            pr_err("data_width_p (%d) does not match product of burst length (%d) and bus width (%d) found in %s\n",
                   data_width_p, cfg->BL, cfg->bus_width, config_p);
            return false;
        } else if (memory_size != size_in_bits_p) {
            pr_err("size_in_bits_p (%lld) does not match device size (%lld) found in %s\n",
                   size_in_bits_p, memory_size, config_p);
            return false;
        } else if (cfg->columns / cfg->BL != num_columns_p) {
            pr_err("num_columns_p (%d) does not match columns (%d) and burst length (%d) found in %s\n",
                   num_columns_p, cfg->columns, cfg->BL, config_p);
            return false;
        }

        return true;
    }

    //////////////////////
    // Sending requests //
    //////////////////////
    bool sendReadReq(addr_t addr) {

        pr_dbg("0x%010llx : co(%d),ch(%d)\n", addr,
               _memory_system->GetConfig()->AddressMapping(addr).column,
               _memory_system->GetConfig()->AddressMapping(addr).channel);

        pr_dbg("sending read request to addr=0x%010llx\n", addr);

        if (_memory_system->WillAcceptTransaction(addr, READ)) {
            _memory_system->AddTransaction(addr, READ);
            return true;
        } else {
            return false;
        }
    }

    bool sendWriteReq(addr_t addr) {
        if (_memory_system->WillAcceptTransaction(addr, WRITE)) {
            _memory_system->AddTransaction(addr, WRITE);
            return true;
        } else {
            return false;
        }
    }

    ////////////////
    // Clock tick //
    ////////////////
    void clockTick() {
        for (int ch = 0; ch < _memory_system->GetConfig()->channels; ch++) {
            if (_read_done[ch] > 0) _read_done[ch]--;
            if (_write_done[ch] > 0) _write_done[ch]--;
        }
        _memory_system->ClockTick();
    }

    /////////////////
    // Print Stats //
    /////////////////
    void printTagStats(uint32_t tag) {
        _memory_system->PrintTagStats(tag);
    }

    void printFinalStats() {
        _memory_system->PrintStats();
    }

    //////////////////////////////
    // Query completed requests //
    //////////////////////////////
    bool getReadDone(int channel) const {
        return _read_done[channel] > 0;
    }

    bool getWriteDone(int channel) const {
        return _write_done[channel] > 0;
    }

    addr_t getReadDoneAddr(int channel) const {
        return _read_done_addr[channel];
    }

    addr_t getWriteDoneAddr(int channel) const {
        return _write_done_addr[channel];
    }


private:
    std::unique_ptr<MemorySystem>       _memory_system;
    std::vector<uint8_t> _read_done;
    std::vector<addr_t> _read_done_addr;
    std::vector<uint8_t> _write_done;
    std::vector<addr_t> _write_done_addr;
};


/**
 * Send a read request to the DRAMSim3 memory system.
 * @param[in] dramsim3 A handle to the memory system
 * @param[in] addr An address to read from
 * @return true if the read request was accepted
 */
extern "C" bool bsg_dramsim3_send_read_req(BSGDRAMSim3 * dramsim3, addr_t addr)
{
    return dramsim3->sendReadReq(addr);
}

/**
 * Send a write request to the DRAMSim3 memory system.
 * @param[in] addr An address to write to
 * @return true if the write request was accepted
 */
extern "C" bool bsg_dramsim3_send_write_req(BSGDRAMSim3 *dramsim3, addr_t addr)
{
    return dramsim3->sendWriteReq(addr);
}

/**
 * Execute a single clock tick in the memory system.
 */
extern "C" void bsg_dramsim3_tick(BSGDRAMSim3 *dramsim3)
{
    dramsim3->clockTick();
}

/**
 * Print Stats
 * @param[in] The tag to keep track of stats
 */
extern "C" void bsg_dramsim3_print_stats(BSGDRAMSim3 *dramsim3, uint32_t tag)
{
    dramsim3->printTagStats(tag);
}

/**
 * Check if the channel has complete a read request.
 * @param[in] ch The channel to check for completion.
 */
extern "C" bool bsg_dramsim3_get_read_done(BSGDRAMSim3 *dramsim3, int ch)
{
    return dramsim3->getReadDone(ch);
}

/**
 * Check if the channel has complete a write request.
 * @param[in] ch The channel to check for completion.
 */
extern "C" bool bsg_dramsim3_get_write_done(BSGDRAMSim3 *dramsim3, int ch)
{
    return dramsim3->getWriteDone(ch);
}

/**
 * Get the address of a complete read memory request.
 * @param[in] ch The channel to check for an address.
 */
extern "C" addr_t bsg_dramsim3_get_read_done_addr(BSGDRAMSim3 *dramsim3, int ch)
{
    return dramsim3->getReadDoneAddr(ch);
}

/**
 * Get the addres of a complete write memory request.
 * @param[in] ch The channel to check for an address.
 */
extern "C" addr_t bsg_dramsim3_get_write_done_addr(BSGDRAMSim3 *dramsim3, int ch)
{
    return dramsim3->getWriteDoneAddr(ch);
}

/**
 * Cleanup code for the memory system.
 */
extern "C" void bsg_dramsim3_exit(BSGDRAMSim3 *dramsim3)
{
    dramsim3->printFinalStats();
    delete dramsim3;
}

/**
 * Initialize the memory system.
 * @param[in] num_channels_p RTL parameter for the expected number of channels
 * @param[in] data_width_p   RTL parameter for the expected data width of the memory system (BL * device width)
 * @param[in] size_p         RTL parameter for the exepected size of the memory system in bits
 * @param[in] config_p       The path to the configuration file for the memory system (.ini)
 * @return A DRAMSim3 handle
 */
extern "C" void* bsg_dramsim3_init(
    /* for sanity checking */
    int num_channels_p,
    int data_width_p,
    long long size_in_bits_p,
    int num_columns_p,
    char *config_p)
{

    BSGDRAMSim3 *dramsim3 = new BSGDRAMSim3(num_channels_p, config_p);

    if (!dramsim3->isValid(num_channels_p,
                           data_width_p,
                           size_in_bits_p,
                           num_columns_p,
                           config_p)) {

        bsg_dramsim3_exit(dramsim3);
        exit(1);
    }

    return dramsim3;
}
