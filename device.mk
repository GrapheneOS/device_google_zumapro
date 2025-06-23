#
# Copyright (C) 2011 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include device/google/gs-common/device.mk
include device/google/gs-common/gs_watchdogd/watchdog.mk
include device/google/gs-common/ramdump_and_coredump/ramdump_and_coredump.mk
include device/google/gs-common/soc/soc.mk
include device/google/gs-common/modem/modem.mk
include device/google/gs-common/aoc/aoc.mk
include device/google/gs-common/trusty/trusty.mk
include device/google/gs-common/pcie/pcie.mk
include device/google/gs-common/storage/storage.mk
include device/google/gs-common/thermal/dump/thermal.mk
include device/google/gs-common/thermal/thermal_hal/device.mk
include device/google/gs-common/performance/perf.mk
include device/google/gs-common/power/power.mk
include device/google/gs-common/pixel_metrics/pixel_metrics.mk
include device/google/gs-common/soc/freq.mk
include device/google/gs-common/gps/dump/log.mk
include device/google/gs-common/bcmbt/dump/dumplog.mk
include device/google/gs-common/display/dump.mk
include device/google/gs-common/display_logbuffer/dump.mk
include device/google/gs-common/gxp/gxp.mk
include device/google/gs-common/camera/dump.mk
include device/google/gs-common/radio/dump.mk
include device/google/gs-common/gear/dumpstate/aidl.mk
include device/google/gs-common/widevine/widevine.mk
include device/google/gs-common/sota_app/factoryota.mk
include device/google/gs-common/misc_writer/misc_writer.mk
include device/google/gs-common/gyotaku_app/gyotaku.mk
include device/google/gs-common/bootctrl/bootctrl_aidl.mk
include device/google/gs-common/betterbug/betterbug.mk
include device/google/gs-common/recorder/recorder.mk
include device/google/gs-common/fingerprint/fingerprint.mk

include device/google/zumapro/dumpstate/item.mk

TARGET_BOARD_PLATFORM := zumapro
ALLOW_MISSING_DEPENDENCIES := true

AB_OTA_POSTINSTALL_CONFIG += \
	RUN_POSTINSTALL_system=true \
	POSTINSTALL_PATH_system=system/bin/otapreopt_script \
	FILESYSTEM_TYPE_system=ext4 \
POSTINSTALL_OPTIONAL_system=true

# Set Vendor SPL to match platform
VENDOR_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)

# Set boot SPL
BOOT_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)

PRODUCT_SOONG_NAMESPACES += \
	hardware/google/av \
	hardware/google/interfaces \
	hardware/google/pixel \
	device/google/zumapro \

LOCAL_KERNEL := $(TARGET_KERNEL_DIR)/Image.lz4

# Set the environment variable to switch the Keymint HAL service to Rust
TRUSTY_KEYMINT_IMPL := rust

ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
#Set IKE logs to verbose for WFC
PRODUCT_PROPERTY_OVERRIDES += log.tag.IKE=VERBOSE

#Set Shannon IMS logs to debug
PRODUCT_PROPERTY_OVERRIDES += log.tag.SHANNON_IMS=DEBUG

#Set Shannon QNS logs to debug
PRODUCT_PROPERTY_OVERRIDES += log.tag.ShannonQNS=DEBUG
PRODUCT_PROPERTY_OVERRIDES += log.tag.ShannonQNS-ims=DEBUG
PRODUCT_PROPERTY_OVERRIDES += log.tag.ShannonQNS-emergency=DEBUG
PRODUCT_PROPERTY_OVERRIDES += log.tag.ShannonQNS-mms=DEBUG
PRODUCT_PROPERTY_OVERRIDES += log.tag.ShannonQNS-xcap=DEBUG
PRODUCT_PROPERTY_OVERRIDES += log.tag.ShannonQNS-HC=DEBUG

# Modem userdebug
include device/google/zumapro/modem/userdebug.mk
endif

ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
# b/36703476: Set default log size to 1M
PRODUCT_PROPERTY_OVERRIDES += \
	ro.logd.size=1M
# b/114766334: persist all logs by default rotating on 30 files of 1MiB
# change to 60 files from zumapro
PRODUCT_PROPERTY_OVERRIDES += \
	logd.logpersistd=logcatd \
	logd.logpersistd.size=60

