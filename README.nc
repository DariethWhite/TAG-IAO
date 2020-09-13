/////////////////////////////////////////////////////////////////////////////////////////////////////
// Main engine script - receives link messages from any interface script. Handles the core AO work
//
// Interface definition: The following link_message commands are handled by this script. All of
// these are sent in the string field. All other fields are ignored
//
// ZHAO_RESET                          Reset script
// ZHAO_LOAD|<notecardName>            Load specified notecard
// ZHAO_NEXTSTAND                      Switch to next stand
// ZHAO_STANDTIME|<time>               Time between stands. Specified in seconds, expects an integer.
//                                     0 turns it off
// ZHAO_AOON                           AO On
// ZHAO_AOOFF                          AO Off
// ZHAO_SITON                          Sit On
// ZHAO_SITOFF                         Sit Off
// ZHAO_RANDOMSTANDS                   Stands cycle randomly
// ZHAO_SEQUENTIALSTANDS               Stands cycle sequentially
// ZHAO_SETTINGS                       Prints status
// ZHAO_SITS                           Select a sit
// ZHAO_GROUNDSITS                     Select a ground sit
// ZHAO_WALKS                          Select a walk
//
// ZHAO_SITANYWHERE_ON                 Sit Anywhere mod On
// ZHAO_SITANYWHERE_OFF                Sit Anywhere mod Off
//
// ZHAO_TYPE_ON                        Typing AO On
// ZHAO_TYPE_OFF                       Typing AO Off
//
// ZHAO_TYPEKILL_ON                    Typing Killer On
// ZHAO_TYPEKILL_OFF                   Typing Killer Off
//
// ZHAO_STANDON                          Sit On
// ZHAO_STANDOFF                         Sit Off
//
// So, to send a command to the ZHAO-II engine, send a linked message:
//
//   llMessageLinked(LINK_SET, 0, "ZHAO_AOON", NULL_KEY);
//
// This script uses a listener on channel -91234. If other scripts are added to the ZHAO, make sure
// they don't use the same channel
/////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////
// New notecard format
//
/////////////////////////////////////////////////////////////////////////////////////////////////////
// Lines starting with a / are treated as comments and ignored. Blank lines are ignored. Valid lines
// look like this:
//
// [ Walking ]SexyWalk1|SexyWalk2|SexyWalk3
//
// The token (in this case, [ Walking ]) identifies the animation to be overridden. The rest is a
// list of animations, separated by the '|' (pipe) character. You can specify multiple animations
// for Stands, Walks, Sits, and GroundSits. Multiple animations on any other line will be ignored.
// You can have up to 12 animations each for Walks, Sits and GroundSits. There is no hard limit
// on the number of stands, but adding too many stands will make the script run out of memory and
// crash, so be careful. You can repeat tokens, so you can split the Stands up across multiple lines.
// Use the [ Standing ] token in each line, and the script will add the animation lists together.
//
// Advanced: Each 'animation name' can be a comma-separated list of animations, which will be played
// together. For example:
//
// [ Walking ]SexyWalk1UpperBody,SexyWalk1LowerBody|SexyWalk2|SexyWalk3
//
// Note the ',' between SexyWalk1UpperBody and SexyWalk1LowerBody - this tells ZHAO-II to treat these
// as a single 'animation' and play them together. The '|' between this 'animation' and SexyWalk2 tells
// ZHAO-II to treat SexyWalk2 and SexyWalk3 as separate walk animations. You can use this to layer
// animations on top of each other.
//
// Do not add any spaces around animation names!!!
//
// The token can be one of the following:
//
// [ Standing ]
// [ Walking ]
// [ Sitting ]
// [ Sitting On Ground ]
// [ Crouching ]
// [ Crouch Walking ]
// [ Landing ]
// [ Standing Up ]
// [ Falling ]
// [ Flying Down ]
// [ Flying Up ]
// [ Flying ]
// [ Flying Slow ]
// [ Hovering ]
// [ Jumping ]
// [ Pre Jumping ]
// [ Running ]
// [ Turning Right ]
// [ Turning Left ]
// [ Floating ]
// [ Swimming Forward ]
// [ Swimming Up ]
// [ Swimming Down ]
// [ Typing ]
//
// [ Settings ]
//
/////////////////////////////////////////////////////////////////////////////////////////////////////
