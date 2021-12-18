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
__global__ void association_kernel (Trans* input, int input_num, Pattern* pattern, int* pat_data_array, int pat_num, int pattern_dim); 