defmodule Barlix.GS1Test do
  use ExUnit.Case, async: true
  doctest Barlix.GS1
  import Barlix.GS1
  import TestUtils
  require Integer

  use ExCheck

  describe "encode/1" do
    test "basic encoding" do
      assert encode!("123456") ==
               s_to_l(
                 "0000000000110100111001011001110010001011000111000101101000110111011000111010110000000000"
               )
    end

    test "fnc_1 can be used" do
      assert encode!([:fnc_1, ?1, ?2, ?3, ?4, ?5, ?6]) ==
               s_to_l(
                 "000000000011010011100111101011101011001110010001011000111000101101011011100011000111010110000000000"
               )

      assert encode!([:fnc_1, ?1, ?2, ?3, ?4, :fnc_1, ?5, ?6]) ==
               s_to_l(
                 "00000000001101001110011110101110101100111001000101100011110101110111000101101000101111011000111010110000000000"
               )
    end

    test "fails with odd amount of digits" do
      assert_raise RuntimeError, fn -> encode!("12345") end
    end

    test "fails with non-fnc_1 atom" do
      assert_raise ArgumentError, fn -> encode!([:fnc_2, ?1, ?2, ?3, ?4, ?5, ?6]) end
    end
  end

  @tag iterations: 500
  property "encodes pair of digits" do
    for_all codes in such_that(
              xx in non_empty(list(int(?0, ?9)))
              when Integer.is_even(length(xx))
            ) do
      {x, _} = encode(codes)
      x == :ok
    end
  end

  @tag iterations: 500
  property "errors out if odd number of digits" do
    for_all codes in such_that(
              xx in non_empty(list(int(?0, ?9)))
              when Integer.is_odd(length(xx))
            ) do
      try do
        encode(codes)
      rescue
        _e in RuntimeError -> true
      end
    end
  end
end
