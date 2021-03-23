#import <Foundation/Foundation.h>

@class DNDModeAssertionLifetime;

@interface DNDModeAssertionDetails : NSObject
+ (id)userRequestedAssertionDetailsWithIdentifier:(NSString *)identifier modeIdentifier:(NSString *)modeIdentifier lifetime:(DNDModeAssertionLifetime *)lifetime;
- (BOOL)invalidateAllActiveModeAssertionsWithError:(NSError **)error;
- (id)takeModeAssertionWithDetails:(DNDModeAssertionDetails *)assertionDetails error:(NSError **)error;
@end

@interface DNDModeAssertionService : NSObject
+ (id)serviceForClientIdentifier:(NSString *)clientIdentifier;
- (BOOL)invalidateAllActiveModeAssertionsWithError:(NSError **)error;
- (id)takeModeAssertionWithDetails:(DNDModeAssertionDetails *)assertionDetails error:(NSError **)error;
@end

@interface RPControlCenterClient
@property BOOL recordingOn;
@end

@interface RPControlCenterModule
@property RPControlCenterClient* client;
@end

static BOOL DNDEnabled;
static BOOL DNDEnabledTemp;
static DNDModeAssertionService *assertionService;

static void enableDND(){
  if (!assertionService) {
    assertionService = (DNDModeAssertionService *)[%c(DNDModeAssertionService) serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
  }
  DNDModeAssertionDetails *newAssertion = [%c(DNDModeAssertionDetails) userRequestedAssertionDetailsWithIdentifier:@"com.apple.control-center.manual-toggle" modeIdentifier:@"com.apple.donotdisturb.mode.default" lifetime:nil];
  [assertionService takeModeAssertionWithDetails:newAssertion error:NULL];
  
}

static void disableDND(){
  if (!assertionService) {
    assertionService = (DNDModeAssertionService *)[%c(DNDModeAssertionService) serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
  }
  [assertionService invalidateAllActiveModeAssertionsWithError:NULL];
}


%hook RPControlCenterClient
-(void)startRecordingWithHandler:(/*^block*/id)arg1{
  %orig;
  %log;
  NSLog(@"[RPScreenRecorder]gilshahar7 startRecordingWithHandler");
  //recording started, save the DND state and enable it if needed.
  DNDEnabledTemp = DNDEnabled;
  if(DNDEnabled == false){
    //need to enable DND
    enableDND();
  }
}
%end

%hook RPControlCenterMenuModuleViewController
-(void)didStopRecordingOrBroadcast{
	%orig;
	
	if(MSHookIvar<RPControlCenterClient*>(self, "_client").recordingOn == NO){
		//recording ended, decide what to do with DND
		if(DNDEnabledTemp == false){
			//need to disable DND
			disableDND();
		}
	}
}
%end

%hook RPControlCenterModule
-(void)didStopRecordingOrBroadcast {
  %orig;
  if(self.client.recordingOn == NO){
    //recording ended, decide what to do with DND
    if(DNDEnabledTemp == false){
      //need to disable DND
      disableDND();
    }
  }
}
%end

%hook DNDState
-(BOOL)isActive {
  //save the DND state.
	DNDEnabled = %orig;
	return DNDEnabled;
}
%end

%ctor
{
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"])
    {
        //load ReplayKitModule bundle so we can hook it
        NSBundle* moduleBundle = [NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ReplayKitModule.bundle"];
        if (!moduleBundle.loaded)
            [moduleBundle load];
        %init;
    }
}
