# This file defines some methods that let you move entities during page transitions

require 'sketchup.rb'
require 'mover_extensions/mover_names.rb'

#=============================================================================

def group_or_component?(ent)
    ent.kind_of? Sketchup::Group or ent.kind_of? Sketchup::ComponentInstance
end

def get_entities_to_move(page)
    model = page.model
    entities = model.entities
    $moving_entities_map = {}
    
    # Get a list of names of all entities that will move for the page
    move_data = page.get_attribute "skp", "entities_to_move"
    return if not move_data.kind_of? Array
    
    # look up each entity in the list and get its current and desired transform
    # the attribute data is an array of arrays.  The first thing in each
    # sub-array is the entity name and the second thing is an array that 
    # defines the desired transform
    # what we return is a Hash with the entity name as a key and an array
    # with the current and wanted transforms as the value
    for a in move_data do
        name = a[0]
        ent = entities[name]
        next if not ent
        next if not group_or_component?(ent)
        tfrom = ent.transformation.to_a
        tto = a[1]
        $moving_entities_map[name] = [ent, tfrom, tto]
    end
    
    $moving_entities_map
end

def move_entities(parameter)
    return 0 if $moving_entities_map.empty?
    
    # move each entity to its new position
    $moving_entities_map.each_value do |a|
        ent = a[0]
        t1 = a[1]
        t2 = a[2]
        ent.move!( Geom::Transformation.interpolate( t1, t2, parameter) )
    end
end

# Save the current position of all selected groups and component instances
# for the selected page
def save_selected_entity_positions
    ss = Sketchup.active_model.selection
    page = Sketchup.active_model.pages.selected_page
    return false if not page
    ents = ss.find_all {|e| e.kind_of?(Sketchup::Group) or e.kind_of?(Sketchup::ComponentInstance)}
    return false if ents.empty?
    
    move_data = page.get_attribute "skp", "entities_to_move", []
    for ent in ents do
        move_data.push [ent.entity_name(true), ent.transformation.to_a]
    end
    page.set_attribute "skp", "entities_to_move", move_data
    
    true
end

def validate_save_position
    model = Sketchup.active_model
    return MF_GRAYED if not model
    ss = model.selection
    return MF_GRAYED if ss.empty?
    
    # See if there are any groups or components selected
    return MF_ENABLED if ss.find {|e| group_or_component? e}

    MF_GRAYED    
end

#=============================================================================

# A frame_change observer

class FrameChangeObserver

# The only method that is really needed is frameChange
# it takes three arguments - the from page, the to page and the parameter
def frameChange(fromPage, toPage, parameter)
    # Just show the information
    #s1 = fromPage ? fromPage.name : "NULL"
    #s2 = toPage ? toPage.name : "NULL"
    #puts "#{s1} to #{s2} at #{parameter}"
    
    if( parameter < 1.0e-3 )
        get_entities_to_move(toPage)
    else
        move_entities parameter
    end
end

end

def observe_frame_changes
    Sketchup::Pages.add_frame_change_observer FrameChangeObserver.new
end

def remember_position_of_selection
    save_selected_entity_positions
    observe_frame_changes
end

def show_selection
    page = Sketchup.active_model.pages.selected_page
    return false if not page

    ss = Sketchup.active_model.selection
    ss.clear
    
    move_data = page.get_attribute "skp", "entities_to_move"
    return if not move_data.kind_of? Array

    model = page.model
    entities = model.entities

    for a in move_data do
        name = a[0]
        ent = entities[name]
        next if not ent
        next if not group_or_component?(ent)
        
        ss.add(ent)
    end
    
    Sketchup.active_model.active_view.invalidate
end
# TODO: I'd like to only enable this when it is really needed
observe_frame_changes

#-----------------------------------------------------------------------------
# Add a new menu item to the Plugins menu
if( not file_loaded?("mover.rb") )

    add_separator_to_menu("Plugins")
    plugins_menu = UI.menu("Plugins")
    cmdId = plugins_menu.add_item("Remember Position of Selection") { remember_position_of_selection }
    plugins_menu.set_validation_proc(cmdId) { validate_save_position }
    plugins_menu.add_item("Show Location of Preserved Selection") { show_selection } 
    file_loaded("mover.rb")
end
