//
// XtifyGlobal.h
//  
//
// Created by Gilad on 4/25/11.
// Copyright 2011 Xtify. All rights reserved.
//
// For help, visit: http://developer.xtify.com


// Xtify AppKey
//
// Enter the AppKey assigned to your app at http://console.xtify.com
// Nothing works without this.

// InternetDJ Key #define xAppKey @"28b40a4a-5723-4051-8702-358a49bf670b"

#define xAppKey @"ENTER YOUR KEY HERE"


// Location updates
//
// Set to YES to let Xtify receive location updates from the user. The user will also receive a prompt asking for permission to do so.
// Set to NO to completely turn off location updates. No prompt will appear. Suitable for simple/rich notification push only

#define xLocationRequired NO  

// Background location update
//
// Set this to TRUE if you want to also send location updates on significant change to Xtify while the app is in the background. 
// Set this to FALSE if you want to send location updates on significant change to Xtify while the app is in the foreground only.

#define xRunAlsoInBackground TRUE 

// Badge management
// 
// Set to XLInboxManagedMethod to let the Xtify SDK manage the badge count on the client and the server
// Set to XLDeveloperManagedMethod if you want to handle updating the badge on the client and server (you'll need to create your own method)
// We've included an example on how to set/update the badge in the main delegate file within our sample apps

#define xBadgeManagerMethod XLInboxManagedMethod 

// This is a premium feature that supports a regional control of messaging by multiple user governed by one primary organization account. Suitable for organizations that have multiple geographical regions or franchise business models. This feature will only work with Enterprise accounts. Please inquire with Xtify to enable this feature.

#define xMultipleMarkets FALSE 
