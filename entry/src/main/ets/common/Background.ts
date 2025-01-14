import { common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';

import Logger from '../common/Logger';

const TAG: string = '[BackgroundManager]'

export default class Background {

  public static startBackgroundRunning(context: common.Context) {
    if (context == null || context == undefined) {
      Logger.error(TAG, 'Context is empty');
      return;
    }

    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: "com.demo.audioplayer",
          abilityName: "EntryAbility"
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 114514,
    }

    wantAgent.getWantAgent(wantAgentInfo).then((wa: WantAgent) => {
      try {
        backgroundTaskManager.startBackgroundRunning(context,
          backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, wa).then(() => {
            Logger.info(TAG, 'Application starts continuing task');
        }).catch((error: BusinessError) => {
          Logger.error(TAG, `Application starts continuing task failed, ${error.message}`);
        })
      } catch (error) {
        Logger.error(TAG, `Application starts continuing task failed, ${error}`);
      }
    });
  }

  public static stopBackgroundRunning(context: common.Context) {
    if (context == null || context == undefined) {
      Logger.error(TAG, 'Context is empty');
      return;
    }
    try {
      backgroundTaskManager.stopBackgroundRunning(context).then(() => {
        Logger.info(TAG, 'Application ends continuing task');
      }).catch((error: BusinessError) => {
        Logger.error(TAG, `Application ends continuing task failed, ${error.message}`);
      })
    } catch (error) {
      Logger.error(TAG, `Application ends continuing task failed, ${error}`);
    }
  }
}