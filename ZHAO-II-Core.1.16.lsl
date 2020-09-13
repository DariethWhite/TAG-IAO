// TAG-ZHAO-II-Core - Stephan Kern(Darieth WHite)
// REworking the script to work with OS > 0.9
// Please see version history Version History.

// ZHAO-II-core - Ziggy Puff, 07/07

// CONSTANTS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Default notecard we read on script_entry
string defaultNoteCard = "Default";

// List of all the animation states
list animState = [ "Sitting on Ground", "Sitting", "Striding", "Crouching", "CrouchWalking",
                   "Soft Landing", "Standing Up", "Falling Down", "Hovering Down", "Hovering Up",
                   "FlyingSlow", "Flying", "Hovering", "Jumping", "PreJumping", "Running",
                   "Turning Right", "Turning Left", "Walking", "Landing", "Standing" ];


// Logic change - we now have a list of tokens. The 'overrides' list is the same
// length as this, i.e. it has one entry per token, *not* one entry per
// animation. Multiple options for a token are stored as | separated strings in
// a single list entry. This was done to save memory, and allow a larger number
// of stands etc. All the xxxIndex variables now refer to the token index, since
// that's how long 'overrides' is.  List of internal tokens. This *must* be in
// the same sequence as the animState list. Note that we combine some tokens
// after the notecard is read (striding/walking, landing/soft landing), etc. The
// publicized tokens list only contains one entry for each pair, but we'll
// accept both, and combine them later
//list tokens = [
//    "[ Sitting On Ground ]",    // 0
//    "[ Sitting ]",              // 1
//    "",                         // 2 - We don't allow Striding as a token
//    "[ Crouching ]",            // 3
//    "[ Crouch Walking ]",       // 4
//    "",                         // 5 - We don't allow Soft Landing as a token
//    "[ Standing Up ]",          // 6
//    "[ Falling ]",              // 7
//    "[ Flying Down ]",          // 8
//    "[ Flying Up ]",            // 9
//    "[ Flying Slow ]",          // 10
//    "[ Flying ]",               // 11
//    "[ Hovering ]",             // 12
//    "[ Jumping ]",              // 13
//    "[ Pre Jumping ]",          // 14
//    "[ Running ]",              // 15
//    "[ Turning Right ]",        // 16
//    "[ Turning Left ]",         // 17
//    "[ Walking ]",              // 18
//    "[ Landing ]",              // 19
//    "[ Standing ]",             // 20
//    "[ Swimming Down ]",        // 21
//    "[ Swimming Up ]",          // 22
//    "[ Swimming Forward ]",     // 23
//    "[ Floating ]",             // 24
//    "[ Typing ]"                // 25
//    "[ Settings ]"              // 26 this is new... we'll see how i can make it work
//];
//
//      |       |       |
//      |       |       |
//      V       V       V
//
integer numOverrides = 27;       // number of overrides == tokens

// The tokens for which we allow multiple animations
//list multiAnimTokenIndexes = [
//    0,  // "[ Sitting On Ground ]"
//    1,  // "[ Sitting ]"
//    18, // "[ Walking ]"
//    20  // "[ Standing ]"
//];

// Index of interesting animations
integer noAnimIndex     = -1;
integer sitgroundIndex  = 0;
integer sittingIndex    = 1;
integer stridingIndex   = 2;
integer standingupIndex = 6;
integer hoverdownIndex  = 8;
integer hoverupIndex    = 9;
integer flyingslowIndex = 10;
integer flyingIndex     = 11;
integer hoverIndex      = 12;
integer walkingIndex    = 18;
integer standingIndex   = 20;
integer swimdownIndex   = 21;
integer swimupIndex     = 22;
integer swimmingIndex   = 23;
integer waterTreadIndex = 24;
integer typingIndex     = 25;

// list of animations that have a different value when underwater
list underwaterAnim = [ "hoverIndex", "flyingIndex", "flyingslowIndex", "hoverupIndex", "hoverdownIndex" ];

