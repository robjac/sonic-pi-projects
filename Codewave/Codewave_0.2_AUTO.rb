## Codewave_0.2 -Tuned Resonators in C minor
## Coded by Nanomancer

#######################

max_t = 10

load_samples [:ambi_drone, :ambi_haunted_hum, :ambi_lunar_land]
$global_clock = 0
use_bpm 60
set_volume! 5
set_sched_ahead_time! 2
use_cue_logging false
SEED = Time.now.usec
puts "Epoch seed: #{SEED}"
# use_random_seed  #  # 220574 # 263020 # 746742 # 100
# use_random_seed 471646
# use_random_seed 32625
# use_random_seed 489370
use_random_seed SEED # 746742 # 100

# sleep 2
# sample :elec_blip
# puts "SYNC"
# sleep 2


################ FUNCTIONS ########################


define :stopwatch do |int, max, fade|
  ## interval in seconds(just for log timer), max in mins, fade in secs
  count = 0
  set_mixer_control! amp: 1, amp_slide: 0.1
  with_bpm 60 do
    ctrl = true
    while count / 60.0 <= max
      if count % int == 0
        puts "Time: #{count / 60.0} Minutes"
      end
      count += 1
      sleep 1
      $global_clock = count / 60.0
      if count >= (max*60) - fade && ctrl == true
        set_mixer_control! amp: 0.01, amp_slide: fade
        puts "Stopping - #{fade} sec fadeout"
        ctrl = false
      end
    end
  end
end

define :autosync do |id, num = 0|
  tick(:as)
  puts "Liveloop ID: #{id} | No: #{look(:as)}"
  return sync id if look(:as) == num
end

define :autocue do |id, time|
  return cue id if $global_clock >= time
end

define :autostop do |time|
  return stop if $global_clock >= time
end

define :mk_rand_scale do |scale, len = 8|
  rand_s = []
  len.times do
    rand_s << scale.choose
  end
  return rand_s.ring
end


#############  CLOCK  #####################

in_thread do
  stopwatch(15, max_t, max_t*60*0.1)
end

##############  BASS  #########################

live_loop :pulsar do
  use_synth :growl
  autosync(:pulse)
  autostop(rrand max_t*0.75, max_t) # (rrand_i 5, 8)
  puts "Pulsar"

  # cut = [55, 60, 65, 70, 75, 80, 85, 80, 75, 70, 65, 60].ring.tick(:cut)
  #notes = (knit :c3, 4, :ds3, 1, :b2, 1)
  #notes = (knit :c3, 2, :ds3, 1, :c3, 2, :b2, 1)
  notes = (knit :c3, 2, :ds3, 1, :c3, 1)
  with_fx :reverb, mix: 0.3, room: 0.3, amp: 1 do
    notes.size.times do
      cut = [55, 60, 65, 70, 75, 80, 85, 80, 75, 70, 65, 60].ring.tick(:cut)
      play notes.tick, amp: 0.19, attack: 1.125, sustain: 1.25, release: 3, cutoff: cut, res: 0.2
      sleep 8
    end
  end
  if one_in 3
    sleep [8, 16, 24].choose
  end
end

############## TUNED RESONATED DRONE  #########################
cue :drn

live_loop :drone do
  autosync(:drn)
  autostop(max_t) #(rrand_i 6, 8)
  autocue(:prb, (rrand 0, max_t*0.3))
  autocue(:pulse, (rrand 0, max_t*0.4))
  autocue(:stc, (rrand 0, max_t*0.3))
  autocue(:trans, (rrand max_t*0.2, max_t*0.5))

  scl = scale(:c5, :harmonic_minor, num_octaves: 1)[0..4]
  # scl = chord([:c1, :c2, :c3].choose, :minor, num_octaves: 2)
  notes = mk_rand_scale(scl, 4)

  puts "Drone sequence: #{notes}"
  #  (notes.size * 2).times do
  notes.size * 2.times do
    frq = midi_to_hz(notes.tick)
    del = (1.0 / frq)# * 2
    with_fx :echo, amp: 1, mix: 1, phase: del, decay: 2 do
      sample :ambi_drone, attack: 0.6, pan: 0, amp: 0.8, rate: 0.5, cutoff: 117.5
      sleep 8
    end
  end
end

##############  TUNED RESONATED HUM  #########################

