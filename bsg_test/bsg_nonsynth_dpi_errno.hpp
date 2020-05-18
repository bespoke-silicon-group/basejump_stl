// Copyright (c) 2019, University of Washington All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
// Redistributions of source code must retain the above copyright notice, this list
// of conditions and the following disclaimer.
// 
// Redistributions in binary form must reproduce the above copyright notice, this
// list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
// 
// Neither the name of the copyright holder nor the names of its contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef __BSG_NONSYNTH_DPI_ERRNO
#define __BSG_NONSYNTH_DPI_ERRNO

#ifdef __cplusplus
extern "C" {
#endif

#define BSG_NONSYNTH_DPI_SUCCESS       (0)
#define BSG_NONSYNTH_DPI_FAIL          (-1)
#define BSG_NONSYNTH_DPI_TIMEOUT       (-2)
#define BSG_NONSYNTH_DPI_UNINITIALIZED (-3)
#define BSG_NONSYNTH_DPI_INVALID       (-4)
#define BSG_NONSYNTH_DPI_INITIALIZED_TWICE (-4) // same as invalid
#define BSG_NONSYNTH_DPI_BUSY          (-5)
#define BSG_NONSYNTH_DPI_NOT_WINDOW    (-6)
#define BSG_NONSYNTH_DPI_NOT_READY     (-7)
#define BSG_NONSYNTH_DPI_NOT_VALID     (-8)
#define BSG_NONSYNTH_DPI_NO_CREDITS    (-9)
#define BSG_NONSYNTH_DPI_UNALIGNED     (-10)

        static inline const char* bsg_nonsynth_dpi_strerror(int err)
        {
                static const char *strtab [] = {
                        [-BSG_NONSYNTH_DPI_SUCCESS]           = "Success",
                        [-BSG_NONSYNTH_DPI_FAIL]              = "Failure",
                        [-BSG_NONSYNTH_DPI_TIMEOUT]           = "Timeout",
                        [-BSG_NONSYNTH_DPI_UNINITIALIZED]     = "Not initialized",
                        [-BSG_NONSYNTH_DPI_INVALID]           = "Invalid input",
                        [-BSG_NONSYNTH_DPI_BUSY]              = "Busy",
                        [-BSG_NONSYNTH_DPI_NOT_WINDOW]        = "Not in clock window",
                        [-BSG_NONSYNTH_DPI_NOT_READY]         = "Not ready",
                        [-BSG_NONSYNTH_DPI_NOT_VALID]         = "Not valid",
                        [-BSG_NONSYNTH_DPI_NO_CREDITS]        = "No credits",
                        [-BSG_NONSYNTH_DPI_UNALIGNED]         = "Unaligned memory request",
                };
                return strtab[-err];
        }

        static inline int bsg_nonsynth_dpi_is_error(int err)
        {
                return (err < BSG_NONSYNTH_DPI_SUCCESS) && (err >= BSG_NONSYNTH_DPI_UNALIGNED);
        }

#ifdef __cplusplus
}
#endif

#endif
