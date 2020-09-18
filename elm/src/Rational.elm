{-
Rational numbers, built on top of BigInt.
Numerators and Denominators are always stored as positive BigInts, with a sign.
-}

module Rational exposing (..)

import BigInt as BI

type alias Numerator = BI.BigInt
type alias Denominator = BI.BigInt
type Sign = Pos | Neg
    
type alias Rational = { num : Numerator
                      , denom : Denominator
                      , sign : Sign }
    
zero = BI.fromInt 0

{- Conversions -}

fromInt : Int -> Int -> Rational
fromInt n d =
    let s = if (n >= 0 && d >= 0) || (n < 0 && d < 0)
            then Pos else Neg
    in { num = BI.abs <| BI.fromInt n
       , denom = BI.abs <| BI.fromInt d
       , sign = s}  

fromBigInt : BI.BigInt -> BI.BigInt -> Rational
fromBigInt n d =
    let s = if (BI.gte n zero && BI.gte d zero) || (BI.lt n zero && BI.lt d zero)
            then Pos else Neg
    in { num = BI.abs n
       , denom = BI.abs d
       , sign = s }

{- Arithmetic Operators -}

addSign : Rational -> Rational -> Sign
addSign a b = if eqSign a b then a.sign
              else case pos a of
                       True -> if gte a b then Pos else Neg
                       False -> if gte b a then Pos else Neg

addNums : Rational -> Rational -> BI.BigInt
addNums a b = if eqSign a b then BI.add a.num b.num
              else case pos a of
                       True -> BI.sub a.num b.num
                       False -> BI.sub b.num a.num
                                
add : Rational -> Rational -> Rational
add a b = let (an, bn) = normalize a b
          in { num = addNums an bn
             , denom = an.denom
             , sign = addSign a b }
             |> reduce

sub : Rational -> Rational -> Rational
sub a b = add a (negate b)

mulSign : Rational -> Rational -> Sign
mulSign a b = if eqSign a b then Pos else Neg
    
mul : Rational -> Rational -> Rational
mul a b = let s = mulSign a b
              n = BI.mul a.num b.num
              d = BI.mul a.denom b.denom
          in { num = n, denom = d, sign = s } |> reduce          

div : Rational -> Rational -> Rational
div a b = mul a { num = b.denom, denom = b.num, sign = b.sign }

{- Comparison Operators -}

gt : Rational -> Rational -> Bool
gt a b = case eqSign a b of
             True -> let (an, bn) = normalize a b
                     in if pos a then BI.gt an.num bn.num
                         else BI.gt bn.num an.num
             False -> pos a

gte : Rational -> Rational -> Bool
gte a b = gt a b || (reduce a) == (reduce b)
              
lt : Rational -> Rational -> Bool
lt a b = gt b a

lte : Rational -> Rational -> Bool
lte a b = gte b a

{- Rational-Specific Utilities -}

pos : Rational -> Bool
pos r = r.sign == Pos      

negate : Rational -> Rational
negate r = let s = if pos r then Neg else Pos
           in { num = r.num, denom = r.denom, sign = s }
        
eqSign : Rational -> Rational -> Bool
eqSign a b = (a.sign == Pos && b.sign == Pos) ||
                (a.sign == Neg && b.sign == Neg)

normalize : Rational -> Rational -> (Rational, Rational)
normalize a b = let d = lcm a.denom b.denom
                    n1 = BI.mul a.num (BI.div d (a.denom))
                    n2 = BI.mul b.num (BI.div d (b.denom))
                in ( { num = n1, denom = d, sign = a.sign }
                   , { num = n2, denom = d, sign = b.sign })

reduce : Rational -> Rational
reduce r = let d = gcd r.num r.denom
           in { num = BI.div r.num d
              , denom = BI.div r.denom d
              , sign = r.sign }

{- Arithmetic Utilities -}
               
lcm : BI.BigInt -> BI.BigInt -> BI.BigInt 
lcm a b = BI.div (BI.mul a b) (gcd a b)
      
gcd : BI.BigInt -> BI.BigInt -> BI.BigInt
gcd a b = if a == zero then b
          else if b == zero then a
          else case (BI.modBy b a) of
                   (Just m) -> gcd b m
                   Nothing -> zero
