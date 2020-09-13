Stephan Kern 2020-09-13
    Remove Print Free Memory -- Pointless in opensim
    Reformat.
    Relocate README style stuff to a new file.
    Relocate VersionHistory to its own file.
    Upgrade license to GPL v3.

Marcus Gray, 2010-01-03
         ADDED option to disable AO in Mouselook (interface, core)
         ADDED possibility to set certain settings in a config notecard (adding  tag [ Settings ], editing loadcards only :P)

Marcus Gray, 07/02/2009 (July 2nd)
          hardened script against animation names containing ":" (":"-character is used for unlooped anims timing)
         should now work with anything thas isn't ":" followed by only an integer (loadcards, minor core)

interlude:
         added this and that 0o, fixed some bugs i think
         uhm
         ...yeah
         at least some kindergarden level math errors x)


Marcus Gray / Johann Ehrler, 09/28/2008:
         Inserted some new parts for the stand-ON/OFF-toggle function.
         Also terminated some typos.

Johann Ehrler, 09/16/2008:
         WARNING: This script was MONO-recompiled!

Johann Ehrler, 04/19/2008:
         Added support for custom animation timing.

Johann Ehrler, 04/06/2008:
         Some optimations are done...like cleaning up the code and merge it with newly
         developed functions from a trunk of the core script.
         Added the byte count to the free memory display for a much better geek factor. ;o)
         The channel for the listener depends now on the owner UUID...not really necessary but funny.
         Corrected some typos, redundant whitespaces and indentations.
         Set Marcus change date to the right year. ;P

Marcus Gray, 03/26/2008:
         Included Seamless Sit mod by Moeka Kohime (core script).
         Freed some memory DELETING THE DEFAULT UNOVERRIDABLE ANIMS!!!!!!!! (core script)
         Added sit anywhere functionality to replace stands by groundsits (core script).
         Therefore changed functionality of Sit-ON/OFF button to work as Sit Anywhere button (interface).

Ziggy, 07/16/07 - Warning instead of error on 'no animation in inventory', that way SL's built-in
                  anims can be used

Ziggy, 07/14/07 - 2 bug fixes. Listens aren't being reset on owner change, and a typo in the
                  ground sit animation code

Ziggy, 06/07:
         Reduce script count, since idle scripts take up scheduler time
         Tokenize notecard reader, to simplify notecard setup
         Remove scripted texture changes, to simplify customization by animation sellers

Fennec Wind, January 18th, 2007:
         Changed Walk/Sit/Ground Sit dialogs to show animation name (or partial name if too long)
         and only show buttons for non-blank entries.
         Fixed minor bug in the state_entry, ground sits were not being initialized.


Dzonatas Sol, 09/06: Fixed forward walk override (same as previous backward walk fix).

Based on Francis Chung's Franimation Overrider v1.8

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307, USA.
