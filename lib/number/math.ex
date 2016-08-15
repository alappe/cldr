# http://icu-project.org/apiref/icu4c/classRuleBasedNumberFormat.html
defmodule Cldr.Number.Math do
  @default_rounding 3
    
  @doc """
  Returns the default rounding used by fraction_as_integer/2
  and any other Cldr function that takes a `rounding` argument.
  """
  def default_rounding do
    @default_rounding
  end

  @doc """
  Returns the fractional part of a float, decimal as an integer.
  
  * `number` can be either a `float`, `Decimal` or `integer` although
  an integer has no fraction part and will therefore always return 0.
  
  * `rounding` is the precision applied on each internal iteration as 
  the fraction is converted to an integer.  The default rounding is 3.
  
  ## Examples
  
      iex> Cldr.Number.Math.fraction_as_integer(123.456)               
      456
      
      iex> Cldr.Number.Math.fraction_as_integer(123.456, 2)               
      46
      
      iex> Cldr.Number.Math.fraction_as_integer(Decimal.new("123.456"), 3)
      456
      
      iex> Cldr.Number.Math.fraction_as_integer(1999, 3)                   
      0
  """
  def fraction_as_integer(fraction, rounding \\ @default_rounding)
  
  def fraction_as_integer(fraction, rounding) when is_float(fraction) and fraction > 1.0 do
    fraction_as_integer(fraction - trunc(fraction), rounding)
  end
  def fraction_as_integer(fraction, rounding) when is_float(fraction) do
    do_fraction_as_integer(fraction, rounding)
  end
  
  @decimal_10 Decimal.new(10)
  def fraction_as_integer(fraction, rounding) when is_map(fraction) do
    if Decimal.cmp(fraction, Decimal.new(1)) == :gt do
      Decimal.sub(fraction, Decimal.round(fraction, 0, :floor)) |> fraction_as_integer(rounding)
    else
      do_fraction_as_integer(fraction, rounding)
    end
  end
  
  def fraction_as_integer(fraction, _rounding) when is_integer(fraction) do
    0
  end

  
  @doc """
  Returns the number of decimal digits in the integer
  part of a number.
  
  `number` can be an `integer`. `Decimal` or `float`.
  
  ## Examples
  
      iex(10)> Cldr.Number.Math.number_of_integer_digits(1234)              
      4
  
      iex(11)> Cldr.Number.Math.number_of_integer_digits(Decimal.new("123456789"))
      9
      
      iex(15)> Cldr.Number.Math.number_of_integer_digits(1234.456)                     
      4
  """
  def number_of_integer_digits(number) when is_integer(number) do
    do_number_of_integer_digits(number, 0)
  end
  
  def number_of_integer_digits(number) when is_float(number) do
    trunc(number)
    |> do_number_of_integer_digits(0)
  end
  
  def number_of_integer_digits(number) when is_map(number) do
    Decimal.round(number, 0, :floor)
    |> Decimal.to_integer
    |> do_number_of_integer_digits(0)
  end
  
  @doc """
  Remove trailing zeroes from an integer.
  
  `number` must be an integer.
  
  ## Examples
  
      iex> Cldr.Number.Math.remove_trailing_zeroes(1234000)
      1234
  """
  def remove_trailing_zeroes(number) when is_integer(number) and number == 0, do: number
  def remove_trailing_zeroes(number) when is_integer(number) do
    if rem(number, 10) != 0 do
      number
    else
      div(number,10) |> remove_trailing_zeroes()
    end
  end
  
  @doc """
  Check if the `number` is within a `range`.
  
  `number` can be either an `integer` or `float`.
  When an integer, the comparison is made using the 
  standard Elixir `in` operator.
  
  When `number` is a `float` the comparison is made
  using the `>=` and `<=` operators on the range 
  endpoints.
  
  *Since this function is only provided to support plural
  rules, the float comparison is only valid if the
  float has no fractional part.*
  
  ## Examples
  
      iex> Cldr.Number.Math.within(2.0, 1..3)           
      true
      
      iex> Cldr.Number.Math.within(2.1, 1..3)
      false
  
  """
  def within(number, range) when is_integer(number) do
    number in range
  end
  
  # When checking if a decimal is in a range it is only
  # valid if there are no decimal places
  def within(number, first..last) when is_float(number) do
    number == trunc(number) && number >= first && number <= last
  end
  
  @doc """
  Calculates the modulo of a number (integer, float, decimal).
  
  For the case of an integer the result is that of the BIF
  function `rem/2`. For the other cases the modulo is calculated 
  separately.
  
  ## Examples
  
      iex> Cldr.Number.Math.mod(123, 5)      
      3
  
      iex> Cldr.Number.Math.mod(1234.0, 5)
      4.0
  
      iex> Cldr.Number.Math.mod(Decimal.new("1234.456"), 5)
      #Decimal<4.456>
  
      iex> Cldr.Number.Math.mod(1234.456, 5)             
      4.455999999999904
      
      iex> Cldr.Number.Math.mod(Decimal.new(123.456), Decimal.new(3.4))
      #Decimal<1.056>
      
      iex> Cldr.Number.Math.mod Decimal.new(123.456), 3.4             
      #Decimal<1.056>
      
      iex> Cldr.Number.Math.mod(123.456, 3.4)            
      1.0560000000000116
  """
  @spec mod(integer | float | %Decimal{}, integer | float | %Decimal{}) :: integer | float | %Decimal{}
  def mod(number, modulus) when is_integer(number) do
    rem(number, modulus)
  end
  
  def mod(number, modulus) when is_float(number) do
    number - (Float.floor(number / modulus) * modulus)
  end
  
  def mod(number, modulus) when is_map(number) and is_map(modulus) do
    modulo = Decimal.div(number, modulus) |> Decimal.round(0, :floor) |> Decimal.mult(modulus)
    Decimal.sub(number, modulo)
  end
  
  def mod(number, modulus) when is_map(number) and (is_integer(modulus) or is_float(modulus)) do
    mod(number, Decimal.new(modulus))
  end
  
  @doc """
  Convert a decimal to a float
  """
  @spec to_float(%Decimal{}) :: float
  def to_float(decimal) do
    decimal.sign * decimal.coef * 1.0 * :math.pow(10, decimal.exp)
  end
  
  defp do_fraction_as_integer(fraction, rounding) when is_float(fraction) do
    if (truncated_fraction = trunc(fraction)) == fraction do
      truncated_fraction
    else
      Float.round(fraction, rounding) * 10 |> do_fraction_as_integer(rounding)
    end
  end
  
  defp do_fraction_as_integer(fraction, rounding) when is_map(fraction) do
    truncated_fraction = Decimal.round(fraction, 0, :floor)
    if Decimal.equal?(truncated_fraction, fraction) do
      truncated_fraction |> Decimal.to_integer
    else
      Decimal.round(fraction, rounding) |> Decimal.mult(@decimal_10) |> do_fraction_as_integer(rounding)
    end
  end
  
  defp do_number_of_integer_digits(number, count) do
    if number == 0 do
      count
    else
      div(number, 10) |> do_number_of_integer_digits(count + 1)
    end
  end
end 