// corresponding list of animations that we override the overrider with when underwater
list underwaterOverride = [ "waterTreadIndex", "swimmingIndex", "swimmingIndex", "swimupIndex", "swimdownIndex"];

// This is an ugly hack, because the standing up animation doesn't work quite
// right (SL is borked, this has been bug reported) If you play a pose overtop
// the standing up animation, your avatar tends to get stuck in place. This is a
// list of anims that we'll stop automatically
list autoStop = [ 5, 6, 19 ];
// Amount of time we'll wait before autostopping the animation (set to 0 to turn
// off autostopping)
float autoStopTime = 1.5;

// How long before flipping stand animations
integer standTimeDefault = 30;

// How fast we should poll for changed anims (as fast as possible)
// In practice, you will not poll more than 8 times a second.
float timerEventLength = 0.25;

// The minimum time between events.
// While timerEvents are scaled automatically by the server, control events
// are processed much more aggressively, and needs to be throttled by this
// script
float minEventDelay = 0.25;

// The key for the typing animation
//      key typingAnim      =       "c541c47f-e0c0-058b-ad1a-d6ae3a4584d9";
// we dont need this right now ;)

// Listen channel for pop-up menu
//
// Mod: Channel will now be generated from owner UUID.
integer listenChannel = -1; //-91234;

// GLOBALS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

integer typingStatus = FALSE;               // status of avatar typing

integer numTyping;                          // Number of typing anims
integer numStands;                          // Number of stands - needed for auto cycle
integer randomStands = FALSE;               // Whether stands cycle randomly
integer curStandIndex;                      // Current stand - needed for cycling
string curStandAnim = "";                   // Current Stand animation
string curSitAnim = "";                     // Current sit animation
string curWalkAnim = "";                    // Current walk animation
string curGsitAnim = "";                    // Current ground sit animation
string curTypingAnim = "";                  // Current typing animation

list overrides = [];                        // List of animations we override

string  lastAnim = "";                      // last Animation we ever played
string  lastAnimSet = "";                   // last set of animations we ever played
integer lastAnimIndex = 0;                  // index of the last animation we ever played
string  lastAnimState = "";                 // last thing llGetAnimation() returned

integer dialogStandTime = 30;       // How long before flipping stand animations
integer standTime = 30;       // How long before flipping stand animations

integer animOverrideOn = TRUE;              // Is the animation override on?
integer gotPermission  = FALSE;             // Do we have animation permissions?

integer listenHandle;                       // Listen handlers - only used for pop-up menu, then turned off

integer haveWalkingAnim = FALSE;            // Hack to get it so we face the right way when we walk backwards

integer sitOverride = TRUE;                 // Whether we're overriding sit or not
integer standOverride = TRUE;                 // Whether we're overriding sit or not
integer typingOverrideOn = TRUE;            // Whether we're overriding typing or not
integer typingKill = FALSE;                 // Whether we're killing the typing completely
integer mlAO = TRUE;                        // Whether AO is ON/OF in Mouselook
/// Sit Anywhere mod by Marcus Gray
/// just one var to overrider stands... let's see how this works out 0o
integer sitAnywhereOn = FALSE;

integer listenState = 0;                    // What pop-up menu we're handling now

integer loadInProgress = FALSE;             // Are we currently loading a notecard
string  notecardName = "";                  // The notecard we're currently reading

key Owner = NULL_KEY;

// String constants to save a few bytes
string EMPTY = "";
//
string TIMINGSEPARATOR = "²Ø";
//
string SEPARATOR = "|";
string TRYAGAIN = "Please correct the notecard and try again.";
string S_SIT = "Sit override: ";
string S_SIT_AW = "Sit anywhere: ";
string S_TYPING = "Typing override: ";
string S_TKILL_ON = "Typing killer: On - This also removes custom typing animations!";
string S_TKILL_OFF = "Typing killer: Off";

//////////////////////////////////////////////////////////////////////////
/// Seamless Sit mod by Moeka Kohime
///
integer em;
list temp;
key sit = "1a5fe8ac-a804-8a5d-7cbd-56bd83184568";

