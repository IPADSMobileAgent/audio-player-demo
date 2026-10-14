import { ProgressBar } from '../view/ProgressBar';
import { SongList } from '../view/SongList';
import { ControlBar } from '../view/ControlBar';
import { DeviceDialog } from '../view/DeviceDialog';
import { MUSIC_DATA } from '../common/MockSongs';
import { Song, PlayerState, PlayMode } from '../common/Types';
import Global from '../common/Global';
import Logger from '../common/Logger';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
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
  private requestingDevicePermission: boolean = false;
  private startingRemoteAbility: boolean = false;

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
              this.discoverDevices();
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
              this.stopDiscovering();
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
              this.startRemoteAbility();
            })

          Button('Device List')
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
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
    if (context === undefined) {
      Logger.error(TAG, 'UIAbility context is unavailable');
      return;
    }
    // this.player.setPlayerCallback();
    this.fillPlayList(context).then(() => {
      Logger.info(TAG, 'PlayList is ready');
    });
    Global.InitializeManagers(context);

    Global.PlayerManager.setPlayList(this.playList);
    Global.PlayerManager.setParent(this);
    this.discoverDevices(false);
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

  async requestPermissions(context: common.UIAbilityContext, permissions: Array<Permissions>): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const result = await atManager.requestPermissionsFromUser(context, permissions);
    Logger.info(TAG, `Permission result: ${JSON.stringify(result)}`);
    return result.authResults.length === permissions.length &&
      result.authResults.every((status) => status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
  }

  private showMessage(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  private async discoverDevices(showStatus: boolean = true): Promise<void> {
    if (this.requestingDevicePermission) {
      return;
    }
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
    if (context === undefined) {
      this.showMessage('The application is not ready. Try again.');
      return;
    }
    this.requestingDevicePermission = true;
    try {
      const manager = Global.RemoteDeviceManager;
      if (!manager.isReady()) {
        const granted = await this.requestPermissions(context, ['ohos.permission.DISTRIBUTED_DATASYNC']);
        if (!granted) {
          Logger.warn(TAG, 'Distributed data permission was not granted');
          this.showMessage('Device discovery requires permission. Allow it and tap Discover devices again.');
          return;
        }
        manager.initialize();
      }
      const started = manager.startDiscover();
      if (showStatus) {
        this.showMessage(started ? 'Discovering devices...' : 'Device discovery is already running.');
      }
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(TAG, `Discover devices failed: [${error.code}] ${error.message}`);
      this.showMessage(`Device discovery failed: ${error.message}`);
    } finally {
      this.requestingDevicePermission = false;
    }
  }

  private stopDiscovering(): void {
    try {
      Global.RemoteDeviceManager.stopDiscover();
      this.showMessage('Device discovery stopped.');
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(TAG, `Stop discovery failed: [${error.code}] ${error.message}`);
      this.showMessage(`Could not stop discovery: ${error.message}`);
    }
  }

  private async startRemoteAbility(): Promise<void> {
    if (this.startingRemoteAbility) {
      return;
    }
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
    if (context === undefined) {
      this.showMessage('The application is not ready. Try again.');
      return;
    }
    this.startingRemoteAbility = true;
    try {
      await Global.RemoteDeviceManager.startRemoteAbility(context, Global.PlayerManager.exportRestoreInfo());
      this.showMessage('App started on the remote device.');
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(TAG, `Remote startup failed: [${error.code}] ${error.message}`);
      this.showMessage(`Could not start the remote app: ${error.message}`);
    } finally {
      this.startingRemoteAbility = false;
    }
  }

  showDeviceDialog() {
    if (!Global.RemoteDeviceManager.isReady()) {
      this.showMessage('Tap Discover devices and grant permission first.');
      return;
    }
    if (this.dialogController !== undefined) {
      this.dialogController.close();
    }
    this.dialogController = new CustomDialogController({
      builder: DeviceDialog({}),
      autoCancel: true
    })
    this.dialogController.open();
    Logger.info(TAG, 'Device dialog open done')
  }
}
