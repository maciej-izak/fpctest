{
     File:       AudioUnitParameters.h
 
     Contains:   Parameter constants for Apple AudioUnits
 
     Copyright:  (c) 2002-2008 by Apple Inc., all rights reserved.
 
     Bugs?:      For bug reports, consult the following page on
                 the World Wide Web:
 
                     http://www.freepascal.org/bugs.html
 
}
{	  Pascal Translation:  Gorazd Krosl <gorazd_1957@yahoo.ca>, October 2009 }

{
    Modified for use with Free Pascal
    Version 308
    Please report any bugs to <gpc@microbizz.nl>
}

{$ifc not defined MACOSALLINCLUDE or not MACOSALLINCLUDE}
{$mode macpas}
{$packenum 1}
{$macro on}
{$inline on}
{$calling mwpascal}

unit AudioUnitParameters;
interface
{$setc UNIVERSAL_INTERFACES_VERSION := $0400}
{$setc GAP_INTERFACES_VERSION := $0308}

{$ifc not defined USE_CFSTR_CONSTANT_MACROS}
    {$setc USE_CFSTR_CONSTANT_MACROS := TRUE}
{$endc}

{$ifc defined CPUPOWERPC and defined CPUI386}
	{$error Conflicting initial definitions for CPUPOWERPC and CPUI386}
{$endc}
{$ifc defined FPC_BIG_ENDIAN and defined FPC_LITTLE_ENDIAN}
	{$error Conflicting initial definitions for FPC_BIG_ENDIAN and FPC_LITTLE_ENDIAN}
{$endc}

{$ifc not defined __ppc__ and defined CPUPOWERPC32}
	{$setc __ppc__ := 1}
{$elsec}
	{$setc __ppc__ := 0}
{$endc}
{$ifc not defined __ppc64__ and defined CPUPOWERPC64}
	{$setc __ppc64__ := 1}
{$elsec}
	{$setc __ppc64__ := 0}
{$endc}
{$ifc not defined __i386__ and defined CPUI386}
	{$setc __i386__ := 1}
{$elsec}
	{$setc __i386__ := 0}
{$endc}
{$ifc not defined __x86_64__ and defined CPUX86_64}
	{$setc __x86_64__ := 1}
{$elsec}
	{$setc __x86_64__ := 0}
{$endc}
{$ifc not defined __arm__ and defined CPUARM}
	{$setc __arm__ := 1}
{$elsec}
	{$setc __arm__ := 0}
{$endc}

{$ifc defined cpu64}
  {$setc __LP64__ := 1}
{$elsec}
  {$setc __LP64__ := 0}
{$endc}


{$ifc defined __ppc__ and __ppc__ and defined __i386__ and __i386__}
	{$error Conflicting definitions for __ppc__ and __i386__}
{$endc}

