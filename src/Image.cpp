//
// Created by Daniel Lopez on 12/29/17.
//

#include <iostream>
#include <cassert>
#include "Image.h"

Image::Image() {
    reserve(28*28);
}

void Image::addRow(const vector<unsigned char> &row) {
    insert(end(), row.begin(), row.end());
}

void Image::print() const {
    int index = 0;
    cout << "A [" << int(label) << "]" << endl;
    for (unsigned int i = 0; i < size(); i++) {
//        if (!(i % 28)) {
//            cout << index++ << ": ";
//        }
        cout << (int) at(i) << '\t';
        if (!((i+1) % 28)) {
            cout << endl;
        }
    }
}

vector<double> Image::toVectorOfDoubles() const {
    vector<double> result(size());
    for (unsigned int i = 0; i < size(); i++) {
        result[i] = double(at(i));
    }
    assert (result.size() == size());
    return result;
}

size_t Image::getLabel() const {
    return size_t (label);
}

void Image::setLabel(unsigned char l) {
    label = l;
}