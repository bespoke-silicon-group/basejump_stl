#include <string>
#include <cfenv>
#include <cmath>
#include <typeinfo>
#include "AddSubTester.hpp"
#include "FPUTestUtil.hpp"
using namespace std;

template <typename T>
AddSubTester<T>::AddSubTester()
{
  int width = sizeof(T) * 8;
  string inputFilename = "add_sub_input.rom"; 
  string outputFilename = "add_sub_output.rom"; 
 
  _inputROM.open(inputFilename);
  _outputROM.open(outputFilename);  
}

template <typename T>
AddSubTester<T>::~AddSubTester()
{
  _inputROM.close();
  _outputROM.close();
}

template <typename T>
void AddSubTester<T>::Test(T a, T b, bool sub_i)
{
  TestResult<T> tres;
  Arrange(a, b, sub_i);
  Act(a, b, sub_i, &tres);
  Assert(&tres);
}

template <typename T>
void AddSubTester<T>::Arrange(T a, T b, bool sub_i)
{
  _inputROM << (sub_i ? "1" : "0") << "_";
  _inputROM << FPUTestUtil::ConvertToBinaryString(a) << "_";
  _inputROM << FPUTestUtil::ConvertToBinaryString(b) << endl;
}

template <typename T>
void AddSubTester<T>::Act(T a, T b, bool sub_i, TestResult<T> *tres)
{
  if (typeid(T) == typeid(float))
  {
    bool sgn = CalculateSign(a, b, sub_i);
    uint32_t sign = sgn ? 0x80000000 : 0;
    int hex_a = FPUTestUtil::ConvertFloatToInt(a);
    int hex_b = FPUTestUtil::ConvertFloatToInt(b);
    int sub_mag = (hex_a & 0x80000000) ^ (hex_b & 0x80000000) ^ (sub_i << 31);
    bool a_infty = FPUTestUtil::IsInfty(a);
    bool b_infty = FPUTestUtil::IsInfty(b);
    bool a_denormal = FPUTestUtil::IsDenormal(a);
    bool b_denormal = FPUTestUtil::IsDenormal(b);

    if (FPUTestUtil::IsSigNaN(a) || FPUTestUtil::IsSigNaN(b))
    {
        tres->unimplemented = 0; 
        tres->invalid = 1; 
        tres->overflow = 0;
        tres->underflow = 0;
        tres->z = FPUTestUtil::ConvertIntToFloat(sign | 0x7fbfffff); // signan
    }
    else if (FPUTestUtil::IsNaN(a) || FPUTestUtil::IsNaN(b))
    {
        tres->unimplemented = 0; 
        tres->invalid = 0; 
        tres->overflow = 0;
        tres->underflow = 0;
        tres->z = FPUTestUtil::ConvertIntToFloat(sign | 0x7fffffff); // quiet nan
    }
    else if (a_infty && b_infty)
    {
        tres->unimplemented = 0; 
        tres->invalid = 0; 
        tres->overflow = 0;
        tres->underflow = 0;
        tres->z = (sub_mag == 0)
            ? FPUTestUtil::ConvertIntToFloat(sign | 0x7f800000)  // infinite
            : FPUTestUtil::ConvertIntToFloat(sign | 0x7fffffff); // quiet NaN
    }
    else if (a_infty && !b_infty)
    {
        tres->unimplemented = 0; 
        tres->invalid = 0; 
        tres->overflow = 0;
        tres->underflow = 0;
        tres->z = FPUTestUtil::ConvertIntToFloat(sign | 0x7f800000);
    }
    else if (!a_infty && b_infty)
    {
        tres->unimplemented = 0; 
        tres->invalid = 0; 
        tres->overflow = 0;
        tres->underflow = 0;
        tres->z = FPUTestUtil::ConvertIntToFloat(sign | 0x7f800000);
    }
    else if (a_denormal || b_denormal)
    {
        tres->unimplemented = 1; 
        tres->invalid = 0; 
        tres->overflow = 0;
        tres->underflow = 0;
        tres->z = FPUTestUtil::ConvertIntToFloat(sign | 0x7fffffff);
    }
    else
    {
        // clear exception flags. 
        if (feclearexcept(FE_ALL_EXCEPT) != 0)
        {
            cout << "failed to clear floating point exception." << endl;
        }

        float z = (sub_i == 1)
            ? a - b
            : a + b;
        
        int invalid = 0;
        int overflow = 0;
        int underflow = 0;

        // grab exception flags
        FPUTestUtil::CheckError(fegetexceptflag((fexcept_t *) &invalid, FE_INVALID));
        FPUTestUtil::CheckError(fegetexceptflag((fexcept_t *) &overflow, FE_OVERFLOW));
        FPUTestUtil::CheckError(fegetexceptflag((fexcept_t *) &underflow, FE_UNDERFLOW));
       
        if (FPUTestUtil::IsDenormal(z)) 
        {
            tres->unimplemented = 0;
            tres->invalid = 0; 
            tres->overflow = 0;
            tres->underflow = 1;
            tres->z = FPUTestUtil::ConvertIntToFloat(sign | 0);
        }
        else if (underflow != 0)
        {
            tres->unimplemented = 0;
            tres->invalid = 0; 
            tres->overflow = 0;
            tres->underflow = 1;
            tres->z = FPUTestUtil::ConvertIntToFloat(sign | 0);
        }
        else if (overflow != 0)
        {
            tres->unimplemented = 0;
            tres->invalid = 0; 
            tres->overflow = 1;
            tres->underflow = 0;
            tres->z = FPUTestUtil::ConvertIntToFloat(sign | 0x7f800000);
        }
        else
        {
            tres->unimplemented = 0;
            tres->invalid = invalid; 
            tres->overflow = overflow;
            tres->underflow = underflow;
            tres->z = z;
        }
    }
  }
  else if (typeid(T) == typeid(double))
  {
    bool sgn = CalculateSign(a, b, sub_i);
    uint64_t sign = sgn ? 0x8000000000000000 : 0;
    uint64_t hex_a = FPUTestUtil::ConvertDoubleToInt(a);
    uint64_t hex_b = FPUTestUtil::ConvertDoubleToInt(b);
    uint64_t sub_mag = (hex_a & 0x8000000000000000) ^ (hex_b & 0x8000000000000000) ^ ((long) sub_i << 63);
    bool a_infty = FPUTestUtil::IsInfty((double) a);
    bool b_infty = FPUTestUtil::IsInfty((double) b);
    bool a_denormal = FPUTestUtil::IsDenormal((double) a);
    bool b_denormal = FPUTestUtil::IsDenormal((double) b);

    if (FPUTestUtil::IsSigNaN((double) a) || FPUTestUtil::IsSigNaN((double) b))
    {
        tres->unimplemented = 0; 
        tres->invalid = 1; 
        tres->overflow = 0;
        tres->underflow = 0;
        tres->z = FPUTestUtil::ConvertIntToDouble(sign | 0x7ff7ffffffffffff); // signan
    }
    else if (FPUTestUtil::IsNaN((double) a) || FPUTestUtil::IsNaN((double) b))
    {
        tres->unimplemented = 0; 
        tres->invalid = 0; 
        tres->overflow = 0;
        tres->underflow = 0;
        tres->z = FPUTestUtil::ConvertIntToDouble(sign | 0x7fffffffffffffff); // quiet nan
    }
    else if (a_infty && b_infty)
    {
        tres->unimplemented = 0; 
        tres->invalid = 0; 
        tres->overflow = 0;
        tres->underflow = 0;
        tres->z = (sub_mag == 0)
            ? FPUTestUtil::ConvertIntToDouble(sign | 0x7ff0000000000000)  // infinite
            : FPUTestUtil::ConvertIntToDouble(sign | 0x7fffffffffffffff); // quiet NaN
    }
    else if (a_infty && !b_infty)
    {
        tres->unimplemented = 0; 
        tres->invalid = 0; 
        tres->overflow = 0;
        tres->underflow = 0;
        tres->z = FPUTestUtil::ConvertIntToDouble(sign | 0x7ff0000000000000);
    }
    else if (!a_infty && b_infty)
    {
        tres->unimplemented = 0; 
        tres->invalid = 0; 
        tres->overflow = 0;
        tres->underflow = 0;
        tres->z = FPUTestUtil::ConvertIntToDouble(sign | 0x7ff0000000000000);
    }
    else if (a_denormal || b_denormal)
    {
        tres->unimplemented = 1; 
        tres->invalid = 0; 
        tres->overflow = 0;
        tres->underflow = 0;
        tres->z = FPUTestUtil::ConvertIntToDouble(sign | 0x7fffffffffffffff);
    }
    else
    {
        // clear exception flags. 
        if (feclearexcept(FE_ALL_EXCEPT) != 0)
        {
            cout << "failed to clear floating point exception." << endl;
        }

        double z = sub_i
            ? a - b
            : a + b;
        
        int invalid = 0;
        int overflow = 0;
        int underflow = 0;

        // grab exception flags
        FPUTestUtil::CheckError(fegetexceptflag((fexcept_t *) &invalid, FE_INVALID));
        FPUTestUtil::CheckError(fegetexceptflag((fexcept_t *) &overflow, FE_OVERFLOW));
        FPUTestUtil::CheckError(fegetexceptflag((fexcept_t *) &underflow, FE_UNDERFLOW));
       
        if (FPUTestUtil::IsDenormal((double) z)) 
        {
            tres->unimplemented = 0;
            tres->invalid = 0; 
            tres->overflow = 0;
            tres->underflow = 1;
            tres->z = FPUTestUtil::ConvertIntToDouble(sign | 0);
        }
        else if (underflow != 0)
        {
            tres->unimplemented = 0;
            tres->invalid = 0; 
            tres->overflow = 0;
            tres->underflow = 1;
            tres->z = FPUTestUtil::ConvertIntToDouble(sign | 0);
        }
        else if (overflow != 0)
        {
            tres->unimplemented = 0;
            tres->invalid = 0; 
            tres->overflow = 1;
            tres->underflow = 0;
            tres->z = FPUTestUtil::ConvertIntToDouble(sign | 0x7ff0000000000000);
        }
        else
        {
            tres->unimplemented = 0;
            tres->invalid = invalid; 
            tres->overflow = overflow;
            tres->underflow = underflow;
            tres->z = (double) z;
        }
    }
  } 
}

