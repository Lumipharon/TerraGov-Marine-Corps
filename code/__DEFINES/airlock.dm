// Airlock light states, used for generating the light overlays
#define AIRLOCK_LIGHT_BOLTS "bolts"
#define AIRLOCK_LIGHT_EMERGENCY "emergency"
#define AIRLOCK_LIGHT_DENIED "denied"
#define AIRLOCK_LIGHT_CLOSING "closing"
#define AIRLOCK_LIGHT_OPENING "opening"

// Airlock physical states
#define AIRLOCK_CLOSED 1
#define AIRLOCK_CLOSING 2
#define AIRLOCK_OPEN 3
#define AIRLOCK_OPENING 4
#define AIRLOCK_DENY 5
#define AIRLOCK_EMAG 6

//defines to be used with the door's open()/close() procs in order to discriminate what type of open is being done. The door will never open if it's been physically disabled (i.e. welded, sealed, etc.).
/// We should go through the door's normal opening procedure, no overrides.
#define DEFAULT_DOOR_CHECKS 0
/// We're not going through the door's normal opening procedure, we're forcing it open. Can still fail if it's emagged or something. Costs power.
#define FORCING_DOOR_CHECKS 1
/// We are getting this door open if it has not been physically held shut somehow. Play a special sound to signify this level of opening.
#define BYPASS_DOOR_CHECKS 2
