# Implementing the k-medoids Algorithm in Haskell

## Purpose

This document is a guide to implementing the k-medoids clustering algorithm using Haskell. It describes the components of the algorithm and also provides examples of those components. The goals of this document are to 1) assist readers to build a small program in Haskell and 2) expose readers to design considerations in functional programming.

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
* [Worked Examples](#worked-examples)
    - [Utility Functions](#utility-functions)
    - [Cluster Functions](#cluster-functions)
    - [Assignment Functions](#assignment-functions)
    - [Optimisation Functions](#optimisation-functions)
    - [Clustering Functions](#clustering-functions)
    - [Completion Functions](#completion-functions)

## How to Use this Material

This material consists of two parts: descriptions of the functions that comprise a Haskell implementation of the k-medoids clustering algorithm, and example implementations of those functions. Each section in the first part of the document provides a brief overview of the concepts that will be covered in that section, then describes the functionality required to implement those concepts. The functions are presented in approximate order of their complexity, therefore it is suggested that you work through them in the presented order. In each case, first write down the type of the function, then address the base cases (where certain input values directly correspond to certain output values), then complete the implementation. Ensure your function has a defined result for all expected input values, and look for opportunities to simplify your function using reductions and existing functions.

This material assumes little knowledge of Haskell, but you will have less trouble if you are familiar with the language's syntax and the creation of simple functions. If you are an absolute beginner then consider reading the first three lectures and attempting the first three labs of the [CIS194 (Spring 2013) Haskell course](http://www.seas.upenn.edu/%7Ecis194/spring13/). [This guide](https://github.com/futufeld/brainfunc) to implementing a Brainfuck interpreter in Haskell may also be useful preparation.

## Clustering and k-medoids

Clustering is the act of arranging the elements of a dataset into groups based on their similarity. The resultant clusters can indicate prominent characteristics of the dataset, and the relative size of clusters can indicate the relative prominence of those characteristics. Automated clustering techniques make it viable to perform clustering on large datasets, and thereby gain insights into the data that might otherwise not be possible. The effectiveness of these techniques depends on the ability to quantify the similarity of elements in the dataset. Elements of the dataset are typically converted into real vectors which enables the use of common metrics, such as the L2 norm, or Euclidean norm, to measure the distance between them. However, it is not always possible or desirable to transform the elements of the dataset into vectors. The k-medoids algorithm belongs to a class of clustering algorithms that do not require a specific representation of the elements that they cluster, fulfilling this specific need.

The k-medoids algorithm depends on a distance metric that is able to compute, in some way, the dissimilarity of any two elements in the dataset. It uses this metric to both determine to which cluster an element should be assigned and how the elements should be organised within a cluster. The _k_ in _k-medoids_ refers to the number of clusters the algorithm configures the dataset into, and the _medoids_ in _k-medoids_ refers to the elements that are selected to 'represent' each cluster. One interpretation of the algorithm is as follows:

1. Select _k_ elements of the dataset and make each the medoid of an empty cluster.
2. Assign each of the unassigned elements to the cluster that contains the medoid to which they are most similar, as determined by the distance metric.
3. Replace the medoid in each cluster with the element of the cluster that is most similar, according to the distance metric, to its cluster neighbours.
4. Remove all (non-medoid) elements from all clusters and return to Step 2 until the configuration stabilises and no further improvement can be made.

Despite its simplicity, this algorithm has some useful statistical properties and can provide substantial insight into datasets if paired with an appropriate distance metric.

## Preliminaries

### Useful Types for Implementing the k-medoids Algorithm

This section provides a brief overview of the `List` and `Tuple` types, which are both useful for implementing the algorithm, and describes functions useful for manipulating values of type `List`. Each function has a purpose in the implementation of the k-medoid algorithm, if you choose to use it. This section ends with a 'warm-up' exercise that asks you to implement three functions that can also be useful in implementing k-medoids.

###  `List`

The `List` type has the following structure:

```
data [a] = [] | a : [a]
```

Thus a list value is either `[]`, meaning that it is empty, or it has a 'head' element `a` followed by a 'tail' `[a]`, which is another list. In the latter case, we say `a` is 'cons'ed onto `[a]` by the 'cons' operator `:`. The type variable `a` indicates that a list can be created for any type, with the constraint that the list only contains values of that type. The following are all list values:

```
2:1:[]         :: [Integer] -- 2:1:[] can be expressed as [2,1]
'c':'a':'t':[] :: [Char]    -- 'c':'a':'t':[] can be expressed as "cat"
[]             :: [a]       -- The type of a is determined from the
                            -- context in which the value is used
```

We can exploit the structure of list to traverse a sequence of values. For example:

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

The `head` function returns the first element of the list value it receives. If `head` is given an empty list, it throws an error. Examples:

```
head [1,2,3] = 1
head "cat"   = 'c'
head []      = error "Prelude.head: empty list"
```

#### `tail :: [a] -> [a]`

The `tail` function returns a list that contains every element, in the same sequence, of the list it receives but with the first element omitted. If `tail` is given an empty list, it throws an error. Examples:

```
tail [1,2,3] = [2,3]
tail "cat"   = "at"
tail []      = error "Prelude.tail: empty list"
```

#### `cycle :: [a] -> [a]`

The `cycle` function returns an infinite list that repeats elements in the list it receives. If `cycle` is given an empty list, it throws an error. Examples:

```
cycle [1,2,3] = [1,2,3,1,2,3,1,2,3,1,2,...
cycle "cat"   = "catcatcatca...
cycle []      = error "Prelude.cycle: empty list"
```

#### `iterate :: (a -> a) -> a -> [a]`

The `iterate` function generates an infinite list by repeatedly applying the `(a -> a)` function to the last generated element, starting with the non-function argument it receives. Example:

```
iterate (+3) 1 = [1, 4, 7, 11, ...
```

#### `map :: (a -> b) -> [a] -> [b]`

The `map` function returns the result of applying the given function to every element in the given list. Examples:

```
map (+1) [1,2,3]  = [2,3,4]
map (=='c') "cat" = [True,False,False]
map odd []        = []
```

#### `concat :: [[a]] -> [a]`

The `concat` function returns a single list that consists of all the elements in the list of lists it receives. Examples:

```
concat [[1,2,3],[4,5,6]] = [1,2,3,4,5,6]
concat ["cat", "dog"]    = "catdog"
concat []                = []
```

#### `unzip :: [(a, b)] -> ([a], [b])`

The `unzip` function expects a list of `Tuple`s and returns two lists, one that contains the first element of each `Tuple` and one that contains the second element of each `Tuple`. Examples:

```
unzip [(1,4),(2,5),(3,6)]             = ([1,2,3], [4,5,6])
unzip [('c','d'),('a','o'),('t','g')] = ("cat", "dog")
unzip []                              = []
```

#### `take :: Int -> [a] -> [a]`

The `take` function expects an integer _n_ and a list and returns the first _n_ elements of that list. Examples:

```
take 3 [2,4,6,8,10] = [2,4,6]
take 5 [1,2,3]      = [1,2,3]
take 0 "cat"        = ""
```

#### `splitAt :: Int -> [a] -> ([a], [a])`

The `splitAt` function splits the given list at the _n_th element, where _n_ is the given `Int`, and returns a `Tuple` consisting of the two resultant lists. Regarding the result, the _n_th element is in the first list. Examples:

```
splitAt 1 [1,2,3] = ([1], [2,3])
splitAt 2 "cat"   = ("ca", "t")
splitAt 2 []      = ([], [])
```

### `error`

Haskell contains an `error` function that enables the execution of a program to be aborted and a textual message to be printed for the user. `error` is intended to be used in only two circumstances: 1) when truly exceptional cases occur from which it is impossible to recover and 2) when the program enters an invalid state due to programmer error. In the latter case, `error` can inform the developer that a logical error has occurred in the construction of the program. The usage of `error` is `error "<My string>"`, where `"<My string>"` is the message to be printed to the terminal before the program halts.

### Warm-up

#### `lengthDouble`

Implement the `lengthDouble` function which takes a list and returns its length as a value of type `Double`. Examples:

```
lengthDouble [6,4,3,9] = 4.0
lengthDouble "cat"     = 3.0
```

#### `sumDoubles`

Implement the `sumDoubles` function which takes a list of `Double`s and returns their sum. Examples:

```
sumDoubles [1.4, 2.5, 4.6] = 8.5
sumDoubles []              = 0.0
```

#### `minBy`

Implement the `minBy` function which takes a function _f_ and a list and returns the smallest element of that list. The _f_ function maps elements of the list to `Double` values that represent the elements' 'size', by which they are sorted (smaller values first). Examples:

```
minBy lengthDouble ["cube", "house", "cat"] = "cat"
minBy (\x -> (x - 25)^2) [25, 16, 36]       = 25
minBy (-10) []                              = error "'minBy': list must not be empty"
```

#### `rotations`

Implement the `rotations` function which returns all permutations of a list that can be generated by cyclically rotating that list. Examples:

```
rotations [1,2,3] = [[1,2,3], [2,3,1], [3,2,1]]
rotations "cat"   = ["cat", "atc", "tca"]
rotations []      = error "'rotations': list cannot be empty"
```

Hint: consider making use of the `cycle` function.

## Implementing k-medoids

### Representing Clusters

#### Defining Clusters

Clusters are a collection of elements, one of which is the cluster's medoid. The medoid's role as 'representative' of the cluster, and thus the element that other elements are frequently compared to, means that direct access to the medoid is often required. We can reflect this in how we represent clusters using the `Cluster` type, as follows:

```
data Cluster a = Cluster a [a]
```

The type variable `a` in the above definition enables us to represent clusters of values of any type, as is characteristic of the k-medoids algorithm. The data constructor `Cluster a [a]` enables us to treat the medoid - the independent `a` - as a 'special' example of the cluster's elements. The non-medoid elements of the cluster reside in the list.

For the k-medoids algorithm to function, the ability to measure the distance between values of type `a` is required. We can represent the distance metrics that perform this task as follows:

```
type Metric a = a -> a -> Double
```

That is, a value of type `Metric` is any function that takes two values of the same type and produces a result of type `Double`. We will soon see that the type of `a` in `Metric a` must correspond to the type of `a` in `Cluster a` when `Metric`s and `Cluster`s are used in conjunction. The output of a `Metric` function is intended to quantify the dissimilarity of the `a` values to which the metric is applied. The term _distance_ refers to the extent of dissimilarity between two elements, therefore values of type `Metric` represent distance functions. The sum distance of a medoid from its cluster's elements is referred to as the _cost_ of the cluster. Using the concepts of _distance_ and _cost_, we can determine the similarity of elements to different clusters, as well as the similarity of medoids to the elements within their cluster.

#### Required Functions

With the types outlined in this section, it is possible to create the basic functionality of clusters:

* `newCluster`: Creates an empty cluster that contains a specific medoid.
* `addElement`: Adds a (non-medoid) element to an existing cluster.
* `clusterDistance`: Measures the distance between an element and a cluster.
* `clusterCost`: Measures how representative a cluster's medoid is of the elements in that cluster (lower is better).

#### `newCluster`

Implement the `newCluster` function which takes a value of any type and returns a `Cluster` in which that value is the medoid. Examples:

```
newCluster 1     = Cluster 1 []
newCluster "cat" = Cluster "cat" []
newCluster [3.5] = Cluster [3.5] []
```

#### `addElement`

Implement the `addElement` function which takes a value of any type and a `Cluster` and adds the value to the `Cluster`'s list of elements. Examples:

```
addElement "dog" (Cluster "cat" []) = Cluster "cat" ["dog"]
addElement 4 (Cluster 1 [2,3])      = Cluster 1 [2,3,4]
```

#### `clusterDistance`

Implement the `clusterDistance` function which takes a `Metric`, a value of any type, and a `Cluster` and returns the distance of the value from the `Cluster` according to the `Metric`. Examples:

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

With the definition of `Cluster` and basic functionality for interacting with values of this type, it is now possible to create functionality for the assignment of elements to `Cluster`s that are within a cluster _configuration_ (the collection of clusters to which elements of the dataset are assigned). The cluster configuration, unlike clusters, has no remarkable values and can be defined as an alias of `List`:

```
type Configuration a = [Cluster a]
```

where `a` indicates not only that we can have a `Configuration` of any type, but also that the `Configuration` consists of `Cluster`s of that same type. With the `Configuration` type, we can begin implementing the primary functionality of the k-medoids algorithm.

#### Required Functions

Recall that, after clusters are created, the next step in the k-medoids algorithm is to assign elements to clusters within the configuration. We can achieve this with the following functions:

* `nearestCluster`: Finds the most similar cluster to an element.
* `assignElement`: Adds an element to the most similar cluster.
* `assignElements`: Adds many elements to their most similar clusters.

#### `nearestCluster`

Implement the `nearestCluster` function which takes a `Metric`, a value of any type, and a `Configuration` and returns a `Tuple` that contains the nearest `Cluster`, according to the `Metric`, to the value and a list of all other `Cluster`s. Example:

```
cfg = [Cluster 26 [23,27], Cluster 41 [48,52], Cluster 88 [67,91]]
nearestCluster (\x y -> (x - y)^2) 77 cfg = (
    Cluster 88 [67,91], [Cluster 26 [23,27], Cluster 41 [48,52]]
)
```

Hint: consider making use of the `minBy` and `rotations` functions.

#### `assignElement`

Implement the `assignElement` function which takes a `Metric`, a value of any type, and a `Configuration` and returns a `Configuration` in which the value has been added to the nearest `Cluster` (according to the `Metric`). Example:

```
cfg = [Cluster 26 [23,27], Cluster 41 [48,52], Cluster 88 [67,91]]
assignElement (\x y -> (x - y)^2) 43 cfg = [
    Cluster 41 [48,52,43], Cluster 88 [67,91], Cluster 26 [23,27]
]
```

#### `assignElements`

Implement the `assignElements` function which takes a `Metric`, a list and a `Configuration` and returns that `Configuration` with the elements of the list added. Each list element should be in its nearest `Cluster`, according to the `Metric`, in the returned `Configuration`. Example:

```
cfg = [Cluster 26 [23,27], Cluster 41 [48,52], Cluster 88 [67,91]]
assignElements (\x y -> (x - y)^2) [43,13,64,29,101] cfg = [
    Cluster 88 [67,91,101], Cluster 26 [23,27,13,29], Cluster 41 [48,52,43,64]
]
```

### Optimising Clusters

#### Selecting Appropriate Medoids

The k-medoids algorithm must ensure that the medoid of each cluster is the most 'representative' element of that cluster so that: 1) the user can gain some insight into the 'topic' of the cluster (the medoid is an implicit descriptor of the cluster), and 2) so that the cluster is assigned elements most similar to its current collection of elements in the next round of assignments (if the configuration does not stabilise first). This involves checking every element of the cluster to see if it is more similar to its cluster neighbours than the current medoid and, if so, swapping that element and the medoid.

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

Hint: consider making use of the `rotations` function.

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

With the two main steps of the k-medoids algorithm complete, it is now possible to perform an iteration, or re-iteration, of the algorithm. To iterate a configuration, all non-medoid elements are removed from all clusters so that reclustering can be performed. After the elements are reassigned to the clusters, the clusters are re-optimised to ensure that the medoids are representative of the possibly-changed set of elements in each cluster. If the selection of medoids in the previous iteration was effective, the reassignment of the just-removed elements should improve the quality of the configuration - this is the key assumption of the k-medoids algorithm and its effectiveness rests on the strength of this assumption. That is to say, the configuration is not guaranteed to improve in each iteration of the k-medoids algorithm, but the design of the algorithm is such that it often does.

#### Required Functions

In conjunction with the functionality developed thus far, an iteration of the k-medoids algorithm can be performed using the following functions:

* `decluster`: Removes the elements from a cluster (excluding the medoid) so that they can be reassigned to the same or another cluster.
* `deconfigure`: Removes the elements from all clusters so that they can be reassigned to the same or other clusters.
* `kmedoidsIteration`: Executes one iteration of the k-medoids algorithm, ideally refining a cluster configuration to produce a more suitable grouping of elements.

#### `decluster`

Implement the `decluster` function which takes a `Cluster` and returns a `Tuple` in which the first value is the list of elements in the `Cluster` and the second is a variant of the `Cluster` in which only the medoid remains. Examples:

```
decluster (Cluster 1 [2,3,4])     = ([2,3,4], Cluster 1 [])
decluster (Cluster "cat" ["dog"]) = (["dog"], Cluster "cat" [])
```

#### `deconfigure`

Implement the `deconfigure` function which takes a `Configuration` and returns a `Tuple` in which the first value is a list of all non-medoid elements in the `Configuration` and the second is a list of all `Cluster`s in the original `Configuration` with their elements removed. Example:

```
deconfigure [Cluster 1 [2,3,4], Cluster 6 [7,8,9]] = (
    [2,3,4,7,8,9], [Cluster 1 [], Cluster 6 []]
)
```

Hint: consider using the `unzip` and `concat` functions.

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

The implementation of k-medoids is almost complete! All that remains is to create the functionality that guides and terminates the search for higher quality configurations, and to create a function that prevents the user from having to interact directly with the functions that make up the algorithm's implementation. To guide the search, it is necessary to be able to compare the quality of configurations. In the k-medoids algorithm, a configuration's quality is quantified as the sum of all costs of its clusters, which is referred to as the _configuration cost_. Once it is possible to measure configuration cost, a simple search in which an initial configuration is iterated until its cost fails to improve can be implemented. This is referred to as a _greedy_ search strategy because it assumes that always accepting the optimal local, or 'immediate', solution will ultimately lead to the optimal overall solution, which is rarely the case. Even so, the design of the k-medoids algorithm should enable the initial configuration to be improved to some extent.

#### Required Functions

To guide the discovery of increasingly high quality cluster configurations, we need the following functions:

* `configurationCost`: Measures the suitability of how elements are arranged in the clusters of a configuration (lower is better).
* `localSearch`: Keeps applying iterations of the k-medoids algorithm until no further improvement can be made.
* `kmedoids`: Applies the k-medoids algorithm to a collection of elements, returning _k_ clusters of elements.

#### `configurationCost`

Implemement the `configurationCost` function which takes a `Metric` and a `Configuration` and returns the sum of all distances, according to the `Metric`, between the medoids and elements within each of the `Cluster`s. Example:

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

Hint: consider using the `iterate` function.

#### `kmedoids`

Implement the `kmedoids` function which takes an `Int` representing _k_, a `Metric` and a list of elements to cluster and returns the lowest cost, according to the `Metric`, `Configuration` of those elements that it could find. The initial `Configuration` is created by creating _k_ `Cluster`s in which the first _k_ elements of the list are medoids. Example:

```
kmedoids 3 (\x y -> (x - y)^2) [1,4,7,2,5,8,3,6,9] = [
    Cluster 2 [1,3], Cluster 5 [4,6], Cluster 8 [7,9]
]
```

## Extending the Implementation

* It is possible for a configuration to slightly increase in cost before reaching lower cost states, but this possibility is not accounted for by the current implementation of the `localSearch` function. Generally, the k-medoids algorithm is terminated after it fails to improve a configuration in some number of consecutive iterations. Implement an alternative search function that implements this strategy.
* The quality of a configuration produced by the k-medoids algorithm is affected by the initial collection of medoids since they influence the subsequent assignment of elements. By simply selecting the first _k_ elements as medoids, the `kmedoids` function may contribute to poor solutions for particular datasets. Implement one or more functions that generate the initial set of medoids using alternative strategies and modify `kmedoids` to enable the user to provide their "medoids selection" function of choice.
* The `localSearch` function, as it is described in this document, hides information by discarding the `Configuration`s it generates in each iteration of search. These 'in-progress' `Configuration`s can provide valuable metadata regarding how the search of the solution space transpired, which can be valuable to individuals using the implementation. Extend `localSearch` and `kmedoids` so that they return all `Configurations` generated in the process of producing the final result.

_____________________________________________

## Worked Examples

### Utility Functions

#### `lengthDouble`

```
lengthDouble :: [a] -> Double
lengthDouble (x:xs) = 1.0 + lengthDouble xs
lengthDouble []     = 0.0
```

The most straightforward implementation of the `lengthDouble` function uses explicit recursion, in that the function explicitly calls itself in at least one of its clauses. The recursive clause exploits the knowledge that a non-empty list consists of a head element and another list, meaning that the length of that list is 1 (1.0 since the result type is `Double`) plus the length of the adjoining list. In the non-recursive clause, the empty list is mapped directly to the value 0.0. We can be confident that the empty list case will eventually be reached for all inputs because `lengthDouble` recurses on the tail of the argument list. Note that the `Prelude` module includes a `genericLength` function that works for all numerical types, making `lengthDouble` unnecessary.

#### `sumDoubles`

```
sumDoubles :: [Double] -> Double
sumDoubles (x:xs) = x + sumDoubles xs
sumDoubles []     = 0
```

The `sumDoubles` function also uses explicit recursion. An intuition for the base case can be developed by thinking of the 'neutral' or identity value of the result type based on the operation the function performs. The identity of summation is zero, therefore this is the result in the base case. Note that the `Prelude` module includes a `sum` function that works for all numerical types, making `sumDoubles` unnecessary.

#### `minBy`

```
minBy :: (a -> Double) -> [a] -> a
minBy _ []  = error "Cannot calculate minimum of empty list!"
minBy _ [x] = x
minBy f (h:t)
    | f h < f x = h
    | otherwise = x
    where x = minBy f t
```

The `minBy` function has three logical cases: 1) the argument list is empty, therefore no result can be provided (hence `error`), 2) the argument list contains only one value, making search unnecessary, and 3) the argument list contains many values so search for the minimum is necessary. The latter case can be decomposed into a comparison between the 'size' of the head of the list (as indicated by the `f` function) and the minimum of the tail (which can be calculated using `minBy`).