{$ifc defined __ppc__ and __ppc__}
	{$setc TARGET_CPU_PPC := TRUE}
	{$setc TARGET_CPU_PPC64 := FALSE}
	{$setc TARGET_CPU_X86 := FALSE}
	{$setc TARGET_CPU_X86_64 := FALSE}
	{$setc TARGET_CPU_ARM := FALSE}
	{$setc TARGET_OS_MAC := TRUE}
	{$setc TARGET_OS_IPHONE := FALSE}
	{$setc TARGET_IPHONE_SIMULATOR := FALSE}
{$elifc defined __ppc64__ and __ppc64__}
	{$setc TARGET_CPU_PPC := TFALSE}
	{$setc TARGET_CPU_PPC64 := TRUE}
	{$setc TARGET_CPU_X86 := FALSE}
	{$setc TARGET_CPU_X86_64 := FALSE}
	{$setc TARGET_CPU_ARM := FALSE}
	{$setc TARGET_OS_MAC := TRUE}
	{$setc TARGET_OS_IPHONE := FALSE}
	{$setc TARGET_IPHONE_SIMULATOR := FALSE}
{$elifc defined __i386__ and __i386__}
	{$setc TARGET_CPU_PPC := FALSE}
	{$setc TARGET_CPU_PPC64 := FALSE}
	{$setc TARGET_CPU_X86 := TRUE}
	{$setc TARGET_CPU_X86_64 := FALSE}
	{$setc TARGET_CPU_ARM := FALSE}
{$ifc defined(iphonesim)}
 	{$setc TARGET_OS_MAC := FALSE}
	{$setc TARGET_OS_IPHONE := TRUE}
	{$setc TARGET_IPHONE_SIMULATOR := TRUE}
{$elsec}
	{$setc TARGET_OS_MAC := TRUE}
	{$setc TARGET_OS_IPHONE := FALSE}
	{$setc TARGET_IPHONE_SIMULATOR := FALSE}
{$endc}
{$elifc defined __x86_64__ and __x86_64__}
	{$setc TARGET_CPU_PPC := FALSE}
	{$setc TARGET_CPU_PPC64 := FALSE}
	{$setc TARGET_CPU_X86 := FALSE}
	{$setc TARGET_CPU_X86_64 := TRUE}
	{$setc TARGET_CPU_ARM := FALSE}
	{$setc TARGET_OS_MAC := TRUE}
	{$setc TARGET_OS_IPHONE := FALSE}
	{$setc TARGET_IPHONE_SIMULATOR := FALSE}
{$elifc defined __arm__ and __arm__}
	{$setc TARGET_CPU_PPC := FALSE}
	{$setc TARGET_CPU_PPC64 := FALSE}
	{$setc TARGET_CPU_X86 := FALSE}
	{$setc TARGET_CPU_X86_64 := FALSE}
	{$setc TARGET_CPU_ARM := TRUE}
	{ will require compiler define when/if other Apple devices with ARM cpus ship }
	{$setc TARGET_OS_MAC := FALSE}
	{$setc TARGET_OS_IPHONE := TRUE}
	{$setc TARGET_IPHONE_SIMULATOR := FALSE}
{$elsec}
	{$error __ppc__ nor __ppc64__ nor __i386__ nor __x86_64__ nor __arm__ is defined.}
{$endc}

{$ifc defined __LP64__ and __LP64__ }
  {$setc TARGET_CPU_64 := TRUE}
{$elsec}
  {$setc TARGET_CPU_64 := FALSE}
{$endc}

{$ifc defined FPC_BIG_ENDIAN}
	{$setc TARGET_RT_BIG_ENDIAN := TRUE}
	{$setc TARGET_RT_LITTLE_ENDIAN := FALSE}
{$elifc defined FPC_LITTLE_ENDIAN}
	{$setc TARGET_RT_BIG_ENDIAN := FALSE}
	{$setc TARGET_RT_LITTLE_ENDIAN := TRUE}
{$elsec}
	{$error Neither FPC_BIG_ENDIAN nor FPC_LITTLE_ENDIAN are defined.}
{$endc}
{$setc ACCESSOR_CALLS_ARE_FUNCTIONS := TRUE}
{$setc CALL_NOT_IN_CARBON := FALSE}
{$setc OLDROUTINENAMES := FALSE}
{$setc OPAQUE_TOOLBOX_STRUCTS := TRUE}
{$setc OPAQUE_UPP_TYPES := TRUE}
{$setc OTCARBONAPPLICATION := TRUE}
{$setc OTKERNEL := FALSE}
{$setc PM_USE_SESSION_APIS := TRUE}
{$setc TARGET_API_MAC_CARBON := TRUE}
{$setc TARGET_API_MAC_OS8 := FALSE}
{$setc TARGET_API_MAC_OSX := TRUE}
{$setc TARGET_CARBON := TRUE}
{$setc TARGET_CPU_68K := FALSE}
{$setc TARGET_CPU_MIPS := FALSE}
{$setc TARGET_CPU_SPARC := FALSE}
{$setc TARGET_OS_UNIX := FALSE}
{$setc TARGET_OS_WIN32 := FALSE}
{$setc TARGET_RT_MAC_68881 := FALSE}
{$setc TARGET_RT_MAC_CFM := FALSE}
{$setc TARGET_RT_MAC_MACHO := TRUE}
{$setc TYPED_FUNCTION_POINTERS := TRUE}
{$setc TYPE_BOOL := FALSE}
{$setc TYPE_EXTENDED := FALSE}
{$setc TYPE_LONGLONG := TRUE}
uses MacTypes;
{$endc} {not MACOSALLINCLUDE}

{$ALIGN POWER}


//#pragma mark General Declarations

