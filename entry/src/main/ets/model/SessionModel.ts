import { avSession } from '@kit.AVSessionKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

import Logger from '../common/Logger';

const TAG: string = '[SessionModel]'

export class SessionManager {
  session: avSession.AVSession;

  constructor(context: common.Context) {
    avSession.createAVSession(context, 'DemoPlayer', 'audio').then((s: avSession.AVSession) => {
      this.session = s;
      Logger.info(TAG, `Created session, id = ${s.sessionId}`);
    }).catch((err: BusinessError) => {
      Logger.error(TAG, `Failed to create session: ${err.message}`);
    })
  }

  setState(state: avSession.PlaybackState) {
    this.session.setAVPlaybackState({ state: state }).then(() => {
      Logger.info(TAG, `Session state set to ${state}`);
    }).catch((err: BusinessError) => {
      Logger.error(TAG, `Session state set error: ${err.message}`);
    });
  }
}