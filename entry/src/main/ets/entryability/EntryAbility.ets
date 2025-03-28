import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import Global from '../common/Global';
import Logger from '../common/Logger';
import { RemoteRestoreInfo } from '../common/Types';
import {promptAction} from '@kit.ArkUI';

const TAG: string = '[EntryAbility]';

export default class EntryAbility extends UIAbility {

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

      promptAction.showDialog({
        title: `Received message from another device`,
        message: `Should continue to song index ${Global.RestoreInfo.playIndex}, time ${Global.RestoreInfo.currentTime / 1000}s`,
        buttons: [
          {
            text: "OK",
            color: '#000000'
          }
        ]
      })
    }
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
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
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