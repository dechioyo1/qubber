import os
import logging
from PySide6.QtCore import QObject, Property, Signal, Slot

DEFAULT_THEME_CONTENT = """//
// This is a sample Telegram Desktop theme file.
// It was generated from the 'colors.palette' style file.
//
// To create a theme with a background image included you should
// put two files in a .zip archive:
//
// First one is the color scheme like the one you're viewing
// right now, this file should be named 'colors.tdesktop-theme'.
//
// Second one should be the background image and it can be named
// 'background.jpg', 'background.png', 'tiled.jpg' or 'tiled.png'.
// You should name it 'background' (if you'd like it not to be tiled),
// or it can be named 'tiled' (if you'd like it to be tiled).
//
// After that you need to change the extension of your .zip archive
// to 'tdesktop-theme', so you'll have:
//
// mytheme.tdesktop-theme
// |-colors.tdesktop-theme
// |-background.jpg (or tiled.jpg, background.png, tiled.png)
//

windowBg: #ffffff;
windowFg: #000000;
windowBgOver: #f1f1f1;
windowBgRipple: #e5e5e5;
windowFgOver: windowFg;
windowSubTextFg: #999999;
windowSubTextFgOver: #919191;
windowBoldFg: #222222;
windowBoldFgOver: #222222;
windowBgActive: #3587e4;
windowFgActive: #ffffff;
windowActiveTextFg: #126dcd;
windowShadowFg: #000000;
windowShadowFgFallback: #f1f1f1;
shadowFg: #00000018;
slideFadeOutBg: #0000003c;
slideFadeOutShadowFg: windowShadowFg;
imageBg: #000000;
imageBgTransparent: #ffffff;
activeButtonBg: windowBgActive;
activeButtonBgOver: #2f85db;
activeButtonBgRipple: #1a75d0;
activeButtonFg: windowFgActive;
activeButtonFgOver: activeButtonFg;
activeButtonSecondaryFg: #c9e4ff;
activeButtonSecondaryFgOver: activeButtonSecondaryFg;
activeLineFg: #2d83de;
activeLineFgError: #e48383;
lightButtonBg: windowBg;
lightButtonBgOver: #e2edfa;
lightButtonBgRipple: #c6dbf6;
lightButtonFg: windowActiveTextFg;
lightButtonFgOver: lightButtonFg;
attentionButtonFg: #d14e4e;
attentionButtonFgOver: #d14e4e;
attentionButtonBgOver: #fcdfde;
attentionButtonBgRipple: #f4c3c2;
outlineButtonBg: windowBg;
outlineButtonBgOver: lightButtonBgOver;
outlineButtonOutlineFg: windowBgActive;
outlineButtonBgRipple: lightButtonBgRipple;
menuBg: windowBg;
menuBgOver: windowBgOver;
menuBgRipple: windowBgRipple;
menuIconFg: #999999;
menuIconFgOver: #8a8a8a;
menuSubmenuArrowFg: #373737;
menuFgDisabled: #cccccc;
menuSeparatorFg: #f1f1f1;
scrollBarBg: #00000053;
scrollBarBgOver: #0000007a;
scrollBg: #00000000;
scrollBgOver: #0000001a;
smallCloseIconFg: #c7c7c7;
smallCloseIconFgOver: #a3a3a3;
radialFg: windowFgActive;
radialBg: #00000056;
placeholderFg: windowSubTextFg;
placeholderFgActive: #aaaaaa;
inputBorderFg: #e0e0e0;
filterInputBorderFg: #49a4f3;
checkboxFg: #b3b3b3;
sliderBgInactive: #e0e7ef;
sliderBgActive: windowBgActive;
tooltipBg: #eef1f5;
tooltipFg: #5b6580;
tooltipBorderFg: #c8cddb;
titleBg: windowBgOver;
titleShadow: #00000003;
titleButtonFg: #ababab;
titleButtonBgOver: #e5e5e5;
titleButtonFgOver: #9a9a9a;
titleButtonCloseBgOver: #e81123;
titleButtonCloseFgOver: windowFgActive;
titleFgActive: #3e3c3e;
titleFg: #acacac;
trayCounterBg: #f23c34;
trayCounterBgMute: #888888;
trayCounterFg: #ffffff;
trayCounterBgMacInvert: #ffffff;
trayCounterFgMacInvert: #ffffff01;
layerBg: #0000007f;
cancelIconFg: menuIconFg;
cancelIconFgOver: menuIconFgOver;
boxBg: windowBg;
boxTextFg: windowFg;
boxTextFgGood: #4ab44a;
boxTextFgError: #d84d4d;
boxTitleFg: #404040;
boxSearchBg: boxBg;
boxSearchCancelIconFg: cancelIconFg;
boxSearchCancelIconFgOver: cancelIconFgOver;
boxTitleAdditionalFg: #808080;
boxTitleCloseFg: cancelIconFg;
boxTitleCloseFgOver: cancelIconFgOver;
membersAboutLimitFg: windowSubTextFgOver;
contactsBg: windowBg;
contactsBgOver: windowBgOver;
contactsNameFg: boxTextFg;
contactsStatusFg: windowSubTextFg;
contactsStatusFgOver: windowSubTextFgOver;
contactsStatusFgOnline: windowActiveTextFg;
photoCropFadeBg: layerBg;
photoCropPointFg: #ffffff7f;
introBg: windowBg;
introTitleFg: windowBoldFg;
introDescriptionFg: windowSubTextFg;
introErrorFg: windowSubTextFg;
introCoverTopBg: #0c68d0;
introCoverBottomBg: #2f90f0;
introCoverIconsFg: #53a6ff;
introCoverPlaneTrace: #53a6ff69;
introCoverPlaneInner: #c5d2e8;
introCoverPlaneOuter: #9eb4d4;
introCoverPlaneTop: #ffffff;
dialogsMenuIconFg: menuIconFg;
dialogsMenuIconFgOver: menuIconFgOver;
dialogsBg: windowBg;
dialogsNameFg: windowBoldFg;
dialogsChatIconFg: dialogsNameFg;
dialogsDateFg: windowSubTextFg;
dialogsTextFg: windowSubTextFg;
dialogsTextFgService: windowActiveTextFg;
dialogsDraftFg: #dd4b39;
dialogsVerifiedIconBg: windowBgActive;
dialogsVerifiedIconFg: windowFgActive;
dialogsSendingIconFg: #c1c1c1;
dialogsSentIconFg: #2483e8;
dialogsUnreadBg: windowBgActive;
dialogsUnreadBgMuted: #bbbbbb;
dialogsUnreadFg: windowFgActive;
dialogsArchiveFg: #525252;
dialogsOnlineBadgeFg: #4dc920;
dialogsBgOver: windowBgOver;
dialogsNameFgOver: windowBoldFgOver;
dialogsChatIconFgOver: dialogsNameFgOver;
dialogsDateFgOver: windowSubTextFgOver;
dialogsTextFgOver: windowSubTextFgOver;
dialogsTextFgServiceOver: dialogsTextFgService;
dialogsDraftFgOver: dialogsDraftFg;
dialogsVerifiedIconBgOver: dialogsVerifiedIconBg;
dialogsVerifiedIconFgOver: dialogsVerifiedIconBg;
dialogsSendingIconFgOver: dialogsSendingIconFg;
dialogsSentIconFgOver: dialogsSentIconFg;
dialogsUnreadBgOver: dialogsUnreadBg;
dialogsUnreadBgMutedOver: dialogsUnreadBgMuted;
dialogsUnreadFgOver: dialogsUnreadFg;
dialogsArchiveFgOver: #525252;
dialogsBgActive: #3682d9;
dialogsNameFgActive: windowFgActive;
dialogsChatIconFgActive: dialogsNameFgActive;
dialogsDateFgActive: windowFgActive;
dialogsTextFgActive: windowFgActive;
dialogsTextFgServiceActive: dialogsTextFgActive;
dialogsDraftFgActive: #c3d8f7;
dialogsVerifiedIconBgActive: dialogsTextFgActive;
dialogsVerifiedIconFgActive: dialogsBgActive;
dialogsSendingIconFgActive: #ffffff99;
dialogsSentIconFgActive: dialogsTextFgActive;
dialogsUnreadBgActive: dialogsTextFgActive;
dialogsUnreadBgMutedActive: dialogsDraftFgActive;
dialogsUnreadFgActive: dialogsBgActive;
dialogsOnlineBadgeFgActive: #ffffff;
dialogsForwardBg: dialogsBgActive;
dialogsForwardFg: dialogsNameFgActive;
searchedBarBg: windowBgOver;
searchedBarBorder: shadowFg;
searchedBarFg: windowSubTextFgOver;
topBarBg: windowBg;
emojiPanBg: windowBg;
emojiPanCategories: #f7f7f7;
emojiPanHeaderFg: windowSubTextFg;
emojiPanHeaderBg: #fffffff2;
emojiIconFg: #999999;
stickerPanDeleteBg: #000000cc;
stickerPanDeleteFg: windowFgActive;
stickerPreviewBg: #ffffffb0;
historyTextInFg: windowFg;
historyTextOutFg: windowFg;
historyCaptionInFg: historyTextInFg;
historyCaptionOutFg: historyTextOutFg;
historyFileNameInFg: historyTextInFg;
historyFileNameOutFg: historyTextOutFg;
historyOutIconFg: #057ae8;
historyOutIconFgSelected: #1178e6;
historyIconFgInverted: windowFgActive;
historySendingOutIconFg: #98b5d9;
historySendingInIconFg: #9ea9b5;
historySendingInvertedIconFg: #ffffffc8;
historySystemBg: #8698b47f;
historySystemBgSelected: #b9c3d4a2;
historySystemFg: windowFgActive;
historyUnreadBarBg: #fcfbfa;
historyUnreadBarBorder: shadowFg;
historyUnreadBarFg: #4d78b4;
historyForwardChooseBg: #0000004c;
historyForwardChooseFg: windowFgActive;
historyPeer1NameFg: #c03d33;
historyPeer1UserpicBg: #ff845e;
historyPeer2NameFg: #4fad2d;
historyPeer2UserpicBg: #9ad164;
historyPeer3NameFg: #d09306;
historyPeer3UserpicBg: #e5ca77;
historyPeer4NameFg: windowActiveTextFg;
historyPeer4UserpicBg: #518ffa;
historyPeer5NameFg: #8544d6;
historyPeer5UserpicBg: #b694f9;
historyPeer6NameFg: #cd4073;
historyPeer6UserpicBg: #ff8aac;
historyPeer7NameFg: #227fad;
historyPeer7UserpicBg: #52b3e4;
historyPeer8NameFg: #ce671b;
historyPeer8UserpicBg: #febb5b;
historyPeerUserpicFg: windowFgActive;
historyPeer1UserpicBg2: #d45246;
historyPeer2UserpicBg2: #46ba43;
historyPeer3UserpicBg2: #e5ca77;
historyPeer4UserpicBg2: #366ecf;
historyPeer5UserpicBg2: #6c61df;
historyPeer6UserpicBg2: #d95574;
historyPeer7UserpicBg2: #2c7dd4;
historyPeer8UserpicBg2: #f68136;
historyPeerSavedMessagesBg2: historyPeer4UserpicBg2;
historyScrollBarBg: #00000040;
historyScrollBarBgOver: #00000053;
historyScrollBg: #00000000;
historyScrollBgOver: #0000001a;
msgInBg: windowBg;
msgInBgSelected: #b7d5fc;
msgOutBg: #dcebfd;
msgOutBgSelected: #b7d5fc;
msgSelectOverlay: #2c6cd44c;
msgStickerOverlay: #2c6cd47f;
msgInServiceFg: windowActiveTextFg;
msgInServiceFgSelected: windowActiveTextFg;
msgOutServiceFg: windowActiveTextFg;
msgOutServiceFgSelected: windowActiveTextFg;
msgInShadow: #7185a229;
msgInShadowSelected: #184b9730;
msgOutShadow: #0b43911a;
msgOutShadowSelected: #265baa29;
msgInDateFg: #9ea7b6;
msgInDateFgSelected: #6489c5;
msgOutDateFg: #829cc2;
msgOutDateFgSelected: #668fc2;
msgServiceFg: windowFgActive;
msgServiceBg: #003c8059;
msgServiceBgSelected: #5997dda2;
msgInReplyBarColor: activeLineFg;
msgInReplyBarSelColor: activeLineFg;
msgOutReplyBarColor: historyOutIconFg;
msgOutReplyBarSelColor: historyOutIconFgSelected;
msgImgReplyBarColor: msgServiceFg;
msgInMonoFg: #496691;
msgOutMonoFg: #496691;
msgDateImgFg: msgServiceFg;
msgDateImgBg: #00000054;
msgDateImgBgOver: #00000074;
msgDateImgBgSelected: #173a7187;
msgFileThumbLinkInFg: #126dcd;
msgFileThumbLinkInFgSelected: lightButtonFgOver;
msgFileThumbLinkOutFg: #086cd0;
msgFileThumbLinkOutFgSelected: lightButtonFgOver;
msgFileInBg: windowBgActive;
msgFileInBgOver: #4592e4;
msgFileInBgSelected: #4889d3;
msgFileOutBg: windowBgActive;
msgFileOutBgOver: #4592e4;
msgFileOutBgSelected: #4889d3;
msgFile1Bg: #6b9bdf;
msgFile1BgDark: #5487ce;
msgFile1BgOver: #4b7dc4;
msgFile1BgSelected: #4780d0;
msgFile2Bg: #61b96e;
msgFile2BgDark: #4da859;
msgFile2BgOver: #44a050;
msgFile2BgSelected: #46a07e;
msgFile3Bg: #e47272;
msgFile3BgDark: #cd5b5e;
msgFile3BgOver: #c35154;
msgFile3BgSelected: #9f6a82;
msgFile4Bg: #efc274;
msgFile4BgDark: #e6a561;
msgFile4BgOver: #dc9c5a;
msgFile4BgSelected: #b19d84;
msgWaveformInActive: windowBgActive;
msgWaveformInActiveSelected: #4889d3;
msgWaveformInInactive: #d3dbe6;
msgWaveformInInactiveSelected: #98b4e1;
msgWaveformOutActive: windowBgActive;
msgWaveformOutActiveSelected: #4889d3;
msgWaveformOutInactive: #b0cae7;
msgWaveformOutInactiveSelected: #82abdb;
msgBotKbOverBgAdd: #ffffff20;
msgBotKbIconFg: msgServiceFg;
msgBotKbRippleBg: #00000020;
mediaInFg: msgInDateFg;
mediaInFgSelected: msgInDateFgSelected;
mediaOutFg: #7d97bd;
mediaOutFgSelected: #597fb3;
youtubePlayIconBg: #e83131c8;
youtubePlayIconFg: windowFgActive;
videoPlayIconBg: #0000007f;
videoPlayIconFg: #ffffff;
reportSpamBg: emojiPanHeaderBg;
reportSpamFg: windowFg;
historyToDownShadow: #00000040;
historyComposeAreaBg: msgInBg;
historyComposeAreaFg: historyTextInFg;
historyComposeAreaFgService: msgInDateFg;
historyComposeIconFg: menuIconFg;
historyComposeIconFgOver: menuIconFgOver;
historySendIconFg: windowBgActive;
historySendIconFgOver: windowBgActive;
historyPinnedBg: historyComposeAreaBg;
historyReplyBg: historyComposeAreaBg;
historyReplyCancelFg: cancelIconFg;
historyReplyCancelFgOver: cancelIconFgOver;
historyComposeButtonBg: historyComposeAreaBg;
historyComposeButtonBgOver: windowBgOver;
historyComposeButtonBgRipple: windowBgRipple;
overviewCheckBg: #00000040;
overviewCheckFg: windowBg;
overviewCheckFgActive: windowBg;
overviewPhotoSelectOverlay: #358ce433;
profileStatusFgOver: #798fb2;
notificationsBoxMonitorFg: windowFg;
notificationsBoxScreenBg: dialogsBgActive;
notificationSampleUserpicFg: windowBgActive;
notificationSampleCloseFg: #d7d7d7;
notificationSampleTextFg: #d7d7d7;
notificationSampleNameFg: #939393;
mainMenuBg: windowBg;
mainMenuCoverBg: dialogsBgActive;
mainMenuCoverFg: windowFgActive;
mediaPlayerBg: windowBg;
mediaPlayerActiveFg: windowBgActive;
mediaPlayerInactiveFg: sliderBgInactive;
mediaPlayerDisabledFg: #98c2ef;
mediaviewFileBg: windowBg;
mediaviewFileNameFg: windowFg;
mediaviewFileSizeFg: windowSubTextFg;
mediaviewFileRedCornerFg: #d55959;
mediaviewFileYellowCornerFg: #e8a659;
mediaviewFileGreenCornerFg: #49a957;
mediaviewFileBlueCornerFg: #5186cf;
mediaviewFileExtFg: activeButtonFg;
mediaviewMenuBg: #383838;
mediaviewMenuBgOver: #505050;
mediaviewMenuBgRipple: #676767;
mediaviewMenuFg: windowFgActive;
mediaviewBg: #222222eb;
mediaviewVideoBg: imageBg;
mediaviewControlBg: #0000003c;
mediaviewControlFg: windowFgActive;
mediaviewCaptionBg: #11111180;
mediaviewCaptionFg: mediaviewControlFg;
mediaviewSaveMsgBg: toastBg;
mediaviewSaveMsgFg: toastFg;
mediaviewPlaybackActive: #c7c7c7;
mediaviewPlaybackInactive: #252525;
mediaviewPlaybackActiveOver: #ffffff;
mediaviewPlaybackInactiveOver: #474747;
mediaviewPlaybackProgressFg: #ffffffc7;
mediaviewPlaybackIconFg: mediaviewPlaybackActive;
mediaviewPlaybackIconFgOver: mediaviewPlaybackActiveOver;
mediaviewTransparentBg: #ffffff;
mediaviewTransparentFg: #cccccc;
notificationBg: windowBg;
"""

