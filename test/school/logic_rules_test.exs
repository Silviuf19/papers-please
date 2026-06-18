defmodule School.LogicRulesTest do
  use ExUnit.Case, async: true

  alias School.Logic
  alias School.Package

  # Each validation rule is its own public function that takes a %Package{} and
  # returns {:valid, _} or {:invalid, _}. These tests call those functions
  # directly, one rule at a time. Only the fields a rule looks at need to be set
  # on the package; the rest keep their %Package{} defaults.

  describe "validate_rule1/1 - letters must weigh under 500g" do
    test "a 500g letter is invalid" do
      assert {:invalid, _} = Logic.validate_rule1(%Package{type: :letter, weight: 500})
    end

    test "a 400g letter is valid" do
      assert {:valid, _} = Logic.validate_rule1(%Package{type: :letter, weight: 400})
    end
  end

  describe "validate_rule2/1 - international packages require a customs form" do
    test "international without a customs form is invalid" do
      assert {:invalid, _} =
               Logic.validate_rule2(%Package{destination: :international, has_customs_form: false})
    end
  end

  describe "validate_rule3/1 - fragile packages cannot use standard shipping" do
    test "a fragile standard package is invalid" do
      assert {:invalid, _} =
               Logic.validate_rule3(%Package{type: :fragile, shipping_class: :standard})
    end
  end

  describe "validate_rule4/1 - parcels over 5000g must use priority" do
    test "a heavy parcel that is not priority is invalid" do
      assert {:invalid, _} =
               Logic.validate_rule4(%Package{
                 type: :parcel,
                 weight: 6000,
                 shipping_class: :standard
               })
    end

    test "a heavy parcel that uses priority is valid" do
      assert {:valid, _} =
               Logic.validate_rule4(%Package{
                 type: :parcel,
                 weight: 6000,
                 shipping_class: :priority
               })
    end
  end

  describe "validate_rule5/1 - declared value over 100 requires insurance" do
    test "value over 100 without insurance is invalid" do
      assert {:invalid, _} =
               Logic.validate_rule5(%Package{declared_value: 186.5, has_insurance: false})
    end
  end

  describe "validate_rule6/1 - fragile packages must have a fragile sticker" do
    test "a fragile package without a sticker is invalid" do
      assert {:invalid, _} =
               Logic.validate_rule6(%Package{type: :fragile, has_fragile_sticker: false})
    end
  end

  describe "validate_rule7/1 - EU and international must use express or priority" do
    test "an EU standard package is invalid" do
      assert {:invalid, _} =
               Logic.validate_rule7(%Package{destination: :eu, shipping_class: :standard})
    end

    test "an EU express package is valid" do
      assert {:valid, _} =
               Logic.validate_rule7(%Package{destination: :eu, shipping_class: :express})
    end
  end

  describe "validate_rule8/1 - letters cannot have insurance" do
    test "a letter with insurance is invalid" do
      assert {:invalid, _} = Logic.validate_rule8(%Package{type: :letter, has_insurance: true})
    end
  end

  describe "validate_rule9/1 - standard shipping only for domestic under 2000g" do
    test "a domestic standard package over 2000g is invalid" do
      assert {:invalid, _} =
               Logic.validate_rule9(%Package{
                 destination: :domestic,
                 shipping_class: :standard,
                 weight: 2500
               })
    end

    test "a non-domestic standard package is invalid" do
      assert {:invalid, _} =
               Logic.validate_rule9(%Package{
                 destination: :eu,
                 shipping_class: :standard,
                 weight: 400
               })
    end

    test "a domestic standard package under 2000g is valid" do
      assert {:valid, _} =
               Logic.validate_rule9(%Package{
                 destination: :domestic,
                 shipping_class: :standard,
                 weight: 1000
               })
    end
  end

  describe "validate_rule10/1 - fragile international over 1000g must use priority" do
    test "a fragile international 1100g express package is invalid" do
      assert {:invalid, _} =
               Logic.validate_rule10(%Package{
                 type: :fragile,
                 destination: :international,
                 shipping_class: :express,
                 weight: 1100
               })
    end

    test "a fragile international 1100g priority package is valid" do
      assert {:valid, _} =
               Logic.validate_rule10(%Package{
                 type: :fragile,
                 destination: :international,
                 shipping_class: :priority,
                 weight: 1100
               })
    end
  end
end
