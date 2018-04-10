
#include <MultilayerPerceptron/MultilayerPerceptron.h>
#include <ConvolutionalNetwork/ConvolutionalNetwork.h>
#include <ConvolutionalNetwork/ConvolutionalLayer.h>
#include <iostream>
#include <cmath>
#include <ProgressBar.h>
#include <CapsuleNetwork/Capsule.h>
#include <Utils.h>
#include <models/VectorMap.h>
#include <cassert>
#include <CapsuleNetwork/CapsuleNetwork.h>
#include <models/CUUnifiedBlob.h>

void test_SingleLayerCNN() {
    auto image = MNISTReader::getInstance()->trainingData[0];
    ConvolutionalLayer layer(28, 28, 256, 9, 9);
    MultilayerPerceptron mp(layer.getOutputSize1D(), 10, {});

    mp.init();
    layer.setInput({image.toFeatureMap()});

    layer.calculateOutput();
    vector<double> mlpOutput = mp.loadInputAndGetOutput(layer.getOutputAsOneDimensional());
    vector<double> error(mlpOutput.size());

    ProgressBar pb(5000);
    for (int iter = 0; iter < 5000; iter++) {
        for (int i = 0; i < mlpOutput.size(); i++) {
            double target = 0;
            if (i == image.getLabel()) {
                target = 1;
            };
            error[i] = mlpOutput[i] * (1-mlpOutput[i]) * (target - mlpOutput[i]);
        }
        vector<double> mlpLastLayerError = mp.backPropagateError(error);
        layer.backPropagate(
                FeatureMap::toFeatureMaps(
                        layer.outputHeight,
                        layer.outputWidth,
                        mlpLastLayerError
                )
        );

        layer.calculateOutput();
        mlpOutput = mp.loadInputAndGetOutput(layer.getOutputAsOneDimensional());

        pb.updateProgress(iter);
    }


    cout << endl;

    for (int i = 0; i < mlpOutput.size(); i++) {
        double target = 0;
        if (i == image.getLabel()) {
            target = 1;
        };
        error[i] = mlpOutput[i] * (1-mlpOutput[i]) * (target - mlpOutput[i]);
        cout << i << ": " << mlpOutput[i] << " " << error[i] << endl;
    }

    layer.printKernel(1);
    layer.printOutput(1);
}

void test_CapsuleNetSquishing() {
    int dim = 3;
    arma::vec testInput(dim, arma::fill::randn);

    testInput.print("test input...");
    Utils::squish(testInput).print("output is....");
}

void fillFeatureMapWithRandom(FeatureMap& featureMap) {
    for (auto& row : featureMap) {
        for (auto& col : row) {
            col = Utils::getWeightRand(10) + 10;
        }
    }
}


void test_VectorMapFromFeatureMaps() {
    vector<FeatureMap> inputs;
    size_t inputsDepth = 256, outputVectorDim = 8, outputsDepth = 32;
    size_t row = 6, col = 6;

    // create and fill inputs with garbage
    for (int i = 0; i < inputsDepth; i++) {
        FeatureMap fm;
        fm.setSize(row, col);
        fillFeatureMapWithRandom(fm);
        inputs.push_back(fm);
    }

    vector<VectorMap> vectorMaps = VectorMap::toSquishedVectorMap(outputVectorDim, inputs);
    assert (vectorMaps.size() == outputsDepth);

    // just check the first vector
    arma::vec singleVector = vectorMaps[0][0][0];
    arma::vec originalVector(outputVectorDim);
    for (int i = 0; i < outputVectorDim; i++) {
        originalVector[i] = inputs[i][0][0];
    }

    originalVector = Utils::squish(originalVector);
    for (int i = 0; i < outputVectorDim; i++) {
        assert (singleVector[i] == originalVector[i]);
    }
}

void test_FeatureMapsFromVectorMap() {
    size_t inputsDepth = 32, vectorDim = 8, outputsDepth = 256;
    size_t row = 6, col = 6;
    vector<arma::vec> inputs(row*col*inputsDepth, arma::vec(vectorDim, arma::fill::randu));

    for (auto& v : inputs) {
        for (auto& val : v) {
            val = Utils::getWeightRand(10) + 10;
        }
    }

    vector<FeatureMap> maps = VectorMap::toArrayOfFeatureMaps(row, col, inputsDepth, inputs);
}

