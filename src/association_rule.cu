#include "association_rule.h"
Trans trans[TRANSNUM];
int tnum = 0;
int sdata[ITEMSIZE]; 
//int sdata_num = 0;

void apply_association(std::map<int, int>&itemmp){
    for (int i = 0; i < tnum; i ++) {
        for (int j = 0; j < trans[i].num; ++j) {
            int data = trans[i].data[j];
            if (data == 1) {
            }
            if (itemmp.find(data) == itemmp.end()) {
                itemmp[data] = 1;
            } else {
                itemmp[data] ++;
            }
            //cout << "a" << endl;
        }
    }
    return;
}

int main() {

    ifstream fin;
    fin.open("BMS1_itemset_mining.txt");
    string line;
    tnum = 0;
    while(getline(fin, line)) {
        //cout << "zz" << std::endl;
        stringstream ss(line);
        int x;
        int dnum = 0;
        while(ss >> x) {
            trans[tnum].data[dnum++] = x;
            
        }
        if ((dnum <= DATA_SIZE)) {
            trans[tnum++].num = dnum;
        }  
        if (tnum > 50000) {
            break;
        }
    }
    std::map<int, int> itemmp;
    apply_association(itemmp);
    
        
    
    //int pat_size = 0;
    int sdata_num = 0;
    for (std::map<int,int>::iterator iter = itemmp.begin(); iter != itemmp.end(); ++iter) {
        
        if (iter->second > THREASHOLD) {
            sdata[sdata_num++] = iter->first;
        }
    }
    sort(sdata, sdata+sdata_num);
    
    //for (int i = 0; i < sdata_num; ++i) {
    //    cout << sdata[i] <<'\t';
    //}
    cout << tnum << endl;
    cout << sdata_num << endl;
    int dual_size = (sdata_num-1)*sdata_num/2;
    Pattern* pattern = new Pattern[dual_size];
    
    
    int dual_ptr = 0;
    int per_size = dual_size/STREAM_NUM;
    int pos = 0;
    int pos_array[STREAM_NUM];
    int size_array[STREAM_NUM];
    pos_array[0] = 0;
    for (int  i = 0; i < sdata_num-1; ++i) {
        for (int j = i+1; j < sdata_num; ++j) {
            pattern[dual_ptr].pat_num = 2;
            pattern[dual_ptr].num = 0;
            pattern[dual_ptr].data[0] = sdata[i];
            pattern[dual_ptr].data[1] = sdata[j];
            dual_ptr++;
        }
        if (pos < STREAM_NUM - 1) {
            if (per_size < dual_ptr - pos_array[pos]) {
                size_array[pos] = dual_ptr - pos_array[pos];   
                pos ++;
                if (pos < STREAM_NUM) {
                    pos_array[pos] = dual_ptr;
                } 
            }
        }
    }
    size_array[pos] = dual_ptr - pos_array[pos];
    

    for (int i = 0; i < STREAM_NUM; ++i) {
        cout << pos_array[i]<<" " << size_array[i] << endl;
    }
    
    
    cudaStream_t streams[STREAM_NUM];
    Pattern *device_pattern[STREAM_NUM];
    Trans* device_trans;
    
    int *device_pat_num;
    int *host_pat_num;
    
    for (int i = 0; i < STREAM_NUM; ++i) {
        cudaStreamCreate(&streams[i]);
        cudaMalloc((void**)&device_pattern[i], 300000*sizeof(Pattern));
    }

    cudaMalloc((void**)&device_trans, tnum * sizeof(Trans));

    cudaMalloc((void**)&device_pat_num, STREAM_NUM*sizeof(int));
    cudaMemcpy(device_trans,  trans, tnum*sizeof(Trans), cudaMemcpyHostToDevice);
    for (int i = 0; i < STREAM_NUM; ++i) {
        cudaMemcpyAsync(device_pattern[i], &pattern[pos_array[i]], size_array[i] * sizeof(Pattern), cudaMemcpyHostToDevice, streams[i]);
        int threadnum = 512;
        dim3 threadDim(threadnum);
        dim3 blockDim(1);
        association_kernel<<<blockDim, threadDim, 0 ,streams[i]>>>(device_trans,tnum, device_pattern[i], size_array[i]); 
    }


    for (int i = 0; i < STREAM_NUM; ++i) {
        Pattern* output_pattern = new Pattern[PERMEM/sizeof(Pattern)];
        cudaMemcpyAsync(output_pattern, device_pattern[i], PERMEM, cudaMemcpyDeviceToHost, streams[i]);
    }
    host_pat_num = new int[STREAM_NUM];
    cudaMemcpy(host_pat_num, device_pat_num, STREAM_NUM*sizeof(int), cudaMemcpyDeviceToHost);


    return 0;
}