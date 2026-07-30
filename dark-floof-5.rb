#!/usr/bin/env ruby

# Dark Floof V: The Neon Silence - Terminal Edition
# A text-adventure game with combat, exploration, and procedural room generation

require 'securerandom'

# ANSI color codes
class String
  def magenta; "\e[35m#{self}\e[0m"; end
  def cyan; "\e[36m#{self}\e[0m"; end
  def green; "\e[32m#{self}\e[0m"; end
  def yellow; "\e[33m#{self}\e[0m"; end
  def red; "\e[31m#{self}\e[0m"; end
  def white; "\e[37m#{self}\e[0m"; end
  def bold; "\e[1m#{self}\e[0m"; end
end

class DarkFloof5
  ROOM_COUNT = 250
  
  attr_accessor :game_state, :locations, :combat_log

  def initialize
    @game_state = {
      current_location: 'entrance',
      hp: 100,
      max_hp: 100,
      mask: 'none',
      dread: 0,
      fracture: 0,
      echo: 0,
      scraps: 0,
      ion_credits: 50,
      gun: 'revolver',
      ammo: 12,
      faction: 'unaligned',
      inventory: ['lighter'],
      is_in_combat: false,
      current_enemy: nil,
      turn_count: 0
    }
    
    @combat_log = []
    @locations = {}
    @enemies = {
      wraith: { name: 'Wraith', hp: 30, max_hp: 30, damage: 8, loot: { scraps: 15, ion_credits: 5 } },
      scavenger: { name: 'Scavenger', hp: 40, max_hp: 40, damage: 10, loot: { scraps: 25, ion_credits: 10 } },
      silence_guardian: { name: 'Silence Guardian', hp: 60, max_hp: 60, damage: 15, loot: { scraps: 50, ion_credits: 30 } },
      the_rift: { name: 'THE RIFT', hp: 150, max_hp: 150, damage: 25, loot: { scraps: 200, ion_credits: 100 } }
    }
    
    generate_world
  end

  # ============================================
  # WORLD GENERATION
  # ============================================

  def generate_world
    room_ids = []

    # Create entrance
    @locations['entrance'] = {
      name: 'The Pulse - Entrance',
      desc: 'You stand at the rusted front doors of The Pulse, an abandoned nightclub. Neon signs flicker erratically—purple, cyan, pink. The bass still throbs through the walls somehow, like the building remembers the music. Cold air leaks from gaps in the frame.',
      exits: {},
      npcs: ['A figure in a gas mask sits by the door'],
      items: ['neon-tag'],
      zone: 'entrance',
      danger: false
    }
    room_ids << 'entrance'

    # Generate 249 random rooms
    249.times do |i|
      room_id = "room_#{i}"
      room_ids << room_id

      desc = random_description
      has_npc = rand > 0.7
      has_items = rand > 0.5
      is_danger = rand > 0.8

      @locations[room_id] = {
        name: "The Pulse - Room #{i + 1}",
        desc: desc,
        exits: {},
        npcs: has_npc ? [random_npc] : [],
        items: has_items ? [random_item] : [],
        zone: "zone_#{i / 50}",
        danger: is_danger
      }
    end

    # Connect rooms with random exits
    room_ids.each_with_index do |room_id, index|
      num_exits = rand(2..4)
      directions = ['north', 'south', 'east', 'west', 'up', 'down']
      used_dirs = []

      num_exits.times do
        dir = directions.sample
        next if used_dirs.include?(dir)
        used_dirs << dir

        target_room = room_ids.sample
        @locations[room_id][:exits][dir] = target_room
      end

      # Add escape routes back to entrance
      if index > 0 && rand > 0.85
        escape_dir = ['north', 'south', 'east', 'west'].sample
        @locations[room_id][:exits][escape_dir] = 'entrance'
      end
    end

    # Create boss room
    boss_room_id = room_ids[rand(1...room_ids.length)]
    @locations[boss_room_id][:is_boss] = true
    @locations[boss_room_id][:name] = 'The Basement - The Rift'
    @locations[boss_room_id][:desc] = "You've reached a strange chamber. The walls are stone, older than the building above. In the center of the room, reality seems to... shimmer. The air tastes like copper. You sense something old and aware watching you from the distortion."
    @locations[boss_room_id][:npcs] = ['THE RIFT - Final Boss']
    @locations[boss_room_id][:items] = []
    @locations[boss_room_id][:danger] = true
  end

  def random_description
    descriptions = [
      'A dimly lit corridor with flickering neon signs.',
      'An abandoned office covered in dust and debris.',
      'A narrow hallway with water dripping from the ceiling.',
      'A storage room filled with broken equipment.',
      'A kitchen area with rusted appliances.',
      'A bathroom with shattered mirrors.',
      'A stairwell leading both up and down into darkness.',
      'A small room with graffiti covering every wall.',
      'A lounge area with overturned furniture.',
      'A technical room with exposed wiring.',
      'A server room with humming machinery.',
      'A ventilation shaft with metallic grating.',
      'A corridor with peeling wallpaper and water stains.',
      'A room filled with old filing cabinets.',
      'A hallway lined with boarded-up doors.',
      'A basement passage with concrete walls.',
      'A room with broken neon signs piled in corners.',
      'A storage closet barely large enough to move in.',
      'A hallway with echoing footsteps behind you.',
      'A room where the air seems to shimmer.',
      'A narrow passage between two walls.',
      'A room with a single working light bulb.',
      'A hallway with markings on the floor.',
      'A room that smells of rust and decay.',
      'A passage with graffiti warnings.',
      'A room filled with shelves of unknown items.',
      'A hallway where shadows move independently.',
      'A room with a low ceiling and tight walls.',
      'A passage that seems longer than it should be.',
      'A room with cold spots and warm spots.',
      'A hallway with doors that won\'t open.',
      'A room with mirrors reflecting nothing.',
      'A passage underground with stone walls.',
      'A room with machinery that still hums.',
      'A hallway with blood-red paint.',
      'A room filled with chairs arranged in circles.',
      'A passage that slopes downward slowly.',
      'A room with curtains hanging from the walls.',
      'A hallway with numbers etched into walls.',
      'A room where your breath becomes visible.',
      'A passage with tiles missing from floor.',
      'A room with a locked metal door.',
      'A hallway that branches unexpectedly.',
      'A room with abandoned experiments.',
      'A passage with warning symbols.',
      'A room with a skylight showing nothing.',
      'A hallway with cables running overhead.',
      'A room that feels older than the building.',
      'A passage with acoustic panels on walls.',
      'A room with a sense of being watched.'
    ]
    descriptions.sample
  end

  def random_npc
    npcs = [
      'A silent figure in the corner',
      'Something breathing in the dark',
      'A voice with no owner',
      'Eyes reflecting no light',
      'A shape that\'s almost human',
      'A presence you can feel',
      'A figure made of static',
      'Something that was never alive',
      'A memory that walks'
    ]
    npcs.sample
  end

  def random_item
    items = [
      'corroded-coin', 'rusted-key', 'torn-journal', 'broken-radio', 'dead-battery',
      'vinyl-record', 'broken-watch', 'faded-photograph', 'crumpled-note', 'old-lighter',
      'bent-nail', 'glass-shard', 'copper-wire', 'chain-link', 'safety-pin',
      'rubber-band', 'candle-stub', 'metal-coin', 'leather-strap', 'cloth-scrap',
      'bottle-cap', 'spring', 'bolt', 'washer', 'rivet',
      'neon-tag', 'circuit-board', 'transistor', 'diode', 'capacitor',
      'crystal-glass', 'mirror-shard', 'plastic-card', 'ticket-stub', 'postcard'
    ]
    items.sample
  end

  # ============================================
  # DISPLAY FUNCTIONS
  # ============================================

  def clear_screen
    system('clear') || system('cls')
  end

  def display_header
    puts "\n" + "═" * 80
    puts "DARK FLOOF V: THE NEON SILENCE".magenta.bold
    puts "═" * 80 + "\n"
  end

  def display_location
    loc = @locations[@game_state[:current_location]]
    
    puts "[ #{loc[:name]} ]".cyan.bold
    puts "─" * 80
    puts "\n#{loc[:desc]}\n\n"
    
    if loc[:exits].any?
      puts "Exits: #{loc[:exits].keys.join(', ').upcase}".yellow
    end
    
    if loc[:npcs].any?
      puts "NPCs: #{loc[:npcs].join(' | ')}".green
    end
    
    if loc[:items].any?
      puts "Items: #{loc[:items].join(', ')}".white
    end
    
    puts "\n"
  end

  def display_status
    hp_color = @game_state[:hp] > 50 ? :green : @game_state[:hp] > 25 ? :yellow : :red
    
    puts "┌─ STATUS " + "─" * 70 + "┐"
    puts "│ HP: #{@game_state[:hp].to_s.send(hp_color)}/#{@game_state[:max_hp]}  Dread: #{@game_state[:dread]}  Fracture: #{@game_state[:fracture]}  Echo: #{@game_state[:echo]}"
    puts "│ Scraps: #{@game_state[:scraps]}  Ion Credits: #{@game_state[:ion_credits]}  Ammo: #{@game_state[:ammo]}"
    puts "│ Gun: #{@game_state[:gun]}  Mask: #{@game_state[:mask]}  Faction: #{@game_state[:faction]}"
    puts "│ Inventory: #{@game_state[:inventory].join(', ')}"
    puts "└" + "─" * 79 + "┘\n"
  end

  def display_combat_log
    puts "┌─ COMBAT LOG " + "─" * 66 + "┐"
    if @combat_log.any?
      @combat_log.last(6).each do |entry|
        color = :white
        color = :red if entry.include?('damage')
        color = :green if entry.include?('heal')
        color = :yellow if entry.include?('miss')
        puts "│ #{entry.send(color)}"
      end
    else
      puts "│ No combat activity"
    end
    puts "└" + "─" * 79 + "┘\n"
  end

  def add_combat_log(message)
    @combat_log << message
    @combat_log.shift if @combat_log.length > 15
  end

  # ============================================
  # MOVEMENT
  # ============================================

  def move(direction)
    loc = @locations[@game_state[:current_location]]
    
    unless loc[:exits][direction]
      add_combat_log("Can't go #{direction.upcase} from here.")
      return
    end

    @game_state[:current_location] = loc[:exits][direction]
    new_loc = @locations[@game_state[:current_location]]
    
    add_combat_log("Moved #{direction.upcase} to #{new_loc[:name]}")
    
    # Check for random encounters
    if new_loc[:danger] && rand > 0.6
      enemies = [:wraith, :scavenger, :silence_guardian]
      start_combat(enemies.sample)
    elsif new_loc[:is_boss]
      add_combat_log("THE RIFT EMERGES BEFORE YOU")
      start_combat(:the_rift)
    end
    
    @game_state[:dread] = [@game_state[:dread] + 1, 100].min
  end

  # ============================================
  # COMBAT SYSTEM
  # ============================================

  def start_combat(enemy_key)
    enemy = @enemies[enemy_key].dup
    @game_state[:current_enemy] = { key: enemy_key, data: enemy }
    @game_state[:is_in_combat] = true
    add_combat_log("Encountered #{enemy[:name]}!")
    add_combat_log("Type ATTACK or RUN to act.")
  end

  def player_attack
    unless @game_state[:is_in_combat]
      add_combat_log("Not in combat.")
      return
    end

    if @game_state[:gun] == 'none' || @game_state[:ammo] == 0
      add_combat_log("No ammo! Use MELEE instead.")
      return
    end

    damage = rand(10..30)
    hit = rand > 0.2

    if hit
      @game_state[:current_enemy][:data][:hp] -= damage
      add_combat_log("Shot #{@game_state[:current_enemy][:data][:name]} for #{damage} damage.")
      @game_state[:ammo] -= 1

      if @game_state[:current_enemy][:data][:hp] <= 0
        end_combat(true)
        return
      end
    else
      add_combat_log("Shot missed!")
    end

    enemy_attack
  end

  def player_melee
    unless @game_state[:is_in_combat]
      add_combat_log("Not in combat.")
      return
    end

    damage = rand(5..20)
    hit = rand > 0.15

    if hit
      @game_state[:current_enemy][:data][:hp] -= damage
      add_combat_log("Slashed #{@game_state[:current_enemy][:data][:name]} for #{damage} damage.")

      if @game_state[:current_enemy][:data][:hp] <= 0
        end_combat(true)
        return
      end
    else
      add_combat_log("Melee attack missed!")
    end

    enemy_attack
  end

  def enemy_attack
    enemy = @game_state[:current_enemy][:data]
    damage = rand(0..10) + enemy[:damage]
    hit = rand > 0.25

    if hit
      @game_state[:hp] -= damage
      add_combat_log("#{enemy[:name]} dealt #{damage} damage!")

      if @game_state[:hp] <= 0
        end_combat(false)
      end
    else
      add_combat_log("#{enemy[:name]}'s attack missed!")
    end
  end

  def end_combat(player_won)
    @game_state[:is_in_combat] = false
    enemy = @game_state[:current_enemy][:data]

    if player_won
      add_combat_log("#{enemy[:name]} defeated!")
      loot = enemy[:loot]
      @game_state[:scraps] += loot[:scraps]
      @game_state[:ion_credits] += loot[:ion_credits]
      add_combat_log("Gained #{loot[:scraps]} scraps, #{loot[:ion_credits]} ion credits.")
      @game_state[:dread] = [@game_state[:dread] - 5, 0].max
    else
      add_combat_log("You have fallen.")
      @game_state[:hp] = @game_state[:max_hp]
      @game_state[:current_location] = 'entrance'
      @game_state[:dread] = [@game_state[:dread] + 10, 100].min
      add_combat_log("You wake at the entrance...")
    end

    @game_state[:current_enemy] = nil
  end

  def run_from_combat
    unless @game_state[:is_in_combat]
      add_combat_log("Not in combat.")
      return
    end

    success = rand > 0.4

    if success
      add_combat_log("You flee from combat!")
      @game_state[:is_in_combat] = false
      @game_state[:current_enemy] = nil
      @game_state[:dread] = [@game_state[:dread] + 3, 100].min
    else
      add_combat_log("Failed to escape!")
      enemy_attack
    end
  end

  # ============================================
  # INVENTORY & ITEMS
  # ============================================

  def pickup_item(item_name)
    loc = @locations[@game_state[:current_location]]
    
    unless loc[:items].include?(item_name)
      add_combat_log("No #{item_name} here.")
      return
    end

    @game_state[:inventory] << item_name
    loc[:items].delete(item_name)
    add_combat_log("Picked up #{item_name}")
  end

  def heal
    if @game_state[:scraps] >= 25
      @game_state[:scraps] -= 25
      @game_state[:hp] = @game_state[:max_hp]
      @game_state[:dread] = [@game_state[:dread] - 10, 0].max
      add_combat_log("Used med-kit. Feeling restored.")
    else
      add_combat_log("Need 25 scraps to heal.")
    end
  end

  # ============================================
  # COMMAND PARSER
  # ============================================

  def parse_command(input)
    cmd = input.strip.downcase
    parts = cmd.split(' ')
    action = parts[0]
    arg = parts[1..-1].join(' ')

    case action
    when 'help'
      display_help
    when 'move', 'go'
      move(arg) unless arg.empty?
    when 'n'
      move('north')
    when 's'
      move('south')
    when 'e'
      move('east')
    when 'w'
      move('west')
    when 'up'
      move('up')
    when 'down'
      move('down')
    when 'look'
      add_combat_log(@locations[@game_state[:current_location]][:desc])
    when 'attack'
      player_attack
    when 'melee'
      player_melee
    when 'run'
      run_from_combat
    when 'inventory', 'inv'
      add_combat_log("Inventory (#{@game_state[:inventory].length} items): #{@game_state[:inventory].join(', ') || 'empty'}")
    when 'status'
      add_combat_log("HP: #{@game_state[:hp]}/#{@game_state[:max_hp]} | Dread: #{@game_state[:dread]} | Fracture: #{@game_state[:fracture]}")
      add_combat_log("Scraps: #{@game_state[:scraps]} | Ion Credits: #{@game_state[:ion_credits]} | Ammo: #{@game_state[:ammo]}")
    when 'pickup'
      pickup_item(arg) unless arg.empty?
    when 'heal'
      heal
    when 'talk'
      add_combat_log("The NPCs here say nothing. They just stare.")
    when 'clear'
      @combat_log = []
    when ''
      # Empty command
    else
      add_combat_log("Unknown command: #{action}")
    end
  end

  def display_help
    add_combat_log("--- COMMANDS ---")
    add_combat_log("MOVE [N/S/E/W/UP/DOWN] - Navigate")
    add_combat_log("ATTACK - Use gun in combat")
    add_combat_log("MELEE - Punch/stab in combat")
    add_combat_log("RUN - Escape combat")
    add_combat_log("LOOK - Examine location")
    add_combat_log("PICKUP [item] - Take an item")
    add_combat_log("INVENTORY - Check items")
    add_combat_log("STATUS - View stats")
    add_combat_log("HEAL - Restore HP (25 scraps)")
    add_combat_log("TALK - Interact with NPCs")
  end

  # ============================================
  # MAIN GAME LOOP
  # ============================================

  def run
    clear_screen
    display_header
    add_combat_log("Dark Floof V: The Neon Silence loaded.")
    add_combat_log("Type HELP for commands.")

    loop do
      clear_screen
      display_header
      display_location
      display_combat_log
      display_status

      print "> ".magenta.bold
      input = gets.chomp

      break if input.downcase == 'quit' || input.downcase == 'exit'

      parse_command(input)
    end

    puts "\nThanks for playing Dark Floof V: The Neon Silence.\n".cyan
  end
end

# ============================================
# MAIN
# ============================================

if __FILE__ == $0
  game = DarkFloof5.new
  game.run
end