void test_CapsuleNetwork_ForwardPropagation() {
    CapsuleNetwork capsuleNetwork;
    vector<arma::vec> output = capsuleNetwork.loadImageAndGetOutput(0);

    for (int i = 0; i < 10; i++) {
        cout << "length of vector corresponding to " << i << ": " << sqrt(Utils::square_length(output[i])) << endl;
    }
}

void test_CapsuleNetwork_BackPropagation() {
    CapsuleNetwork capsuleNetwork;
    vector<arma::vec> output = capsuleNetwork.loadImageAndGetOutput(0);
    vector<arma::vec> error = capsuleNetwork.getErrorGradient(output, MNISTReader::getInstance()->trainingData[0].getLabel());
    capsuleNetwork.backPropagate(error);
    output = capsuleNetwork.loadImageAndGetOutput(0);

    for (int i = 0; i < 10; i++) {
        cout << "length of vector corresponding to " << i << ": " << sqrt(Utils::square_length(output[i])) << endl;
    }
}

void test_CapsuleNetwork_Epoch() {
    CapsuleNetwork capsuleNetwork;

    auto& data = MNISTReader::getInstance()->trainingData;
    const size_t batchSize = 250;

    ProgressBar pb(data.size());
    for (size_t i = 0; i < data.size(); i++) {
        vector<arma::vec> output = capsuleNetwork.loadImageAndGetOutput(i);
        vector<arma::vec> error = capsuleNetwork.getErrorGradient(output, data[i].getLabel());
        capsuleNetwork.backPropagate(error);

        if (i%batchSize == batchSize-1) {
            capsuleNetwork.updateWeights();
            capsuleNetwork.loadImageAndPrintOutput(i);
        }
        pb.updateProgress(i);
    }
}

void test_CapsuleNetwork_getMarginLoss() {
    CapsuleNetwork capsuleNetwork;
    vector<arma::vec> output = capsuleNetwork.loadImageAndGetOutput(0);
    double totalLoss = capsuleNetwork.getTotalMarginLoss(MNISTReader::getInstance()->trainingData[0].getLabel(), output);

    cout << "total loss is: " << totalLoss << endl;
}

void test_NetworkTallyingTiming() {
    MultilayerPerceptron mp(784, 10, {16,16});
    ConvolutionalNetwork cnn;
    CapsuleNetwork capsNet;

//    mp.init();
//    cnn.init();

//    mp.runEpoch();
//    cnn.runEpoch();
//    capsNet.runEpoch();

//    mp.tally(true);
//    cnn.tally(true);
//    capsNet.tally(true); // true for training set, false for testing set

//    mp.train();
//    cnn.train();
    capsNet.train();
}

void test_CapsuleNetwork_reconstruction() {
    CapsuleNetwork capsuleNetwork;
    int targetLabel = (int) MNISTReader::getInstance()->trainingData[0].getLabel();

    vector<arma::vec> output = capsuleNetwork.loadImageAndGetOutput(0);
    for (int i = 0; i < 10; i++) {
        cout << "length of vector corresponding to " << i << ": " << sqrt(Utils::square_length(output[i])) << endl;
    }
    cout << endl;

    vector<arma::vec> capsuleError = capsuleNetwork.getErrorGradient(output, targetLabel);
    vector<arma::vec> mlpError = capsuleNetwork.getReconstructionError(output, 0);

    capsuleNetwork.backPropagate(capsuleError);
    capsuleNetwork.backPropagate(mlpError);
    capsuleNetwork.updateWeights();

    vector<arma::vec> updatedOutput = capsuleNetwork.loadImageAndGetOutput(0);

    for (int i = 0; i < 10; i++) {
        cout << "length of vector corresponding to " << i << ": " << sqrt(Utils::square_length(updatedOutput[i])) << endl;
    }
}

void test_CapsuleNetwork_multipleReconstruction() {
    CapsuleNetwork capsuleNetwork;
    for (int i = 0; i < 10; i++) {
        int targetLabel = (int) MNISTReader::getInstance()->trainingData[0].getLabel();

        vector<arma::vec> output = capsuleNetwork.loadImageAndGetOutput(0);

        vector<arma::vec> capsuleError = capsuleNetwork.getErrorGradient(output, targetLabel);
        vector<arma::vec> mlpError = capsuleNetwork.getReconstructionError(output, 0);

        capsuleNetwork.backPropagate(capsuleError);
        capsuleNetwork.backPropagate(mlpError);
        capsuleNetwork.updateWeights();
    }

    vector<arma::vec> updatedOutput = capsuleNetwork.loadImageAndGetOutput(4);
    cout << "target label: " << MNISTReader::getInstance()->trainingData[4].getLabel() << endl;
    for (int i = 0; i < 10; i++) {
        cout << "length of vector corresponding to " << i << ": " << sqrt(Utils::square_length(updatedOutput[i])) << endl;
    }
}

