import common from '@ohos.app.ability.common';

import { ProgressBar } from '../view/ProgressBar';
import { SongList } from '../view/SongList';
import { ControlBar } from '../view/ControlBar';
import { DeviceDialog } from '../view/DeviceDialog';
import { MUSIC_DATA } from '../common/MockSongs';
import { Song, PlayerState, PlayMode } from '../common/Types';
import Global from '../common/Global';
import Logger from '../common/Logger';
import { abilityAccessCtrl, Permissions, Want, wantConstant } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';

const TAG: string = '[PlayerHome]'

@Entry
@Component
struct PlayerHome {
  @StorageLink("playList") playList: Array<Song> = [];

  @State playerState: PlayerState = PlayerState.NOT_INITIALIZED;
  @State playMode: PlayMode = PlayMode.SEQUENTIAL;

  // For the song list
  @State songIndex: number = 0;

  // For the progress bar
  @State current: number = 0;
  @State total: number = 100;

  private dialogController?: CustomDialogController = undefined;

  build() {
    Column({ space: 20 }) {
      Text(`PlayerState: ${PlayerState[this.playerState]}`)
        .fontSize(35)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      Column({ space: 20 }) {
        Row({ space: 20 }) {
          Button('Discover devices')
            .width('40%')
            .height(50)
            .backgroundColor(0xffffff)
            .borderRadius(12)
            .fontColor(0x333333)
            .fontSize(18)
            .padding({ left: 10, right: 10 })
            .onClick(() => {
              Logger.info(TAG, 'Try to discover the devices');
              Global.RemoteDeviceManager.startDiscover();
            })

          Button('Stop Discover')
            .width('40%')
            .height(50)
            .backgroundColor(0xffffff)
            .borderRadius(12)
            .fontColor(0x333333)
            .fontSize(18)
            .padding({ left: 10, right: 10 })
            .onClick(() => {
              Global.RemoteDeviceManager.stopDiscover();
            })
        }
        .justifyContent(FlexAlign.Center)
        .margin({ top: 10 })

        Row({ space: 20 }) {
          Button('Try StartAbility')
            .width('40%')
            .height(50)
            .backgroundColor(0xffffff)
            .borderRadius(12)
            .fontColor(0x333333)
            .fontSize(18)
            .padding({ left: 10, right: 10 })
            .onClick(() => {
              const networkId = Global.RemoteDeviceManager.exportBoundList()[0].networkId;
              Logger.info(TAG, 'Try to start ' + networkId);
              (getContext(this) as common.UIAbilityContext).startAbility({
                bundleName: 'com.demo.audioplayer',
                abilityName: 'EntryAbility',
                deviceId: networkId,
                parameters: {
                  restoreInfo: Global.PlayerManager.exportRestoreInfo()
                }
              }).then(() => {
                Logger.info(TAG, 'startAbility finished');
              }).catch((err: BusinessError) => {
                Logger.error(TAG, `Error starting, error: [${err.code}] ${err.message}`);
              });
            })

          Button('Show Dialog')
            .width('40%')
            .height(50)
            .backgroundColor(0xffffff)
            .borderRadius(12)
            .fontColor(0x333333)
            .fontSize(18)
            .padding({ left: 10, right: 10 })
            .onClick(() => {
              this.showDeviceDialog();
            })
        }
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 20 })
      }
      .backgroundColor(0xF2F2F2)
      .borderRadius(12)
      .padding({ top: 20, bottom: 20 })
      .margin({ left: '5%', right: '5%' })


      SongList({ selectedIndex: $songIndex })
        .backgroundColor(0xE6E6E6)
        .borderRadius(12)
        .margin({ top: 10, bottom: 10 })

      ProgressBar({ current: $current, total: $total })
        .backgroundColor(0xE6E6E6)
        .borderRadius(12)
        .margin({ top: 10, bottom: 10 })

      ControlBar({ playerState: $playerState, selectedIndex: $songIndex })
        .backgroundColor(0xE6E6E6)
        .borderRadius(12)
        .margin({ top: 10, bottom: 10 })
    }
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(HorizontalAlign.Center)
    .height('90%')
    .width('100%')
  }

  async fillPlayList(ctx: common.UIAbilityContext) {
    MUSIC_DATA.forEach((musicProp) => {
      let avFd = ctx.resourceManager.getRawFdSync(musicProp.filePath) as media.AVFileDescriptor;
      this.playList.push(new Song(musicProp, avFd));
    })
  }

  aboutToAppear() {
    // this.player.setPlayerCallback();
    this.fillPlayList(getContext(this) as common.UIAbilityContext).then(() => {
      Logger.info(TAG, 'PlayList is ready');
    });
    this.requestPermissions(['ohos.permission.DISTRIBUTED_DATASYNC']);

    Global.InitializeManagers(getContext(this));

    Global.PlayerManager.setPlayList(this.playList);
    Global.PlayerManager.setParent(this);
  }

  onPageShow() {
    if (Global.RestoreInfo.shouldContinue) {
      Global.RestoreInfo.shouldContinue = false;
      Logger.info(TAG, 'Player continue!');
      Global.PlayerManager.playIndex(
        Global.RestoreInfo.playIndex,
        Global.PlayerManager.currentTime
      );
    }
  }

  requestPermissions(permissions: Array<Permissions>) {
    let atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(getContext(this), permissions).then((result) => {
      Logger.info(TAG, 'Grant permission success: ' + result);
    }).catch((reason: BusinessError) => {
      Logger.error(TAG, 'Grant permission error: ' + reason.message);
    })
  }

  showDeviceDialog() {
    if (this.dialogController !== undefined) {
      this.dialogController.close();
    }
    this.dialogController = new CustomDialogController({
      builder: DeviceDialog({
        deviceList: Global.RemoteDeviceManager.exportDeviceList(),
        boundList: Global.RemoteDeviceManager.exportBoundList(),
        selectedIndex: -1
      }),
      autoCancel: true
    })
    this.dialogController.open();
    Logger.info(TAG, 'Device dialog open done')
  }
}