PRODUCT_PRODUCT_PROPERTIES += \
	ro.logcat.compress=true
endif

ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
PRODUCT_PROPERTY_OVERRIDES += \
	persist.vendor.usb.displayport.enabled=1
else
PRODUCT_PROPERTY_OVERRIDES += \
	persist.vendor.usb.displayport.enabled=1
endif

USE_LASSEN_OEMHOOK := true

# Pixel Logger
include hardware/google/pixel/PixelLogger/PixelLogger.mk

ifneq ($(BOARD_WITHOUT_RADIO),true)

# Use Lassen specifc Shared Modem Platform
SHARED_MODEM_PLATFORM_VENDOR := lassen

else # ifneq ($(BOARD_WITHOUT_RADIO),true)

# Pixel Logger
BOARD_SEPOLICY_DIRS += hardware/google/pixel-sepolicy/logger_app

endif # ifneq ($(BOARD_WITHOUT_RADIO),true)

# Shared Modem Platform
include device/google/gs-common/modem/modem_svc_sit/shared_modem_platform.mk

# Use for GRIL
USES_LASSEN_MODEM := true
ifneq ($(BOARD_WITHOUT_RADIO),true)
$(call soong_config_set_bool,grilservice,use_google_qns,true)
endif

ifeq ($(USES_GOOGLE_DIALER_CARRIER_SETTINGS),true)
USE_GOOGLE_DIALER := true
USE_GOOGLE_CARRIER_SETTINGS := true
PRODUCT_PROPERTY_OVERRIDES += \
	ro.vendor.uses_google_dialer_carrier_settings=1
# GoogleDialer in PDK build with "USES_GOOGLE_DIALER_CARRIER_SETTINGS=true"
PRODUCT_SOONG_NAMESPACES += vendor/google_devices/zumapro/proprietary/GoogleDialer
endif

ifeq ($(USES_GOOGLE_PREBUILT_MODEM_SVC),true)
USE_GOOGLE_PREBUILT_MODEM_SVC := true
endif

# Audio client implementation for RIL
USES_GAUDIO := true

# ######################
# GRAPHICS - GPU (begin)

# Must match BOARD_USES_SWIFTSHADER in BoardConfig.mk
USE_SWIFTSHADER ?= false

# HWUI
ifeq ($(USE_SWIFTSHADER),true)
$(warning USE_SWIFTSHADER set to current target)
TARGET_USES_VULKAN = false
else
TARGET_USES_VULKAN = true
endif

$(call soong_config_set,pixel_mali,soc,$(TARGET_BOARD_PLATFORM))
# TODO (b/297408842): The gralloc is being open-sourced, and we cannot pass
# "zumapro" as SOC to build it. Pass "zuma" as SOC for now.
$(call soong_config_set,arm_gralloc,soc,zuma)

include device/google/gs-common/gpu/gpu.mk

# Install the OpenCL ICD Loader
PRODUCT_SOONG_NAMESPACES += external/OpenCL-ICD-Loader
PRODUCT_PACKAGES += \
	libOpenCL
ifeq ($(DEVICE_IS_64BIT_ONLY),false)
PRODUCT_PACKAGES += \
	mali_icd__customer_pixel_opencl-icd_ARM32.icd
endif

ifeq ($(USE_SWIFTSHADER),true)
$(warning USE_SWIFTSHADER set to current target)
PRODUCT_PACKAGES += \
	libEGL_angle \
	libGLESv1_CM_angle \
	libGLESv2_angle \
	vulkan.pastel
endif

# SurfaceFlinger / RenderEngine
ifeq ($(TARGET_USES_VULKAN),true)
# b/293371537 Opt in to RE-Graphite's aconfig-based preview rollout
PRODUCT_VENDOR_PROPERTIES += debug.renderengine.graphite_preview_optin=true
else
$(warning TARGET_USES_VULKAN == false, cannot opt in to RE-Graphite rollout in SurfaceFlinger)
PRODUCT_VENDOR_PROPERTIES += debug.renderengine.graphite_preview_optin=false
endif

PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
	frameworks/native/data/etc/android.hardware.vulkan.version-1_3.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
	frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
	frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml \
	frameworks/native/data/etc/android.software.vulkan.deqp.level-2024-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml \
	frameworks/native/data/etc/android.software.opengles.deqp.level-2024-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml

