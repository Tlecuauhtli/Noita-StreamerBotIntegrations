dofile("data/scripts/lib/mod_settings.lua")

local mod_id = "streamerboti"

mod_settings_version = 1
mod_settings = 
{
  {
    category_id = "connection_settings",
    ui_name = "Connection Settings",
    settings = {
        {
          id = "ws_host",
          ui_name = "Streamer Bot WS address",
          ui_description = [[The Streamer Bot WS address ej. ws://127.0.0.1:5036]],
          value_default = "ws://127.0.0.1:5036",
          scope = MOD_SETTING_SCOPE_RUNTIME
        }
    }
  }, 
  {
    category_id = "voting_settings",
    ui_name = "Voting Settings",
    settings = {
      {
        id = "voting_time",
        ui_name = "Voting Time",
        ui_description = "Time for voting in seconds",
        value_default = "30",
				allowed_characters = "0123456789",
        scope = MOD_SETTING_SCOPE_RUNTIME
      }, 
      {
        id = "voting_cooldown",
        ui_name = "Time between polls",
        ui_description = "Time between polls in seconds",
        value_default = "30",
				allowed_characters = "0123456789",
        scope = MOD_SETTING_SCOPE_RUNTIME
      }, 
      {
        id = "voting_n",
        ui_name = "Options per poll",
        ui_description = "Amount of options avalaible for voting",
        value_default = 4,
				value_min = 2,
				value_max = 12,
        scope = MOD_SETTING_SCOPE_RUNTIME
      }, 
      {
        id = "random_no_vote",
        ui_name = "On no vote chose random",
        ui_description = "If no one voted a random option is selected",
        value_default = false,
        scope = MOD_SETTING_SCOPE_RUNTIME
      },
      {
        id = "show_votes",
        ui_name = "Show votes",
        ui_description = "Show the vote counters",
        value_default = false,
        scope = MOD_SETTING_SCOPE_RUNTIME
      }
    }
  }
}

function ModSettingsUpdate(init_scope)
    local old_version = mod_settings_get_version(mod_id) -- This can be used to migrate some settings between mod versions.
    mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
