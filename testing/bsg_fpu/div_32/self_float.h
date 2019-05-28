class float16_t{ // 1,5,10
public:
    float16_t();
    float16_t(double f);

    bool isInf() const{
       return this->exponent() == 31 && !(this->m_value & 0x3FF);
    }
    bool isNaN() const{
        return this->exponent() == 31 && this->m_value & 0x3FF;
    }
    bool isZero() const{
        return (this->m_value & 0x7FFF) == 0;
    }

    inline char exponent() const{
       return (m_value & 0x7C00) >> 10;
    }

    inline unsigned short mantissa() const{
        return m_value & 0x3FF;
    }

    bool isDenormal() const{
        return (this->m_value & 0x7C00) == 0;
    }

    bool isPositive() const{
        return (this->m_value & 0x8000) == 0;
    }

    inline unsigned short representation() const{
        return m_value;
    }

    float16_t operator +(float16_t o) const;
    float16_t operator -(float16_t o) const;
    float16_t operator *(const float16_t &o) const;
    float16_t operator /(const float16_t &o) const;

    operator double(); // convert to double

    static float16_t fromRepresentation(unsigned short rep){
        float16_t f;
        f.m_value = rep;
        return f;
    }
private:
    unsigned short internalMantissa() const{ 
        if(this->exponent() != 0) {
            return this->mantissa() | 0x0400;
        } else
            return this->mantissa() << 1;
    }
    unsigned short m_value;
};