template <typename T>
void AddSubTester<T>::Assert(TestResult<T> *tres)
{
  _outputROM << tres->ToString() << endl;
}

template <typename T>
bool AddSubTester<T>::CalculateSign(T a, T b, bool sub_i)
{
  bool sign;

  if (typeid(float) == typeid(T))
  {
    uint32_t hex_a = hex(a);
    uint32_t hex_b = hex(b);
    uint32_t a_sign = hex_a & 0x80000000;
    uint32_t b_sign = hex_b & 0x80000000;
    uint32_t a_abs = hex_a & 0x7fffffff;
    uint32_t b_abs = hex_b & 0x7fffffff;

    if (a_sign == 0 && b_sign == 0)
    {
      if (a_abs >= b_abs) 
        sign = false;
      else
        sign = sub_i;
    }
    else if (a_sign == 0 && b_sign == 0x80000000)
    {
        if (a_abs >= b_abs)
            sign = false;
        else
            sign = !sub_i;
    }
    else if (a_sign == 0x80000000 && b_sign == 0)
    {
        if (a_abs >= b_abs)
            sign = true;
        else
            sign = sub_i;
    }
    else
    {
        if (a_abs >= b_abs)
            sign = true;
        else
            sign = !sub_i;
    }
    
    return sign;
  }
  else if (typeid(double) == typeid(T))
  {
    uint64_t hex_a = hex64(a);
    uint64_t hex_b = hex64(b);
    uint64_t a_sign = hex_a & 0x8000000000000000;
    uint64_t b_sign = hex_b & 0x8000000000000000;
    uint64_t a_abs = hex_a & 0x7fffffffffffffff;
    uint64_t b_abs = hex_b & 0x7fffffffffffffff;

    if (a_sign == 0 && b_sign == 0)
    {
      if (a_abs >= b_abs) 
        sign = false;
      else
        sign = sub_i;
    }
    else if (a_sign == 0 && b_sign == 0x8000000000000000)
    {
        if (a_abs >= b_abs)
            sign = false;
        else
            sign = !sub_i;
    }
    else if (a_sign == 0x8000000000000000 && b_sign == 0)
    {
        if (a_abs >= b_abs)
            sign = true;
        else
            sign = sub_i;
    }
    else
    {
        if (a_abs >= b_abs)
            sign = true;
        else
            sign = !sub_i;
    }
    
    return sign;

  }
  else
  {
    return false;
  }
}





// template class declaration
template class AddSubTester<float>;
template class AddSubTester<double>;