Although beyond the scope of this guide, a more idiomatic implementation of `minBy` can be created by making use of the `minimumBy` and `comparing` functions. The `comparing` function (type `Ord a => (b -> a) -> b -> b -> Ordering`, where `Ord` indicates that values of type `a` must implement the `Ord` typeclass and thus have a notion of order) takes a function that can indicate the 'size' of an element and converts it into a function that returns the `Ordering` of two of those elements; that is, whether the first value is less than, equal to, or greater than the second. The `minimumBy` function takes one such comparison function and a list and returns the minimum element of that list according to the function. With `comparing` and `minimumBy`, the `minBy` function can be implemented as follows:

```
minBy :: (a -> Double) -> [a] -> a
minBy f = minimumBy (comparing f)
```

Note that the `comparing` function is defined in the `Data.Ord` module.

#### `rotations`

```
rotations :: [a] -> [[a]]
rotations [] = error "Cannot generate rotations of empty list!"
rotations xs = takeN . go $ cycle xs
    where
        go xs' = takeN xs' : go (tail xs)
        takeN = take (length xs)
```

There are many ways to implement `rotations` and the above is just one approach. Recall that the `cycle` function creates an infinite list by cycling the list it receives. This implementation takes the first `n` elements of this infinite list, then repeats this action on that list's tail. By doing this `n` number of times, where `n` is the length of the argument list, all rotations are generated.

