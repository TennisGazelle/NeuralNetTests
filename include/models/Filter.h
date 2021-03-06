//
// Created by Daniel Lopez on 1/8/18.
//

#ifndef NEURALNETS_FILTER_H
#define NEURALNETS_FILTER_H

#include <vector>

using namespace std;

class Filter : public vector< vector< vector<double> > > {
public:
    void clearInit(size_t depth, size_t height, size_t width);
    void init(size_t depth, size_t height, size_t width);
    void clearOut();
    Filter operator+(const Filter& right);
    void velocityUpdateWithWeights(const Filter& incomingAdjustments);
};


#endif //NEURALNETS_FILTER_H