//#if !TARGET_OS_IPHONE
{$ifc not TARGET_OS_IPHONE}
{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The following specifies the equivalent parameterID's for the Group scope for standard
MIDI Controllers. This list is not exhaustive. It represents the parameters, and their corresponding 
MIDI messages, that should be supported in Group scope by MIDI capable AUs.

Group scope parameter IDs from 0 < 512 are reserved for mapping MIDI controllers.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ }
const
	kAUGroupParameterID_Volume = 7;	// value 0 < 128
	kAUGroupParameterID_Sustain = 64; 	// value 0-63 (off), 64-127 (on)
	kAUGroupParameterID_AllNotesOff = 123;	// value ignored
	kAUGroupParameterID_ModWheel = 1;	// value 0 < 128
	kAUGroupParameterID_PitchBend = $E0;	// value -8192 - 8191
	kAUGroupParameterID_AllSoundOff = 120;	// value ignored
	kAUGroupParameterID_ResetAllControllers = 121;	// value ignored
	kAUGroupParameterID_Pan = 10;	// value 0 < 128
	kAUGroupParameterID_Foot = 4;	// value 0 < 128
	kAUGroupParameterID_ChannelPressure = $D0;	// value 0 < 128
	kAUGroupParameterID_KeyPressure = $A0;	// values 0 < 128
	kAUGroupParameterID_Expression = 11;	// value 0 < 128
	kAUGroupParameterID_DataEntry = 6;	// value 0 < 128

	kAUGroupParameterID_Volume_LSB = kAUGroupParameterID_Volume + 32;		// value 0 < 128
	kAUGroupParameterID_ModWheel_LSB = kAUGroupParameterID_ModWheel + 32;	// value 0 < 128
	kAUGroupParameterID_Pan_LSB = kAUGroupParameterID_Pan + 32;			// value 0 < 128
	kAUGroupParameterID_Foot_LSB = kAUGroupParameterID_Foot + 32;		// value 0 < 128
	kAUGroupParameterID_Expression_LSB = kAUGroupParameterID_Expression + 32;	// value 0 < 128
	kAUGroupParameterID_DataEntry_LSB = kAUGroupParameterID_DataEntry + 32;	// value 0 < 128
	
	kAUGroupParameterID_KeyPressure_FirstKey = 256;	// value 0 < 128
	kAUGroupParameterID_KeyPressure_LastKey = 383;	// value 0 < 128	


{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Supporting the kAUGroupParameterID_KeyPressure parameter indicates to hosts that your audio unit
supports polyphonic "aftertouch" key pressure. 

Each of the 128 MIDI key numbers can have its own value for polyphonic aftertouch. To respond to 
aftertouch for a particular key, your audio unit needs to support an additional parameter 
specifically for that key. The aftertouch parameter ID for a given MIDI key is equal to the MIDI 
key number plus 256. For example, the aftertouch parameter ID for MIDI key #60 (middle C) is:

	60 + kAUGroupParameterID_KeyPressure_FirstKey = 316
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ }

// Parameters for all Panner AudioUnits
const
	kPannerParam_Gain = 0;			// 0 .. 1
	
	kPannerParam_Azimuth = 1;		// -180 .. +180 degrees
	kPannerParam_Elevation = 2;		// -90 .. +90 degrees
	kPannerParam_Distance = 3;		// 0 .. 1
	
	kPannerParam_CoordScale = 4;	// 0.01 .. 1000 meters
	kPannerParam_RefDistance = 5;	// 0.01 .. 1000 meters

{$endc}	{ not TARGET_OS_IPHONE }

//#pragma mark Apple Specific

// Parameters for the AUMixer3D unit
// only some of these parameters are available in the embedded implementation of this AU
const
// Input, Degrees, -180->180, 0
	k3DMixerParam_Azimuth = 0;
        
		// Input, Degrees, -90->90, 0
	k3DMixerParam_Elevation = 1;
        
		// Input, Metres, 0->10000, 1
	k3DMixerParam_Distance = 2;
        
		// Input/Output, dB, -120->20, 0
	k3DMixerParam_Gain = 3;
	
		// Input, rate scaler	0.5 -> 2.0
	k3DMixerParam_PlaybackRate = 4;

// Parameters for the AUMultiChannelMixer unit
const
	kMultiChannelMixerParam_Volume = 0;
	kMultiChannelMixerParam_Enable = 1;

		// read-only
	// these report level in dB, as do the other mixers
	kMultiChannelMixerParam_PreAveragePower = 1000;
	kMultiChannelMixerParam_PrePeakHoldLevel = 2000;
	kMultiChannelMixerParam_PostAveragePower = 3000;
	kMultiChannelMixerParam_PostPeakHoldLevel = 4000;