def parse_telegram_theme(file_path):
    """Parse a Telegram Desktop theme file and resolve color keys."""
    if not os.path.exists(file_path):
        try:
            os.makedirs(os.path.dirname(file_path), exist_ok=True)
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(DEFAULT_THEME_CONTENT)
            logging.info(f"Created default theme file at {file_path}")
        except Exception as e:
            logging.error(f"Failed to create default theme file: {e}")

    raw_dict = {}
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("//"):
                    continue
                # Remove inline comment
                if "//" in line:
                    line = line.split("//")[0].strip()
                if ":" in line:
                    key, val = line.split(":", 1)
                    key = key.strip()
                    val = val.strip().rstrip(";")
                    raw_dict[key] = val
    except Exception as e:
        logging.error(f"Error reading theme file at {file_path}: {e}")

    # Resolve key references
    resolved = {}
    def resolve_val(val, depth=0):
        if depth > 15:
            return val
        val = val.strip()
        if val in raw_dict:
            return resolve_val(raw_dict[val], depth + 1)
        return val

    for k, v in raw_dict.items():
        resolved[k] = resolve_val(v)

    def convert_color(hex_str):
        hex_str = hex_str.strip()
        if not hex_str.startswith("#"):
            return hex_str
        # Convert 8-digit hex #RRGGBBAA (Telegram format) to #AARRGGBB (QML format)
        if len(hex_str) == 9:
            r = hex_str[1:3]
            g = hex_str[3:5]
            b = hex_str[5:7]
            a = hex_str[7:9]
            return f"#{a}{r}{g}{b}"
        return hex_str

    return {k: convert_color(v) for k, v in resolved.items()}