// CODE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
/// Seamless Sit mod by Moeka Kohime
integer CheckSit()
{
    if(!sitOverride)
        return FALSE;
    temp = llGetAnimationList(llGetOwner());
    if (temp==[])
        return FALSE;
    if (llListFindList(temp,[sit])!=-1)
        return TRUE;
    return FALSE;
}


startAnimationList(string _csvAnims) {
    list anims = llCSV2List(_csvAnims);
    integer i;
    for(i=0; i<llGetListLength(anims); i++)
    {
//
//  Mod: Get the special timing parameter
        list newAnim = llParseStringKeepNulls(llList2String(anims,i), [TIMINGSEPARATOR], []);
        string newAnimName = llList2String(newAnim, 0);


        if(llGetListLength(newAnim) == 2)
        {
            integer newStandTime = (integer)llList2String(newAnim, 1);
            if(newStandTime > 0)
                standTime = (integer)llList2String(newAnim, 1);
            else
                llOwnerSay("Found improper custom timing parameter for animation \""+ newAnimName + "\" - The value must be greater 0, please correct this!");
        }
        else
            standTime = dialogStandTime;
//
//
//        llStartAnimation(llList2String(anims,i));
        llStartAnimation(newAnimName);
    }
}

stopAnimationList(string _csvAnims) {
    list anims = llCSV2List(_csvAnims);
    integer i;
    for(i=0; i<llGetListLength(anims); i++)
    {
//
//  Mod: Get the special timing parameter
        list newAnim = llParseStringKeepNulls(llList2String(anims,i) ,
            [TIMINGSEPARATOR], [""]);
        string newAnimName = llList2String(newAnim, 0);
//
//
//        llStopAnimation(llList2String(anims,i));
        llStopAnimation(newAnimName);
    }
}

startNewAnimation(string _anim, integer _animIndex, string _state) {
    if(_anim != lastAnimSet) {
        string newAnim;
        if(lastAnim != EMPTY)
            stopAnimationList(lastAnim);
        if(_anim != EMPTY) {   // Time to play a new animation
             list newAnimSet = llParseStringKeepNulls(_anim, [SEPARATOR], []);
             newAnim = llList2String(newAnimSet, (integer)llFloor(llFrand(llGetListLength(newAnimSet))));

             startAnimationList(newAnim);

            if(llListFindList(autoStop, [_animIndex]) != -1) {
                // This is an ugly hack, because the standing up animation doesn't work quite right
                // (SL is borked, this has been bug reported)
                // If you play a pose overtop the standing up animation, your avatar tends to get
                // stuck in place.
                if(lastAnim != EMPTY) {
                   stopAnimationList(lastAnim);
                   lastAnim = EMPTY;
                }
                llSleep(autoStopTime);
                stopAnimationList(_anim);
            }
        }
        lastAnim = newAnim;
        lastAnimSet = _anim;
    }
    lastAnimIndex = _animIndex;
    lastAnimState = _state;
}

