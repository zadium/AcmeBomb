/**
*   @author: Zai Dium

    @name: AcmeBomb
    @description:

    @version: 1.4
    @updated: "2023-12-01 15:50:09"
    @revision: 373
    @localfile: ?defaultpath\AcmeBomb\?@name.lsl
    @license: by-nc-sa [https://creativecommons.org/licenses/by-nc-sa/4.0/]
*/

integer SoundTime = 11; //* seconds
float After = 0.045; //* explode after
float Power = 1000;
float age = 4;
integer started = FALSE;
integer exploded = FALSE;

fire()
{
    //PSYS_SRC_TEXTURE, "Fire",

    llParticleSystem([
       PSYS_PART_FLAGS,
            PSYS_PART_INTERP_SCALE_MASK
            //| PSYS_PART_FOLLOW_VELOCITY_MASK
            | PSYS_PART_INTERP_COLOR_MASK
            | PSYS_PART_EMISSIVE_MASK
            //| PSYS_PART_RIBBON_MASK
            //| PSYS_PART_WIND_MASK
            ,
        PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_EXPLODE,

        PSYS_SRC_BURST_RADIUS,      0.5,
        PSYS_SRC_BURST_RATE,        0.1,
        PSYS_SRC_BURST_PART_COUNT,  20,

        PSYS_SRC_ANGLE_BEGIN,       -PI,
        PSYS_SRC_ANGLE_END,         PI,

        PSYS_PART_START_COLOR,      <0.5, 0.3, 0.1>,
        PSYS_PART_END_COLOR,        <0.5, 0.3, 0.1>,

        PSYS_PART_START_SCALE,      <0.5, 0.5, 0>,
        PSYS_PART_END_SCALE,        <2, 2, 0>,

        PSYS_SRC_BURST_SPEED_MIN,   0.5,
        PSYS_SRC_BURST_SPEED_MAX,   1,

        PSYS_SRC_MAX_AGE,           5,
        PSYS_SRC_ACCEL,             <0.0, 0.0, 0.0>,

        PSYS_SRC_OMEGA,             <0.2, 0.2, 0.2>,

        PSYS_PART_MAX_AGE,          1,

        PSYS_PART_START_GLOW,       0.05,
        PSYS_PART_END_GLOW,         0.01,

        PSYS_PART_START_ALPHA,      0.5,
        PSYS_PART_END_ALPHA,        0.8

    ]);
}

fuse()
{
    llParticleSystem([
        PSYS_PART_FLAGS,
            PSYS_PART_INTERP_COLOR_MASK
            | PSYS_PART_INTERP_SCALE_MASK
            | PSYS_PART_EMISSIVE_MASK
            | PSYS_PART_FOLLOW_VELOCITY_MASK
            | PSYS_PART_BOUNCE_MASK
//            | PSYS_PART_FOLLOW_SRC_MASK
        ,
        PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_ANGLE_CONE,
        PSYS_SRC_BURST_RADIUS,      0.08,
        PSYS_SRC_BURST_RATE,        0.1,
        PSYS_SRC_ANGLE_BEGIN,       -PI/25,
        PSYS_SRC_ANGLE_END,         PI/25,
        PSYS_SRC_BURST_PART_COUNT,  5,
        PSYS_SRC_BURST_SPEED_MIN,   0.05,
        PSYS_SRC_BURST_SPEED_MAX,   0.05,
        PSYS_SRC_ACCEL,             <0.0, 0.0, 0.0>,
        PSYS_SRC_OMEGA,             <0.0, 0.0, 0.1>,

        PSYS_PART_START_COLOR,      <0.967, 0.755, 0.033>,
        PSYS_PART_END_COLOR,        <1, 1, 1 >,
        PSYS_PART_START_GLOW,       0.01,
        PSYS_PART_END_GLOW,         0.00,
        PSYS_PART_START_ALPHA,      0.5,
        PSYS_PART_END_ALPHA,        0.2,
        PSYS_PART_START_SCALE,      <0.03, 0.03, 0.03>,
        PSYS_PART_END_SCALE,        <0.07, 0.07, 0.07>,
        PSYS_PART_MAX_AGE,          2
        ]);
}

push(key target_key, float power)
{
    vector target_pos = llList2Vector(llGetObjectDetails(target_key, [OBJECT_POS]), 0);
    float mass = llGetObjectMass(target_key);
    float dist = llFabs(llVecDist(target_pos, llGetPos()));
    vector v = llVecNorm(target_pos - llGetPos());

    /**ChatGPT3:
        k = k0 / e^(d/10)

        Where k0 is the strength of the bomb (i.e., the value of k when d = 0),
        e is the mathematical constant e (approximately 2.71828),
        and 10 is a scaling factor that determines how quickly k decreases with distance.

        You can adjust the value of 10 to control the rate of decrease.
    */
    float e = 2.71828;
    float p;
    if (dist>0)
        p = power/(llPow(e, (dist/10)));
    else
        p = power;
    llPushObject(target_key,( <0,0,1> +v*p)*mass, ZERO_VECTOR, FALSE); //* pushing in z too a lil
}

explode()
{
    llSensor("", NULL_KEY, AGENT | ACTIVE, 20.0, PI);
}

start()
{
    if (!started)
    {
        started = TRUE;
        llPlaySound("runaway", 1);
        llSleep(1);
        llSensorRemove();
        llSetTextureAnim( FALSE, 0, 1, 1, 1, 1, 0);
        llSetTextureAnim( ANIM_ON | SMOOTH | LOOP, 0, 1, 1, 1, 1, After);
        fuse();
        llPlaySound("fuse-explode", 1);
        llSetTimerEvent(SoundTime);
    }
}

reset()
{
    started = FALSE;
    exploded = FALSE;
    llSetAlpha(1, 0);
    llSetTextureAnim( FALSE, 0, 1, 1, 1, 1, 0);
    llParticleSystem([]);
    //llSensorRepeat("", NULL_KEY, AGENT | ACTIVE, 2, PI, 1);
    //llSensor("", NULL_KEY, AGENT, 20.0, PI);
}

default
{
    state_entry()
    {
        llSensorRemove();
        reset();
    }

    on_rez(integer number)
    {
        //llResetScript();
        reset();
        start();
    }

    touch_start(integer num_detected)
    {
        if (llGetOwner()==llDetectedKey(0))
            if (exploded)
                reset();
            else if (started)
                explode();
            else
                start();
    }

    timer()
    {
        explode();
    }

    sensor(integer number_detected)
    {
        if (started)
        {
            exploded = TRUE;
            llSetTimerEvent(0);
            llSetAlpha(0, 0);
            fire();
            if (Power>0)
            {
                integer c = 0;
                while (c<number_detected)
                {
                    key k = llDetectedKey(c);
                       push(k, Power);
                    c++;
                }
            }
            started = FALSE;
            llSleep(age);
            llDie();
        }
    }
}
