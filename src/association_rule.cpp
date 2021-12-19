#include "association_rule.h"
#include <map>
#include <pthread>
#include <algorithm>
#define TRANSNUM 100
#define ITEMSIZE 100
#define PERMEM 0x10000
#define STREAM_NUM 4
Trans trans[TRANSNUM];
int tnum = 0;
int sdata[ITEMSIZE]; 
int sdata_num = 0;

void apply_association(std::map<int, int>&itemmp){
    for (int i = 0; i < tnum; i ++) {
        for (int j = 0; j < trans[i].num; ++j) {
            int data = trans[i].data[j];
            if (itemmp.find(data) == itemmp.end()) {
                itemmp[data] = 1;
            } else {
                itemmp[data] ++;
            }
        }
    }
    return;
}

int main() {

    std::map<int, int> itemmp;
    apply_association(itemmp);
    
    cudaStream_t streams[STREAM_NUM];
    Pattern *device_pattern[STREAM_NUM];
    int *device_pat_num;
    int *host_pat_num;
    int pos_array[STREAM_NUM];
    int size_array[STREAM_NUM];
    
    int pat_size = 0;
    for (auto iter = itemmp.begin(); iter != itemmp.end(); ++iter) {
        if (iter->second > THREASHOLD) {
            sdata[sdata_num] = iter->first;
        }
    }
    sort(sdata, sdata+sdata_num);
    int dual_size = (sdata_num-1)*sdata_num/2;
    Pattern* pattern = new pattern[dual_size];
    int dual_ptr = 0;
    int per_size = dual_size/STREAM_NUM;
    int pos = 0;
    pos_array[0] = 0;
    for (int  i = 0; i < sdata_num-1; ++i) {
        for (int j = i+1; j < sdata_num; ++j) {
            pattern[dual_ptr].pat_num = 2;
            pattern[dual_ptr].num = 0;
            pattern[dual_ptr].data[0] = Sdata[i];
            pattern[dual_ptr].data[1] = Sdata[j];
            dual_ptr++;
        }
        if (per_size < dual_ptr - pos_array[pos]) {
            size_array[pos] = dual_ptr - pos_array[pos];   
            pos ++;
            if (pos < STREAM_NUM) {
                pos_array[pos] = dual_ptr;
            } 
        }

    }
    for (int i = 0; i < STREAM_NUM; ++i) {
        cudaStreamCreate(&streams[i]);
        cudaMalloc((void**)&device_pattern[i], PERMEM);
    }
    cudaMalloc((void**)&device_trans, PERMEM);
    cudaMalloc((void**)&device_pat_num, STREAM_NUM*sizeof(int));
    cudaMemcpy(device_trans,  trans, tnum*sizeof(Trans), cudaMemcpyHostToDevice);
    for (int i = 0; i < STREAM_NUM; ++i) {
        cudaMemcpyAsync(device_pattern[i], &pattern[pos_array[i]], size_array[i],cudaMemcpyHostToDevice, streams[i]);
        int threadnum = 1024;
        association_kernel<<<1, threadnum, threadnum, streams[i]>>>(device_trans,tnum, device_pattern[i], size_array[i], device_pat_num+i); 
    }


    for (int i = 0; i < STREAM_NUM; ++i) {
        Pattern* output_pattern = new Pattern[PERMEM/sizeof(Pattern)];
        cudaMemcpyAsync(output_pattern, device_pattern[i], PERMEM, cudaMemcpyDeviceToHost, streams[i]);
    }
    host_pat_num = new int[STREAM_NUM];
    cudaMemcpy(host_pat_num, device_pat_num, STREAM_NUM*sizeof(int), cudaMemcpyDeviceToHost);


    return 0;
}