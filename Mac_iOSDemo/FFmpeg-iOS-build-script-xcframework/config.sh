#!/bin/sh

FF_VERSION="4.2.4"
#FF_VERSION="snapshot-git"
if [[ $FFMPEG_VERSION != "" ]]; then
  FF_VERSION=$FFMPEG_VERSION
fi

SOURCE="../"
XCODE_PATH=$(xcode-select -p)
LIBRARY_NAME="FFmpeg"
LIBRARY_FILE="$LIBRARY_NAME.a"

XCFRAMEWORK_FILE="$LIBRARY_NAME.xcframework"

# 尝试过 enable-ffmpeg ffplay ffprobe ffserver, 打包成XCFramework的时候会报错
CONFIGURE_FLAGS="\
                --disable-gpl \
                --disable-nonfree \
				--enable-cross-compile \
				--disable-debug \
				--disable-indevs --disable-outdevs \
				--enable-pic \
                --enable-runtime-cpudetect \
                --disable-gray \
                --disable-swscale-alpha \
                --disable-programs \
                --enable-ffmpeg \
                --enable-ffplay \
                --enable-ffprobe \
                --enable-ffserver \
                --disable-doc \
                --disable-htmlpages \
                --disable-manpages \
                --disable-podpages \
                --disable-txtpages \
                --disable-avdevice \
                --enable-avcodec \
                --enable-avformat \
                --enable-avutil \
                --enable-swresample \
                --enable-swscale \
                --disable-postproc \
                --enable-avfilter \
                --disable-avresample \
                --enable-network \
                --disable-d3d11va \
                --disable-dxva2 \
                --disable-vaapi \
                --disable-vdpau \
                --disable-encoders \
                --enable-encoder=png \
                --enable-encoder=mjpeg \
                --enable-encoder=mpeg4 \
                --enable-encoder=aac \
                --enable-encoder=h264 \
                --enable-encoder=hevc \
                --disable-decoders \
                --enable-decoder=aac \
                --enable-decoder=aac_latm \
                --enable-decoder=flv \
                --enable-decoder=h264 \
                --enable-decoder=mp3* \
                --enable-decoder=vp6f \
                --enable-decoder=flac \
                --enable-decoder=hevc \
                --enable-decoder=mjpeg \
                --enable-decoder=mpeg4 \
                --enable-decoder=pcm_s16le \
                --disable-hwaccels \
                --disable-muxers \
                --enable-muxer=mp4 \
                --enable-muxer=image2 \
                --enable-muxer=mov \
                --enable-muxer=mjpeg \
                --enable-muxer=avi \
                --enable-muxer=h264 \
                --disable-demuxers \
                --enable-demuxer=rtsp \
                --enable-demuxer=mjpeg \
                --enable-demuxer=avi \
                --enable-demuxer=h264 \
                --enable-demuxer=pcm_s16le \
                --enable-demuxer=aac \
                --enable-demuxer=concat \
                --enable-demuxer=data \
                --enable-demuxer=flv \
                --enable-demuxer=hls \
                --enable-demuxer=live_flv \
                --enable-demuxer=mov \
                --enable-demuxer=mp3 \
                --enable-demuxer=mpegps \
                --enable-demuxer=mpegts \
                --enable-demuxer=mpegvideo \
                --enable-demuxer=flac \
                --enable-demuxer=hevc \
                --enable-demuxer=webm_dash_manifest \
                --disable-parsers \
                --enable-parser=mjpeg \
                --enable-parser=mpeg4video \
                --enable-parser=aac \
                --enable-parser=aac_latm \
                --enable-parser=h264 \
                --enable-parser=flac \
                --enable-parser=hevc \
                --enable-bsfs \
                --enable-bsf=chomp \
                --enable-bsf=dca_core \
                --enable-bsf=dump_extradata \
                --enable-bsf=hevc_mp4toannexb \
                --enable-bsf=imx_dump_header \
                --enable-bsf=mjpeg2jpeg \
                --enable-bsf=mjpega_dump_header \
                --enable-bsf=mov2textsub \
                --enable-bsf=mp3_header_decompress \
                --enable-bsf=mpeg4_unpack_bframes \
                --enable-bsf=noise \
                --enable-bsf=remove_extradata \
                --enable-bsf=text2movsub \
                --enable-bsf=vp9_superframe \
                --disable-protocols \
                --enable-protocol=async \
                --enable-protocol=file \
                --enable-protocol=udp \
                --enable-protocol=tcp \
                --enable-protocol=rtp \
                --disable-devices \
                --disable-filters \
                --enable-filter=nullsrc \
                --enable-filter=nullsink \
                --enable-filter=hflip \
                --enable-filter=vflip \
                --enable-filter=rotate \
                --enable-filter=transpose \
                --enable-filter=anullsrc \
                --enable-filter=anullsink \
                --enable-filter=aresample \
                --disable-audiotoolbox \
                --disable-videotoolbox \
                --disable-iconv \
                --disable-bzlib \
                --disable-vda"

