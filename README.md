piano
=====

Mark K Cowan, mark@battlesnake.co.uk

Script to start a TiMidity++ synth and connect my MIDI controller (Evolution MK-449C) to it.  Edit the script head to match your keyboard/controller.

Syntax:
    piano
    piano start
    piano stop
    piano restart

With no parameters, "start" is assumed.

Edit the script head to match your controller (`aconnect -i`) and your synthesizer (`aconnect -o`) if not using TiMidity++.
