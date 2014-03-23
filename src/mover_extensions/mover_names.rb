# This example shows how to use attributes to name entities.

# add a method to Sketchup::Entity to name it
class Sketchup::Entity

# This method gets the name of an Entity.  Returns nil if it is not named.
def entity_name(create_if_needed = false)
    aname = self.get_attribute("skp", "name")
    if( not aname and create_if_needed )
        aname = self.entityID.to_s
        self.set_attribute("skp", "name", aname)
    end
    aname
end

# This method names the Entity
def entity_name=(aname)
    if( aname )
        self.set_attribute("skp", "name", aname)
    else
        self.delete_attribute("skp", "name")
    end
    aname
end

end # class Sketchup::Entity

# Extend the [] method on SketchUp::Entities so that you can
# do a lookup by name in addition to by index.
# Returns nil if no Entity with the given name is found
class Sketchup::Entities

if not method_defined? :original_brackets
    alias_method :original_brackets, :[]
end

def [](arg)
    # If it is a String, then use the value as a name and look it up
    if( arg.instance_of?(String) )
        ent = self.find {|e| e.entity_name == arg}
        return ent
    end
    
    # use the default implementation
    original_brackets(arg)
end

end

