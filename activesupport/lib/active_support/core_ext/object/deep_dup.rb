require 'active_support/core_ext/thread'
require 'active_support/core_ext/object/duplicable'

class Object
  # Returns a deep copy of object if it's duplicable. If it's
  # not duplicable, returns +self+.
  #
  #   object = Object.new
  #   dup    = object.deep_dup
  #   dup.instance_variable_set(:@a, 1)
  #
  #   object.instance_variable_defined?(:@a) # => false
  #   dup.instance_variable_defined?(:@a)    # => true
  def deep_dup
    if duplicable?
      ActiveSupport::DeepDuper.new(self).result
    else
      self
    end
  end
end

module ActiveSupport
  class DeepDuper
    def initialize(object)
      @object = object
    end

    def result
      Thread.recursion_guard(object, :dup.to_proc) do |clone|
        copy_all_instance_variables(clone)
      end
    end

    protected

    attr_reader :object

    private

    def copy_all_instance_variables(clone)
      object.instance_variables.each do |ivar|
        copy_instance_variable(clone, ivar)
      end
    end

    def copy_instance_variable(clone, ivar)
      original_value = clone.instance_variable_get(ivar)
      if instance_variable_unchanged?(ivar, original_value)
        new_value = original_value.deep_dup
        clone.instance_variable_set(ivar, new_value)
      end
    end

    def instance_variable_unchanged?(ivar, value)
      object.instance_variable_get(ivar).equal?(value)
    end
  end
end

class Array
  # Returns a deep copy of array.
  #
  #   array = [1, [2, 3]]
  #   dup   = array.deep_dup
  #   dup[1][2] = 4
  #
  #   array[1][2] # => nil
  #   dup[1][2]   # => 4
  def deep_dup
    map(&:deep_dup)
  end
end

class Hash
  # Returns a deep copy of hash.
  #
  #   hash = { a: { b: 'b' } }
  #   dup  = hash.deep_dup
  #   dup[:a][:c] = 'c'
  #
  #   hash[:a][:c] # => nil
  #   dup[:a][:c]  # => "c"
  def deep_dup
    each_with_object(dup) do |(key, value), hash|
      hash[key.deep_dup] = value.deep_dup
    end
  end
end
