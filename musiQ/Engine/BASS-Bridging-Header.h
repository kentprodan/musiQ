//
//  BASS-Bridging-Header.h
//  musiQ
//
//  Bridging header for BASS audio library
//

#ifndef BASS_Bridging_Header_h
#define BASS_Bridging_Header_h

// BASS Core Library
#import "bass.h"

// BASS Add-ons for extended format support
#import "bassflac.h"   // FLAC support
#import "bassdsd.h"    // DSD support
#import "bassopus.h"   // OPUS support
// #import "basswv.h"     // WavPack support (not downloaded)

// Note: Uncomment these imports after BASS framework is added to Frameworks/
// Download BASS from: https://www.un4seen.com/

#endif /* BASS_Bridging_Header_h */