// Figure out what animation we should be playing right now
animOverride() {
    string  curAnimState = llGetAnimation(Owner);
    integer curAnimIndex;
    integer underwaterAnimIndex;

    // Convert the ones we don't handle
    if(curAnimState == "Striding") {
        curAnimState = "Walking";
    } else if(curAnimState == "Soft Landing") {
        curAnimState = "Landing";
    }

    // Remove the list check, since it only contains one element
    // Check if we need to work around any bugs in llGetAnimation
    // Hack, because, SL really likes to switch between crouch and crouchwalking for no reason
    if(curAnimState == "CrouchWalking") {
      if(llVecMag(llGetVel()) < .5)
         curAnimState = "Crouching";
    }

    if(curAnimState == lastAnimState && curAnimState != "Walking") {
        // This conditional not absolutely necessary (In fact it's better if it's not here)
        // But it's good for increasing performance.
        // One of the drawbacks of this performance hack is the underwater animations
        // If you fly up, it will keep playing the "swim up" animation even after you've
        // left the water.
        if(CheckSit()!=TRUE) {// Seamless Sit
            em=0;
            return;
        }else{
            if(em==0){startNewAnimation(EMPTY, noAnimIndex, curAnimState);em=1;}
        }
    }

    curAnimIndex        = llListFindList(animState, [curAnimState]);
    underwaterAnimIndex = llListFindList(underwaterAnim, [curAnimIndex]);

    // For all the multi-anims, we know the animation name to play. Send
    // in the actual overrides index, since that's what this function
    // expects, not the index into the multi-anim list
    if(curAnimIndex == standingIndex) {
        // Sit Anywhere
        if(sitAnywhereOn) {
            startNewAnimation(curGsitAnim, sitgroundIndex, curAnimState);
        }
        else
        {
            if(standOverride){ // Sity Anywhere is OFF AND Stand AO is on ;)
                startNewAnimation(curStandAnim, standingIndex, curAnimState);
            }
            else {
                 startNewAnimation(EMPTY, noAnimIndex, curAnimState);
            }
        }

    }
    else if(curAnimIndex == sittingIndex) {
        // Check if sit override is turned off
        if ((sitOverride == FALSE) && (curAnimState == "Sitting") && (CheckSit() != TRUE)) {// Seamless Sit
            startNewAnimation(EMPTY, noAnimIndex, curAnimState);
        }
        else {
            if(CheckSit()==TRUE){// Seamless Sit
            startNewAnimation(curSitAnim, sittingIndex, curAnimState);
            } else {
            startNewAnimation(EMPTY, noAnimIndex, curAnimState);
            }
        }
    }
    else if(curAnimIndex == walkingIndex) {
        startNewAnimation(curWalkAnim, walkingIndex, curAnimState);
    }
    else if(curAnimIndex == sitgroundIndex) {
        startNewAnimation(curGsitAnim, sitgroundIndex, curAnimState);
    }
    else {
        if(underwaterAnimIndex != -1) {
            // Only call llGetPos if we care about underwater anims
            vector curPos = llGetPos();
            if(llWater(ZERO_VECTOR) > curPos.z) {
                curAnimIndex = llList2Integer(underwaterOverride, underwaterAnimIndex);
            }
        }
        startNewAnimation(llList2String(overrides, curAnimIndex), curAnimIndex, curAnimState);
    }
}

// Switch to the next stand anim
doNextStand(integer fromUI) {
    if(numStands > 0) {
        if(!sitAnywhereOn && standOverride) { //no need to change stands if we're sitting anyways ;)
            if(randomStands) {
                curStandIndex = llFloor(llFrand(numStands));
            } else {
                curStandIndex = (curStandIndex + 1) % numStands;
            }

            curStandAnim = findMultiAnim(standingIndex, curStandIndex);
            if(lastAnimState == "Standing")
                startNewAnimation(curStandAnim, standingIndex, lastAnimState);

            if(fromUI == TRUE) {
                string newAnimName = llList2String(
                    llParseStringKeepNulls(curStandAnim, [TIMINGSEPARATOR], []), 0);
                llOwnerSay("Switching to stand '" + newAnimName + "'.");
            }
        }
    } else {
        if(fromUI == TRUE) {
            llOwnerSay("No stand animations configured.");
        }
    }

    llResetTime();
}

// Start or stop typing animation
typingOverride(integer isTyping) {
    if(isTyping) {
        // if we totally kill typing anims
        if(typingKill){
            llStopAnimation("type");
            //typingStatus = FALSE;
        }
        else {
            integer curTypingIndex = 0;
            if(numTyping > 1){
                curTypingIndex = llFloor(llFrand(numTyping));
            }
            curTypingAnim = findMultiAnim(typingIndex, curTypingIndex);
            startAnimationList(curTypingAnim);
        }
    }
    else if(!typingKill){
        stopAnimationList(curTypingAnim);
    }
}