### Cluster Functions

#### `newCluster`

```
newCluster :: a -> Cluster a
newCluster m = Cluster m []
```

The `newCluster` function depends on the `Cluster a [a]` data constructor to construct a value of type `Cluster`. As the argument to `newCluster` is intended to be the medoid (hence the parameter name `m`), it occupies the 'significant' element position (the first `a` in `Cluster a [a]`). Furthermore, it _must_ occupy this position because the Haskell language won't allow the construction of a `Cluster` without a value for this position, whereas the list can be empty (and is in a new cluster because it is yet to be filled with non-medoid elements).

#### `addElement`

```
addElement :: a -> Cluster a -> Cluster a
addElement e (Cluster m es) = Cluster m (e:es)
```

Adding an element to a cluster means associating it with the medoid of that cluster. The medoid remains in its place (it is assumed to remain the most representative element of the cluster despite the addition of the new element) and the element is made part of the cluster's collection of elements. In this implementation the parameter names `e` and `es` represent 'element' and 'cluster elements', respectively.

#### `clusterDistance`

```
clusterDistance :: Metric a -> a -> Cluster a -> Double
clusterDistance f e (Cluster m _) = f m e
```

The distance of an element from a cluster in the k-medoids algorithm is calculated as the distance between that element and the cluster's medoid. The `clusterDistance` function performs this calculation by applying the distance metric `f` to the element `e` and medoid `m` of the argument `Cluster`. The non-medoid elements of the `Cluster` are not relevant, so `_` is used to avoid creating a binding.