#endif

# GRAPHICS - GPU (end)
# ####################

PRODUCT_SHIPPING_API_LEVEL := $(SHIPPING_API_LEVEL)

# Device Manifest, Device Compatibility Matrix for Treble
DEVICE_MANIFEST_FILE := \
	device/google/zumapro/manifest.xml
DEVICE_PRODUCT_COMPATIBILITY_MATRIX_FILE += device/google/zumapro/device_framework_matrix_product_8.xml
DEVICE_MATRIX_FILE := \
	device/google/zumapro/compatibility_matrix.xml

BOARD_USE_CODEC2_AIDL := V1
ifneq (,$(filter aosp_%,$(TARGET_PRODUCT)))
DEVICE_MANIFEST_FILE += \
	device/google/zumapro/manifest_media_aosp.xml
else
DEVICE_MANIFEST_FILE += \
	device/google/zumapro/manifest_media.xml
endif

DEVICE_PACKAGE_OVERLAYS += device/google/zumapro/overlay

# RKP VINTF
-include vendor/google_nos/host/android/hals/keymaster/aidl/strongbox/RemotelyProvisionedComponent-citadel.mk

# Enforce the Product interface
PRODUCT_PRODUCT_VNDK_VERSION := current
PRODUCT_ENFORCE_PRODUCT_PARTITION_INTERFACE := true

# Init files
PRODUCT_COPY_FILES += \
	$(LOCAL_KERNEL):kernel \

PRODUCT_PACKAGES += fsck.f2fs.vendor


# Recovery files
PRODUCT_COPY_FILES += \
	device/google/zumapro/conf/init.recovery.device.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.zumapro.rc \
	device/google/zumapro/conf/init.recovery.device.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.zuma.rc

# Fstab files
ifeq (true,$(TARGET_BOOTS_16K))
PRODUCT_SOONG_NAMESPACES += \
        device/google/zumapro/conf/fs-16kb
else ifeq (ext4,$(TARGET_RW_FILE_SYSTEM_TYPE))
PRODUCT_SOONG_NAMESPACES += \
        device/google/zumapro/conf/ext4
else
PRODUCT_SOONG_NAMESPACES += \
        device/google/zumapro/conf/f2fs
endif

PRODUCT_PACKAGES += \
	fstab.zuma \
	fstab.zumapro \
	fstab.zuma.vendor_ramdisk \
	fstab.zumapro.vendor_ramdisk \
	fstab.zuma-fips \
	fstab.zumapro-fips \
	fstab.zuma-fips.vendor_ramdisk \
	fstab.zumapro-fips.vendor_ramdisk

include device/google/gs-common/insmod/insmod.mk

# Insmod config files
PRODUCT_COPY_FILES += \
	$(call find-copy-subdir-files,init.insmod.*.cfg,$(TARGET_KERNEL_DIR),$(TARGET_COPY_OUT_VENDOR_DLKM)/etc)

# For creating dtbo image
PRODUCT_HOST_PACKAGES += \
	mkdtimg

PRODUCT_PACKAGES += \
	messaging

# CHRE
## tools
ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
PRODUCT_PACKAGES += \
	chre_power_test_client \
	chre_test_client \
	chre_aidl_hal_client
endif

# PCIe
ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
PRODUCT_PACKAGES += \
	factory_pcie
endif

## hal
include device/google/gs-common/chre/hal.mk
PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.context_hub.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.context_hub.xml

## Enable the CHRE Daemon
CHRE_USF_DAEMON_ENABLED := false

# Filesystem management tools
PRODUCT_PACKAGES += \
	linker.vendor_ramdisk \
	tune2fs.vendor_ramdisk \
	resize2fs.vendor_ramdisk

# Userdata Checkpointing OTA GC
PRODUCT_PACKAGES += \
	checkpoint_gc

# Vendor verbose logging default property
ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
PRODUCT_PROPERTY_OVERRIDES += \
	persist.vendor.verbose_logging_enabled=true
else
PRODUCT_PROPERTY_OVERRIDES += \
	persist.vendor.verbose_logging_enabled=false
endif

# Touch
PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml

ifneq (,$(filter ripcurrentpro, $(TARGET_PRODUCT)))
	include device/google/gs-common/touch/gti/gti.mk
endif