// Displays menu of animation choices
doMultiAnimMenu(integer _animIndex, string _animType, string _currentAnim) {
    // Dialog enhancement - Fennec Wind
    // Fix - a no-mod anim with a long name will break this

    list anims = llParseString2List(llList2String(overrides, _animIndex), [SEPARATOR], []);
    integer numAnims = llGetListLength(anims);
    if(numAnims > 12) {
        llOwnerSay("Too many animations, only the first 12 will be displayed.");
        numAnims = 12;
        return;
    }

    list buttons = [];
    integer i;
    string animNames = EMPTY;
    for(i=0; i<numAnims; i++){
        animNames += "\n" + (string)(i+1) + ". " + llList2String(anims, i);
        buttons += [(string)(i+1)];
    }
    // If no animations were configured, say so and just display an "OK" button
    if(animNames == EMPTY){
        animNames = "\n\nNo overrides have been configured.";
    }
    llListenControl(listenHandle, TRUE);
    llDialog(Owner, "Select the " + _animType + " animation to use:\n\nCurrently: " + _currentAnim + animNames,
              buttons, listenChannel);
}

// Returns an animation from the multiAnims
string findMultiAnim (integer _animIndex, integer _multiAnimIndex){
    list animsList = llParseString2List(llList2String(overrides, _animIndex), [SEPARATOR], []);
    return llList2String(animsList, _multiAnimIndex);
}

// Returns true if we should override the current animation
integer checkAndOverride() {
    if(animOverrideOn && gotPermission){
        animOverride();
        return TRUE;
    }
    return FALSE;
}

// Load all the animation names from a notecard
loadNoteCard(){
    if(llGetInventoryKey(notecardName) == NULL_KEY) {
        llOwnerSay("Notecard '" + notecardName + "' does not exist, or does not have full permissions.");
        notecardName = EMPTY;
        loadInProgress = FALSE;
        return;
    }
    else{
        loadInProgress = TRUE;
        // Faster events while processing our notecard
        llMinEventDelay(0);
        // Clear out saved override information, since we now allow sparse notecards
        overrides = [];
        integer i;
        for(i=0; i<numOverrides; i++)
            overrides += [EMPTY];
        // Clear out multi-anim info as well, since we may end up with fewer options
        // that the last time
        curStandIndex = 0;
        curStandAnim = EMPTY;
        curSitAnim = EMPTY;
        curWalkAnim = EMPTY;
        curGsitAnim = EMPTY;
        // Start reading the data
        llMessageLinked(LINK_SET, 0, "LOAD_NC|" + notecardName, NULL_KEY);
    }
}

// Stop loading notecard
endNotecardLoad() {
    loadInProgress = FALSE;
    notecardName = EMPTY;
    // Restore the minimum event delay
    llMinEventDelay(minEventDelay);
}

// Initialize listeners, and reset some status variables
initialize(){
    Owner = llGetOwner();
    llSetTimerEvent(0.0);
    if(animOverrideOn)
        llSetTimerEvent(timerEventLength);

    lastAnim = EMPTY;
    lastAnimSet = EMPTY;
    lastAnimIndex = noAnimIndex;
    lastAnimState = EMPTY;
    gotPermission = TRUE;

    // Create new listener, and turn it off
    if(listenHandle)
        llListenRemove(listenHandle);

    listenHandle = llListen(listenChannel, EMPTY, Owner, EMPTY);
    llListenControl(listenHandle, FALSE);
}

// STATE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