#### `clusterCost`

```
clusterCost :: Metric a -> Cluster a -> Double
clusterCost f (Cluster m es) = go (f m) es
    where
        go f' (e:es') = f' e + go f' es'
        go _  []      = 0
```

Recall that the cost of a cluster is the sum of the distances between the medoid and cluster elements according to the distance function. As the elements are stored within a list, the cluster cost is calculated by recursing through the elements, applying the distance function with respect to the medoid to each, and summing the results. Note that the above implementation can be modified by making use of the `sum` function:

```
clusterCost :: Metric a -> Cluster a -> Double
clusterCost f (Cluster m es) = sum $ go (f m) es
    where
        go f' (e:es') = f' e : go f' es'
        go _ []       = [0]
```

As a result of this change the only action of the `go` function is to apply a function to each element in the given list and collect the results into a new list. This is identical to the behaviour of the `map` function. With `map`, the `go` function is no longer necessary and `clusterCost` can be simplified as follows:

```
clusterCost :: Metric a -> Cluster a -> Double
clusterCost f (Cluster m es) = sum $ map (f m) es
```

### Assignment Functions

#### `nearestCluster`

```
nearestCluster :: Metric a -> a -> Configuration a -> (Cluster a, Configuration a)
nearestCluster f e cs = (nearest, others)
    where
        (nearest:others) = minBy distance (rotations cs)
        distance (c:_) = clusterDistance f e c
```

