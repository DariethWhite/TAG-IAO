/*TAG-AO-notecard-loader
 *Notecard loader for AOs in tag.
 *Intended for use on TAG Grid, compatiblity with other grids is not guaranteed
*/

//CONSTANTS
string cardName = "Default";

init() {
    loadNoteCard();
}

default {
    state_entry() {
        init();
    }
}