default {
    state_entry() {
        integer i;

        Owner = llGetOwner();

        // Just a precaution, this shouldn't be on after a reset
        if(listenHandle)
            llListenRemove(listenHandle);

        // Generate the channel from the owner UUID.
        listenChannel = (1 + (integer)("0xF" + llGetSubString(llGetOwner(), 0, 6)));

        listenHandle = llListen(listenChannel, EMPTY, Owner, EMPTY);

        if(llGetAttached())
            llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION|PERMISSION_TAKE_CONTROLS);
        // populate override list with blanks
        overrides = [];
        for (i=0; i<numOverrides; i++) {
            overrides += [ EMPTY ];
        }
        randomStands = FALSE;
        initialize();
        notecardName = defaultNoteCard;
        loadInProgress = TRUE;
        loadNoteCard();

        // turn off the auto-stop anim hack
        if(autoStopTime == 0)
            autoStop = [];

        llResetTime();
    }

    on_rez(integer _code) {
        initialize();
    }

    attach(key _k) {
        if(_k != NULL_KEY)
            llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION|PERMISSION_TAKE_CONTROLS);
    }

    run_time_permissions(integer _perm) {
      if(_perm != (PERMISSION_TRIGGER_ANIMATION|PERMISSION_TAKE_CONTROLS))
         gotPermission = FALSE;
      else {
         llTakeControls(CONTROL_BACK|CONTROL_FWD, TRUE, TRUE);
         gotPermission = TRUE;
      }
    }

    link_message(integer _sender, integer _num, string _message, key _id) {

        // Coming from an interface script
        if(_message == "ZHAO_RESET") {
            llOwnerSay("Resetting...");
            llResetScript();

        }
        else if(_message == "ZHAO_AOON") {
            // AO On
            llOwnerSay("ON");
            llSetTimerEvent(timerEventLength);
            animOverrideOn = TRUE;
            checkAndOverride();

        }
        else if(_message == "ZHAO_AOOFF") {
            //AO OFF
            llOwnerSay("OFF");
            llSetTimerEvent(0.0);
            animOverrideOn = FALSE;
            startNewAnimation(EMPTY, noAnimIndex, lastAnimState);
            lastAnim = EMPTY;
            lastAnimSet = EMPTY;
            lastAnimIndex = noAnimIndex;
            lastAnimState = EMPTY;

        }
        else if(_message == "ZHAO_STANDON") {
            // Turning on sit override
            standOverride = TRUE;
            llOwnerSay("Stand AO On");
            if(lastAnimState == "Standing")
                startNewAnimation(curStandAnim, standingIndex, lastAnimState);

        }
        else if(_message == "ZHAO_STANDOFF") {
            // Turning off sit override
            standOverride = FALSE;
            llOwnerSay("Stand AO Off");
            if(lastAnimState == "Standing")
                startNewAnimation(EMPTY, noAnimIndex, lastAnimState);

        }
        else if(_message == "ZHAO_SITON") {
            // Turning on sit override
            sitOverride = TRUE;
            llOwnerSay(S_SIT + "On");
            if(lastAnimState == "Sitting")
                startNewAnimation(curSitAnim, sittingIndex, lastAnimState);

        }
        else if(_message == "ZHAO_SITOFF") {
            // Turning off sit override
            sitOverride = FALSE;
            llOwnerSay(S_SIT + "Off");
            if(lastAnimState == "Sitting")
                startNewAnimation(EMPTY, noAnimIndex, lastAnimState);

        }
        else if(_message == "ZHAO_SITANYWHERE_ON") {
            // Turning on sit anywhre mod
            sitAnywhereOn = TRUE;
            llOwnerSay(S_SIT_AW + "On");
            if(lastAnimState == "Standing")
                startNewAnimation(curGsitAnim, sitgroundIndex, lastAnimState);

        }
        else if(_message == "ZHAO_SITANYWHERE_OFF") {
            // Turning off sit anywhere mod
            sitAnywhereOn = FALSE;
            llOwnerSay(S_SIT_AW + "Off");
            if(lastAnimState == "Standing")
                startNewAnimation(curStandAnim, standingIndex, lastAnimState);

        }
        else if(_message == "ZHAO_TYPEAO_ON") {
            // Turning on typing override
            typingOverrideOn = TRUE;
            llOwnerSay(S_TYPING + "On");
            typingStatus = FALSE;

        }
        else if(_message == "ZHAO_TYPEAO_OFF") {
            // Turning off typing override
            typingOverrideOn = FALSE;
            llOwnerSay(S_TYPING + "Off");
            if(typingStatus && !typingKill) {
                stopAnimationList(curTypingAnim);
                typingStatus = FALSE;
            }
        }
        else if(_message == "ZHAO_TYPEKILL_ON") {
            // Turning on Typing killer
            typingKill = TRUE;
            llOwnerSay(S_TKILL_ON);
            typingStatus = FALSE;
        }
        else if(_message == "ZHAO_TYPEKILL_OFF") {
            // Turning off Typing killer
            typingKill = FALSE;
            llOwnerSay(S_TKILL_OFF);
            typingStatus = FALSE;
        }
        else if(_message == "ZHAO_RANDOMSTANDS") {
            // Cycling to next stand - sequential or random
            randomStands = TRUE;
            llOwnerSay("Stand cycling: Random");

        }
        else if(_message == "ZHAO_SEQUENTIALSTANDS") {
            // Cycling to next stand - sequential or random
            randomStands = FALSE;
            llOwnerSay("Stand cycling: Sequential");

        }
        else if(_message == "ZHAO_SETTINGS") {
            // Print settings
            if(sitOverride) {
                llOwnerSay(S_SIT + "On");
            }
            else {
                llOwnerSay(S_SIT + "Off");
            }
            if(sitAnywhereOn) {
                llOwnerSay(S_SIT_AW + "On");
            }
            else {
                llOwnerSay(S_SIT_AW + "Off");
            }
            if(typingOverrideOn) {
                llOwnerSay(S_TYPING + "On");
            }
            else {
                llOwnerSay(S_TYPING + "Off");
            }
            if(typingKill) {
                llOwnerSay(S_TKILL_ON);
            }
            else {
                llOwnerSay(S_TKILL_OFF);
            }
            if(randomStands) {
                llOwnerSay("Stand cycling: Random");
            }
            else {
                llOwnerSay("Stand cycling: Sequential");
            }
            llOwnerSay("Stand cycle time: " + (string)dialogStandTime + " seconds");

        }
        else if(_message == "ZHAO_NEXTSTAND") {
            // Cycling to next stand - sequential or random. This is from UI, so we
            // want feedback
            doNextStand(TRUE);

        }
        else if(llGetSubString(_message, 0, 14) == "ZHAO_STANDTIME|") {
            // Stand time change
            dialogStandTime = (integer)llGetSubString(_message, 15, -1);
            llOwnerSay("Stand cycle time: " + (string)dialogStandTime + " seconds");

        }
        else if(llGetSubString(_message, 0, 9) == "ZHAO_LOAD|") {
            // Can't load while we're in the middle of a load
            if(loadInProgress == TRUE) {
                llOwnerSay("Cannot load new notecard, still reading notecard '" + notecardName + "'");
                return;
            }

            // Notecard menu
            notecardName = llGetSubString(_message, 10, -1);
            loadNoteCard();

        }
        else if(_message == "ZHAO_SITS") {
            // Selecting new sit anim

            // Move these to a common function
            doMultiAnimMenu(sittingIndex, "Sitting", curSitAnim);

            listenState = 1;

        }
        else if(_message == "ZHAO_WALKS") {
            // Same thing for the walk

            // Move these to a common function
            doMultiAnimMenu(walkingIndex, "Walking", curWalkAnim);

            listenState = 2;

        }
        else if(_message == "ZHAO_GROUNDSITS") {
            // And the ground sit

            // Move these to a common function
            doMultiAnimMenu(sitgroundIndex, "Sitting On Ground", curGsitAnim);

            listenState = 3;
        }


        //Notecard read, we get the string sent over and do some tests
        else if(llGetSubString(_message, 0, 11) == "END_NC_LOAD|") {
            //if loading was a success...
            if(_num) {
                overrides = [];
                //convert overrides back to a list
                overrides = llCSV2List(llGetSubString(_message, 12, llStringLength(_message) - 1));
                // Do we have a walking animation?
                if(llList2String(overrides, walkingIndex) != EMPTY) {
                     haveWalkingAnim = TRUE;
                }
                // Reset stand, walk, sit and ground-sit anims to first entry
                curStandIndex = 0;
                numStands = llGetListLength(llParseString2List(llList2String(overrides, standingIndex),
                                             [SEPARATOR], []));

                numTyping = llGetListLength(llParseString2List(llList2String(overrides, typingIndex),
                                             [SEPARATOR], []));

                curStandAnim = findMultiAnim(standingIndex, 0);
                curWalkAnim = findMultiAnim(walkingIndex, 0);
                curSitAnim = findMultiAnim(sittingIndex, 0);
                curGsitAnim = findMultiAnim(sitgroundIndex, 0);

                // Clear out the currently playing anim so we play the new one on the next cycle
                startNewAnimation(EMPTY, noAnimIndex, lastAnimState);
                lastAnim = EMPTY;
                lastAnimSet = EMPTY;
                lastAnimIndex = noAnimIndex;
                lastAnimState = EMPTY;

                llOwnerSay("Finished reading notecard '" + notecardName + "'.");
                printFreeMemory();
            }
            endNotecardLoad();
        }
    }

    listen(integer _channel, string _name, key _id, string _message) {
        // Turn listen off. We turn it on again if we need to present
        // another menu
        llListenControl(listenHandle, FALSE);

        if(listenState == 1) {
            // Dialog enhancement - Fennec Wind
            // Note that this is within one 'overrides' entry
            curSitAnim = findMultiAnim(sittingIndex, (integer)_message - 1);
            if(lastAnimState == "Sitting") {
                startNewAnimation(curSitAnim, sittingIndex, lastAnimState);
            }
            llOwnerSay("New sitting animation: " + curSitAnim);

        }
        else if(listenState == 2) {
            // Dialog enhancement - Fennec Wind
            // Note that this is within one 'overrides' entry
            curWalkAnim = findMultiAnim(walkingIndex, (integer)_message - 1);
            if(lastAnimState == "Walking") {
                startNewAnimation(curWalkAnim, walkingIndex, lastAnimState);
            }
            llOwnerSay("New walking animation: " + curWalkAnim);

        }
        else if(listenState == 3) {
            // Dialog enhancement - Fennec Wind
            // Note that this is within one 'overrides' entry
            curGsitAnim = findMultiAnim(sitgroundIndex, (integer)_message - 1);
            // Lowercase 'on' - that's the anim name in SL
            if(lastAnimState == "Sitting on Ground" || (lastAnimState == "Standing" && sitAnywhereOn)) {
                startNewAnimation(curGsitAnim, sitgroundIndex, lastAnimState);
            }
            llOwnerSay("New sitting on ground animation: " + curGsitAnim);
        }
    }

    changed(integer _change) {
        if(_change & CHANGED_TELEPORT) {
            lastAnimSet = EMPTY;
            lastAnimState = EMPTY;
            checkAndOverride();
        }
    }

    collision_start(integer _num) {
        checkAndOverride();
    }

    collision(integer _num) {
    //   checkAndOverride();
    }

    collision_end(integer _num) {
       checkAndOverride();
    }

    control(key _id, integer _level, integer _edge) {
        if(_edge) {
            // SL tends to mix animations together on forward or backward walk. It could be because
            // of anim priorities. This helps stop the default walking anims, so it won't mix with
            // the desired anim. This also lets the avi turn around on a backwards walk for a more natural
            // look.
            // Reverse the order of the checks, since we'll often get the control key combination, but we
            // may be flying
            if(llGetAnimation(Owner) == "Walking") {
                if(_level & _edge & (CONTROL_BACK | CONTROL_FWD)) {
                    if(haveWalkingAnim) {
                        llStopAnimation("walk");
                        llStopAnimation("female_walk");
                    }
                }
            }

            checkAndOverride();
        }
    }

    timer() {
        // TYPING AO!!!!!!!!!!!
        if((numTyping > 0 && typingOverrideOn) || typingKill) {
            integer typingTemp = llGetAgentInfo(Owner) & AGENT_TYPING; // are we typing?
            if(typingTemp != typingStatus) { //status changed since last checked?
                typingOverride(typingTemp);
                typingStatus = typingTemp;//save the current status.
            }
        }
        if(checkAndOverride()) {
            // Is it time to switch stand animations?
            // Stand cycling can be turned off
            if((standTime != 0) && (llGetTime() > standTime)) {
                // Don't interrupt the typing animation with a stand change.
                // Not from UI, no feedback
                if(!typingStatus)
                    doNextStand(FALSE);
            }
        }
    }
}
