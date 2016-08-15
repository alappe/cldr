defmodule Cldr.Number.Cardinal do
  use Cldr.Number.PluralRule, :cardinal
  
  @type operand :: non_neg_integer
  
  # Generate the functions to process plural rules
  @spec do_plural_rule(binary, number, operand, operand, operand, operand, operand) 
    :: :one | :two | :few | :many | :other

  Enum.each @configured_locales, fn (locale) ->
    function_body = @rules[locale] |> rules_to_condition_statement(__MODULE__)
    function = quote do
      defp do_plural_rule(unquote(locale), n, i, v, w, f, t), do: unquote(function_body)
    end
    if System.get_env("DEBUG"), do: IO.puts Macro.to_string(function)
    Code.eval_quoted(function, [], __ENV__)
  end
end 