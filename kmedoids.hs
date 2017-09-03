
import Data.List (minimumBy)
import Data.Ord (comparing)

data Cluster a = Cluster a [a] deriving (Show, Eq)
type Configuration a = [Cluster a]
type Metric a = a -> a -> Double

--
-- Utility functions
--

minBy :: (a -> Double) -> [a] -> a
minBy f = minimumBy (comparing f)

rotations :: [a] -> [[a]]
rotations [] = error "Cannot generate rotations of empty list!"
rotations xs = takeN . go $ cycle xs
    where
        go xs' = takeN xs' : go (tail xs)
        takeN = take (length xs)

--
-- Cluster functions
--

newCluster :: a -> Cluster a
newCluster m = Cluster m []

addElement :: a -> Cluster a -> Cluster a
addElement e (Cluster m es) = Cluster m (e:es)

clusterDistance :: Metric a -> a -> Cluster a -> Double
clusterDistance f e (Cluster m _) = f m e

clusterCost :: Metric a -> Cluster a -> Double
clusterCost f (Cluster m es) = sum $ map (f m) es

--
-- Assignment functions
--

nearestCluster :: Metric a -> a -> Configuration a -> (Cluster a, Configuration a)
nearestCluster f e cs = (head result, tail result)
    where
        result = minBy distance (rotations cs)
        distance = (clusterDistance f e) . head

assignElement :: Metric a -> a -> Configuration a -> Configuration a
assignElement f e cs = addElement e nearest : others
    where (nearest, others) = nearestCluster f e cs

assignElements :: Metric a -> [a] -> Configuration a -> Configuration a
assignElements f = flip $ foldr (assignElement f)

--
-- Optimisation functions
--

clusterPermutations :: Cluster a -> [Cluster a]
clusterPermutations (Cluster m es) = map newCluster' (rotations (m:es))
    where newCluster' (h:t) = Cluster h t

updateCluster :: Metric a -> Cluster a -> Cluster a
updateCluster f = minBy (clusterCost f) . clusterPermutations

updateConfiguration :: Metric a -> Configuration a -> Configuration a
updateConfiguration f = map $ updateCluster f

--
-- Clustering functions
--

decluster :: Cluster a -> ([a], Cluster a)
decluster (Cluster m xs) = (xs, newCluster m)

deconfigure :: Configuration a -> ([a], Configuration a)
deconfigure cs = (concat elements, medoids)
    where (elements, medoids) = unzip (map decluster cs)

kmedoidsIteration :: Metric a -> Configuration a -> Configuration a
kmedoidsIteration f = updateConfiguration f . (uncurry (assignElements f)) . deconfigure

--
-- Completion functions
--

configurationCost :: Metric a -> Configuration a -> Double
configurationCost f = sum . map (clusterCost f)

localSearch :: Metric a -> Configuration a -> Configuration a
localSearch f = search . iterate (kmedoidsIteration f)
    where
        search (x:y:xs)
            | cost x > cost y = search (y:xs)
            | otherwise       = x
        cost = configurationCost f

kmedoids :: Int -> Metric a -> [a] -> Configuration a
kmedoids _ f [] = []
kmedoids k f xs = localSearch f $ assignElements f elements initial
    where
        initial = map newCluster medoids
        (medoids, elements) = splitAt k xs