live_loop :probe do
  autosync(:prb)
  autostop(rrand max_t*0.7, max_t)
  #notes = chord([:c1, :c2, :c3].choose, :minor, num_octaves: 2).shuffle
  #notes = scale(:c4, :harmonic_minor, num_octaves: 1).shuffle
  notes = (ring 60, 62, 63, 65, 68, 71, 72).shuffle
  puts "Probe sequence: #{notes}"

  vol = 0.8

  4.times do

    phase = [0.25, 0.5, 0.75, 1, 1.5, 2].choose
    puts "Probe AM: #{phase}"
    with_fx :lpf, res: 0.1, cutoff: [70, 75, 80, 85].choose do
      with_fx :compressor, threshold:  0.4 do
        with_fx :slicer, mix: [1, 0.75, 0.5, 0.25].choose, smooth_up: phase * 0.5, smooth_down: phase * 0.125, phase: phase do
          with_fx :reverb, mix: [0.5, 0.6, 0.7, 0.8].choose, room: [0.6, 0.7, 0.8].choose do

            frq = midi_to_hz(notes.tick)
            with_fx :echo, amp: 0.7, mix: 0.85, phase: 1.0 / frq, decay: 2 do
              sample :ambi_haunted_hum, beat_stretch: 4, pan: -0.75, amp: vol, rate: (ring -0.25, 0.5, 0.25).tick(:ambi)
            end
            sleep [16, 8, 16].ring.look(:ambi)

            frq = midi_to_hz(notes.tick)
            with_fx :echo, amp: 0.7, mix: 0.85, phase: 1.0 / frq, decay: 2 do
              sample :ambi_haunted_hum, beat_stretch: 4, pan: 0.75, amp: vol, rate: (ring 0.25, -0.5, -0.25).look(:ambi)
            end
            sleep [16, 8, 16].ring.look(:ambi)
          end
          sleep [4, 6, 8, 12, 16, 24].choose
        end
      end
    end
  end
end

##############  TUNED RINGMOD / SYNTH  #########################

# sprd_arr = [3,4,5,6,7,8].shuffle
scales_arr = []
2.times do
  scl = scale([:c5, :c6].choose, :harmonic_minor, num_octaves: 2)
  scales_arr << mk_rand_scale(scl, 3)
end
puts scales_arr

live_loop :transmission do
  use_synth :blade

  autosync(:trans)
  autostop(rrand max_t*0.8, max_t) # (rrand_i 5, 7)
  chd = chord(:c1, :minor, num_octaves: 2).shuffle
  scl = scale([:c4, :c5, :c6].choose, :harmonic_minor, num_octaves: 1)

  # notes = mk_rand_scale(scl, 3)
  notes = scales_arr.choose

  puts "Transmission sequence: #{notes}"
  slp = [[3,3,2], [4,4,2], [6,6,3], [8,8,4]].choose.ring
  # slp = [[3,3,2], [4,4,2], [2,3,3], [3,2,2]].choose.ring

  (slp.size * 2).times do
    att, sus, rel = slp.tick * 0.3, slp.look * 0.2, slp.look * 0.5
    phase = [0.25, 0.5, 0.75, 1].choose
    mod_frq = rdist(0.0125, 0.5) * midi_to_hz(chd.tick(:chd))
    puts "Transmission AM: #{phase} | Ring mod frq: #{mod_frq}"
    with_fx :echo, mix: 0.25, phase: 1.5, decay: 4 do
      with_fx :ring_mod, freq: mod_frq do
        with_fx :slicer, mix: [0.9, 0.5, 0.25, 0.125].choose, smooth_up: phase * 0.5, smooth_down: phase * 0.125, phase: phase do
          play notes.look, amp: 0.07, attack: att, sustain: sus, release: rel, cutoff: 85
          sleep slp.look
        end
      end
    end
  end
  sleep [4, 8, 12, 16, 20, 32].choose
end

live_loop :static do
  use_synth :bnoise
  autosync(:stc)
  autostop(rrand max_t*0.6, max_t)
  scl = scale(:c2, :harmonic_minor, num_octaves: 2).choose
  mod_frq = midi_to_hz(scl)
  phs = [0.125, 0.5, 0.25, 0.75, 1].choose
  len = [6, 8, 10, 12, 16, 24].choose
  puts "Static - AM: #{phs} | Len: #{len}"
  with_fx :hpf, cutoff: 60 do
    with_fx :ring_mod, freq: mod_frq do
      with_fx :slicer, smooth_up: phs*0.25, mix: rrand(0.3,0.9), phase: phs do
        with_fx :reverb, mix: 0.5, room: 0.6 do
          cut = rrand(60, 120)
          amt = rrand(60, 120) # cut + (rrand 0, 40)
          s = play :c4, amp: 0.04, attack: len*0.5, release: len*0.5, cutoff: cut, cutoff_slide: len*0.5, res: (rrand 0.01, 0.6)
          control s, cutoff: amt
          sleep len*0.5
          control s, cutoff: cut
          sleep len*0.5
        end
      end
    end
  end
  if len <= 6
    sleep 2
  else
    sleep [10, 16, 20, 24].choose
  end
end
