#include <random>

extern "C" int get_random_binary() {
  //static std::random_device rd;
  static std::mt19937 e(0);
  static std::uniform_int_distribution<int> dis (0,1);
  int rand = dis(e);
  return rand;
}


extern "C" float get_random_float() {
  //static std::random_device rd;
  static std::default_random_engine e(0);
  static std::uniform_real_distribution<> dis (0, 1);
  float rand = dis(e);
  //printf("CPP %f\n", rand);
  return rand;
}
