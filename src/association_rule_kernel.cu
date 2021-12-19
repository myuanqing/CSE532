#include "association_rule.h"
__device__ bool is_sub_array(Trans* trans, Pattern* pattern) {
         
    // whether matches            
    bool ret = false;
    int pat_data_num = pattern.pat_num;
    int input_data_num = trans.num;
    if (pat_data_num <= input_data_num) {
        int input_ptr = 0;
        int pat_ptr = 0;
        while ( (pat_ptr < pat_data_num) && (input_ptr < input_data_num) ) {
            if (pattern.data[pat_ptr] < trans.data[input_ptr]) break;
            else if (pattern.data[pat_ptr] == trans.data[input_ptr]) {
                pat_ptr ++;
                input_ptr ++;
            } else {
                input_ptr ++;
            }
        }
        if (pat_ptr == pat_data_num)
            ret = true; 
    }                           
    return ret;
}

__device__ bool generate_new_pattern (Pattern* old, Pattern* cur, Pattern* tail) {

    bool ret = false;
    if ( (old->pat_num == cur->pat_num) && (old->num > THREASHOLD) ) {
        int m = 0;
        for (; m < cur->pat_num-1; ++m) {
            if (old->data[m] != cur->data[m]) {
                break;
            }
        }
                
        if (m == cur->pat_num-1) {
            tail.pat_num = old.pat_num;
            tail.num = 0;
            for (int i = 0; i < old.pat_num; ++i) {
                tail.data[m] = tail.data[m];
            }
            tail.data[pat.pat_num] = cur.data[pat.pat_num-1];
            ret = true;
        }

    }
    return ret;
}

__global__ void association_kernel (Trans* input, int input_num, Pattern* pattern, int pat_num, int* ret) {
    
    int pat_idx = 0;    
    int cmp_idx = 0;

    extern __shared__ int smem[];

    //one pattern a time
    while(pat_idx < pat_num) {
        smem[threadIdx.x] = 0;
        // All input on this thread
        int input_idx = threadIdx.x;
        while (input_idx < input_num) {            
            // whether matches            
            if (is_sub_array(pattern+pat_idx, input + input_idx)) {
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
            pattern[pat_idx].num = smem[0];
            smem[0] = pat_num;
            int k = cmp_idx;
            if (pattern[pat_idx].num > THREASHOLD) {
                bool start = false;
                for (; k < pat_idx; k++) {
                    if (generate_new_pattern(pattern+k, pattern+pat_idx, pattern+pat_num))
                        if (!start) {
                            start = true;
                            cmp_idx = k;   
                        }
                        smem[0] = pat_num++;
                    }
                }
            }  
        } 
        __syncthreads();

        pat_num = smem[0];
        pat_idx ++;


    }
    *ret = pat_num;
}