# Sensors
PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
	frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.compass.xml \
	frameworks/native/data/etc/android.hardware.sensor.dynamic.head_tracker.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.dynamic.head_tracker.xml \
	frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.gyroscope.xml \
	frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml\
	frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepcounter.xml \
	frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepdetector.xml
ifneq ($(DISABLE_SENSOR_BARO_HIFI),true)
PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.sensor.barometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.barometer.xml \
	frameworks/native/data/etc/android.hardware.sensor.hifi_sensors.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.hifi_sensors.xml
endif
ifneq ($(DISABLE_SENSOR_PROX),true)
PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml
endif

# Add sensor HAL AIDL product packages
PRODUCT_PACKAGES += android.hardware.sensors-service.multihal

# USB HAL
PRODUCT_PACKAGES += \
	android.hardware.usb-service
PRODUCT_PACKAGES += \
	android.hardware.usb.gadget-service

ifneq (,$(filter ripcurrentpro, $(TARGET_PRODUCT)))
PRODUCT_PACKAGES += usb_service_init_rc_i2c11
else
PRODUCT_PACKAGES += usb_service_init_rc_i2c6
endif

# MIDI feature
PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml

# default usb debug functions
ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
PRODUCT_PROPERTY_OVERRIDES += \
	persist.vendor.usb.usbradio.config=dm
endif

-include hardware/google/pixel/power-libperfmgr/aidl/device.mk

# IRQ rebalancing.
include hardware/google/pixel/rebalance_interrupts/rebalance_interrupts.mk

#
# Audio HALs
#

# Libs
PRODUCT_PACKAGES += \
	com.android.future.usb.accessory

PRODUCT_PACKAGES += \
	android.hardware.memtrack-service.pixel \
	libion_exynos \
	libion

PRODUCT_PACKAGES += \
	libhwjpeg

# Video Editor
PRODUCT_PACKAGES += \
	VideoEditorGoogle

# WideVine modules
include device/google/zumapro/widevine/device.mk
PRODUCT_PACKAGES += \
	liboemcrypto \

RIPCURRENTPRO_PRODUCT := %ripcurrentpro
ifneq (,$(filter $(RIPCURRENTPRO_PRODUCT), $(TARGET_PRODUCT)))
        LOCAL_TARGET_PRODUCT := ripcurrentpro
else
        # WAR: continue defaulting to slider build on zumapro
        LOCAL_TARGET_PRODUCT := slider
endif

include device/google/gs-common/camera/lyric.mk

$(call soong_config_set,lyric,soc,zumapro)
# lyric::tuning_product is set in device-specific makefiles,
# such as device/google/${DEVICE}/device-${DEVICE}.mk

# WiFi
PRODUCT_PACKAGES += \
	wificond \
	libwpa_client

# Connectivity
PRODUCT_PACKAGES += \
        ConnectivityOverlay

PRODUCT_PACKAGES_DEBUG += \
	f2fs_io \
	check_f2fs \
	f2fs.fibmap \
	dump.f2fs

# Storage health HAL
PRODUCT_PACKAGES += \
	android.hardware.health.storage-service.default

# Battery Mitigation
include device/google/gs-common/battery_mitigation/bcl.mk
# storage pixelstats
-include hardware/google/pixel/pixelstats/device.mk

# Enable project quotas and casefolding for emulated storage without sdcardfs
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/android_t_baseline.mk)
PRODUCT_VIRTUAL_AB_COMPRESSION_METHOD := lz4

# Enforce generic ramdisk allow list
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

# Titan-M
ifeq (,$(filter true, $(BOARD_WITHOUT_DTLS)))
include device/google/gs-common/dauntless/gsc.mk
endif

PRODUCT_PACKAGES_DEBUG += \
	WvInstallKeybox

# WiFi
PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
	frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
	frameworks/native/data/etc/android.hardware.wifi.aware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.aware.xml \
	frameworks/native/data/etc/android.hardware.wifi.passpoint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.passpoint.xml \
	frameworks/native/data/etc/android.hardware.wifi.rtt.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.rtt.xml

# Bluetooth channel sounding
ifneq (,$(RELEASE_RANGING_STACK))
PRODUCT_COPY_FILES += \
        frameworks/native/data/etc/android.hardware.bluetooth_le.channel_sounding.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.channel_sounding.xml
