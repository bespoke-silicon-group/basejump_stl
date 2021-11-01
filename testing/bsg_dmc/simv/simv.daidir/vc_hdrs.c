#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <stdio.h>
#include <dlfcn.h>
#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif

/* VCS error reporting routine */
extern void vcsMsgReport1(const char *, const char *, int, void *, void*, const char *);

#ifndef _VC_TYPES_
#define _VC_TYPES_
/* common definitions shared with DirectC.h */

typedef unsigned int U;
typedef unsigned char UB;
typedef unsigned char scalar;
typedef struct { U c; U d;} vec32;

#define scalar_0 0
#define scalar_1 1
#define scalar_z 2
#define scalar_x 3

extern long long int ConvUP2LLI(U* a);
extern void ConvLLI2UP(long long int a1, U* a2);
extern long long int GetLLIresult();
extern void StoreLLIresult(const unsigned int* data);
typedef struct VeriC_Descriptor *vc_handle;

#ifndef SV_3_COMPATIBILITY
#define SV_STRING const char*
#else
#define SV_STRING char*
#endif

#endif /* _VC_TYPES_ */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_hdl_check_path
#define __VCS_IMPORT_DPI_STUB_uvm_hdl_check_path
__attribute__((weak)) int uvm_hdl_check_path(/* INPUT */const char* A_1)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static int (*_vcs_dpi_fp_)(/* INPUT */const char* A_1) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (int (*)(const char* A_1)) dlsym(RTLD_NEXT, "uvm_hdl_check_path");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_hdl_check_path");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_hdl_check_path */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_hdl_deposit
#define __VCS_IMPORT_DPI_STUB_uvm_hdl_deposit
__attribute__((weak)) int uvm_hdl_deposit(/* INPUT */const char* A_1, const /* INPUT */svLogicVecVal *A_2)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static int (*_vcs_dpi_fp_)(/* INPUT */const char* A_1, const /* INPUT */svLogicVecVal *A_2) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (int (*)(const char* A_1, const svLogicVecVal* A_2)) dlsym(RTLD_NEXT, "uvm_hdl_deposit");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1, A_2);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_hdl_deposit");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_hdl_deposit */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_hdl_force
#define __VCS_IMPORT_DPI_STUB_uvm_hdl_force
__attribute__((weak)) int uvm_hdl_force(/* INPUT */const char* A_1, const /* INPUT */svLogicVecVal *A_2)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static int (*_vcs_dpi_fp_)(/* INPUT */const char* A_1, const /* INPUT */svLogicVecVal *A_2) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (int (*)(const char* A_1, const svLogicVecVal* A_2)) dlsym(RTLD_NEXT, "uvm_hdl_force");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1, A_2);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_hdl_force");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_hdl_force */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_hdl_release_and_read
#define __VCS_IMPORT_DPI_STUB_uvm_hdl_release_and_read
__attribute__((weak)) int uvm_hdl_release_and_read(/* INPUT */const char* A_1, /* INOUT */svLogicVecVal *A_2)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static int (*_vcs_dpi_fp_)(/* INPUT */const char* A_1, /* INOUT */svLogicVecVal *A_2) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (int (*)(const char* A_1, svLogicVecVal* A_2)) dlsym(RTLD_NEXT, "uvm_hdl_release_and_read");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1, A_2);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_hdl_release_and_read");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_hdl_release_and_read */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_hdl_release
#define __VCS_IMPORT_DPI_STUB_uvm_hdl_release
__attribute__((weak)) int uvm_hdl_release(/* INPUT */const char* A_1)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static int (*_vcs_dpi_fp_)(/* INPUT */const char* A_1) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (int (*)(const char* A_1)) dlsym(RTLD_NEXT, "uvm_hdl_release");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_hdl_release");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_hdl_release */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_hdl_read
#define __VCS_IMPORT_DPI_STUB_uvm_hdl_read
__attribute__((weak)) int uvm_hdl_read(/* INPUT */const char* A_1, /* OUTPUT */svLogicVecVal *A_2)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static int (*_vcs_dpi_fp_)(/* INPUT */const char* A_1, /* OUTPUT */svLogicVecVal *A_2) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (int (*)(const char* A_1, svLogicVecVal* A_2)) dlsym(RTLD_NEXT, "uvm_hdl_read");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1, A_2);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_hdl_read");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_hdl_read */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_dpi_get_next_arg_c
#define __VCS_IMPORT_DPI_STUB_uvm_dpi_get_next_arg_c
__attribute__((weak)) SV_STRING uvm_dpi_get_next_arg_c()
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static SV_STRING (*_vcs_dpi_fp_)() = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (SV_STRING (*)()) dlsym(RTLD_NEXT, "uvm_dpi_get_next_arg_c");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_();
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_dpi_get_next_arg_c");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_dpi_get_next_arg_c */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_dpi_get_tool_name_c
#define __VCS_IMPORT_DPI_STUB_uvm_dpi_get_tool_name_c
__attribute__((weak)) SV_STRING uvm_dpi_get_tool_name_c()
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static SV_STRING (*_vcs_dpi_fp_)() = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (SV_STRING (*)()) dlsym(RTLD_NEXT, "uvm_dpi_get_tool_name_c");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_();
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_dpi_get_tool_name_c");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_dpi_get_tool_name_c */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_dpi_get_tool_version_c
#define __VCS_IMPORT_DPI_STUB_uvm_dpi_get_tool_version_c
__attribute__((weak)) SV_STRING uvm_dpi_get_tool_version_c()
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static SV_STRING (*_vcs_dpi_fp_)() = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (SV_STRING (*)()) dlsym(RTLD_NEXT, "uvm_dpi_get_tool_version_c");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_();
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_dpi_get_tool_version_c");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_dpi_get_tool_version_c */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_dpi_regcomp
#define __VCS_IMPORT_DPI_STUB_uvm_dpi_regcomp
__attribute__((weak)) void* uvm_dpi_regcomp(/* INPUT */const char* A_1)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static void* (*_vcs_dpi_fp_)(/* INPUT */const char* A_1) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (void* (*)(const char* A_1)) dlsym(RTLD_NEXT, "uvm_dpi_regcomp");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_dpi_regcomp");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_dpi_regcomp */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_dpi_regexec
#define __VCS_IMPORT_DPI_STUB_uvm_dpi_regexec
__attribute__((weak)) int uvm_dpi_regexec(/* INPUT */void* A_1, /* INPUT */const char* A_2)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static int (*_vcs_dpi_fp_)(/* INPUT */void* A_1, /* INPUT */const char* A_2) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (int (*)(void* A_1, const char* A_2)) dlsym(RTLD_NEXT, "uvm_dpi_regexec");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1, A_2);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_dpi_regexec");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_dpi_regexec */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_dpi_regfree
#define __VCS_IMPORT_DPI_STUB_uvm_dpi_regfree
__attribute__((weak)) void uvm_dpi_regfree(/* INPUT */void* A_1)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static void (*_vcs_dpi_fp_)(/* INPUT */void* A_1) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (void (*)(void* A_1)) dlsym(RTLD_NEXT, "uvm_dpi_regfree");
    }
    if (_vcs_dpi_fp_) {
        _vcs_dpi_fp_(A_1);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_dpi_regfree");
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_dpi_regfree */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_re_match
#define __VCS_IMPORT_DPI_STUB_uvm_re_match
__attribute__((weak)) int uvm_re_match(/* INPUT */const char* A_1, /* INPUT */const char* A_2)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static int (*_vcs_dpi_fp_)(/* INPUT */const char* A_1, /* INPUT */const char* A_2) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (int (*)(const char* A_1, const char* A_2)) dlsym(RTLD_NEXT, "uvm_re_match");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1, A_2);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_re_match");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_re_match */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_dump_re_cache
#define __VCS_IMPORT_DPI_STUB_uvm_dump_re_cache
__attribute__((weak)) void uvm_dump_re_cache()
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static void (*_vcs_dpi_fp_)() = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (void (*)()) dlsym(RTLD_NEXT, "uvm_dump_re_cache");
    }
    if (_vcs_dpi_fp_) {
        _vcs_dpi_fp_();
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_dump_re_cache");
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_dump_re_cache */

#ifndef __VCS_IMPORT_DPI_STUB_uvm_glob_to_re
#define __VCS_IMPORT_DPI_STUB_uvm_glob_to_re
__attribute__((weak)) SV_STRING uvm_glob_to_re(/* INPUT */const char* A_1)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static SV_STRING (*_vcs_dpi_fp_)(/* INPUT */const char* A_1) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (SV_STRING (*)(const char* A_1)) dlsym(RTLD_NEXT, "uvm_glob_to_re");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "uvm_glob_to_re");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_uvm_glob_to_re */

