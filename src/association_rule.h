#include <cuda.h>
#include <cuda_runtime.h>
#include <map>
#include <sstream>
#include <iostream>
#include <fstream>
#include <string>
#include <algorithm>
using namespace std;
#define TRANSNUM 60000
#define ITEMSIZE 60000
#define PATTERNNUM 500000
#define STREAM_NUM 8
#define CUDATHREAD 1024

#define DATA_SIZE 30
#define THREASHOLD 10

struct Trans {
    int num;
    int data[DATA_SIZE];
};

struct Pattern {
    int num;
    int pat_num;
    int data[DATA_SIZE];
};
__global__ void association_kernel (Trans* input, int input_num, Pattern* pattern, int pat_num); 