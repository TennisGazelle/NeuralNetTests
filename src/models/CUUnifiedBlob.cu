//
// Created by daniellopez on 4/4/18.
//

#include <cassert>
#include <CUDAUtils.h>
#include <iostream>
#include <cmath>
#include "models/CUUnifiedBlob.h"
#include "CUDAUtils.h"

using namespace std;

CUUnifiedBlob::CUUnifiedBlob(int pSize) : size(pSize), data(nullptr), isGPUAllocated(false) {
    assert (pSize > 0);
    allocateMemory();
}

CUUnifiedBlob::~CUUnifiedBlob() {
    if (isGPUAllocated) {
        deallocateMemory();
    }
}

void CUUnifiedBlob::allocateMemory() {
    assert(!isGPUAllocated);
    auto error = cudaMallocManaged((void**)&data, size * sizeof(double), cudaMemAttachGlobal);
    CUDAUtils::handleError(error);
    isGPUAllocated = true;
}

void CUUnifiedBlob::deallocateMemory() {
    assert(isGPUAllocated);
    cudaFree(data);
    data = nullptr;
    isGPUAllocated = false;
}

void CUUnifiedBlob::clear() {
    for (int i = 0; i < size; i++) {
        data[i] = 0.0;
    }
}

void CUUnifiedBlob::resize(int newSize) {
    deallocateMemory();
    size = newSize;
    allocateMemory();
}

void CUUnifiedBlob::print(const string& msg, int width) {
    if (!msg.empty()) {
        cout << msg << endl;
    }
    int bufferSize = min(size, 30);
    for (int i = 0; i < bufferSize; i++) {
        cout << data[i] << "\t";
        if (((i+1) % width) == 0) {
            cout << endl;
        }
    }
    cout << endl;
}

bool CUUnifiedBlob::operator==(const CUUnifiedBlob &other) const {
    if (this == &other) {
        return true;
    }

    if (size != other.size) {
        cout << "bad sizes" << endl;
        return false;
    }

    for (int i = 0; i < size; i++) {
        if (data[i] != other.data[i]) {
            cout << "they didn't match at: " << i << endl;
            cout << "this: " << data[i] << " other: " << other.data[i] << endl;
            return false;
        }
    }

    return true;
}

void CUUnifiedBlob::setValueAt_1D(int location, double incomingValue) {
    assert(0 <= location && location < size);
    data[location] = incomingValue;
}

void CUUnifiedBlob::setValueAt_2D(int x, int y, int xDim, double incomingValue) {
    // where is the location?
    int location = x * xDim;
    location += y;

    setValueAt_1D(location, incomingValue);
}

void CUUnifiedBlob::setValueAt_3D(int x, int y, int z, int xDim, int yDim, double incomingValue) {
    int location = z * xDim * yDim;
    location += x * xDim;
    location += y;

    setValueAt_1D(location, incomingValue);
}

void CUUnifiedBlob::matrixVectorMultiplication(CUUnifiedBlob &matrix, CUUnifiedBlob &inputVector,
                                               CUUnifiedBlob &outputVector, int inputDim, int outputDim) {
    assert(matrix.size == inputDim*outputDim);
    assert(inputVector.size == inputDim);
    assert(outputVector.size == outputDim);

    for (int i = 0; i < outputDim; i++) {
        for (int j = 0; j < inputDim; j++) {
            outputVector.data[i] += inputVector.data[j] * matrix.data[i*inputDim + j];
        }
    }
}

void CUUnifiedBlob::vectorVectorSoftmax(CUUnifiedBlob& b, CUUnifiedBlob& c,
                                        int numClasses, int tensorSize) {
    for (int k = 0; k < numClasses; k++) {
        double sum_b_exps = 0.0;
        for (int t = 0; t < tensorSize; t++) {
            sum_b_exps += exp(b.data[t*numClasses + k]);
        }

        // then go through the c's and set accordingly
        for (int t = 0; t < tensorSize; t++) {
            c.data[t*numClasses + k] = exp(b.data[t*numClasses + k])/ sum_b_exps;
        }
    }
}

void CUUnifiedBlob::weightReduceVectors(CUUnifiedBlob &u_hat, CUUnifiedBlob &c, CUUnifiedBlob &v, int numClasses,
                                        int tensorSize, int dim) {
    for (int k = 0; k < numClasses; k++) {
        for (int t = 0; t < tensorSize; t++) {
            int u_hat_index = t*numClasses*dim + k*dim;

            for (int i = u_hat_index; i < u_hat_index + dim; i++) {
                u_hat.data[i] *= c.data[t*numClasses+k];
                v.data[i % (numClasses*dim)] += u_hat.data[i];
            }
        }
    }
}

void CUUnifiedBlob::vectorSquash(CUUnifiedBlob &v, int numVecs, int vecDim) {
    for (int v_index = 0; v_index < numVecs*vecDim; v_index += vecDim) {
        double sum_squares = 0;
    	for (int i = 0; i < vecDim; i++) {
    	    sum_squares += pow(v.data[v_index + i], 2);
    	}
    	double squashFactor = sum_squares / (1.0 + sum_squares);
    	sum_squares = sqrt(sum_squares);
    	for (int i = 0; i < vecDim; i++) {
    		v.data[v_index + i] *= squashFactor / sum_squares;
    	}
    }
}

