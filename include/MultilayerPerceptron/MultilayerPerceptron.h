//
// Created by Daniel Lopez on 12/28/17.
//

#ifndef NEURALNETS_MULTILAYERPERCEPTRON_H
#define NEURALNETS_MULTILAYERPERCEPTRON_H


#include "PerceptronLayer.h"
#include "MNISTReader.h"

class MultilayerPerceptron {
public:
    MultilayerPerceptron(size_t inputLayerSize, size_t outputLayerSize, vector<size_t> hiddenLayerSizes);
    void init(const string& possibleInputFilename = "");
    void run();
    vector<double> loadImageAndGetOutput(int imageIndex, bool useTraining = true);
    vector<double> loadInputAndGetOutput(const vector<double>& input);
    void train();

    // TODO: break this function down to get the error inputs from the input fields...
    void runEpoch();
    double tallyAndReportAccuracy(bool useTraining = true);

    void writeToFile();
    void writeToFile(ofstream &fout);
    bool readFromFile(const string& filename);
    void getLayerFromFile(ifstream& fin);

private:
    vector<PerceptronLayer> layers;
    unsigned int numTrainingEpochs = 200;

    vector<size_t> layerSizes;
};


#endif //NEURALNETS_MULTILAYERPERCEPTRON_H