#ifndef __VCS_IMPORT_DPI_STUB_svapfGetAttempt
#define __VCS_IMPORT_DPI_STUB_svapfGetAttempt
__attribute__((weak)) void* svapfGetAttempt(/* INPUT */unsigned int A_1)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static void* (*_vcs_dpi_fp_)(/* INPUT */unsigned int A_1) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (void* (*)(unsigned int A_1)) dlsym(RTLD_NEXT, "svapfGetAttempt");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "svapfGetAttempt");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_svapfGetAttempt */

#ifndef __VCS_IMPORT_DPI_STUB_svapfReportResult
#define __VCS_IMPORT_DPI_STUB_svapfReportResult
__attribute__((weak)) void svapfReportResult(/* INPUT */unsigned int A_1, /* INPUT */void* A_2, /* INPUT */int A_3)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static void (*_vcs_dpi_fp_)(/* INPUT */unsigned int A_1, /* INPUT */void* A_2, /* INPUT */int A_3) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (void (*)(unsigned int A_1, void* A_2, int A_3)) dlsym(RTLD_NEXT, "svapfReportResult");
    }
    if (_vcs_dpi_fp_) {
        _vcs_dpi_fp_(A_1, A_2, A_3);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "svapfReportResult");
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_svapfReportResult */

#ifndef __VCS_IMPORT_DPI_STUB_svapfGetAssertEnabled
#define __VCS_IMPORT_DPI_STUB_svapfGetAssertEnabled
__attribute__((weak)) int svapfGetAssertEnabled(/* INPUT */unsigned int A_1)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static int (*_vcs_dpi_fp_)(/* INPUT */unsigned int A_1) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_stub_initialized_ = 1;
        _vcs_dpi_fp_ = (int (*)(unsigned int A_1)) dlsym(RTLD_NEXT, "svapfGetAssertEnabled");
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "svapfGetAssertEnabled");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_svapfGetAssertEnabled */


#ifdef __cplusplus
}
#endif