if [ "$X264" ]
then
		CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
fi

if [ "$FDK_AAC" ]
then
		CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfdk-aac --enable-nonfree"
fi

function ConfigureForIOS() {
		local arch=$1
		DEPLOYMENT_TARGET="9.0"
		PLATFORM="iPhoneOS"

    LIBTOOL_FLAGS="\
		 -syslibroot $XCODE_PATH/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk \
		 -L$XCODE_PATH/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/iOSSupport/usr/lib"

    CFLAGS="-arch $arch"

		if [ "$arch" = "i386" -o "$arch" = "x86_64" ]
		then
				PLATFORM="iPhoneSimulator"
				CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
				CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-asm"
		else
				CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
				if [ "$ARCH" = "arm64" ]
				then
						EXPORT="GASPP_FIX_XCODE5=1"
				fi
		fi
}

function ConfigureForTVOS() {
		local arch=$1
		DEPLOYMENT_TARGET="12.0"
		PLATFORM="AppleTVOS"

    LIBTOOL_FLAGS="\
		 -syslibroot $XCODE_PATH/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS.sdk \
		 -L$XCODE_PATH/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS.sdk/System/usr/lib"

    CFLAGS="-arch $arch"

		if [ "$arch" = "i386" -o "$arch" = "x86_64" ]
		then
				PLATFORM="AppleTVSimulator"
				CFLAGS="$CFLAGS -mtvos-simulator-version-min=$DEPLOYMENT_TARGET"
				CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-asm"
		else
				CFLAGS="$CFLAGS -mtvos-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
				if [ "$ARCH" = "arm64" ]
				then
						EXPORT="GASPP_FIX_XCODE5=1"
				fi
		fi
}

function ConfigureForMacOS() {
		local arch=$1
		DEPLOYMENT_TARGET="10.14"
		PLATFORM="MacOSX"

    LIBTOOL_FLAGS="\
		 -syslibroot $XCODE_PATH/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
		 -L$XCODE_PATH/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/usr/lib"

    CFLAGS="-arch $arch"
		CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-asm"
		CFLAGS="$CFLAGS -mmacosx-version-min=$DEPLOYMENT_TARGET"
}

function ConfigureForMacCatalyst() {
		local arch=$1
		DEPLOYMENT_TARGET="10.15"
		PLATFORM="iPhoneOS"

    LIBTOOL_FLAGS="\
		-syslibroot $XCODE_PATH/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk \
		-L$XCODE_PATH/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk/System/iOSSupport/usr/lib \
		-L$XCODE_PATH/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/maccatalyst"

		CFLAGS="-arch $arch"
		CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-asm"

		CFLAGS="$CFLAGS -target x86_64-apple-ios13.0-macabi \
						-isysroot $XCODE_PATH/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
						-isystem $XCODE_PATH/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/iOSSupport/usr/include \
						-iframework $XCODE_PATH/Platforms/MacOSX.platform/Developer/SDKs/MacOS.sdk/System/iOSSupport/System/Library/Frameworks"

		LDFLAGS="$LDFLAGS -target x86_64-apple-ios13.0-macabi \
				-isysroot $XCODE_PATH/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
				-L$XCODE_PATH/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/iOSSupport/usr/lib \
				-L$XCODE_PATH/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/maccatalyst \
				-iframework $XCODE_PATH/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/iOSSupport/System/Library/Frameworks"
}

# supported platforms are: "ffmpeg_ios", "ffmpeg_tvos", "ffmpeg_macos", "ffmpeg_maccatalyst"

function Architectures() {
		local platform=$1

		case $platform in
				ffmpeg_ios)					echo "arm64 x86_64" ;;
				ffmpeg_tvos) 				echo "arm64 x86_64" ;;
				ffmpeg_macos)				echo "x86_64" ;;
				ffmpeg_maccatalyst)	echo "x86_64" ;;
		esac
}

function Configure() {
		local platform=$1
		local arch=$2

		echo "${ORANGE}Configuring for platform: $platform, arch: $arch"

		case $platform in
				ffmpeg_ios)					ConfigureForIOS $arch ;;
				ffmpeg_tvos) 				ConfigureForTVOS $arch ;;
				ffmpeg_macos)				ConfigureForMacOS $arch ;;
				ffmpeg_maccatalyst)	ConfigureForMacCatalyst $arch ;;
		esac
}