endif

PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
	frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml

PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
	frameworks/native/data/etc/android.hardware.camera.concurrent.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.concurrent.xml \
	frameworks/native/data/etc/android.hardware.camera.full.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.full.xml\
	frameworks/native/data/etc/android.hardware.camera.raw.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.raw.xml\

ifneq ($(DISABLE_CAMERA_FS),true)
PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml
else
PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.camera.autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.autofocus.xml
endif

#PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/handheld_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/handheld_core_hardware.xml \
	frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
	frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
	frameworks/native/data/etc/android.hardware.wifi.passpoint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.passpoint.xml \

PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
	frameworks/native/data/etc/android.hardware.audio.pro.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.pro.xml \

PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml \

ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
PRODUCT_PACKAGES += displaycolor_service
endif

# Camera
PRODUCT_PROPERTY_OVERRIDES += \
	vendor.camera.multicam.enable_p23_multicam=true

PRODUCT_PROPERTY_OVERRIDES += \
	persist.sys.sf.color_saturation=1.0

PRODUCT_CHARACTERISTICS := nosdcard

PRODUCT_PACKAGES += hostapd
PRODUCT_PACKAGES += wpa_supplicant
PRODUCT_PACKAGES += wpa_supplicant.conf

WIFI_PRIV_CMD_UPDATE_MBO_CELL_STATUS := enabled

ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
PRODUCT_PACKAGES += wpa_cli
PRODUCT_PACKAGES += hostapd_cli
endif

####################################
## VIDEO
####################################

# Video
# 1. Codec 2.0
# for settings used by different C2 hal
include device/google/gs-common/mediacodec/common/mediacodec_common.mk
# for Exynos C2 Hal
include device/google/gs-common/mediacodec/samsung/mediacodec_samsung.mk
# for Bigwave C2 Hal
include device/google/gs-common/mediacodec/bigwave/mediacodec_bigwave.mk
$(call soong_config_set,bigw,soc,zuma)

PRODUCT_PROPERTY_OVERRIDES += media.c2.hal.selection=aidl
####################################

# CBD (CP booting deamon)
CBD_USE_V2 := true
CBD_PROTOCOL_SIT := true

# setup dalvik vm configs.
$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)

PRODUCT_TAGS += dalvik.gc.type-precise

# Exynos OpenVX framework
PRODUCT_PACKAGES += \
		libexynosvision

ifeq ($(TARGET_USES_CL_KERNEL),true)
PRODUCT_PACKAGES += \
	libopenvx-opencl
endif

# Trusty (KM, GK, Storage)
$(call inherit-product, system/core/trusty/trusty-storage.mk)
$(call inherit-product, system/core/trusty/trusty-base.mk)

# Trusty unit test tool
PRODUCT_PACKAGES_DEBUG += \
    trusty-ut-ctrl \
    tipc-test \
    trusty_stats_test \

# Trusty Metrics Daemon
PRODUCT_SOONG_NAMESPACES += \
	vendor/google/trusty/common

PRODUCT_PACKAGES += \
	trusty_metricsd

$(call soong_config_set,google_displaycolor,displaycolor_platform,zuma)
PRODUCT_PACKAGES += \
	libdisplaycolor \
	libdisplaypanel

# System props to enable Bluetooth Quality Report (BQR) feature
ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
PRODUCT_PRODUCT_PROPERTIES += \
	persist.bluetooth.bqr.event_mask?=262174 \
	persist.bluetooth.bqr.min_interval_ms=500
endif

#VNDK
PRODUCT_PACKAGES += \
	vndk-libs

#PRODUCT_ENFORCE_RRO_TARGETS := \
#	framework-res

# Dynamic Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# fastbootd
PRODUCT_PACKAGES += \
	android.hardware.fastboot@1.1-impl.pixel \
	fastbootd

#google iwlan
PRODUCT_PACKAGES += \
	Iwlan

#Iwlan test app for userdebug/eng builds
ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
PRODUCT_PACKAGES += \
	IwlanTestApp
endif

PRODUCT_PACKAGES += \
	whitelist \
	libstagefright_hdcp \
	libskia_opt

#PRODUCT_PACKAGES += \
	mfc_fw.bin \
	calliope_sram.bin \
	calliope_dram.bin \
	calliope_iva.bin \
	vts.bin

