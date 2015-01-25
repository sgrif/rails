require 'abstract_unit'
require 'active_support/core_ext/object'

class DeepDupTest < ActiveSupport::TestCase
  def test_array_deep_dup
    array = [1, [2, 3]]
    dup = array.deep_dup
    dup[1][2] = 4
    assert_equal nil, array[1][2]
    assert_equal 4, dup[1][2]
  end

  def test_hash_deep_dup
    hash = { :a => { :b => 'b' } }
    dup = hash.deep_dup
    dup[:a][:c] = 'c'
    assert_equal nil, hash[:a][:c]
    assert_equal 'c', dup[:a][:c]
  end

  def test_array_deep_dup_with_hash_inside
    array = [1, { :a => 2, :b => 3 } ]
    dup = array.deep_dup
    dup[1][:c] = 4
    assert_equal nil, array[1][:c]
    assert_equal 4, dup[1][:c]
  end

  def test_hash_deep_dup_with_array_inside
    hash = { :a => [1, 2] }
    dup = hash.deep_dup
    dup[:a][2] = 'c'
    assert_equal nil, hash[:a][2]
    assert_equal 'c', dup[:a][2]
  end

  def test_deep_dup_initialize
    zero_hash = Hash.new 0
    hash = { :a => zero_hash }
    dup = hash.deep_dup
    assert_equal 0, dup[:a][44]
  end

  def test_object_deep_dup
    object = Object.new
    dup = object.deep_dup
    dup.instance_variable_set(:@a, 1)
    assert !object.instance_variable_defined?(:@a)
    assert dup.instance_variable_defined?(:@a)
  end

  class DupTest
    attr_accessor :a

    def initialize(a = nil)
      @a = a
    end
  end

  def test_deep_dup_will_dup_all_instance_variables
    object = DupTest.new("foo")
    clone = object.deep_dup

    assert_not_same object.a, clone.a
    assert_equal "foo", clone.a
  end

  def test_deep_dup_works_with_non_duplicable_instance_variables
    object = DupTest.new(1)
    clone = object.deep_dup

    assert_equal 1, clone.a
  end

  def test_deep_dup_does_nothing_on_non_duplicable_objects
    original_value = "foo"
    object = DupTest.new(original_value)
    def object.duplicable?; false; end
    clone = object.deep_dup

    assert_same object.a, clone.a
    assert_same object.a, original_value
  end

  def test_deep_dup_is_recursive
    object = DupTest.new(DupTest.new("foo"))
    clone = object.deep_dup

    assert_not_same object.a.a, clone.a.a
  end

  def test_deep_dup_handles_circular_references
    object = DupTest.new
    other_object = DupTest.new
    object.a = other_object
    other_object.a = object
    clone = object.deep_dup

    assert_not_same other_object, clone.a
    assert_not_same object, clone.a.a
    assert_same clone.a, clone.a.a.a
    assert_same clone.a.a, clone.a.a.a.a
  end

  class DupsSomeButNotAllIvars
    attr_reader :a, :b

    def initialize(a, b)
      @a = a
      @b = b
    end

    def initialize_dup(other)
      super
      @b = b.dup
      $b_after_dup = b
    end
  end

  def test_deep_dup_does_not_redup_objects_duped_in_initialize_dup
    object = DupsSomeButNotAllIvars.new("foo", "bar")
    clone = object.deep_dup

    assert_same clone.b, $b_after_dup
  end
end
