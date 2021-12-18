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


__global__ void* association_kernel (Trans* input, int input_num, Pattern* pattern, int* pat_data_array, int pat_num, int pattern_dim) {
    
    pattern += pattern_dim * blockIdx.x;
    //int tid = threadIdx.x + blockIdx.x * blockDim.x;    
    int pat_idx = 0;
    
    int cmp_idx = 0;
    extern __shared__ int smem[];

    //one pattern a time
    while(pat_idx < pat_num) {
        smem[threadIdx.x] = 0;
        Pattern pat = pattern[pat_idx];
        // All input on this thread
        int input_idx = threadIdx.x;
        while (input_idx < input_num) {
            Trans ipt = input[input_idx];            
            // whether matches            
            int pat_data_num = pat.pat_num;
            int input_data_num = ipt.num;
            if (pat_data_num <= input_data_num) {
                int input_ptr = 0;
                int pat_ptr = 0;
                while ( (pat_ptr < pat_data_num) && (input_ptr < input_data_num) ) {
                    if (pat.data[pat_ptr] < ipt.data[input_ptr]) break;
                    else if (pat.data[pat_ptr] == ipt.data[input_ptr]) {
                        pat_ptr ++;
                        input_ptr ++;
                    } else {
                        input_ptr ++;
                    }
                }
                if (pat_ptr == pat_data_num)
                    smem[threadIdx.x] ++; 
            }                           
            input_idx += blockDim.x;

        }
        __syncthreads();
        //sum up this pattern
        for (int i = (blockDim.x >> 1); i > 0; i >>=1 ) {
            if (threadIdx.x < i) {
                smem[threadIdx.x] += smem[threadIdx.x + i];
            }
            __syncthreads();
        }


        if (threadIdx.x == 0) {
            // write back
            pat.num = smem[0];
            smem[0] = pat_num;
            int k = cmp_idx;
            if (pat.num > THREASHOLD) {
                bool start = false;
                for (; k < pat_idx; k++) {
                    if ( (pattern[k].pat_num == pat.pat_num) && (pattern[k].num > THREASHOLD) ) {
                        bool test = true;
                        for (int m = 0; m < pat.pat_num-1; ++m) {
                            if (pattern[k].data[m] != pat.data[m]) {
                                test = false;
                                break;
                            }
                        }
                        if (test && (!start)) {
                            start = true;
                            cmp_idx = k;   
                        }
                        if (test) {
                            pattern[pat_num].pat_num= pat.pat_num;
                            pattern[pat_num].num = 0;
                            for (int m = 0; m < pat.pat_num; ++m) {
                                pattern[pat_num].data[m] = pattern[k].data[m];
                            }
                            pattern[pat_num].data[pat.pat_num] = pat.data[pat.pat_num-1];
                            smem[0] = pat_num++;

                        }

                    }
                }
            }  
        } 
        __syncthreads();

        pat_num = smem[0];
        pat_idx ++;


    }
}