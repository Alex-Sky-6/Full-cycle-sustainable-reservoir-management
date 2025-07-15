# Integration of Graph Convolutional Network and Multi-Objective Evolutionary Algorithm for Reservoir Optimal Operation

## Project Overview

This project is an integrated system that combines Graph Convolutional Network (GCN) and Multi-Objective Evolutionary Algorithm (MOEA) for optimal operation of cascade reservoir systems. The system is specifically designed for multi-objective optimal operation of the upper Yangtze River cascade reservoirs (including Wudongde, Baihetan, Xiluodu, Xiangjiaba, Three Gorges, and Gezhouba reservoirs), considering multiple objectives such as power generation benefits, flood control safety, and ecological environment protection.

## System Architecture

### Core Algorithms
- **Integration_of_GCN_and_MOEA_model**: Main algorithm integrating GCN and MOEA
- **ALGORITHM**: Base algorithm class providing general optimization framework
- **PRORES**: Base reservoir problem class defining basic structure of reservoir operation problems
- **reservoir**: Specific implementation of reservoir operation problem

### Optimization Algorithm Components
- **NDSort**: Non-dominated sorting algorithm
- **TournamentSelection**: Tournament selection operator
- **CrowdingDistance**: Crowding distance calculation
- **UniformPoint**: Uniform weight vector generation
- **EnvironmentalSelection**: Environmental selection strategy

## Main Features

### 1. Multi-Objective Optimization
The system optimizes three main objectives:
- **Power Generation Maximization**: Calculate power generation of each reservoir to maximize total power benefits
- **Flood Control Safety Maximization**: Consider water level control during flood season and water level guarantee during water supply period
- **Ecological Environment Protection**: Minimize carbon emissions, protect river ecology, and maintain minimum ecological flow

### 2. Graph Convolutional Network Integration
- Construct correlation graph network between reservoirs
- Establish adjacency matrix using correlation analysis
- Identify key nodes through graph centrality analysis
- Perform intelligent crossover and mutation operations based on graph structure

### 3. Constraint Handling
- Water level upper and lower bound constraints
- Water balance constraints
- Power output constraints
- Flow constraints
- Flood control constraints

## File Structure

```
Core Code/
├── ALGORITHM.m                    # Base algorithm class
├── PRORES.m                      # Base reservoir problem class
├── reservoir.m                   # Reservoir operation problem implementation
├── solver.m                      # Main solver program
├── NDSort.m                      # Non-dominated sorting
├── TournamentSelection.m         # Tournament selection
├── CrowdingDistance.m           # Crowding distance calculation
├── UniformPoint.m               # Uniform weight vector generation
├── Integration_of_GCN_and_MOEA_model/  # GCN-MOEA integration algorithm
│   ├── Integration_of_GCN_and_MOEA_model.m  # Main algorithm
│   ├── CalFitness.m             # Fitness calculation
│   ├── CalHV.m                  # Hypervolume calculation
│   ├── CalHVLoss.m              # Hypervolume loss
│   ├── DensityEstimate.m        # Density estimation
│   ├── EnvironmentalSelection.m  # Environmental selection
│   ├── EnvironmentalSelection1.m # Environmental selection variant
│   ├── LevelSort.m              # Level sorting
│   └── SPDSort.m                # SPD sorting
├── Runoff-Wudongde-Monthly-Standardized.xlsx      # Wudongde monthly runoff data
└── Xiangjiaba-ThreeGorges-Interval-Monthly-Flow-Standardized.xlsx  # Xiangjiaba-Three Gorges interval flow data
```

## Data Description

### Input Data
- **Runoff Data**: Standardized monthly runoff data of Wudongde reservoir
- **Interval Flow**: Standardized monthly flow data of Xiangjiaba-Three Gorges interval
- **Reservoir Parameters**: Physical characteristic parameters of each reservoir (storage capacity, water level limits, etc.)

### Decision Variables
- **Dimension**: 72 dimensions (6 reservoirs × 12 months)
- **Variable Type**: Continuous real variables
- **Constraint Range**: Upper and lower water level limits for each reservoir in each month

## Usage

### Basic Execution
```matlab
% Run solver directly
solver()

% Or run with specified parameters
[Dec,Obj,Con] = solver('algorithm',@Integration_of_GCN_and_MOEA_model,'problem',@reservoir,'M',3,'N',200,'maxFE',10000);
```

### Parameter Settings
- `N`: Population size (default 100)
- `maxFE`: Maximum number of function evaluations (default 50000)
- `M`: Number of objective functions (3)
- `D`: Dimension of decision variables (72)

## Algorithm Features

### 1. Graph Network Modeling
- Construct graph network based on decision variable correlations
- Dynamically adjust adjacency matrix connection strategies
- Identify important nodes using PageRank and betweenness centrality

### 2. Intelligent Evolutionary Operations
- Graph structure-based neighborhood search
- Maximum clique detection for optimized parent selection
- Self-attention mechanism enhanced crossover operations
- Weight optimization to improve search efficiency

### 3. Multi-stage Optimization Strategy
- Early stage uses graph network-guided evolution
- Later stage switches to traditional MOEA strategy
- Adaptive balance between exploration and exploitation

## Technical Requirements

- MATLAB R2018a or higher
- Optimization Toolbox
- Statistics and Machine Learning Toolbox

## Output Results

The system outputs include:
- **Pareto Optimal Solution Set**: Non-dominated reservoir operation schemes
- **Objective Function Values**: Values of three objectives - power generation benefits, flood control safety, and ecological environment
- **Decision Variables**: Optimal water levels for each reservoir in each month
- **Constraint Violation**: Satisfaction degree of various constraints

## Application Scenarios

This system is suitable for:
- Optimal operation of large cascade reservoir systems
- Multi-objective water resource management
- Hydropower system operation optimization
- Watershed comprehensive management decision support

## Notes

1. Ensure data file paths are correct
2. Adjust reservoir parameters according to actual conditions
3. Set algorithm parameters reasonably to balance computational efficiency and solution quality
4. Results need to be verified in combination with actual engineering constraints

## Copyright

This project is for academic research purposes. Please cite the source when using.