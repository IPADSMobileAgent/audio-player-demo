import { common } from '@kit.AbilityKit';

import { PlayerManager } from '../model/PlayerModel';
import { SessionManager } from '../model/SessionModel'
import { RemoteRestoreInfo } from '../common/Types';
import { RemoteDeviceManager } from '../model/RemoteDeviceModel';

const TAG: string = '[Global]'

export default class Global {
  static PlayerManager: PlayerManager;
  static SessionManager: SessionManager;
  static RemoteDeviceManager: RemoteDeviceManager;
  static RestoreInfo: RemoteRestoreInfo = new RemoteRestoreInfo();

  static InitializeManagers(context: common.Context) {
    Global.PlayerManager = new PlayerManager(context);
    Global.SessionManager = new SessionManager(context);
    Global.RemoteDeviceManager = new RemoteDeviceManager();
  }
}