// Output Units
// Parameters for the AudioDeviceOutput, DefaultOutputUnit, and SystemOutputUnit units
const
// Global, LinearGain, 0->1, 1
	kHALOutputParam_Volume = 14;

// Parameters for the AUTimePitch, AUTimePitch (offline), AUPitch units
const
	kTimePitchParam_Rate = 0;
//#if !TARGET_OS_IPHONE
{$ifc not TARGET_OS_IPHONE}
	kTimePitchParam_Pitch = 1;
	kTimePitchParam_EffectBlend = 2;		// only for the AUPitch unit
{$endc} { not TARGET_OS_IPHONE }

//#if !TARGET_OS_IPHONE
{$ifc not TARGET_OS_IPHONE}
const
// Input, Dry/Wet equal-power blend, %	  0.0 -> 100.0
	k3DMixerParam_ReverbBlend = 5;

		// Global, dB,		-40.0 -> +40.0
	k3DMixerParam_GlobalReverbGain = 6;
	
		// Input, Lowpass filter attenuation at 5KHz :		decibels -100.0dB -> 0.0dB
		// smaller values make sound more muffled; a value of 0.0 indicates no filtering
	k3DMixerParam_OcclusionAttenuation = 7;
	
		// Input, Lowpass filter attenuation at 5KHz :		decibels -100.0dB -> 0.0dB
		// smaller values make sound more muffled; a value of 0.0 indicates no filtering
	k3DMixerParam_ObstructionAttenuation = 8;
	
		// read-only
		//
		// For each of the following, use the parameter ID plus the channel number
		// to get the specific parameter ID for a given channel.
		// For example, k3DMixerParam_PostAveragePower indicates the left channel
		// while k3DMixerParam_PostAveragePower + 1 indicates the right channel.
	k3DMixerParam_PreAveragePower = 1000;
	k3DMixerParam_PrePeakHoldLevel = 2000;
	k3DMixerParam_PostAveragePower = 3000;
	k3DMixerParam_PostPeakHoldLevel = 4000;
{$endc} { not TARGET_OS_IPHONE }

//#pragma mark Apple Specific - Desktop

//#if !TARGET_OS_IPHONE
{$ifc not TARGET_OS_IPHONE}
{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The following sections specify the parameter IDs for the audio units included in Mac OS X.
Host applications can use these IDs to directly address these parameters without first discovering 
them through the AUParameterInfo mechanism (see the AudioUnitProperties.h header file)

Each parameter is preceeded by a comment that indicates scope, unit of measurement, minimum
value, maximum value, and default value.
    
See the AudioUnitProperties.h header file for additional information that a parameter may report

When displaying to the user information about a parameter, a host application should always
get the parameter information from the audio unit itself.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ }


// Effect units
// The values for some effect unit parameters depend on the audio unit's sample rate.
// For example, maximum values are typically the Nyquist frequency (indicated here as 
// SampleRate/2).

// Parameters for the AUBandpass unit
const
// Global, Hz, 20->(SampleRate/2), 5000
	kBandpassParam_CenterFrequency = 0;

		// Global, Cents, 100->12000, 600
	kBandpassParam_Bandwidth = 1;

// Some parameters for the AUGraphicEQ unit
const
// Global, Indexed, currently either 10 or 31
	kGraphicEQParam_NumberOfBands = 10000;

// Parameters for the AUHipass unit
const
// Global, Hz, 10->(SampleRate/2), 6900
	kHipassParam_CutoffFrequency = 0;
		
		// Global, dB, -20->40, 0
	kHipassParam_Resonance = 1;

// Parameters for the AULowpass unit
const
// Global, Hz, 10->(SampleRate/2), 6900
	kLowPassParam_CutoffFrequency = 0;
		
		// Global, dB, -20->40, 0
	kLowPassParam_Resonance = 1;

// Parameters for the AUHighShelfFilter unit
const
// Global, Hz, 10000->(SampleRate/2), 10000
	kHighShelfParam_CutOffFrequency = 0;
		
		// Global, dB, -40->40, 0
	kHighShelfParam_Gain = 1;