The `nearestCluster` function has to search through the `Cluster`s in the given `Configuration` to find that which is nearest to the given element, but must also return the `Cluster`s that are not nearest. This is so that a caller of `nearestCluster` can manipulate that nearest `Cluster` and then combine it with the rest, reconstructing the `Configuration` (if `nearestCluster` instead only returned the nearest `Cluster`, the caller would have to identify the position of that `Cluster` in the `Configuration`).

As such, we cannot simply recurse through the given `Configuration`, as this would prevent us from retaining the more distant `Cluster`s. In the above implementation, we address this by searching for the unique rotation of the `Configuration` in which the head `Cluster` is nearest, meaning that the tail contains all of the `Cluster`s that are more distant. The search is performed by `minBy` and the rotations are generated by `rotations`.

The implementation of `nearestCluster` can be simplified by using the `head` and `tail` functions instead of pattern matching on lists. These functions should generally be avoided since they can fail when used on empty lists. However, the error cases in `nearestCluster` can only be encountered if the result of `rotations` is an empty list, which is not possible as can be seen from the implementation of `rotations` above. Therefore `nearestCluster` can be simplified as follows:

```
nearestCluster :: Metric a -> a -> Configuration a -> (Cluster a, Configuration a)
nearestCluster f e cs = (head result, tail result)
    where
        result = minBy distance (rotations cs)
        distance cs' = clusterDistance f e (head cs')
```