void CUUnifiedBlob::CUDA_matrixVectorMultiplication(CUUnifiedBlob &matrix,
                                                    CUUnifiedBlob &inputVector,
                                                    CUUnifiedBlob &outputVector,
                                                    int inputDim,
                                                    int outputDim,
                                                    int numMultiplications) {
    cu_matrixVectorMultiplication_kernel<<<numMultiplications, outputDim>>>(matrix.data,
                                                    inputVector.data,
                                                    outputVector.data,
                                                    inputDim,
                                                    outputDim);
}

void CUUnifiedBlob::CUDA_vectorVectorSoftmax(CUUnifiedBlob &b,
                                             CUUnifiedBlob &c,
                                             int numClasses,
                                             int tensorSize) {
    int offset = 0;
    do {
        unsigned int numThreadsToAllocate = (unsigned int) min(1024, tensorSize);
        cu_vectorVectorSoftmax_kernel<<<numClasses, numThreadsToAllocate, numThreadsToAllocate*sizeof(double)>>>(b.data, c.data, numClasses, tensorSize, offset);
        tensorSize -= numThreadsToAllocate;
        offset++;
    } while (tensorSize > 0);
}

void CUUnifiedBlob::CUDA_weightReduceVectors(CUUnifiedBlob &u_hat,
                                             CUUnifiedBlob &c,
                                             CUUnifiedBlob &v,
                                             int numClasses,
                                             int tensorSize,
                                             int dim) {
    dim3 blockDimensions(numClasses, dim);
    int offset = 0;
    do {
    	unsigned int numThreadsToAllocate = (unsigned int) min(1024, tensorSize);
    	cu_weightReduceVector_kernel<<<blockDimensions, tensorSize, tensorSize*sizeof(double)>>>(u_hat.data, c.data, v.data, numClasses, tensorSize, dim, offset);
    	tensorSize -= numThreadsToAllocate;
    	offset++;
    } while (tensorSize > 0);
}

void CUUnifiedBlob::CUDA_vectorSquash(CUUnifiedBlob &v, int numVecs, int vecDim) {
    dim3 blockDims(1, numVecs);

    if (blockDims.y > 1024) {
    	while (blockDims.y > 1024) {
    		blockDims.x++;
    		blockDims.y -= 1024;
       	}
    	blockDims.y = 1024;
    }
    cu_vectorSquash_kernel<<<blockDims, vecDim, vecDim*sizeof(double)>>>(v.data, numVecs, vecDim);
}

__global__
void cu_matrixVectorMultiplication_kernel(double *matrix, double *inputVector, double *outputVector,
                                          int inputDim, int outputDim) {
    int u_hat_index = threadIdx.x + (blockIdx.x * outputDim);
    double cache = 0.0;
    for (int c = 0; c < inputDim; c++) {
        cache += matrix[u_hat_index*inputDim+c] * inputVector[blockIdx.x*inputDim+c];
    }
    outputVector[u_hat_index] = cache;
}

__global__
void cu_vectorVectorSoftmax_kernel(double *b, double *c, int numClasses, int tensorSize, int offset) {
    int t = threadIdx.x + offset;
    int k = blockIdx.x;

    extern __shared__
    double shared_b_exps[];

    double my_exp_b = exp(b[t*numClasses+k]); // consider using hexp() for speed
    shared_b_exps[t] = my_exp_b;
    __syncthreads();

    for (unsigned int s = 1; s < blockDim.x; s *= 2) {
        if (t % (2*s) == 0) {
            shared_b_exps[t] += shared_b_exps[t + s];
        }
        __syncthreads();
    }

    double sum_exps = shared_b_exps[0];
    c[t*numClasses + k] = my_exp_b / sum_exps;
}

__global__
void cu_weightReduceVector_kernel(double *u_hat, double *c, double *v, int numClasses, int tensorSize, int dim, int offset) {
    int k = blockIdx.x * gridDim.x + blockIdx.y;
    int specificDim = blockIdx.y;
    int t = threadIdx.x + offset;

    int u_hat_index = t*numClasses*dim + k*dim;

    extern __shared__
    double shared_v_vec[];

    u_hat[u_hat_index + specificDim] *= c[t*numClasses+k];
    shared_v_vec[t] = u_hat[u_hat_index + specificDim] * c[t*numClasses+k];
    __syncthreads();

    for (unsigned int s = 1; s < blockDim.x; s *= 2) {
        if (t % (2*s) == 0) {
            shared_v_vec[t] += shared_v_vec[t + s];
        }
        __syncthreads();
    }
    double sum_exps = shared_v_vec[0];

    if (t == 0) {
        v[k*dim + specificDim] = shared_v_vec[0];
    }
}

__global__
void cu_vectorSquash_kernel(double *v, int numVecs, int vecDim) {
    int v_index = blockIdx.y*gridDim.x + blockIdx.x;
    int v_val_index = threadIdx.x;

    extern __shared__
    double shared_v_values[];
    // reduce the square of the individual elements in shared mem
    if (v_index < numVecs) {
    	shared_v_values[v_val_index] = pow(v[v_index*vecDim + v_val_index], 2);
    }
    __syncthreads();
    for (unsigned int s = 1; s < blockDim.x; s *= 2) {
        if (v_val_index % (2*s) == 0) {
        	shared_v_values[v_val_index] += shared_v_values[v_val_index + s];
        }
        __syncthreads();
    }

    // calc squashing func
    if (v_val_index == 0) {
        shared_v_values[1] = shared_v_values[0] / (1 + shared_v_values[0]);
        shared_v_values[0] = sqrt(shared_v_values[0]);
    }
    __syncthreads();

    if (v_index < numVecs) {
        v[v_index*vecDim + v_val_index] *= shared_v_values[1] / shared_v_values[0];   	
    }
}