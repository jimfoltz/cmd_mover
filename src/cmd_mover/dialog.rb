module CMD::Mover

  def self.create_dialog

    @dlg = UI::WebDialog.new("CMD's Mover", false, REG_KEY, 280, 300)

    html = File.join(PLUGIN_ROOT, 'mover.html')

    @dlg.set_file(html)

    @dlg.add_action_callback("toggle_observer") do |d, a|
      observe_frame_changes()
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

    @dlg.add_action_callback('play_anim') do |d, a|
      puts "play_anim:#{a.inspect}"
    end
    @dlg.add_action_callback('stop_anim') do |d, a|
      puts "stop_anim:#{a.inspect}"
    end

    def self.set_checkbox_checked(cb, st)
      if st == true
        cmd = "document.getElementById('#{cb}').checked = true;"
      else
        cmd = "document.getElementById('#{cb}').checked = false;"
      end
      @dlg.execute_script cmd
    end
    @dlg.show

  end # create_dialog

end
