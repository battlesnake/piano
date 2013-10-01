#!/bin/bash

# Mark K Cowan, mark@battlesnake.co.uk

# Used to identify controller (MIDI source), in my case an Evolution MK-449C
CONTROLLER="MK-449C"
CONTROLLER_PORT=0
# Used to identify synthesizer (MIDI sink), this script uses TiMidity++ by default
SYNTH="TiMidity"
# Port on synthesizer to use (TiMidity has 4 by default, I have Guitar Pro 5 in Wine mapped to ports 2 & 3)
SYNTH_PORT=0

# Your sound card may not support this, try 44100 or 48000 (and set BUFFERSIZE to 8 unless it causes choppy sound)
SAMPLE_RATE=96000
BUFFERSIZE=10

function start {
	if ! pidof timidity > /dev/null
	then
		echo "Starting timidity synthesizer"
		timidity -Os -s$SAMPLE_RATE -iA -B2,$BUFFERSIZE & disown
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

	OLDTIM=`pidof timidity`
	if [ "$OLDTIM" ]
	then
		echo "Stopping previous Timidity instance"
		kill $OLDTIM
		sleep 0.5
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