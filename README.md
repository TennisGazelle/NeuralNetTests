# A CUDA implementation of Capsule Networks 
#### By Daniel Lopez
Computer Science Graduate Student at the University of Nevada, Reno.

Three implementations of Neural Nets, built on top of one another for CUDA implementation and further researach/development.
Written in C++/CUDA for full control over data management and moving (not implying TensorFlow or other projects are badly written, or don't allow low-level control of data)

All mentioned neural networks are generalized to a very simple API.
They contain single and multi-threaded implementations for their Forward and Backward Propagation.
Momentum learning is opted for instead of SGD, necessitating a velocity and delta equivalent for all W's found within the classes.

Unit tests pending for integrity, but you can trust me when I say they work. :)
If there are any issues found, please report them to the issues panel of this repository.

 - __Multilayer Perceptron__ - A simple, feed-forward, fully connected neural network.
 Generalized to a very simple initialization API.  Makes use of `PerceptronLayer` which is essentially an array of `Perceptron`'s.
 This uses the perceptron model, as literally as possible.  A possible optimization would be to use the matrix based implementation for weight management.
 - __Convolutional Network__ - A basic CNN with Convolutional and Pooling layers implemented.  
 Only the Convolutional layers, however, have been extensively tested.
 The convolutional layers have built in ReLU activation.
 A design pattern for a more generalizable non-linear activation functions that may be used across neural nets is ready, but not implemented.
 - __Capsule Network__ - Based off the work of [Sabour et al](https://arxiv.org/abs/1710.09829), this is a straightforward implementation using `Armadillo` vectors and matrices for linear algebra.
 Dynamic Routing is implemented in CPU and in CUDA (not yet in CUDA).
 

# Building/Running
The preferred IDE is [CLion](https://www.jetbrains.com/clion/) by [JetBrains](https://www.jetbrains.com/), but choose whatever floats your boat :)

## Dependencies
This project is build with CMake and only uses the armadillo library as dependency.
Instructions for [Armadillo download](http://arma.sourceforge.net) installation may be found on [their website](http://arma.sourceforge.net).
However, the folowing should work fine
```bash
> sudo apt-get install libarmadillo-dev
```

## Building
```bash
> mkdir cmake-build-cubix # spelling of build directory is important
> cd cmake-build-cubix
> cmake .. # or cmake --build . --target NeuralNets -- -j 4
> make
```
## Running
```bash
> cd cmake-build-cubix/
> ./NeuralNets
```
Ignore, the segmentation fault error shown at the end; this is a destructor error and does not affect the speed up performance of the assignment.

## Running on `Cubix`
```bash
> cd slurm
> ./run.py
```

__IMPORTANT PLEASE NOTE:__ 
Given the chosen design pattern (which will be modified in the future), the variable size of the internal number of tensor channels is stored as a `static const int` per every run of the program
The function in `main.cu` named `void test_speedupTimings_seq_par()` runs 30 runs of the intended trials, forward propagation, back propagation and epoch (epoch commented out for time purposes).

To change and run these vary these values for all possible sizes shown in the paper: `A GPU Acceleration Method for Dynamically Routed Capsule Networks`, please perform the following

1. Open `include/Config.h`
2. Change variable `cnNumTensorChannels`, which may be found in line 21.
3. Recompile with `make`
4. Rerun with `./NeuralNets`

Note this change doesn't require a recompile of 

