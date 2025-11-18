--- @class FOV.Fraction : Object
--- @overload fun(numerator, denominator): FOV.Fraction
--- @type FOV.Fraction
local Fraction = prism.Object:extend("Fraction")

function Fraction:__new(numerator, denominator)
   self.numerator = numerator
   self.denominator = denominator or 1
end

function Fraction:__tostring()
   return self.numerator .. "/" .. self.denominator
end

function Fraction:tonumber()
   return self.numerator / self.denominator
end

function Fraction:__mul(other)
   if type(other) == "number" then
      return Fraction(self.numerator * other, self.denominator)
   else
      return Fraction(self.numerator * other.numerator, self.denominator * other.denominator)
   end
end

function Fraction.__eq(lhs, rhs)
   return lhs.numerator * rhs.denominator == lhs.denominator * rhs.numerator
end

function Fraction.__lt(lhs, rhs)
   return lhs.numerator * rhs.denominator < lhs.denominator * rhs.numerator
end

function Fraction.__le(lhs, rhs)
   return lhs.numerator * rhs.denominator <= lhs.denominator * rhs.numerator
end

function Fraction.__add(lhs, rhs)
   return Fraction(
      lhs.numerator * rhs.denominator + lhs.denominator * rhs.numerator,
      lhs.denominator * rhs.denominator
   )
end

function Fraction.__sub(lhs, rhs)
   return Fraction(
      lhs.numerator * rhs.denominator - lhs.denominator * rhs.numerator,
      lhs.denominator * rhs.denominator
   )
end

function Fraction:__unm()
   return Fraction(-self.numerator, self.denominator)
end

return Fraction
