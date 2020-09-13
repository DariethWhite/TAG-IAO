/*TAG-AO-notecard-loader
 *Notecard loader for AOs in tag.
 *Intended for use on TAG Grid, compatiblity with other grids is not guaranteed
*/

//CONSTANTS
string cardName = "Default";

init() {
    loadNoteCard(cardName);
}

loadNoteCard(string card) {
    integer lines;
    integer i;
    string line;
    if(llGetInventoryType(card) != 7) {
        llOwnerSay("Error: " + card + " card was not found. Check permissions");
        return;
    }
    else {
        lines = osGetNumberOfNotecardLines(card);
        for(i=0; i<lines; i++) {
            line = osGetNotecardLine(card, i);
        }
    }
}

default {
    state_entry() {
        init();
    }
    link_message(integer sender_num, integer num, string text, key id) {
        command = llGetSubString(text, 0, llSubStringIndex(text, "|")-1);
        rest = llGetSubString(text, llSubStringIndex(text, "|"), -1);
        if(command == "LOADCARD") {
            
        }
    }
}