# This will be called only if IMSService is building with source code for dev branches.
$(call inherit-product-if-exists, vendor/samsung_slsi/telephony/$(BOARD_USES_SHARED_VENDOR_TELEPHONY)/shannon-ims/device-vendor.mk)

PRODUCT_PACKAGES += ShannonIms

PRODUCT_PACKAGES += ShannonRcs

# Exynos RIL and telephony
# Multi SIM(DSDS)
SIM_COUNT := 2
SUPPORT_MULTI_SIM := true
# Support NR
SUPPORT_NR := true
# Support 5G on both stacks
SUPPORT_NR_DS := true
# Using IRadio 2.1
USE_RADIO_HAL_2_1 := true
# Using Early Send Device Info
USE_EARLY_SEND_DEVICE_INFO := true
# Using New Radio Access Format to modem
USE_NEW_RADIO_ACCESS_SPECIFIER_FORMAT := true

#$(call inherit-product, vendor/google_devices/telephony/common/device-vendor.mk)
#$(call inherit-product, vendor/google_devices/zumapro/proprietary/device-vendor.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
#$(call inherit-product, hardware/google_devices/exynos5/exynos5.mk)
#$(call inherit-product-if-exists, hardware/google_devices/zumapro/zumapro.mk)
#$(call inherit-product-if-exists, vendor/google_devices/common/exynos-vendor.mk)
#$(call inherit-product-if-exists, hardware/broadcom/wlan/bcmdhd/firmware/bcm4375/device-bcm.mk)
include device/google/gs-common/sensors/sensors.mk
# Zuma Pro USF configuration is identical to Zuma
$(call soong_config_set,usf,target_soc,zuma)

PRODUCT_COPY_FILES += \
	device/google/zumapro/default-permissions.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/default-permissions/default-permissions.xml \
	device/google/zumapro/component-overrides.xml:$(TARGET_COPY_OUT_VENDOR)/etc/sysconfig/component-overrides.xml \
	frameworks/native/data/etc/handheld_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/handheld_core_hardware.xml \

# Vibrator Diag
PRODUCT_PACKAGES_DEBUG += \
	diag-vibrator \
	diag-vibrator-cs40l25a \
	diag-vibrator-drv2624 \
	$(NULL)

PRODUCT_PACKAGES += \
	android.hardware.health-service.zumapro \
	android.hardware.health-service.zumapro_recovery \

# Audio
# Audio Vendor Prebuilt
$(call soong_config_set,aoc_spk_post_processing,prebuilts_dir,$(RELEASE_GOOGLE_SPKPOSTPROCESSING_ZUMAPRO_DIR))

# Audio HAL Server & Default Implementations
ifeq ($(USE_AUDIO_HAL_AIDL),true)
include device/google/gs-common/audio/aidl.mk
else
include device/google/gs-common/audio/hidl_zuma.mk
endif

## AoC soong
PRODUCT_SOONG_NAMESPACES += \
        vendor/google/whitechapel/aoc

$(call soong_config_set,aoc,target_soc,zumapro)
$(call soong_config_set,aoc,target_product,$(TARGET_PRODUCT))

ifneq (,$(OVERRIDE_MEDIA_VOLUME_STEPS))
PRODUCT_PROPERTY_OVERRIDES += \
	ro.config.media_vol_steps=$(OVERRIDE_MEDIA_VOLUME_STEPS)
endif

# vndservicemanager and vndservice no longer included in API 30+, however needed by vendor code.
# See b/148807371 for reference
PRODUCT_PACKAGES += vndservicemanager
PRODUCT_PACKAGES += vndservice

## TinyTools, debug tool and cs35l41 speaker calibration tool for Audio
ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
PRODUCT_PACKAGES += \
	tinyplay \
	tinycap \
	tinymix \
	tinypcminfo \
	tinyhostless \
	cplay \
	aoc_hal \
	aoc_tuning_inft \
	mahal_test \
	ma_aoc_tuning_test \
	crus_sp_cal \
	pixel_ti_cal
endif

PRODUCT_PACKAGES += \
	google.hardware.media.c2@1.0-service \
	libgc2_store \
	libgc2_base \
	libgc2_av1_dec \
	libbo_av1 \
	libgc2_cwl \
	libgc2_utils