class ThemeManager(QObject):
    themeChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.theme_path = os.path.expanduser("~/.config/Qubber/theme")
        self._colors = {}
        self.load_theme()

    @Slot()
    def reloadTheme(self):
        self.load_theme()

    @Slot(str)
    def loadThemeFromFile(self, file_path):
        import shutil
        import urllib.parse
        import urllib.request
        if file_path.startswith("file://"):
            parsed = urllib.parse.urlparse(file_path)
            file_path = urllib.request.url2pathname(parsed.path)
        try:
            os.makedirs(os.path.dirname(self.theme_path), exist_ok=True)
            shutil.copyfile(file_path, self.theme_path)
            self.load_theme()
            logging.info(f"Theme loaded successfully from {file_path}")
        except Exception as e:
            logging.error(f"Failed to load theme from file: {e}")

    def load_theme(self):
        self._colors = parse_telegram_theme(self.theme_path)
        self.themeChanged.emit()

    def get_color(self, key, fallback):
        val = self._colors.get(key)
        if val and val.startswith("#"):
            return val
        return fallback

    @Property(str, notify=themeChanged)
    def colBg(self):
        return self.get_color('windowBg', '#0f172a')

    @Property(str, notify=themeChanged)
    def colCard(self):
        return self.get_color('windowBgOver', '#1e293b')

    @Property(str, notify=themeChanged)
    def colText(self):
        return self.get_color('windowFg', '#f8fafc')

    @Property(str, notify=themeChanged)
    def colMuted(self):
        return self.get_color('windowSubTextFg', '#94a3b8')

    @Property(str, notify=themeChanged)
    def colBorder(self):
        return self.get_color('inputBorderFg', self.get_color('menuSeparatorFg', '#334155'))

    @Property(str, notify=themeChanged)
    def colPrimary(self):
        return self.get_color('windowBgActive', '#6366f1')

    @Property(str, notify=themeChanged)
    def colPrimaryDark(self):
        return self.get_color('activeButtonBgOver', '#4f46e5')

    @Property(str, notify=themeChanged)
    def colAccent(self):
        return self.get_color('windowActiveTextFg', '#8b5cf6')

    @Property(str, notify=themeChanged)
    def colInputBg(self):
        return self.get_color('historyComposeAreaBg', self.get_color('windowBg', '#0f172a'))

    @Property(str, notify=themeChanged)
    def topBarBg(self):
        return self.get_color('titleBg', self.get_color('windowBgOver', '#e8e8e8'))

    @Property(str, notify=themeChanged)
    def topBarFg(self):
        return self.get_color('titleButtonFg', self.get_color('windowFg', '#222222'))

    @Property(str, notify=themeChanged)
    def sidebarBg(self):
        return self.get_color('dialogsBg', self.get_color('windowBg', '#111322'))

    @Property(str, notify=themeChanged)
    def sidebarHeaderBg(self):
        return self.get_color('titleBg', self.get_color('windowBgOver', '#111325'))

    @Property(str, notify=themeChanged)
    def sidebarBgOver(self):
        return self.get_color('dialogsBgOver', self.get_color('windowBgOver', '#1e293b'))

    @Property(str, notify=themeChanged)
    def sidebarBgActive(self):
        return self.get_color('dialogsBgActive', self.get_color('windowBgActive', '#3682d9'))

    @Property(str, notify=themeChanged)
    def msgInBg(self):
        return self.get_color('msgInBg', self.get_color('windowBg', '#1e293b'))

    @Property(str, notify=themeChanged)
    def msgInText(self):
        return self.get_color('historyTextInFg', self.get_color('windowFg', '#f8fafc'))

    @Property(str, notify=themeChanged)
    def msgOutBg(self):
        return self.get_color('msgOutBg', self.get_color('windowBgActive', '#6366f1'))

    @Property(str, notify=themeChanged)
    def msgOutText(self):
        return self.get_color('historyTextOutFg', self.get_color('windowFgActive', '#ffffff'))
