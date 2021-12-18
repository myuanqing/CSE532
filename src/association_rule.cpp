#include "association_rule.h"
#include <map>
#include <pthread>
#include <algorithm>
#define TRANSNUM 100
#define PTHREADNUM 8
#define ITEMSIZE 100
pthread_mutex_t mtx;
Trans[TRANSNUM];
int tnum = TRANSNUM;
int pnum = PTHREADNUM;
std::map<int, int> itemmp;
    
int Sdata[ITEMSIZE]; 
Pattern pattern[ITEMSIZE* ITEMSIZE];
int dual_pat_size = 0;

void* apply_association(void* mytno){
    int tno = (int)mytno;
    for (int i = pno; i < tnum; i += pnum) {
        for (int j = 0; j < trans[i].num; ++j) {
            int data = trans[i].data[j];
            pthread_mutex_lock(&mtx);
            if (itemmp.find(data) == itemmp.end()) {
                itemmp[data] = 1;
            } else {
                itemmp[data] ++;
            }
            pthread_mutex_unlock(&mtx);
        }
    }
    return NULL;
}

int main() {
    pthread_t pid[PTHREADNUM];
    for (int i = 0; i < PTHREADNUM; ++i) {
        pthread_create(&pid[i], NULL, apply_association, (void*)i);   
    }
    for (int i = 0; i < PTHREADNUM; ++i) {
        pthread_join(&pid[i], NULL);   
    }

    int ptn_num = 0;

    int pat_size = 0;

    for (auto iter = itemmp.begin(); iter != itemmp.end(); ++iter) {
        if (iter->second > THREASHOLD) {
            Sdata[ptn_num++] = iter->first;
        }
    }
    sort(Sdata, Sdata+ptn_num);
    for (int  i = 0; i < ptn_num-1; ++i) {
        for (int j = i+1; j < ptn_num; ++j) {
            pattern[dual_pat_size].pat_num = 2;
            pattern[dual_pat_size].num = 0;
            pattern[dual_pat_size].data[0] = Sdata[i];
            pattern[dual_pat_size].data[1] = Sdata[j];
            dual_pat_size ++;
        }
    }

}