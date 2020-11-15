defmodule MdDoctest.Parser do
  @moduledoc false
  @prefix "```elixir\n"
  @suffix "```\n"
  @regex ~r{(#{@prefix}|#{@suffix})}
  @prefix_replace "  ## Example\n\n"
  @suffix_replace "\n"

  @code_result_prefix "## => "

  @code_header "    iex> "
  @code_body "    ...> "
  @code_result "    "

  def to_doctest(binary) when is_binary(binary) do
    @regex
    |> Regex.split(binary, include_captures: true, trim: true)
    |> case do
      [one | []] ->
        one

      [_ | _] = many ->
        many
        |> parse_markdown([])
        |> Enum.reverse()
        |> Enum.map(&map_markdown/1)
        |> Enum.join("")
    end
  end

  defp parse_markdown([], result), do: result
  defp parse_markdown([@prefix | rest], result), do: parse_markdown(rest, [:prefix | result])
  defp parse_markdown([@suffix | rest], result), do: parse_markdown(rest, [:suffix | result])

  defp parse_markdown([o | rest], [:prefix | _] = result),
    do: parse_markdown(rest, [{:code, o} | result])

  defp parse_markdown([o | rest], result), do: parse_markdown(rest, [o | result])

  defp map_markdown(:prefix), do: @prefix_replace
  defp map_markdown(:suffix), do: @suffix_replace
  defp map_markdown(other) when is_binary(other), do: other

  defp map_markdown({:code, o}) when is_binary(o) do
    o
    |> String.split("\n")
    |> parse_code([])
    |> Enum.reverse()
    |> Enum.map(&map_code/1)
    |> Enum.join("\n")
  end

  defp parse_code([], result), do: result

  defp parse_code([@code_result_prefix <> code_result | rest], result) do
    parse_code(rest, [{:result, code_result} | result])
  end

  defp parse_code([o | rest], [] = result) do
    parse_code(rest, [{:header, o} | result])
  end

  defp parse_code([o | rest], [{:result, _} | _] = result) do
    parse_code(rest, [{:header, o} | result])
  end

  defp parse_code([o | rest], result) do
    parse_code(rest, [{:body, o} | result])
  end

  defp map_code({:header, ""}), do: ""
  defp map_code({:header, @code_header <> _ = o}), do: o
  defp map_code({:header, o}), do: @code_header <> o
  defp map_code({:body, @code_body <> _ = o}), do: o
  defp map_code({:body, o}), do: @code_body <> o
  defp map_code({:result, @code_result <> _ = o}), do: o
  defp map_code({:result, o}), do: @code_result <> o
end

defmodule MdDoctest.TransformModuleDoc do
  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    {line, binary} = Module.get_attribute(env.module, :moduledoc)
    moduledoc = binary |> MdDoctest.Parser.to_doctest()

    quote do
      Module.put_attribute(
        unquote(env.module),
        :moduledoc,
        {unquote(line), unquote(moduledoc)}
      )

      def __moduledoc__, do: unquote(moduledoc)
    end
  end
end

defmodule MdDoctest do
  @external_resource readme = Path.join([__DIR__, "../README.md"])

  @moduledoc readme
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(2)

  defdelegate to_doctest(o), to: __MODULE__.Parser

  use __MODULE__.TransformModuleDoc
end
