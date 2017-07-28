# Implementing the k-medoids Algorithm in Haskell

## Purpose

This document is a guide to implementing the k-medoids clustering algorithm using Haskell. It describes the components of the algorithm and (coming soon!) also provides examples of those components. The goals of this document are to 1) assist readers to build a small program in Haskell and 2) expose readers to design considerations in functional programming.

## Contents

* [How to Use this Material](#how-to-use-this-material)
* [Clustering and k-medoids](#clustering-and-k-medoids)
* [Preliminaries](#preliminaries)
* [Implementing k-medoids](#implementing-k-medoids)
    - [Representing Clusters](#representing-clusters)
    - [Assigning Elements](#assigning-elements)
    - [Optimising Clusters](#optimising-clusters)
    - [Performing Clustering](#performing-clustering)
    - [Completing the Algorithm](#completing-the-algorithm)
* [Extending the Implementation](#extending-the-implementation)

## How to Use this Material

This material consists of two parts: descriptions of the functions that comprise a Haskell implementation of the k-medoids clustering algorithm, and (coming soon!) example implementations of those functions. Each section in the first part of the document provides a brief overview of the concepts that will be covered in that section, then describes the functionality required to implement those concepts. The functions are presented in approximate order of their complexity, therefore it is suggested that you work through them in the presented order. In each case, first write down the type of the function, then address the base cases (where certain input values directly correspond to certain output values), then complete the implementation. Ensure your function has a defined result for all expected input values, and look for opportunities to simplify your function using existing functions and reductions.

This material assumes little knowledge of Haskell, but you will have less trouble if you are familiar with the language's syntax and the creation of simple functions. If you are an absolute beginner then consider reading the first three lectures and attempting the first three labs of the [CIS194 (Spring 2013) Haskell course](http://www.seas.upenn.edu/%7Ecis194/spring13/). [This guide](https://github.com/futufeld/brainfunc) to implementing a Brainfuck interpreter in Haskell may also be useful preparation.

## Clustering and k-medoids

Clustering is the act of arranging the elements of a dataset into groups based on their similarity. The resultant clusters can indicate prominent characteristics of the dataset, and the relative size of clusters can indicate the relative prominence of the characteristics to which they correspond. Automated clustering techniques make it viable to perform clustering on large datasets, and thereby gain insights into the data that might otherwise not be possible. The effectiveness of these techniques depends on the ability to quantify the similarity of elements in the dataset. Elements of the dataset are typically converted into real vectors, which enables the use of common metrics, such as the the L2 norm, or Euclidean norm, to measure the distance between them. However, it is not always possible or desirable to transform the elements of the dataset into vectors. The k-medoids algorithm belongs to a class of clustering algorithms that do not require a specific representation of the elements that they cluster, fulfilling this specific need.

The k-medoids algorithm depends on a distance metric that is able to compute, in some way, the dissimilarity of any two elements in the dataset. It uses this metric to both determine to which cluster an element should be assigned and how the elements should be organised within a cluster. The _k_ in _k-medoids_ refers to the number of clusters the algorithm configures the dataset into, and the _medoids_ in _k-medoids_ refers to the elements that are selected to 'represent' each cluster. The algorithm operates as follows:

1. Select _k_ elements of the dataset and make each the medoid of an empty cluster.
2. Assign each of the unassigned elements to the cluster that contains the medoid to which they are most similar, as determined by the distance metric.
3. Replace the medoid in each cluster with the element of the cluster that is most similar, according to the distance metric, to its cluster neighbours.
4. Until the configuration stabilises and no further improvement can be made: remove all (non-medoid) elements from all clusters and return to Step 2.

Despite its simplicity, this algorithm has some useful statistical properties and can provide substantial insight into datasets if paired with an appropriate distance metric.

## Preliminaries

### Useful Types for Implementing the k-medoids Algorithm

This section provides a brief overview of the `List` and `Tuple` types, which are both useful for implementing the algorithm, and describes functions useful for manipulating `List`s. Each function has a purpose in the implementation of the k-medoid algorithm, if you choose to use it. This section ends with a 'warm-up' exercise that asks you to implement three functions that can also be useful in implementing k-medoids.

###  `List`

The `List` type has the following structure:

```
data [a] = [] | a : [a]
```

Thus a `List` value is either `[]`, meaning that it is empty, or it has a 'head' element `a` followed by a 'tail' `[a]`, which is another list. In the latter case, we say `a` is 'cons'ed onto `[a]` by the 'cons' operator `:`. The type variable `a` indicates that a list can be created for any type, with the constraint that the list only contains values of that type. The following are all `List` values:

```
2:1:[]         :: [Integer] -- 2:1:[] can be expressed as [1,2]
'c':'a':'t':[] :: [Char]    -- 'c':'a':'t':[] can be expressed as "cat"
[]             :: [a]       -- The type of a is determined from the
                            -- context in which the value is used
```

We can exploit the structure of `List` to traverse a sequence of values. For example:

```
length :: [a] -> Integer
length []     = 0               -- Case: []
length (x:xs) = 1 + (length xs) -- Case: a : [a]
```

### `Tuple`

The type `Tuple` has the following structure:

```
data (,) a b = (,) a b
```

`Tuple` is used to pair values together, which is useful for both indicating that two values are related to each other and for returning more than one value from a function. The type variables `a` and `b` in the definition of `Tuple` indicate that the two values in a `Tuple` can be of different types. The following are all `Tuple` values:

```
(1, 2)            :: (Integer, Integer)
("cat", 5)        :: ([Char], Integer)
(Just 5, [1,2,3]) :: (Maybe Integer, [Integer])
```

We can exploit the structure of `Tuple` to obtain the first and second values. For example:

```
fst :: (a, b) -> a
fst (x, _) = x

snd :: (a, b) -> b
snd (_, y) = y
```

### Useful List Functions

#### `head :: [a] -> a`

The `head` function returns the first element of the `List` value it receives. If `tail` is given an empty `List`, it throws an error. Examples:

```
head [1,2,3] = 1
head "cat"   = 'c'
head []      = error "Prelude.head: empty list"
```

#### `tail :: [a] -> [a]`

The `tail` function returns a `List` that contains every element, in the same sequence, of the `List` it receives but with the first element omitted. If `tail` is given an empty `List`, it throws an error. Examples:

```
tail [1,2,3] = [2,3]
tail "cat"   = "at"
tail []      = error "Prelude.tail: empty list"
```

#### `cycle :: [a] -> [a]`

The `cycle` function returns an infinite `List` that repeats elements in the `List` it receives. If `cycle` is given an empty `List`, it throws an error. Examples:

```
cycle [1,2,3] = [1,2,3,1,2,3,1,2,3,1,2,...
cycle "cat"   = "catcatcatca...
cycle []      = error "Prelude.cycle: empty list"
```

#### `map :: (a -> b) -> [a] -> [b]`

The `map` function returns the result of applying the given function to every element in the given `List`. Examples:

```
map (+1) [1,2,3]  = [2,3,4]
map (=='c') "cat" = [True,False,False]
map odd []        = []
```

#### `concat :: [[a]] -> [a]`

The `concat` function returns a single `List` that consists of all the elements in the `List` of `List`s it receives. Examples:

```
concat [[1,2,3],[4,5,6]] = [1,2,3,4,5,6]
concat ["cat", "dog"]    = "catdog"
concat []                = []
```

#### `unzip :: [(a, b)] -> ([a], [b])`

The `unzip` function expects a `List` of `Tuple`s and returns two `List`s, one that contains the first element of each `Tuple` and one that contains the second element of each `Tuple`. Examples:

```
unzip [(1,4),(2,5),(3,6)]             = ([1,2,3], [4,5,6])
unzip [('c','d'),('a','o'),('t','g')] = ("cat", "dog")
unzip []                              = []
```

#### `take :: Int -> [a] -> [a]`

The `take` function expects an integer _n_ and a `List` and returns the first _n_ elements of that `List`. Examples:

```
take 3 [2,4,6,8,10] = [2,4,6]
take 5 [1,2,3]      = [1,2,3]
```

#### `splitAt :: Int -> [a] -> ([a], [a])`

The `splitAt` function splits the given `List` at the _n_th element, where _n_ is the given `Int`, and returns a `Tuple` consisting of the two resultant `List`s. Regarding the result, the _n_th element is in the first `List`. Examples:

```
splitAt 1 [1,2,3] = ([1], [2,3])
splitAt 2 "cat"   = ("ca", "t")
splitAt 2 []      = ([], [])
```

### `error`

Haskell contains an `error` function that enables the execution of a program to be aborted and a textual message to be printed for the user. `error` is intended to be used in only two circumstances: 1) when truly exceptional cases occur from which it is impossible to recover and 2) when the program enters an invalid state due to programmer error. In the latter case, `error` can inform the developer that a logical error has occurred in the construction of the program. The usage of `error` is `error "<My string>"`, where `"<My string>"` is the message to be printed to the terminal before the program halts.

### Warm-up

#### `sumDoubles`

Implement the `sumDoubles` function which takes a `List` of `Double`s and returns their sum. Examples:

```
sumDoubles [1.4, 2.5, 4.6] = 8.5
sumDoubles []              = 0.0
```

#### `cycles`

Implement the `cycles` function which returns all permutations of a `List` that can be generated by cyclically rotating that `List`. Examples:

```
cycles [1,2,3] = [[1,2,3], [2,3,1], [3,2,1]]
cycles "cat"   = ["cat", "atc", "tca"]
cycles []      = error "'cycles': list cannot be empty"
```

#### `minBy`

Implement the `minBy` function which takes a function _f_ and a `List` and returns the smallest element of that `List`. The 'size' of the elements is determined by the _f_ function which represents this as a `Double`. Examples:

```
minBy genericLength ["cube", "house", "cat"] = "cat"
minBy (\x -> (x - 25)^2) [25, 16, 36]        = 25
minBy (-10) []                               = error "'minBy': list must not be empty"
```

## Implementing k-medoids

### Representing Clusters

#### Defining Clusters

Clusters are a collection of elements, one of which is the cluster's medoid. The medoid's role as 'representative' of the cluster, and thus the element that other elements are frequently compared to, means that direct access to the medoid is often required. We can reflect this in how we represent clusters using the `Cluster` type, as follows:

```
data Cluster a = Cluster a [a]
```

The type variable `a` in the above definition enables us to represent clusters of values of any type, as is characteristic of the k-medoids algorithm. The data constructor `Cluster a [a]` enables us to treat the medoid - the independent `a` - as a 'special' example of the cluster's elements. The non-medoid elements of the cluster reside in the `List`.

For the k-medoids algorithm to function, the ability to measure the distance between values of type `a` is required. We can represent the distance metrics that perform this task as follows:

```
type Metric a = a -> a -> Double
```

That is, a value of type `Metric` is any function that takes two values of the same type and produces a result of type `Double`. We will soon see that the type of `a` in `Metric a` must correspond to the type of `a` in `Cluster a` when `Metric`s and `Cluster`s are used in conjunction. The output of `Metric` functions is intended to quantify the dissimilarity of the `a` values to which the `Metric` is applied. This enables us to determine the similarity of elements to different `Cluster`s and the similarity of medoids to the elements within their `Cluster`.

#### Required Functions

With the types outlined in this section, it is possible to create the basic functionality of clusters:

* `newCluster`: Creates an empty cluster that contains a specific medoid.
* `addElement`: Adds a (non-medoid) element to an existing cluster.
* `clusterDistance`: Measures the distance between an element and a cluster.
* `clusterCost`: Measures how representative a cluster's medoid is of the elements in that cluster. Lower is better.

#### `newCluster`

Implement the `newCluster` function which takes a value of any type and returns a `Cluster` in which that value is the medoid. Examples:

```
newCluster 1     = Cluster 1 []
newCluster "cat" = Cluster "cat" []
newCluster [3.5] = Cluster [3.5] []
```

#### `addElement`

Implement the `addElement` function which takes a `Cluster` and a value and adds that value to the `Cluster`'s elements. Examples:

```
addElement (Cluster "cat" []) "dog" = Cluster "cat" ["dog"]
addElement (Cluster 1 [2,3])  4     = Cluster 1 [2,3,4]
```

#### `clusterDistance`

Implement the `clusterDistance` function which takes a `Metric`, a value and a `Cluster` and returns the distance of the value from the `Cluster` according to the `Metric`. Examples:

```
f x y = genericLength x - genericLength y
clusterDistance f "cube" (Cluster "cat" ["house"]) = 1.0

clusterDistance (\x y -> (x - y)^2) 10 (Cluster 5 [1,3,7,9]) = 25.0
```

#### `clusterCost`

Implement the `clusterCost` function which takes a `Metric` and a `Cluster` and returns the sum of the distances, according to the `Metric`, between the medoid and each element of the `Cluster`. Example:

```
clusterCost (\x y -> (x - y)^2) (Cluster 3 [1,5,7,9]) = 60.0
```

### Assigning Elements

#### Selecting Appropriate Clusters

With the definition of `Cluster` and basic functionality for interacting with values of this type, it is now possible to create functionality for the assignment of elements to `Cluster`s that are within a cluster configuration. The cluster configuration, unlike clusters, has no remarkable values and can be defined as an alias of `List`:

```
type Configuration a = [Cluster a]
```

where `a` indicates not only that we can have a `Configuration` of any type, but also that the `Configuration` consists of `Cluster`s of that same type. With the `Configuration` type, we can begin implementing the primary actions of the k-medoids algorithm.

#### Required Functions

Recall that, after clusters are created, the next step in the k-medoids algorithm is to assign elements to clusters within the configuration. We can achieve this with the following functions:

* `nearestCluster`: Finds the most similar cluster to an element.
* `assignElement`: Adds an element to the most similar cluster.
* `assignElements`: Adds many elements to their most similar clusters.

#### `nearestCluster`

Implement the `nearestCluster` function which takes a `Metric`, a `Configuration` and a value and returns a `Configuration` in which the first element is the nearest, according to the `Metric`, `Cluster` to the value. Example:

```
cfg = [Cluster 26 [23,27], Cluster 41 [48,52], Cluster 88 [67,91]]
nearestCluster (\x y -> (x - y)^2) cfg 77 = [
    Cluster 88 [67,91], Cluster 26 [23,27], Cluster 41 [48,52]
]
```

#### `assignElement`

Implement the `assignElement` function which takes a `Metric`, a value and a `Configuration` and returns a `Configuration` in which the value has been added to the nearest `Cluster` (according to the `Metric`). Example:

```
cfg = [Cluster 26 [23,27], Cluster 41 [48,52], Cluster 88 [67,91]]
assignElement (\x y -> (x - y)^2) 43 cfg = [
    Cluster 41 [48,52,43], Cluster 88 [67,91], Cluster 26 [23,27]
]
```

#### `assignElements`

Implement the `assignElements` function which takes a `Metric`, a `List` and a `Configuration` and returns that `Configuration` with the elements of the `List` added. Each `List` element should be in its nearest `Cluster`, according to the `Metric`, in the returned `Configuration`. Example:

```
cfg = [Cluster 26 [23,27], Cluster 41 [48,52], Cluster 88 [67,91]]
assignElements (\x y -> (x - y)^2) [43,13,64,29,101] cfg = [
    Cluster 88 [67,91,101], Cluster 26 [23,27,13,29], Cluster 41 [48,52,43,64]
]
```

### Optimising Clusters

#### Selecting Appropriate Medoids

The k-medoids algorithm must ensure that the medoid of each cluster is the most 'representative' element of that cluster so that: 1) the user can gain some insight into the 'topic' of the cluster (the medoid is an implicit descriptor of the cluster), and 2) so that the cluster is assigned elements most similar to its current collection of elements in the next round of assignments (if the configuration does not stabilise first). This involves checking every element of the cluster to see if it is more similar to its cluster neighbours than the current medoid and, if so, swapping that element and the medoid. The sum distance of a medoid from its cluster's elements is referred to as the _cost_ of the cluster; the objective of this step of the algorithm is cluster cost minimisation.

#### Required Functions

Keeping the medoid up-to-date with respect to the other elements in a cluster can be achieved by searching for the minimum cost cluster permutation, which can be performed using the following functions:

* `clusterPermutations`: Generates alternative versions of the cluster in which the medoid is other cluster elements.
* `updateCluster`: Converts a cluster into its ideal state by reassigning the medoid to the most representative element of the cluster.
* `updateConfiguration`: Converts all clusters in the configuration into their ideal states.

#### `clusterPermutations`

Implement the `clusterPermutations` function which returns all of the permutations of a `Cluster` generated by swapping its medoid and elements. Example:

```
clusterPermutations (Cluster 1 [2,3,4]) = [
    Cluster 1 [2,3,4], Cluster 2 [3,4,1], Cluster 3 [4,1,2], Cluster 4 [1,2,3]
]
```

#### `updateCluster`

Implement the `updateCluster` function which takes a `Metric` and a `Cluster` and returns the permutation of the `Cluster` that has the lowest cost. Example:

```
updateCluster (\x y -> (x - y)^2) (Cluster 9 [2,1,3,7]) = Cluster 3 [2,1,7,9]
```

#### `updateConfiguration`

Implement the `updateConfiguration` function which takes a `Metric` and a `Configuration` and returns a version of the `Configuration` in which every `Cluster` is optimised (i.e. the sum of distances, according to the `Metric`, between the medoid and cluster elements is the smallest of all possible `Cluster` permutations). Example:

```
cfg = [Cluster 26 [23,27], Cluster 41 [48,52], Cluster 88 [67,91]]
updateConfiguration (\x y -> (x - y)^2) cfg = [
    Cluster 26 [23,27], Cluster 48 [41,52], Cluster 88 [67,91]
]
```

### Performing Clustering

#### Iterating on a Solution

With the two main steps of the k-medoids algorithm complete, it is now possible to perform an iteration, or re-iteration, of the algorithm. To iterate a configuration, all non-medoid elements are removed from all clusters so that reclustering can be performed. After the elements are reassigned to the clusters, the clusters are re-optimised to ensure the medoids represent the possibly-changed set of elements in each cluster. If the selection of medoids in the previous iteration was effective, the reassignment of the removed elements should improve the quality of the configuration - this is the key assumption of the k-medoids algorithm and its effectiveness rests on the strength of this assumption with respect to the dataset being clustered.

#### Required Functions

In conjunction with the functionality developed thus far, an iteration of the k-medoids algorithm can be performed with the following functions:

* `decluster`: Removes the elements from a cluster (excluding the medoid) so that they can be reassigned to the same or another cluster.
* `deconfigure`: Removes the elements from all clusters so that they can be reassigned to the same or other clusters.
* `kmedoidsIteration`: Executes one iteration of the k-medoids algorithm, ideally refining a cluster configuration to produce a more suitable grouping of elements.

#### `decluster`

Implement the `decluster` function which takes a `Cluster` and returns a `Tuple` in which the first value is the `Cluster` with the medoids removed and the second value is a `List` of the `Cluster`'s elements. Examples:

```
decluster (Cluster 1 [2,3,4])     = (Cluster 1 [], [2,3,4])
decluster (Cluster "cat" ["dog"]) = (Cluster "cat" [], ["dog"])
```

#### `deconfigure`

Implement the `deconfigure` function which takes a `Configuration` and returns a `List` of its `Cluster`s declustered. Example:

```
deconfigure [Cluster 1 [2,3,4], Cluster 6 [7,8,9]] = [
    (Cluster 1 [], [2,3,4]), (Cluster 6 [], [7,8,9])
]
```

#### `kmedoidsIteration`

Implement the 'kmedoidsIteration' function which takes a `Metric` and a `Configuration` and returns the result of applying one iteration of the k-medoids algorithm to that `Configuration`. Example:

```
cfg = [Cluster 1 [2,3,4], Cluster 6 [7,8,9]]
kmedoidsIteration (\x y -> (x - y)^2) cfg = [
    Cluster 2 [1,3,4], Cluster 7 [6,8,9]
]
```

### Completing the Algorithm

#### Exploring the Solution Space

The implementation of k-medoids is almost complete! All that remains is to create the functionality that guides and terminates the search for higher quality configurations, and to create a function that prevents the user from having to interact with the components of the algorithm's implementation. To guide the search, it is necessary to be able to compare the quality of configurations. In the k-medoids algorithm, a configuration's quality is quantified as the sum of all costs of its clusters, which is referred to as the configuration's _cost_. Once it is possible measure configuration cost, a simple search in which an initial configuration is iterated until its cost fails to improve can be implemented. This is referred to as a _greedy_ search strategy because it assumes that always accepting the optimal local, or 'immediate', solution will ultimately lead to the optimal overall solution, which is rarely the case. Even so, the design of the k-medoids algorithm will partially compensate and should be able to cluster most datasets with some success.

#### Required Functions

To guide the discovery of increasingly high quality cluster configurations, we will need the following functions:

* `configurationCost`: Measures the suitability of how elements are arranged in the clusters of a configuration. Lower is better.
* `localSearch`: Keeps applying iterations of the k-medoids algorithm until no further improvement is made.
* `kmedoids`: Applies the k-medoids algorithm to a collection of elements, returning _k_ clusters of elements.

#### `configurationCost`

Implemement the `configurationCost` function which takes a `Metric` and a `Configuration` and returns the sum of all distances, according to the `Metric`, between the medoids and elements within each of the `Configuration`'s `Cluster`s. Example:

```
cfg = [Cluster 2 [1,3,4], Cluster 7 [6,8,9]]
configurationCost (\x y -> (x - y)^2) cfg = 12.0
```

#### `localSearch`

Implement the `localSearch` function which takes a `Metric` and a `Configuration` and applies iterations of the k-medoids algorithm to the `Configuration` until the cost of the resultant `Configuration` fails to improve. Example:

```
cfg = [Cluster 1 [2,3,4], Cluster 8 [7,9,5]]
kmedoidsIteration (\x y -> (x - y)^2) cfg = [
    Cluster 3 [1,2,3,4,5], Cluster 8 [7,9]
]
```

#### `kmedoids`

Implement the `kmedoids` function which takes an `Int` _k_, a `Metric` and a `List` of elements to cluster and returns the lowest cost, according to the `Metric`, `Configuration` of those elements that it could find. The initial `Configuration` is created by creating _k_ `Cluster`s in which the first _k_ elements of the `List` are medoids. Example:

```
kmedoids 3 (\x y -> (x - y)^2) [1,4,7,2,5,8,3,6,9] = [
    Cluster 2 [1,3], Cluster 5 [4,6], Cluster 8 [7,9]
]
```

## Extending the Implementation

* It is possible for a configuration to slightly increase in cost before reaching lower cost states, but this potential cannot be realised by the current, greedy implementation of the `localSearch` function. Generally, the k-medoids algorithm is terminated after it fails to improve a configuration after a number of iterations. Implement an alternative search function that implements this strategy.
* The quality of the configuration produced by the k-medoids algorithm is sensitive to the initial collection of medoids due to the extent that medoids influence element assignment. By selecting the _k_ first elements as medoids, the `kmedoids` function may contribute to poor solutions for particular datasets. Implement one or more functions that generate the initial set of medoids using alternative strategies and modify `kmedoids` to enable the user to provide their medoid-selection function of choice.
* The `localSearch` function, as it is described in this document, hides information by discarding the `Configuration`s it generates in each iteration of search. These 'in-progress' `Configuration`s can provide valuable metadata regarding how the search of the solution space transpired, which can be valuable to individuals using the algorithm. Extended `localSearch` and `kmedoids` so that they return all `Configurations` generated in the process of producing the final result.