## Start packet router
include device/google/gs101/telephony/pktrouter.mk

# EdgeTPU
include device/google/gs-common/edgetpu/edgetpu.mk
# Config variables for TPU chip on device.
$(call soong_config_set,edgetpu_config,chip,rio_pro)
# TPU firmware
PRODUCT_PACKAGES += edgetpu-rio.fw

# Connectivity Thermal Power Manager
PRODUCT_PACKAGES += \
	ConnectivityThermalPowerManager

# A/B support
PRODUCT_PACKAGES += \
	otapreopt_script \
	update_engine \
	update_engine_sideload \
	update_verifier

# pKVM
$(call inherit-product, packages/modules/Virtualization/apex/product_packages.mk)
PRODUCT_BUILD_PVMFW_IMAGE := true
ifeq ($(RELEASE_AVF_ENABLE_LLPVM_CHANGES),true)
	# Set the environment variable to enable the Secretkeeper HAL service.
	SECRETKEEPER_ENABLED := true
endif

# Enable to build standalone vendor_kernel_boot image.
PRODUCT_BUILD_VENDOR_KERNEL_BOOT_IMAGE := true

# Enable watchdog timeout loop breaker.
PRODUCT_PROPERTY_OVERRIDES += \
	framework_watchdog.fatal_window.second=600 \
	framework_watchdog.fatal_count=3

# Enable zygote critical window.
PRODUCT_PROPERTY_OVERRIDES += \
	zygote.critical_window.minute=10

# Suspend properties
PRODUCT_PROPERTY_OVERRIDES += \
    suspend.short_suspend_threshold_millis=5000

# Enable Incremental on the device
PRODUCT_PROPERTY_OVERRIDES += \
	ro.incremental.enable=true

# Project
include hardware/google/pixel/common/pixel-common-device.mk

# RadioExt Version
USES_RADIOEXT_V1_7 = true

# Wifi ext
include hardware/google/pixel/wifi_ext/device.mk

# Battery Stats Viewer
PRODUCT_PACKAGES_DEBUG += BatteryStatsViewer

DEVICE_PRODUCT_COMPATIBILITY_MATRIX_FILE += device/google/gs-common/proprietary/android.hardware.gnss.xml
DEVICE_PRODUCT_COMPATIBILITY_MATRIX_FILE += device/google/gs-common/proprietary/vendor.google.aam.xml

# Keymint configuration
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.device_id_attestation.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_id_attestation.xml \
    frameworks/native/data/etc/android.hardware.device_unique_attestation.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.device_unique_attestation.xml

# Call deleteAllKeys if vold detects a factory reset
PRODUCT_VENDOR_PROPERTIES += ro.crypto.metadata_init_delete_all_keys.enabled?=true

# Use HCTR2 for filenames encryption on adoptable storage.
PRODUCT_PROPERTY_OVERRIDES += \
    ro.crypto.volume.options=aes-256-xts:aes-256-hctr2

# Hardware Info Collection
include hardware/google/pixel/HardwareInfo/HardwareInfo.mk

# UFS: the script is used to select the corresponding firmware to run FFU.
PRODUCT_PACKAGES_DEBUG += ufs_firmware_update.sh

ifneq ($(BOARD_WITHOUT_RADIO),true)
# RIL extension service
ifeq (,$(filter aosp_% factory_%,$(TARGET_PRODUCT)))
include device/google/gs-common/pixel_ril/ril.mk
endif
endif

# Touch service
include device/google/gs-common/touch/twoshay/aidl_zuma.mk
include device/google/gs-common/touch/twoshay/twoshay.mk

# TODO: Ensure that GIA is needed in 9th gen pixels
ifneq (,$(filter comet caiman komodo tokay tegu,$(TARGET_PRODUCT)))
RELEASE_PIXEL_GIA_ENABLED := true
endif
ifeq ($(RELEASE_PIXEL_GIA_ENABLED),true)
include device/google/gs-common/input/gia/gia.mk
endif

PRODUCT_CHECK_VENDOR_SEAPP_VIOLATIONS := true

PRODUCT_CHECK_DEV_TYPE_VIOLATIONS := true

PRODUCT_NO_BIONIC_PAGE_SIZE_MACRO := true
PRODUCT_CHECK_PREBUILT_MAX_PAGE_SIZE := true
