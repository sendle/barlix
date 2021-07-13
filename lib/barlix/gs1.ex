defmodule Barlix.GS1 do
  @moduledoc """
  This module implements the [GS1-128](https://en.wikipedia.org/wiki/GS1-128) symbology with Code Set C only. Only FNC-1 and pair of digits are accepted
  """

  @doc """
  Encodes the given value using GS1 128 symbology.

  Must have pair of digits and optionally Function Code 1 (:fnc_1)

  Examples

      Barlix.GS1.encode("123456")

      Barlix.GS1.encode([:fnc_1, ?1, ?2, ?3, ?4, :fnc_1, ?5, ?6])
  """
  @spec encode(String.t() | [member]) :: {:error, binary} | {:ok, Barlix.code()}
        when member: char() | :fnc_1
  def encode(value) do
    value = Barlix.Utils.normalize_string(value)

    with :ok <- validate(value),
         do: loop(value)
  end

  @doc """
  Accepts the same arguments as `encode/1`. Returns `t:Barlix.code/0` or
  raises `Barlix.Error` in case of invalid value.
  """
  @spec encode!(String.t() | [char() | :fnc_1]) :: Barlix.code() | no_return
  def encode!(value) do
    case encode(value) do
      {:ok, code} -> code
      {:error, error} -> raise Barlix.Error, error
    end
  end

  defp validate([h | t]) when h in ?0..?9 or h == :fnc_1 do
    validate(t)
  end

  defp validate([h | _]),
    do:
      {:error,
       "Invalid character found #{IO.chardata_to_string([h])}. Must be a digit or atom :fnc_1"}

  defp validate([]), do: :ok

  defp loop(value) do
    codes = [index(:start_code_c) | do_encode(value)]

    barcode =
      [quiet() | Enum.map(codes, &encoding/1)]
      |> Enum.concat([checksum(codes), stop(), quiet()])
      |> List.flatten()

    {:ok, {:D1, barcode}}
  end

  defp do_encode([]), do: []
  defp do_encode([:fnc_1 | rest]), do: [index(:fnc_1) | do_encode(rest)]
  defp do_encode([h1 | [h2 | rest]]), do: [index([h1, h2]) | do_encode(rest)]
  defp do_encode(arg), do: raise("Expected :fnc_1 or pair of digits! Got #{inspect(arg)}")

  defp checksum([]), do: []

  defp checksum([start | codes]) do
    sum =
      start * 1 + Enum.reduce(Enum.with_index(codes), 0, fn {x, i}, acc -> x * (i + 1) + acc end)

    rem(sum, 103)
    |> encoding
  end

  defp index([x, y]) when x >= ?0 and x <= ?9 and y >= ?0 and y <= ?9 do
    (x - ?0) * 10 + (y - ?0)
  end

  defp index(:start_code_c), do: 105
  defp index(:fnc_1), do: 102

  # More about how the code set is defined can be found here:
  # https://en.wikipedia.org/wiki/Code_128#Bar_code_widths

  defp quiet, do: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  defp stop, do: [1, 1, 0, 0, 0, 1, 1, 1, 0, 1, 0, 1, 1]

  defp encoding(0), do: [1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0]
  defp encoding(1), do: [1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0]
  defp encoding(2), do: [1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0]
  defp encoding(3), do: [1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0]
  defp encoding(4), do: [1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0]
  defp encoding(5), do: [1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0]
  defp encoding(6), do: [1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0]
  defp encoding(7), do: [1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0]
  defp encoding(8), do: [1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0]
  defp encoding(9), do: [1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0]
  defp encoding(10), do: [1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0]
  defp encoding(11), do: [1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0]
  defp encoding(12), do: [1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0]
  defp encoding(13), do: [1, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0]
  defp encoding(14), do: [1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0]
  defp encoding(15), do: [1, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0]
  defp encoding(16), do: [1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 0]
  defp encoding(17), do: [1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0]
  defp encoding(18), do: [1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0]
  defp encoding(19), do: [1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 0]
  defp encoding(20), do: [1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 0]
  defp encoding(21), do: [1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0]
  defp encoding(22), do: [1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 0]
  defp encoding(23), do: [1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0]
  defp encoding(24), do: [1, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0]
  defp encoding(25), do: [1, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0]
  defp encoding(26), do: [1, 1, 1, 0, 0, 1, 0, 0, 1, 1, 0]
  defp encoding(27), do: [1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0]
  defp encoding(28), do: [1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0]
  defp encoding(29), do: [1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0]
  defp encoding(30), do: [1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0]
  defp encoding(31), do: [1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0]
  defp encoding(32), do: [1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0]
  defp encoding(33), do: [1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0]
  defp encoding(34), do: [1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0]
  defp encoding(35), do: [1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0]
  defp encoding(36), do: [1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0]
  defp encoding(37), do: [1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0]
  defp encoding(38), do: [1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0]
  defp encoding(39), do: [1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0]
  defp encoding(40), do: [1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0]
  defp encoding(41), do: [1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0]
  defp encoding(42), do: [1, 0, 1, 1, 0, 1, 1, 1, 0, 0, 0]
  defp encoding(43), do: [1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0]
  defp encoding(44), do: [1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0]
  defp encoding(45), do: [1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0]
  defp encoding(46), do: [1, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0]
  defp encoding(47), do: [1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0]
  defp encoding(48), do: [1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0]
  defp encoding(49), do: [1, 1, 0, 1, 0, 0, 0, 1, 1, 1, 0]
  defp encoding(50), do: [1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 0]
  defp encoding(51), do: [1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0]
  defp encoding(52), do: [1, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0]
  defp encoding(53), do: [1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0]
  defp encoding(54), do: [1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0]
  defp encoding(55), do: [1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0]
  defp encoding(56), do: [1, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0]
  defp encoding(57), do: [1, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0]
  defp encoding(58), do: [1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0]
  defp encoding(59), do: [1, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0]
  defp encoding(60), do: [1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0]
  defp encoding(61), do: [1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0]
  defp encoding(62), do: [1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0]
  defp encoding(63), do: [1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0]
  defp encoding(64), do: [1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0]
  defp encoding(65), do: [1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0]
  defp encoding(66), do: [1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0]
  defp encoding(67), do: [1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0]
  defp encoding(68), do: [1, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0]
  defp encoding(69), do: [1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0]
  defp encoding(70), do: [1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0]
  defp encoding(71), do: [1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0]
  defp encoding(72), do: [1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0]
  defp encoding(73), do: [1, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0]
  defp encoding(74), do: [1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0]
  defp encoding(75), do: [1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0]
  defp encoding(76), do: [1, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0]
  defp encoding(77), do: [1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0]
  defp encoding(78), do: [1, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0]
  defp encoding(79), do: [1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0]
  defp encoding(80), do: [1, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0]
  defp encoding(81), do: [1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0]
  defp encoding(82), do: [1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0]
  defp encoding(83), do: [1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0]
  defp encoding(84), do: [1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0]
  defp encoding(85), do: [1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0]
  defp encoding(86), do: [1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0]
  defp encoding(87), do: [1, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0]
  defp encoding(88), do: [1, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0]
  defp encoding(89), do: [1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0]
  defp encoding(90), do: [1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0]
  defp encoding(91), do: [1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0]
  defp encoding(92), do: [1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0]
  defp encoding(93), do: [1, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0]
  defp encoding(94), do: [1, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0]
  defp encoding(95), do: [1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0]
  defp encoding(96), do: [1, 0, 1, 1, 1, 1, 0, 0, 0, 1, 0]
  defp encoding(97), do: [1, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0]
  defp encoding(98), do: [1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0]
  defp encoding(99), do: [1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0]
  defp encoding(100), do: [1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0]
  defp encoding(101), do: [1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0]
  defp encoding(102), do: [1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0]
  defp encoding(103), do: [1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0]
  defp encoding(104), do: [1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0]
  defp encoding(105), do: [1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0]
end