void test_CUUnifiedBlob_matrixVectorMultiplication() {
    int inputDim = 2, outputDim = 3;
    CUUnifiedBlob v(inputDim), w(inputDim * outputDim), vv(outputDim);
    v.setValueAt_1D(0, 10);
    v.setValueAt_1D(1, 120);

    w.setValueAt_2D(0, 0, inputDim, 1.0);
    w.setValueAt_2D(0, 1, inputDim, 0.0);
    w.setValueAt_2D(1, 0, inputDim, 0.0);
    w.setValueAt_2D(1, 1, inputDim, -1.0);
    w.setValueAt_2D(2, 0, inputDim, 1.0);
    w.setValueAt_2D(2, 1, inputDim, -1.0);

    vv.clear();

    CUUnifiedBlob::matrixVectorMultiplication(w, v, vv, inputDim, outputDim);
    v.print("v");
    w.print("w");
    vv.print("vv");
}

void test_CUUnifiedBlob_CUDA_matrixVectorMultiplication() {
    int inputDim = 8, outputDim = 16, numMultiples=2;
    CUUnifiedBlob v(inputDim * numMultiples),
                  w(inputDim * outputDim * numMultiples),
                 vv(outputDim * numMultiples);

    for (int i = 0; i < inputDim; i++) {
        v.setValueAt_1D(i, i);
        v.setValueAt_1D(i+inputDim, i*10);

        w.setValueAt_2D(i, i, inputDim, 1.0);
        w.setValueAt_2D(i+inputDim, i, inputDim, 1.0);
        w.setValueAt_2D(i+2*inputDim, i, inputDim, 1.0);
        w.setValueAt_2D(i+3*inputDim, i, inputDim, 1.0);
    }
    vv.clear();

    CUUnifiedBlob::CUDA_matrixVectorMultiplication(w, v, vv, inputDim, outputDim, numMultiples);

    v.print("v");
    w.print("w", inputDim);
    vv.print("vv");
}

void test_CUUnifiedBlob_CUDA_softmax() {
    int numClasses = 10, flattenedTensorSize = 45;
    CUUnifiedBlob bMatrix(numClasses * flattenedTensorSize),
                  cMatrix(numClasses * flattenedTensorSize);

    for (int k = 0; k < numClasses; k++) {
        for (int t = 0; t < flattenedTensorSize; t++) {
            bMatrix.setValueAt_2D(t, k, numClasses, t);
        }
    }
    cMatrix.clear();
    bMatrix.print("b:", numClasses);

//    CUUnifiedBlob::vectorVectorSoftmax(bMatrix, cMatrix, numClasses, flattenedTensorSize);
//    cMatrix.print("c sequentially :", numClasses);
//    cMatrix.clear();
    CUUnifiedBlob::CUDA_vectorVectorSoftmax(bMatrix, cMatrix, numClasses, flattenedTensorSize);
    cMatrix.print("c in cuda      :", numClasses);
}

int main() {
//    test_SingleLayerCNN();
//    test_CapsuleNetSquishing();
//    test_VectorMapFromFeatureMaps
//    test_FeatureMapsFromVectorMap();

//    test_CapsuleNetwork_ForwardPropagation();
//    test_CapsuleNetwork_BackPropagation();
//    test_CapsuleNetwork_getMarginLoss();
//    test_CapsuleNetwork_reconstruction();
//    test_CapsuleNetwork_multipleReconstruction();

//    test_CapsuleNetwork_Epoch();
//    test_NetworkTallyingTiming();

//    test_CUUnifiedBlob_matrixVectorMultiplication();
//    test_CUUnifiedBlob_CUDA_matrixVectorMultiplication();
    test_CUUnifiedBlob_CUDA_softmax();

//    ConvolutionalNetwork cnn;
//    cnn.init();
//    cnn.train();

//    MultilayerPerceptron mp(784, 10, {10});
//    mp.init();
//    mp.train();
//    mp.tally(false);

    // TODO have all Networks derive from a master 'Network' class

    return 0;
}