The revised `nearestCluster` is verbose with respect to `cs` in the function `distance`. The `distance` function has the type `Configuration -> Double`. Observe that the functions it is composed of are `clusterDistance f e` (type `Cluster a -> Double`) and `head` (type `[b] -> b`, where `b` in this case is `Configuration a`, therefore `Configuration a -> Cluster a`). The result of `head` is simply passed to `clusterDistance f e`. Functions that behave in this way, where the output type of the first is the input type of the second, can be composed into a single function using function composition:

```
(.) :: (b -> c) -> (a -> b)
(.) f g x = f $ gx
```

The composition function `(.)` enables `distance` to be simplified as follows:

```
nearestCluster :: Metric a -> a -> Configuration a -> (Cluster a, Configuration a)
nearestCluster f e cs = (head result, tail result)
    where
        result = minBy distance (rotations cs)
        distance = (clusterDistance f e) . head
```

#### `assignElement`

```
assignElement :: Metric a -> a -> Configuration a -> Configuration a
assignElement f e cs = addElement e nearest : others
    where (nearest, others) = nearestCluster f e cs
```

This implementation of the `assignElement` function exploits the design of `nearestCluster`. Because the result of `nearestCluster` provides both the nearest `Cluster` and a `Configuration` consisting of the rest of the `Cluster`s, `assignElement` need only cons the modified `Cluster` onto that `Configuration` to rebuild it, maintaining the integrity of the `Configuration` and avoiding the loss or duplication of elements.

#### `assignElements`

```
assignElements :: Metric a -> [a] -> Configuration a -> Configuration a
assignElements f es cs = go (\x y -> assignElement f x y) cs es
    where
        go f cs' (e:es') = f e (go f cs' es')
        go _ cs' []     = cs'
```

The main complication in the implementation of `assignElements` is that each element to be added must be added to the `Configuration` that was produced by adding the previous element. Simply adding each element to the initial argument `Configuration` will ultimately cause all but one of the elements to be lost. Thus the `go` function must pass along the result `Configuration` as it recurses through the elements to add. When all elements are added, `go` returns the last generated `Configuration`.

This pattern in `go` of 'aggregating' changes that occur due to list processing is common and is generalised by the higher-order _fold_ functions, which come in the 'left' and 'right' varieties. The `foldr` ('fold right') function is defined as follows:

```
foldr :: (a -> b -> b) -> b -> [a] -> b
foldr f z (x:xs) = f x (foldr f z xs)
foldr f z []     = z
```

This function recurses through a list of elements of type `a` and uses a function `a -> b -> b` to combine them into a result of type `b`. When the end of the list is encountered, the 'default' value `z`, of type `b`, is returned. By taking a value of type `b` as an input, the `a -> b -> b` function enables the user to 'retain changes' applied while `foldr` recurses. In our `go` function, the changes are the modified `Configuration`s generated by adding elements. Using `foldr`, the `assignElements` function can be implemented as follows:

```
assignElements :: Metric a -> [a] -> Configuration a -> Configuration a
assignElements f es cs = foldr (\x y -> assignElement f x y) cs es
```

The default value in this case for `foldr` is the initial `Configuration`, meaning that `assignElements` returns an unchanged `Configuration` if it receives no elements to assign. If there are elements to assign, then each is assigned to the `Configuration` produced by assigning the previous element, starting with the initial `Configuration`. Note that the function `\x y -> assignElement f x y` has the type `a -> Configuration a` and the type of `assignElement f` is `a -> Configuration a`; indeed, the bindings of `x` and `y` in the former only exist so that the arguments of `assignElement f` can be specified. In such cases [eta reduction](https://wiki.haskell.org/Eta_conversion) can be applied to simplify expressions:

```
assignElements :: Metric a -> [a] -> Configuration a -> Configuration a
assignElements f es cs = foldr (assignElement f) cs es
```

The `es` and `cs` parameters also appear to be candidates for eta-reduction, but cannot be reduced because they do not appear in the same order in `assignElements` and the call to `foldr (assignElement f)`. This can be remedied by flipping the order in which `foldr (assignElement f)` expects its arguments, which can be performed using the `flip` function:

```
flip :: (a -> b -> c) -> (b -> a -> c)
flip f x y = f y x
```

With `flip`, the eta reduction of `es` and `cs` can be performed:

```
assignElements :: Metric a -> [a] -> Configuration a -> Configuration a
assignElements f = flip $ foldr (assignElement f)
```

Note that the `sumDoubles` function involves a notion of 'aggregation' and can also be implemented in terms of `foldr`; the default value is the summation identity and the 'aggregation' function is simply `(+)`:

```
sumDoubles :: [Double] -> Double
sumDoubles = foldr (+) 0
```

Contrast with the explicit recursion implementation of `sumDoubles` in the [Utility Functions](#utility-functions) section. The `lengthDouble` also has a notion of 'aggregation', but implementing it in terms of `foldr` is slightly more complicated since the function ignores the value of each element of the list (it only cares that the elements exist):

```
lengthDouble :: [a] -> Double
lengthDouble = foldr (\_ y -> 1.0 + y) 0.0
```

### Optimisation Functions

#### `clusterPermutations`

```
clusterPermutations :: Cluster a -> [Cluster a]
clusterPermutations (Cluster m es) = go newCluster' $ rotations (m:es)
    where
        go f' (h:t) = f' h : go f' t
        go f' []    = []
        newCluster' (h:t) = Cluster h t
```

The only significant element within a `Cluster` is the medoid. That is to say, the other elements can be in any order without changing the 'meaning' of a `Cluster`. Thus, generating the permutations of a `Cluster` requires simply isolating each element of the cluster (including the medoid) in turn. In the above implementation, this is achieved using the `rotations` function. Note that the behaviour of the `go` function is identical to the `map`. Therefore, the implementation of `clusterPermutations` can be further simplified as follows:

```
clusterPermutations :: Cluster a -> [Cluster a]
clusterPermutations (Cluster m es) = map newCluster' $ rotations (m:es)
    where newCluster' (h:t) = Cluster h t
```

#### `updateCluster`

```
updateCluster :: Metric a -> Cluster a -> Cluster a
updateCluster f c = minBy (clusterCost f) (clusterPermutations c)
```

An 'updated' `Cluster` is the version of that `Cluster` in which the medoid is nearest to its elements, and therefore has the lowest possible cost. Using the `clusterPermutations` function to generate all permutations of the given `Cluster` in terms of its potential medoid, the `updateCluster` function need only search for the permutation that has the lowest cost. Note that the functions `minBy (clusterCost f)` and `clusterPermutations` have the types `[b] -> b` and `Cluster a -> [Cluster a]`, respectively, making them candidates for composition (and removing the need for parameter `c`):

```
updateCluster :: Metric a -> Cluster a -> Cluster a
updateCluster f = minBy (clusterCost f) . clusterPermutations
```

#### `updateConfiguration`

```
updateConfiguration :: Metric a -> Configuration a -> Configuration a
updateConfiguration f (c:cs) = updateCluster f c : updateConfiguration f cs
updateConfiguration f []     = []
```

Updating a `Configuration` only requires updating the `Cluster`s it contains, which can be achieved by using explicit recursion as per the above implementation, but is much more elegantly achieved by using the `map` function (which also allows the `Configuration` parameter to be eta-reduced):

```
updateConfiguration :: Metric a -> Configuration a -> Configuration a
updateConfiguration f = map $ updateCluster f
```

### Clustering Functions

#### `decluster`

```
decluster :: Cluster a -> ([a], Cluster a)
decluster (Cluster m xs) = (xs, newCluster m)
```

The `decluster` function need only pattern match to isolate the given `Cluster`'s medoid and its elements. The `newCluster` function is able to create an empty `Cluster` for a medoid, which makes it ideal for creating the empty version of that `Cluster`.

#### `deconfigure`

```
deconfigure :: Configuration a -> ([a], Configuration a)
deconfigure cs = (concat elements, medoids)
    where (elements, medoids) = unzip (map decluster cs)
```

Mapping over the `Cluster` in a `Configuration` with `decluster` produces a list of tuples that contain, in the first value, a list of elements in a `Cluster` and, in the second, an 'empty' variant of the `Cluster` that contains only the medoid. The `unzip` function breaks this list into two lists, one of the lists of extracted elements and the other of the 'empty' `Cluster`s. The `concat` function is used to create a single list from the individual lists of extracted elements.

#### `kmedoidsIteration`

```
kmedoidsIteration :: Metric a -> Configuration a -> Configuration a
kmedoidsIteration f cs = updateConfiguration f (assignElements f cs' xs)
    where (cs', xs) = deconfigure cs
```

Since the `kmedoidsIteration` function implements an iteration of the k-medoids algorithm, it must perform three actions: remove the elements from all `Cluster`s, assign all elements to the empty `Cluster`s, and optimise each `Cluster` according to cost. These actions are implemented by the `deconfigure`, `assignElements` and `updateConfiguration` functions, respectively, thus `kmedoidsIteration` can be expressed as a combination of those functions.

Pattern matching on the result of `deconfigure` so that the values can be passed to `assignElements f` may not be desirable. The `uncurry` function can be used to modify a function to take a tuple instead of two arguments:

```
uncurry :: (a -> b -> c) -> ((a, b) -> c)
uncurry f p =  f (fst p) (snd p)
```

With `uncurry`, result of `deconfigure` can be directly passed to `assignElements f`:

```
kmedoidsIteration :: Metric a -> Configuration a -> Configuration a
kmedoidsIteration f cs = updateConfiguration f assigned
    where assigned = uncurry' (assignElements f) (deconfigure cs)
```

The position of the binding `cs` at the end of the clause is a hint that function composition can be used to simplify the function. Note that in the above implementation, the result of `deconfigure cs` is simply passed to `uncurry (assignElements f)`, the result of which is simply passed to `updateConfiguration f`. Thus, the functions can be composed together:

```
kmedoidsIteration :: Metric a -> Configuration a -> Configuration a
kmedoidsIteration f = updateConfiguration f . (uncurry' (assignElements f)) . deconfigure
```

### Completion Functions

#### `configurationCost`

```
configurationCost :: Metric a -> Configuration a -> Double
configurationCost f cs = sum $ map (clusterCost f) cs
```

This function is similar to `clusterCost` and the same rationale for its implementation applies. Mapping `clusterCost f` over the `Cluster`s in the given `Configuration` results in a list of their scores which can be summed using the `sum` function. Note that as the type of `sum` is `[Double] -> Double` (in this case) and the type of `map (clusterCost f)` is `[a] -> [Double]`, they are candidates for function composition:

```
configurationCost :: Metric a -> Configuration a -> Double
configurationCost f = sum . map (clusterCost f)
```

#### `localSearch`

```
localSearch :: Metric a -> Configuration a -> Configuration a
localSearch f cs
    | cost cs' < cost cs = localSearch f cs'
    | otherwise          = cs
  where
    cost = configurationCost f
    cs' = kmedoidsIteration f cs
```

The `localSearch` function generates a subsequent iteration of the given `Configuration` and tests if it has a lower configuration cost. If not, the solution cannot be improved and the argument `Configuration` is returned. If so, `localSearch` is performed on the generated `Configuration`. Guards are used to test the search condition.

An alternative approach is to consider search to involve an infinite sequence of solutions that is generated until a `Configuration` poorer than the previous is encountered. The `iterate` function can be used to generate this sequence and a `search` function can be used to implement the termination condition:

```
localSearch :: Metric a -> Configuration a -> Configuration a
localSearch f = search . iterate (kmedoidsIteration f)
    where
        cost = configurationCost f
        search (x:y:xs)
            | cost x > cost y = search (y:xs)
            | otherwise       = x
```

#### `kmedoids`

```
kmedoids :: Int -> Metric a -> [a] -> Configuration a
kmedoids _ f [] = []
kmedoids k f xs = localSearch f initial (kmedoidsIteration f initial)
    where
        initial = assignElements f (map newCluster medoids) elements
        (medoids, elements) = splitAt k xs
```

The `kmedoids` function has to perform three steps: it needs to identify the elements to serve as the initial medoids, it has to generate the initial configuration, and it has to invoke the search on that configuration. These tasks are performed by the `splitAt`, `assignElements` and `localSearch` functions, respectively, allowing `kmedoids` to be implemented as a combination of those functions.
