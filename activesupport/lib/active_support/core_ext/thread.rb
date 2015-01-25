class Thread
  def recursive_objects
    self[:_active_support_recursive_objects] ||= {}
  end

  def self.recursion_guard(obj, if_unset)
    id = obj.object_id
    objects = current.recursive_objects

    if objects[id]
      objects[id]
    else
      begin
        if_unset.call(obj).tap do |result|
          objects[id] = result
          yield(result)
        end
      ensure
        objects.delete(id)
      end
    end
  end
end
