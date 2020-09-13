/*TAG-AO-notecard-loader
 *Notecard loader for AOs in tag.
 *Intended for use on TAG Grid, compatiblity with other grids is not guaranteed
*/

//CONSTANTS
string cardName = "Default";

//tokens
list tokens = [
   "[ Sitting On Ground ]",    // 0
   "[ Sitting ]",              // 1
   "",                         // 2 - We don't allow Striding as a token
   "[ Crouching ]",            // 3
   "[ Crouch Walking ]",       // 4
   "",                         // 5 - We don't allow Soft Landing as a token
   "[ Standing Up ]",          // 6
   "[ Falling ]",              // 7
   "[ Flying Down ]",          // 8
   "[ Flying Up ]",            // 9
   "[ Flying Slow ]",          // 10
   "[ Flying ]",               // 11
   "[ Hovering ]",             // 12
   "[ Jumping ]",              // 13
   "[ Pre Jumping ]",          // 14
   "[ Running ]",              // 15
   "[ Turning Right ]",        // 16
   "[ Turning Left ]",         // 17
   "[ Walking ]",              // 18
   "[ Landing ]",              // 19
   "[ Standing ]",             // 20
   "[ Swimming Down ]",        // 21
   "[ Swimming Up ]",          // 22
   "[ Swimming Forward ]",     // 23
   "[ Floating ]",             // 24
   "[ Typing ]"                // 25
   "[ Settings ]"              // 26 this is new... we'll see how i can make it work
];

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
            if(llGetSubString(line, 0, 1) == "[ "){ //Line is a token
                integer tstart = llSubStringIndex(line, "[") ;
                integer tend = llSubStringIndex(line, "]");
                string token = llGetSubString(tstart, tend);
                string rest = llGetSubString(line, tend+1, -1);
                string setting = parseLine(token, line);
            }
            else {}
        }
    }
}

parseLine(string token, string rest) {
    //llListFindList return -1 on fail, using bitwise not to check.
    integer validToken = ~llListFindList(tokens, [token]);
    string command = "";
    string setting = "";
    if(!validToken) {
        return("INVALID");
    }
    command = llGetSubString(token, 2, -3); //Extract Just the token.
    list anims = llParseString2List(rest, [], ["|"]);
    integer i;
    integer listLen = llGetListLength(anims);
    for(i=0; i<listLen; i++) {
        string anim = llList2String(anims, i);
        anim = osStringReplace(anim, "|", "\\|");
    }
    return(setting)
}

default {
    state_entry() {
        init();
    }
    link_message(integer sender_num, integer num, string text, key id) {
        command = llGetSubString(text, 0, llSubStringIndex(text, "|")-1);
        rest = llGetSubString(text, llSubStringIndex(text, "|")+1, -1);
        if(command == "LOAD_NC") {
            loadNoteCard(rest);
        }
        if(command == "GETSETTING") { //May need renamed.
            //returnSetting(rest);
        }
    }
}
