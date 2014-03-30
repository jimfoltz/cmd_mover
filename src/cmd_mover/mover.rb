# This file defines some methods that let you move entities during page transitions

module CMD
  module Mover

    load File.join(PLUGIN_ROOT, 'dialog.rb')
    load File.join(PLUGIN_ROOT, 'easings.rb')

    class PagesObserver < Sketchup::PagesObserver
      def onContentsModified(pages)
        UI.start_timer(0, false) {
        CMD::Mover.update_dialog()
        }
      end
    end
    
    def self.attach_observers
      puts "attaching observers"
      @pages_observer ||= PagesObserver.new
      Sketchup.active_model.pages.add_observer(@pages_observer)
    end
    def self.remove_observers
      puts "removing observers"
      Sketchup.active_model.pages.remove_observer(@pages_observer)
    end


    def self.group_or_component?(ent)
      ent.kind_of?(Sketchup::Group) or ent.kind_of?(Sketchup::ComponentInstance)
    end

    def self.get_entities_to_move(page)
      model = page.model
      entities = model.entities
      @moving_entities_map = {}

      # Get a list of names of all entities that will move for the page
      move_data = page.get_attribute(DICT_KEY, "entities_to_move")
      return if not move_data.kind_of? Array

      # look up each entity in the list and get its current and desired transform
      # the attribute data is an array of arrays.  The first thing in each
      # sub-array is the entity name and the second thing is an array that 
      # defines the desired transform
      # what we return is a Hash with the entity name as a key and an array
      # with the current and wanted transforms as the value
      for a in move_data do
        name = a[0]
        #ent = entities[name]
        ent = entities.detect{|e| e.get_attribute(DICT_KEY, 'name') == name}
        next if not ent
        next if not group_or_component?(ent)
        next unless ent.valid?
        tfrom = ent.transformation.to_a
        tto   = a[1]
        easing     = a[2]
        @moving_entities_map[name] = [ent, tfrom, tto, easing]
      end

      @moving_entities_map
    end

    def self.move_entities(parameter)
      return 0 if @moving_entities_map.empty?

      # move each entity to its new position
      @moving_entities_map.each_value do |a|
        ent = a[0]
        t1 = a[1]
        t2 = a[2]
        e = a[3]
        a = Easings.send(e || 'linear', parameter, 0.0, 100.0, 1.0) / 100.0
        #ent.move!( Geom::Transformation.interpolate( t1, t2, parameter) )
        ent.move!( Geom::Transformation.interpolate( t1, t2, a) )
      end
    end

    def self.set_entity_name(entity, create_if_needed = false)
      aname = entity.entityID.to_s
      entity.set_attribute(CMD::Mover::DICT_KEY, "name", aname)
      aname
    end


    # Save the current position of all selected groups and component instances
    # for the selected page
    def self.save_selected_entity_positions

      ss              = Sketchup.active_model.selection
      pages           = Sketchup.active_model.pages
      page            = pages.selected_page
      easing          = @dlg.get_element_value('easing')
      transition_time = @dlg.get_element_value('transition_time')

      return false if not page

      ents = ss.find_all {|e| group_or_component?(e)}
      return false if ents.empty?

      pages.selected_page.transition_time = transition_time.to_f

      move_data = page.get_attribute(DICT_KEY, "entities_to_move", [])

      # Update 
      for ent in ents do
        name = set_entity_name(ent, true)
        record = move_data.detect{|e| e[0] == name}
        if record
          record[1] =  ent.transformation.to_a
          record[2] = easing
        else
          move_data.push( [name, ent.transformation.to_a, easing] )
        end
      end

      page.set_attribute(DICT_KEY, "entities_to_move", move_data)

      true
    end

    def self.validate_save_position
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

        if( parameter < 1.0e-3 )
          CMD::Mover.get_entities_to_move(toPage)
        else
          CMD::Mover.move_entities(parameter)
        end
      end

    end # class FrameChangeObserver

    def self.observe_frame_changes
      pages = Sketchup.active_model.pages
      if pages.length < 1
        set_checkbox_checked('cb1', false)
        return
      end
      @cmd_mover_obs ||= FrameChangeObserver.new
      if @id
        Sketchup::Pages.remove_frame_change_observer(@id)
        @id = nil
        set_checkbox_checked('cb1', false)
      else
        @id = Sketchup::Pages.add_frame_change_observer(@cmd_mover_obs)
        set_checkbox_checked('cb1', true)
        pages = Sketchup.active_model.pages
        cpage = pages.selected_page
        pages.selected_page = cpage
      end
    end

    def self.show_selection
      page = Sketchup.active_model.pages.selected_page
      return false if not page

      ss = Sketchup.active_model.selection
      ss.clear

      move_data = page.get_attribute(DICT_KEY, "entities_to_move")
      return if not move_data.kind_of? Array

      model = page.model
      entities = model.entities

      for a in move_data do
        name = a[0]
        #ent = entities[name]
        ent = entities.detect{|e| e.get_attribute(DICT_KEY, 'name') == name}
        next if not ent
        next if not group_or_component?(ent)

        ss.add(ent)
      end

      Sketchup.active_model.active_view.invalidate
    end
    # TODO: I'd like to only enable this when it is really needed
    #observe_frame_changes

    #-----------------------------------------------------------------------------
    # Add a new menu item to the Plugins menu
    if( not file_loaded?("mover.rb") )
      plugins_menu = UI.menu("Plugins")
      plugins_menu.add_item("Mover Dialog") { create_dialog } 
      file_loaded("mover.rb")
    end

  end # module Mover
end # module CMD
