#include <random>

extern "C" int get_random_binary() {
  //static std::random_device rd;
  static std::mt19937 e(0);
  static std::uniform_int_distribution<int> dis (0,1);
  int rand = dis(e);
  return rand;
}
