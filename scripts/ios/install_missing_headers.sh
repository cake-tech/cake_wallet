#!/bin/bash

. ./config.sh

echo "Installing missing headers"

# vmmeter
mkdir -p ${EXTERNAL_IOS_INCLUDE_DIR}/sys

if [ ! -f ${EXTERNAL_IOS_INCLUDE_DIR}/sys/vmmeter.h ]; then
  cp /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/sys/vmmeter.h ${EXTERNAL_IOS_INCLUDE_DIR}/sys/vmmeter.h
fi

# netinet
mkdir -p ${EXTERNAL_IOS_INCLUDE_DIR}/netinet
if [ ! -f ${EXTERNAL_IOS_INCLUDE_DIR}/netinet/ip_var.h ]; then
  cp /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/netinet/ip_var.h ${EXTERNAL_IOS_INCLUDE_DIR}/netinet/ip_var.h
fi

if [ ! -f ${EXTERNAL_IOS_INCLUDE_DIR}/netinet/udp_var.h ]; then
  cp /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/netinet/udp_var.h ${EXTERNAL_IOS_INCLUDE_DIR}/netinet/udp_var.h
fi

# IOKit
mkdir -p ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit
if [ ! -f ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/IOTypes.h ]; then
  cp /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/IOTypes.h  ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/IOTypes.h
fi

if [ ! -f ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/IOMapTypes.h ]; then
  cp /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/IOMapTypes.h  ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/IOMapTypes.h
fi

if [ ! -f ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/IOKitLib.h ]; then
  cp /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/IOKitLib.h ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/IOKitLib.h
fi

if [ ! -f ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/IOReturn.h ]; then
  cp /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/IOReturn.h ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/IOReturn.h
fi

if [ ! -f ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/OSMessageNotification.h ]; then
  cp /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/OSMessageNotification.h  ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/OSMessageNotification.h
fi

# IOKit/ps
mkdir -p ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/ps

if [ ! -f ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/ps/IOPSKeys.h ]; then
  cp /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/ps/IOPSKeys.h ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/ps/IOPSKeys.h
fi

if [ ! -f ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/ps/IOPowerSources.h ]; then
  cp /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/ps/IOPowerSources.h ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/ps/IOPowerSources.h
fi


# libkern
mkdir -p ${EXTERNAL_IOS_INCLUDE_DIR}/libkern

if [ ! -f ${EXTERNAL_IOS_INCLUDE_DIR}/libkern/OSTypes.h ]; then
  cp /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/libkern/OSTypes.h ${EXTERNAL_IOS_INCLUDE_DIR}/libkern/OSTypes.h
fi

if [ ! -f ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/IOKitKeys.h ]; then
  cp /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/IOKit.framework/Versions/A/Headers/IOKitKeys.h ${EXTERNAL_IOS_INCLUDE_DIR}/IOKit/IOKitKeys.h
fi
