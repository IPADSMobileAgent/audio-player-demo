import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { UIContext, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import Global from '../common/Global';
import Logger from '../common/Logger';
import { RemoteRestoreInfo } from '../common/Types';

const TAG: string = '[EntryAbility]';

export default class EntryAbility extends UIAbility {
  private uiContext: UIContext | undefined = undefined;
  private pendingRestoreInfo: RemoteRestoreInfo | undefined = undefined;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    Logger.info(TAG, 'Ability onCreate');
    this.tryToContinue(want, launchParam);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    Logger.info(TAG, 'Ability onNewWant');
    this.tryToContinue(want, launchParam);
  }

  tryToContinue(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, 'Try to continue, launchReason: ' + launchParam.launchReason);
    if (want.parameters !== undefined && want.parameters.restoreInfo != undefined) {
      Global.RestoreInfo = want.parameters.restoreInfo as RemoteRestoreInfo;
      Global.RestoreInfo.shouldContinue = true;
      Logger.info(TAG, `Should continue to song index ${Global.RestoreInfo.playIndex}, time ${Global.RestoreInfo.currentTime}`);

      // On a cold start, defer the dialog until the window has loaded its content.
      this.pendingRestoreInfo = Global.RestoreInfo;
      this.showRestoreDialog();
    }
  }

  private showRestoreDialog(): void {
    if (this.uiContext === undefined || this.pendingRestoreInfo === undefined) {
      return;
    }
    const restoreInfo = this.pendingRestoreInfo;
    this.pendingRestoreInfo = undefined;
    this.uiContext.getPromptAction().showDialog({
      title: `Received message from another device`,
      message: `Should continue to song index ${restoreInfo.playIndex}, time ${restoreInfo.currentTime / 1000}s`,
      buttons: [
        {
          text: "OK",
          color: '#000000'
        }
      ]
    }).catch((err: BusinessError) => {
      Logger.error(TAG, `Failed to show restore dialog: [${err.code}] ${err.message}`);
    });
  }

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult | Promise<AbilityConstant.OnContinueResult> {

    wantParam['restoreInfo'] = Global.PlayerManager.exportRestoreInfo();
    return AbilityConstant.OnContinueResult.AGREE;
  }

  onDestroy(): void {
    Logger.info(TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    Logger.info(TAG, 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/PlayerHome', (err) => {
      if (err.code) {
        Logger.info(TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      Logger.info(TAG, 'Succeeded in loading the content.');
      this.uiContext = windowStage.getMainWindowSync().getUIContext();
      this.showRestoreDialog();
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    this.uiContext = undefined;
    Logger.info(TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    Logger.info(TAG, 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    Logger.info(TAG, 'Ability onBackground');
  }
}
