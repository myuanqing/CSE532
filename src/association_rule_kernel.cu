#include "association_rule.h"
__device__ bool is_sub_array(Pattern* pattern, Trans* trans) {
    
    //printf("enter sub array\n");
    // whether matches            
    bool ret = false;
    int pat_data_num = pattern->pat_num;
    int input_data_num = trans->num;
    //printf("here\n");
    if (pat_data_num <= input_data_num) {
        int input_ptr = 0;
        int pat_ptr = 0;
        while ( (pat_ptr < pat_data_num) && (input_ptr < input_data_num) ) {
            if (pattern->data[pat_ptr] < trans->data[input_ptr]) break;
            else if (pattern->data[pat_ptr] == trans->data[input_ptr]) {
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

    // //bool ret = false;
    // if ( (old->pat_num == cur->pat_num) && (old->num > THREASHOLD) ) {
    //     //int m = 0;
    //     for (int m = 0; m < cur->pat_num-1; ++m) {
    //         if (old->data[m] != cur->data[m]) {
    //             return false;
    //         }
    //     }
                
        
    //     tail->pat_num = old->pat_num;
    //     tail->num = 0;
    //     for (int i = 0; i < old->pat_num; ++i) {
    //             tail->data[i] = old->data[i];
    //     }
    //         tail->data[old->pat_num] = cur->data[old->pat_num-1];
    //         return true;
        

    // }
    return false;
}

__global__ void association_kernel (Trans* input, int input_num, Pattern* pattern, int pat_num) {
    __shared__ int smem[CUDATHREAD];
    int pat_idx = 0;    
    int cmp_idx = 0;
    bool start = false;
    
   
    //one pattern a time
    while(pat_idx < pat_num) {
        //printf("%d, %d\n", pat_idx, pat_num);
        //   
        smem[threadIdx.x] = 0;
        //printf("%d, %d\n", threadIdx.x, input_num); 
        //printf("aaaa");
        // All input on this thread
        int input_idx = threadIdx.x;
        //int tmp_num = 0;
        while (input_idx < input_num) {            
            // whether matches            
            //printf("a\n");
            //if (threadIdx.x == 10) {
            //    printf("hhh\n");
            //}

            if (is_sub_array(pattern+pat_idx, input + input_idx)) {
                smem[threadIdx.x] = smem[threadIdx.x] + 1;
                //tmp_num++;
                //printf("here: %d, %d, %d\n", threadIdx.x, input_idx, input_num);    
            }
            input_idx += blockDim.x;
            //printf("here!\n");
        }
       

        //if (threadIdx.x < 512) {
        //            printf("Wrong\n");
        //}

        //printf("hhh\n");
        
        //
        __syncthreads();        
        //smem[threadIdx.x] = tmp_num;
        //__syncthreads();
        //sum up this pattern
        for (int i = (blockDim.x >> 1); i > 0; i >>=1 ) {
            if (threadIdx.x < i) {
                //printf("%d,%d\n", threadIdx.x, i);
                smem[threadIdx.x] += smem[threadIdx.x + i];
            }
            __syncthreads();
        }
        //printf("here?\n");
        bool mybool = true;
        if (threadIdx.x == 0) {
            // write back
            //printf("%d, %d\n", pat_idx, pat_num);
            pattern[pat_idx].num = smem[0];
            //printf("num: %d\n", pattern[pat_idx].num);
            smem[0] = pat_num;
            if (pattern[pat_idx].num > THREASHOLD) {
                start = false;
                for (int k = cmp_idx; k < pat_idx; k++) {
                //for (int k = 0; k < pat_idx; k++) {  
                    mybool = true;
                                      
                    if ( (pattern[k].pat_num == pattern[pat_idx].pat_num) && (pattern[k].num > THREASHOLD) ) {
    
                        for (int m = 0; m < pattern[k].pat_num-1; ++m) {
                            if (pattern[k].data[m] != pattern[pat_idx].data[m]) {
                                mybool = false;
                                break;
                            }
                        }
                        //printf("%d, %d\n", k, pat_num);
                
                        if (mybool) {
                            //printf("%d,%d,%d\n", k, pat_idx, pat_num);
                            pattern[pat_num].pat_num = pattern[k].pat_num+1;
                            pattern[pat_num].num = 0;
                            
                            for (int i = 0; i < pattern[k].pat_num; ++i) {
                                pattern[pat_num].data[i] = pattern[k].data[i];
                                //printf("%i, %d, %d\n", i, pattern[pat_idx].data[i] , pattern[k].data[i]);
                            }
                            pattern[pat_num].data[pattern[k].pat_num] = pattern[pat_idx].data[pattern[k].pat_num-1];
                            if (!start) {
                                start = true;
                                cmp_idx = k;
                            }
                            //printf("here\n");
                            ++pat_num;
                            smem[0] = pat_num;
                        } 
        
                        
                    }
                    
                }
            }  
            //printf("yy\n");
        } 
        __syncthreads();

        pat_num = smem[0];
        pat_idx ++;
        //printf("%d, %d\n", pat_idx, pat_num);

    }

    if (threadIdx.x == 0)
        printf("Finish, %d\n", pat_num);
}