// Parameters for the AULowShelfFilter unit
const
// Global, Hz, 10->200, 80
	kAULowShelfParam_CutoffFrequency = 0;
		
		// Global, dB, -40->40, 0
	kAULowShelfParam_Gain = 1;

// Parameters for the AUParametricEQ unit
const
// Global, Hz, 20->(SampleRate/2), 2000
	kParametricEQParam_CenterFreq = 0;
		
		// Global, Hz, 0.1->20, 1.0
	kParametricEQParam_Q = 1;
		
		// Global, dB, -20->20, 0
	kParametricEQParam_Gain = 2;

// Parameters for the AUMatrixReverb unit
const
// Global, EqPow CrossFade, 0->100, 100
	kReverbParam_DryWetMix = 0;
		
		// Global, EqPow CrossFade, 0->100, 50
	kReverbParam_SmallLargeMix = 1;
		
		// Global, Secs, 0.005->0.020, 0.06
	kReverbParam_SmallSize = 2;
		
		// Global, Secs, 0.4->10.0, 3.07
	kReverbParam_LargeSize = 3;
		
		// Global, Secs, 0.001->0.03, 0.025
	kReverbParam_PreDelay = 4;
		
		// Global, Secs, 0.001->0.1, 0.035
	kReverbParam_LargeDelay = 5;
		
		// Global, Genr, 0->1, 0.28
	kReverbParam_SmallDensity = 6;
		
		// Global, Genr, 0->1, 0.82
	kReverbParam_LargeDensity = 7;
		
		// Global, Genr, 0->1, 0.3
	kReverbParam_LargeDelayRange = 8;
		
		// Global, Genr, 0.1->1, 0.96
	kReverbParam_SmallBrightness = 9;
		
		// Global, Genr, 0.1->1, 0.49
	kReverbParam_LargeBrightness = 10;

		// Global, Genr, 0->1 0.5
	kReverbParam_SmallDelayRange = 11;

		// Global, Hz, 0.001->2.0, 1.0
	kReverbParam_ModulationRate = 12;

		// Global, Genr, 0.0 -> 1.0, 0.2
	kReverbParam_ModulationDepth = 13;

		// Global, Hertz, 10.0 -> 20000.0, 800.0
	kReverbParam_FilterFrequency = 14;

		// Global, Octaves, 0.05 -> 4.0, 3.0
	kReverbParam_FilterBandwidth = 15;

		// Global, Decibels, -18.0 -> +18.0, 0.0
	kReverbParam_FilterGain = 16;

// Parameters for the AUDelay unit
const
// Global, EqPow Crossfade, 0->100, 50
	kDelayParam_WetDryMix = 0;
		
		// Global, Secs, 0->2, 1
	kDelayParam_DelayTime = 1;
		
		// Global, Percent, -100->100, 50
	kDelayParam_Feedback = 2;
		
		// Global, Hz, 10->(SampleRate/2), 15000
	kDelayParam_LopassCutoff = 3;

// Parameters for the AUPeakLimiter unit
const
// Global, Secs, 0.001->0.03, 0.012
	kLimiterParam_AttackTime = 0;
		
		// Global, Secs, 0.001->0.06, 0.024
	kLimiterParam_DecayTime = 1;
		
		// Global, dB, -40->40, 0
	kLimiterParam_PreGain = 2;


// Parameters for the AUDynamicsProcessor unit
const
// Global, dB, -40->20, -20
	kDynamicsProcessorParam_Threshold = 0;
		
		// Global, dB, 0.1->40.0, 5
	kDynamicsProcessorParam_HeadRoom = 1;
		
		// Global, rate, 1->50.0, 2
	kDynamicsProcessorParam_ExpansionRatio = 2;
		
		// Global, dB
	kDynamicsProcessorParam_ExpansionThreshold = 3;
		
		// Global, secs, 0.0001->0.2, 0.001
	kDynamicsProcessorParam_AttackTime = 4;
		
		// Global, secs, 0.01->3, 0.05
	kDynamicsProcessorParam_ReleaseTime = 5;
		
		// Global, dB, -40->40, 0
	kDynamicsProcessorParam_MasterGain = 6;
	
		// Global, dB, read-only parameter
	kDynamicsProcessorParam_CompressionAmount = 1000;
	kDynamicsProcessorParam_InputAmplitude = 2000;
	kDynamicsProcessorParam_OutputAmplitude = 3000;


