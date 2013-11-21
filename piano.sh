#!/bin/bash

# Mark K Cowan, mark@battlesnake.co.uk

# Used to identify controller (MIDI source), in my case an Evolution MK-449C
CONTROLLER="MK-449C"
CONTROLLER_PORT=0
# Used to identify synthesizer (MIDI sink), e.g. TiMidity, fluidsynth
SYNTH="TiMidity"
# Synth program name e.g. timidity, fluidsynth
SYNTH_PROC="timidity"
# Port on synthesizer to use (TiMidity has 4 by default, I have Guitar Pro 5 in Wine mapped to ports 2 & 3)
SYNTH_PORT=0
# Synth command line
SYNTH_CMD="timidity -iA -Os --ext=wpvseo -s48000 -B1,8"

[ -z "$FLUIDSYNTH" ] && FLUIDSYNTH=1

if [[ $FLUIDSYNTH ]]
then
	SOUNDFONT="/usr/share/sf2/Piano24.sf2"
	SYNTH="FLUID Synth"
	SYNTH_PROC="fluidsynth"
	SYNTH_PORT=0
	SYNTH_CMD="fluidsynth  --server --no-shell  --audio-driver=jack --audio-bufcount=2 --gain=1 --audio-channels=2 --midi-driver=alsa_seq --sample-rate=48000 --audio-bufsize=64 --connect-jack-outputs  $SOUNDFONT"
fi

function start {
	#if [ "$2" == "-k" ]
	#then
	#	echo "Restarting pulseaudio"
	#	pulseaudio -k
	#	pulseaudio -D
	#fi

	if ! pidof timidity > /dev/null
	then
		echo "Starting $SYNTH synthesizer"
		CMD="$SYNTH_CMD"
		echo "\$ $CMD"
		$CMD &
		TPID=$!
		renice -n -5 -p $!
		disown
		sleep 1
	fi

	ALSA_OUT=`aconnect -o | grep "$SYNTH" | tr ':' ' '`
	ALSA_IN=`aconnect -i | grep "$CONTROLLER" | tr ':' ' '`

	MIDI_OUT=`echo "$ALSA_OUT" | cut -f2 -d ' '`
	MIDI_IN=`echo "$ALSA_IN" | cut -f2 -d ' '`

	NAME_OUT=`echo "$ALSA_OUT" | grep "client" | cut -f2 -d "'" | xargs echo`
	NAME_IN=`echo "$ALSA_IN" | grep "client" | cut -f2 -d "'" | xargs echo`

	if [ "$MIDI_IN" ]
	then
		echo "Controller '$NAME_IN' found at index $MIDI_IN"
	else
		echo "Controller '$CONTROLLER' not found"
		return 1
	fi

	if [ "$MIDI_OUT" ]
	then
		echo "Synthesizer '$NAME_OUT' found at index $MIDI_OUT"
	else
		echo "Synthesizer '$SYNTH' not found"
		return 1
	fi

	ACON=`aconnect $MIDI_IN:$CONTROLLER_PORT $MIDI_OUT:$SYNTH_PORT 2>&1`
	if [[ $? == 0 ]]
	then
		echo "Connected '$NAME_IN' to '$NAME_OUT' ($MIDI_IN:$CONTROLLER_PORT -> $MIDI_OUT:$SYNTH_PORT)"
	elif ! [[ "$ACON" =~ "Connection is already subscribed" ]]
	then
		echo "Failed to connect keyboard to synthesizer"
		return 1
	fi
}

function stop {
	echo "Clearing ALSA midi connections"
	aconnect -x

	OLDPID=`pidof $SYNTH_PROC`
	if [ "$OLDPID" ]
	then
		echo "Stopping previous $SYNTH instance"
		kill -s TERM $OLDPID
		sleep 0.5
		kill -s KILL $OLDPID 2>/dev/null
	fi
}

case "$1" in
	"start"|"")
		echo "Starting piano..."
		start || { stop; exit 1; }
		;;
	"restart")
		echo "Restarting piano..."
		stop
		start || { stop; exit 1; }
		;;
	"stop")
		echo "Stopping piano..."
		stop
		;;
	*)
		echo "Unknown command: '$1'"
		exit 1
		;;
esac
