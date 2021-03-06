# This file defines some methods that let you move entities during page transitions

module CMD
  module Mover

    #load File.join(PLUGIN_ROOT, 'mover_names.rb')
    load File.join(PLUGIN_ROOT, 'easings.rb')

    DICT_KEY = "CMD::Mover".freeze
    REG_KEY  = 'CMD\Mover'.freeze

    #=============================================================================

    def self.group_or_component?(ent)
      ent.kind_of? Sketchup::Group or ent.kind_of? Sketchup::ComponentInstance
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
        tto = a[1]
        e = a[2]
        @moving_entities_map[name] = [ent, tfrom, tto, e]
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
      ss   = Sketchup.active_model.selection
      page = Sketchup.active_model.pages.selected_page
      return false if not page
      ents = ss.find_all {|e| e.kind_of?(Sketchup::Group) or e.kind_of?(Sketchup::ComponentInstance)}
      return false if ents.empty?
      e = @dlg.get_element_value('easing')
      tt = @dlg.get_element_value('tt')

      move_data = page.get_attribute(DICT_KEY, "entities_to_move", [])

      # Update 
      for ent in ents do
        name = set_entity_name(ent, true)
        record = move_data.detect{|e| e[0] == name}
        if record
          record[1] =  ent.transformation.to_a
          record[2] = e
          record[3] = tt
        else
          move_data.push( [name, ent.transformation.to_a, e, tt] )
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

    end

    def self.observe_frame_changes
      @cmd_mover_obs ||= FrameChangeObserver.new
      if @id
        Sketchup::Pages.remove_frame_change_observer @id
        @id = nil
        #set_checkbox_checked('cb1', false)
        execute_on('cb1', 'checked=false')
      else
        @id = Sketchup::Pages.add_frame_change_observer @cmd_mover_obs
        #set_checkbox_checked('cb1', true)
        execute_on('cb1', 'checked=true')
        pages = Sketchup.active_model.pages
        cpage = pages.selected_page
        pages.selected_page = cpage
      end
    end

    def self.execute_on(id, script)
      cmd = "document.getElementById('#{id}').#{script}"
      @dlg.execute_script(cmd)
    end

    def self.set_checkbox_checked(cb, st)
      if st == true
        cmd = "document.getElementById('#{cb}').checked = true;"
      else
        cmd = "document.getElementById('#{cb}').checked = false;"
      end
      @dlg.execute_script cmd
    end

    def self.remember_position_of_selection
      save_selected_entity_positions
      tt = @dlg.get_element_value('tt')
      Sketchup.active_model.pages.selected_page.transition_time = tt.to_f
      #observe_frame_changes
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

    def self.create_dialog
      @dlg = UI::WebDialog.new("CMD's Mover", false, REG_KEY, 280, 300)
      html = File.join(PLUGIN_ROOT, 'mover.html')
      @dlg.set_file(html)

      @dlg.add_action_callback("toggle_observer") do |d, a|
        observe_frame_changes
        e = d.get_element_value('easing')
        @easing = e
      end

      @dlg.add_action_callback("remember_positions") do |d, a|
        remember_position_of_selection
      end

      @dlg.add_action_callback("next_prev") do |d, a|
        e = d.get_element_value('easing')
        @easing = e
        if a == "next"
          Sketchup.send_action "pageNext:"
        else
          Sketchup.send_action "pagePrevious:"
        end
      end

      @dlg.add_action_callback("add_scene") do |d, a|
        Sketchup.active_model.pages.add
      end

      @dlg.add_action_callback('view_anim_settings') do |d, a|
        UI.show_model_info("Animation")
      end

      @dlg.show

    end # create_dialog

    #-----------------------------------------------------------------------------
    # Add a new menu item to the Plugins menu
    if( not file_loaded?("mover.rb") )
      add_separator_to_menu("Plugins")
      plugins_menu = UI.menu("Plugins")
      #cmdId = plugins_menu.add_item("Remember Position of Selection") { remember_position_of_selection }
      #plugins_menu.set_validation_proc(cmdId) { validate_save_position }
      #plugins_menu.add_item("Show Location of Preserved Selection") { show_selection } 
      plugins_menu.add_item("Mover Dialog") { create_dialog } 
      file_loaded("mover.rb")
    end

  end # module Mover
end # module CMD