// Parameters for the AUMultibandCompressor unit
const
	kMultibandCompressorParam_Pregain = 0;
	kMultibandCompressorParam_Postgain = 1;
	kMultibandCompressorParam_Crossover1 = 2;
	kMultibandCompressorParam_Crossover2 = 3;
	kMultibandCompressorParam_Crossover3 = 4;
	kMultibandCompressorParam_Threshold1 = 5;
	kMultibandCompressorParam_Threshold2 = 6;
	kMultibandCompressorParam_Threshold3 = 7;
	kMultibandCompressorParam_Threshold4 = 8;
	kMultibandCompressorParam_Headroom1 = 9;
	kMultibandCompressorParam_Headroom2 = 10;
	kMultibandCompressorParam_Headroom3 = 11;
	kMultibandCompressorParam_Headroom4 = 12;
	kMultibandCompressorParam_AttackTime = 13;
	kMultibandCompressorParam_ReleaseTime = 14;
	kMultibandCompressorParam_EQ1 = 15;
	kMultibandCompressorParam_EQ2 = 16;
	kMultibandCompressorParam_EQ3 = 17;
	kMultibandCompressorParam_EQ4 = 18;
	
	// read-only parameters
	kMultibandCompressorParam_CompressionAmount1 = 1000;
	kMultibandCompressorParam_CompressionAmount2 = 2000;
	kMultibandCompressorParam_CompressionAmount3 = 3000;
	kMultibandCompressorParam_CompressionAmount4 = 4000;
	kMultibandCompressorParam_InputAmplitude1 = 5000;
	kMultibandCompressorParam_InputAmplitude2 = 6000;
	kMultibandCompressorParam_InputAmplitude3 = 7000;
	kMultibandCompressorParam_InputAmplitude4 = 8000;
	kMultibandCompressorParam_OutputAmplitude1 = 9000;
	kMultibandCompressorParam_OutputAmplitude2 = 10000;
	kMultibandCompressorParam_OutputAmplitude3 = 11000;
	kMultibandCompressorParam_OutputAmplitude4 = 12000;

// Parameters for the AUVarispeed unit
const
	kVarispeedParam_PlaybackRate = 0;
	kVarispeedParam_PlaybackCents = 1;

// Parameters for the AUFilter unit
const
	kMultibandFilter_LowFilterType = 0;
	kMultibandFilter_LowFrequency = 1;
	kMultibandFilter_LowGain = 2;
	kMultibandFilter_CenterFreq1 = 3;
	kMultibandFilter_CenterGain1 = 4;
	kMultibandFilter_Bandwidth1 = 5;
	kMultibandFilter_CenterFreq2 = 6;
	kMultibandFilter_CenterGain2 = 7;
	kMultibandFilter_Bandwidth2 = 8;
	kMultibandFilter_CenterFreq3 = 9;
	kMultibandFilter_CenterGain3 = 10;
	kMultibandFilter_Bandwidth3 = 11;
	kMultibandFilter_HighFilterType = 12;
	kMultibandFilter_HighFrequency = 13;
	kMultibandFilter_HighGain = 14;

// Mixer Units

// Parameters for the Stereo Mixer unit
const
// Input/Output, Mixer Fader Curve, 0->1, 1
	kStereoMixerParam_Volume = 0;
		
		// Input, Pan, 0->1, 0.5
	kStereoMixerParam_Pan = 1;
	
		// read-only
		//
		// For each of the following, use the parameter ID for the left channel
		// and the parameter ID plus one for the right channel.
		// For example, kStereoMixerParam_PostAveragePower indicates the left channel
		// while kStereiMixerParam_PostAveragePower + 1 indicates the right channel.
	kStereoMixerParam_PreAveragePower = 1000;
	kStereoMixerParam_PrePeakHoldLevel = 2000;
	kStereoMixerParam_PostAveragePower = 3000;
	kStereoMixerParam_PostPeakHoldLevel = 4000;

