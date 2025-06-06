{-# LANGUAGE GHC2021 #-}
{-# LANGUAGE LambdaCase #-} 
{-# LANGUAGE DisambiguateRecordFields #-} 
-- Implement the following functions.
-- When you're done, ghc -Wall -Werror HW1.hs should successfully compile.
--
-- Tells HLS to show warnings, and the file won't be compiled if there are any warnings, e.g.,
-- eval (-- >>>) won't work.
{-# OPTIONS_GHC -Wall -Werror #-}
-- Refines the above, allowing for unused imports.
{-# OPTIONS_GHC -Wno-unused-imports #-}

module HW1 where

-- These import statement ensures you aren't using any "advanced" functions and types, e.g., lists.
import Prelude (Bool (..), Eq (..), Foldable (sum), Int, Integer, Num (..), Ord (..), abs, div, error, even, flip, fst, id, mod, not, odd, otherwise, snd, take, undefined, ($), (&&), (.), (^), (||))
import GHC.Base (remInt)

------------------------------------------------
-- DO NOT MODIFY ANYTHING ABOVE THIS LINE !!! --
------------------------------------------------

---------------------------------------------------
-- Section 1: Function Composition & Transformation
---------------------------------------------------

curry3 :: ((a, b, c) -> d) -> a -> b -> c -> d
curry3 f x y z = f (x, y, z)

uncurry3 :: (a -> b -> c -> d) -> (a, b, c) -> d
uncurry3 f (x, y, z) = f x y z

fst3 :: (a, b, c) -> a
fst3 (x, _, _) = x
    
snd3 :: (a, b, c) -> b
snd3 (_, y, _) = y

thd3 :: (a, b, c) -> c
thd3 (_, _, z) = z

dropFst :: (a, b, c) -> (b, c)
dropFst (_, y, z) = (y, z)

dropSnd :: (a, b, c) -> (a, c)
dropSnd (x, _, z) = (x, z)

dropThd :: (a, b, c) -> (a, b)
dropThd (x, y, _) = (x, y)

mapPair :: (a -> b) -> (a, a) -> (b, b)
mapPair f (x, y) = (f x, f y)


pairApply :: (a -> b) -> (a -> c) -> a -> (b, c)
pairApply f g x = (f x, g x)


const :: a -> b -> a
const value _ = value

constSecond :: a -> b -> b
constSecond  _ value  = value

const2 :: a -> b -> c -> a
const2 value _ _ = value


-- Generatlizations of (.)
(.:) :: (c -> d) -> (a -> b -> c) -> a -> b -> d -- Hint: We saw this in class!
(.:) f g a b = f (g a b)

(.:.) :: (d -> e) -> (a -> b -> c -> d) -> a -> b -> c -> e
(.:.) f g a b c = f (g a b c)

(.::) :: (e -> f) -> (a -> b -> c -> d -> e) -> a -> b -> c -> d -> f
(.::) f g a b c d = f (g a b c d)

(.::.) :: (f -> g) -> (a -> b -> c -> d -> e -> f) -> a -> b -> c -> d -> e -> g
(.::.) f g a b c d e = f (g a b c d e)

-- How can we ever implement such a function!?
impossible :: a -> b
impossible _ = undefined

---------------------------------------------------
-- Section 2: Function Composition & Transformation
---------------------------------------------------
-- Count the number of digits of an integer
countDigits :: Integer -> Integer
countDigits n | n < 0 = countDigits (-n)
              | n < 10 = 1
              | otherwise = 1 + countDigits (n `div` 10)

-- Sums the  digits of an integer
sumDigits :: Integer -> Integer
sumDigits n | n < 0 = sumDigits (-n)
            | n < 10 = n
            | otherwise = n `mod` 10 + sumDigits (n `div` 10)

-- Reverses the  digits of an integer
reverseDigits :: Integer -> Integer
reverseDigits n | n < 0 = -reverseDigits (-n)
                | n < 10 = n
                | otherwise = (n `mod` 10) * (10 ^ (countDigits n - 1)) + reverseDigits (n `div` 10)


-- Returns the length of the Collatz sequence starting from x. collatzLength 1 = 0. You can assume the input is positive.
collatzLength :: Integer -> Integer
collatzLength n | n == 1 = 0
                | even n = 1 +collatzLength (n `div` 2)
                | otherwise = 1 + collatzLength (3 * n + 1)

------------------------
-- Section 3: Generators
------------------------

-- Type definition for a generator: a function producing a sequence of values
-- 1. The first function generates the next value.
-- 2. The second function checks if generation should continue.
-- 3. The third value is the initial value, or seed. It does not count as being generated by the generator.
type Generator a = (a -> a, a -> Bool, a)

-- Retrieves the nth value from a generator, or the last element. The seed does not count as an element.
-- If n is negative, return the seed.
nthGen :: Integer -> Generator a -> a
nthGen n (getNext, hasMore, seed) 
    | n <= 0 = seed
    | not (hasMore seed) = seed
    | otherwise = nthGen (n - 1) (getNext, hasMore, getNext seed)

hasNext :: Generator a -> Bool
hasNext (_, hasMore, seed)  = hasMore seed

-- Behavior is undefined if the generator has stopped.
nextGen :: Generator a -> Generator a
nextGen (getNext, hasMore, seed) = (getNext, hasMore, getNext seed)

-- Will not terminate if the generator does not stop.
lengthGen :: Generator a -> Integer
lengthGen (getNext, hasMore, seed) = 
    if hasMore seed then 1 + lengthGen (nextGen (getNext, hasMore, seed))
    else 0

-- Should terminate for infinite generators as well.
hasLengthOfAtLeast :: Integer -> Generator a -> Bool
hasLengthOfAtLeast n (getNext, hasMore, seed) 
    | n <= 0 = True
    | not (hasMore seed) = False
    | otherwise = hasLengthOfAtLeast (n - 1) (nextGen (getNext, hasMore, seed))

constGen :: a -> Generator a
constGen value = (const value, const True, value)

foreverGen :: (a -> a) -> a -> Generator a
foreverGen getNext seed = (getNext, const True, seed)

emptyGen :: Generator a
emptyGen = (undefined, const False, undefined)

-- Generates all integers except 0.
nextInt :: Integer -> Integer
nextInt n | n >= 0 = -n
          | otherwise = n + 1

integers :: Generator Integer
integers = (nextInt, const True, 1)

-- Sums all the values produced by a generator until it stops.
sumGen :: Generator Integer -> Integer
sumGen (getNext, hasMore, seed) =
    if hasMore seed then getNext seed + sumGen (nextGen (getNext, hasMore, seed))
    else 0

-- Checks if a generator produces a value that satisfies a predicate.
anyGen :: (a -> Bool) -> Generator a -> Bool
anyGen pred (getNext, hasMore, seed) 
    | not (hasMore seed) = False
    | pred (getNext seed) = True
    | otherwise = anyGen pred (nextGen (getNext, hasMore, seed))

-- Adds an additional predicate to a generator.
andAlso :: (a -> Bool) -> Generator a -> Generator a
andAlso pred (getNext, hasMore, seed) = (getNext, \x -> hasMore x && pred x, seed)

-- Bonus (15 points): Generates all positive divisors of a number smaller than the number itself.
divisors :: Integer -> Generator Integer
divisors _ = undefined

-----------------------------------
-- Section 4: Number classification
-----------------------------------

isPrime :: Integer -> Bool
isPrime x =
  let divisorCheck d
        | d * d > x      = False
        | x `mod` d == 0 = True
        | otherwise = divisorCheck (d + 1)
  in x > 1 && not (divisorCheck 2)

nextPrime :: Integer -> Integer
nextPrime n | isPrime (n + 1) = n + 1
            | otherwise = nextPrime (n + 1)
        
primes :: Generator Integer
primes = foreverGen nextPrime 1

--  Helper function that sums the squares of the digits of a number
sumOfPowers:: Integer -> Integer -> Integer
sumOfPowers num powNumber
  | num < 0    = sumOfPowers (-num) powNumber
  | num < 10   = num ^ powNumber
  | otherwise  = digit ^ powNumber + sumOfPowers reminder powNumber
  where
    reminder  = num `div` 10
    digit = num `mod` 10

isHappy :: Integer -> Bool
isHappy n = checkHappy (abs n)
  where
    checkHappy 0 = False
    checkHappy 1 = True
    checkHappy 4 = False
    checkHappy x = checkHappy (sumOfPowers x 2)

isArmstrong :: Integer -> Bool
isArmstrong n =
  let
    number = abs n
    digitsCount = countDigits number
  in sumOfPowers number digitsCount == number


isPalindromicPrime :: Integer -> Bool
isPalindromicPrime n = isPrime n && isPalindromic n
  where
    isPalindromic x = x == reverseDigits x