// Parameters for the AUMatrixMixer unit
const
	kMatrixMixerParam_Volume = 0;
	kMatrixMixerParam_Enable = 1;
	
		// read-only
	// these report level in dB, as do the other mixers
	kMatrixMixerParam_PreAveragePower = 1000;
	kMatrixMixerParam_PrePeakHoldLevel = 2000;
	kMatrixMixerParam_PostAveragePower = 3000;
	kMatrixMixerParam_PostPeakHoldLevel = 4000;

	// these report linear levels - for "expert" use only.
	kMatrixMixerParam_PreAveragePowerLinear = 5000;
	kMatrixMixerParam_PrePeakHoldLevelLinear = 6000;
	kMatrixMixerParam_PostAveragePowerLinear = 7000;
	kMatrixMixerParam_PostPeakHoldLevelLinear = 8000;

// Parameters for the AUNetReceive unit
const
	kAUNetReceiveParam_Status = 0;
	kAUNetReceiveParam_NumParameters = 1;

// Parameters for the AUNetSend unit
const
	kAUNetSendParam_Status = 0;
	kAUNetSendParam_NumParameters = 1;


// Status values for the AUNetSend and AUNetReceive units
const
	kAUNetStatus_NotConnected = 0;
	kAUNetStatus_Connected = 1;
	kAUNetStatus_Overflow = 2;
	kAUNetStatus_Underflow = 3;
	kAUNetStatus_Connecting = 4;
	kAUNetStatus_Listening = 5;

// Parameters for the Distortion unit 
const
	kDistortionParam_Delay = 0;
	kDistortionParam_Decay = 1;
	kDistortionParam_DelayMix = 2;
	kDistortionParam_Decimation = 3;
	kDistortionParam_Rounding = 4;
	kDistortionParam_DecimationMix = 5;
	kDistortionParam_LinearTerm = 6;
	kDistortionParam_SquaredTerm = 7;
	kDistortionParam_CubicTerm = 8;
	kDistortionParam_PolynomialMix = 9;
	kDistortionParam_RingModFreq1 = 10;
	kDistortionParam_RingModFreq2 = 11;
	kDistortionParam_RingModBalance = 12;
	kDistortionParam_RingModMix = 13;
	kDistortionParam_SoftClipGain = 14;
	kDistortionParam_FinalMix = 15;

// Parameters for AURogerBeep
const
	kRogerBeepParam_InGateThreshold = 0;
	kRogerBeepParam_InGateThresholdTime = 1;
	kRogerBeepParam_OutGateThreshold = 2;
	kRogerBeepParam_OutGateThresholdTime = 3;
	kRogerBeepParam_Sensitivity = 4;
	kRogerBeepParam_RogerType = 5;
	kRogerBeepParam_RogerGain = 6;

// Music Device
// Parameters for the DLSMusicDevice unit - defined and reported in the global scope
const
// Global, Cents, -1200, 1200, 0
	kMusicDeviceParam_Tuning = 0;

		// Global, dB, -120->40, 0
	kMusicDeviceParam_Volume = 1;

		// Global, dB, -120->40, 0
	kMusicDeviceParam_ReverbVolume = 2;
// In Mac OS X v10.5, the DLSMusicDevice audio unit does not report parameters in the Group scope.
// However, parameter values can be set in Group scope that correspond to controller values defined  
// by the MIDI specification. This includes the standard MIDI Controller values (such as Volume and
// Mod Wheel) as well as MIDI status messages (such as Pitch Bend and Channel Pressure) and the 
// MIDI RPN control messages.

// For MIDI status messages, use a value of 0 for the "channel part" (lower four bits) when setting  
// these parameters. This allows audio units to distinguish these IDs from the 0-127 
// values used by MIDI controllers in the first byte of status messages.
// 
// The element ID represents the group or channel number.
//
// You can use the MusicDeviceMIDIEvent function to send a MIDI formatted control command to a device.
//
// You can use the SetParameter API calls, declared in the AUComponent.h header file, as follows:
//
//	scope == kAudioUnitScope_Group
//	element == groupID -> in MIDI equivalent to channel number 0->15, 
//			but this is not a limitation of the MusicDevice and values greater than 15 can be specified
//	paramID == midi controller value (0->127), (status bytes corresponding to pitch bend, channel pressure)
//	value == typically the range associated with the corresponding MIDI message	(7 bit, 0->127)
//			pitch bend is specified as a 14 bit value
	
// See the MusicDevice.h header file for more about using the extended control semantics 
// of this API.	

{$endc} { not TARGET_OS_IPHONE }
{$ifc not defined MACOSALLINCLUDE or not MACOSALLINCLUDE}

end.
{$endc} {not MACOSALLINCLUDE}
