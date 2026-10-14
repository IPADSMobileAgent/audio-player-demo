import { distributedDeviceManager } from "@kit.DistributedServiceKit";
import { common } from '@kit.AbilityKit';

import Logger from '../common/Logger';
import { RemoteRestoreInfo } from '../common/Types';

const TAG: string = '[RemoteDeviceManager]';

// Native authentication callbacks can use reason/errInfo instead of BusinessError.message.
interface DeviceBindingFailure {
  code?: number;
  reason?: number;
  errInfo?: string;
  message?: string;
}

export class RemoteDeviceManager {

  private deviceManager: distributedDeviceManager.DeviceManager | undefined = undefined;
  private discoveredDevices: Map<string, distributedDeviceManager.DeviceBasicInfo> = new Map();
  private connectedDevices: Map<string, distributedDeviceManager.DeviceBasicInfo> = new Map();
  private discovering: boolean = false;
  private deviceListListeners: Set<() => void> = new Set();

  // Call only after DISTRIBUTED_DATASYNC has been granted.
  initialize(): void {
    if (this.isReady()) {
      return;
    }
    try {
      this.deviceManager = distributedDeviceManager.createDeviceManager('com.demo.audioplayer');
      Logger.info(TAG, 'deviceManager created');
      this.setDeviceManagerCallback();
      this.refreshBoundList();
      Logger.info(TAG, 'Device manager initialized');
    } catch (err) {
      // Release partially registered listeners so initialization can be retried.
      if (this.deviceManager !== undefined) {
        try {
          distributedDeviceManager.releaseDeviceManager(this.deviceManager);
        } catch (releaseError) {
          Logger.error(TAG, `Release device manager failed: ${releaseError}`);
        }
      }
      this.deviceManager = undefined;
      Logger.error(TAG, `Initialize device manager failed: ${err}`);
      throw err;
    }
  }

  isReady(): boolean {
    return this.deviceManager !== undefined;
  }

  private getDeviceManager(): distributedDeviceManager.DeviceManager {
    if (this.deviceManager === undefined) {
      throw new Error('Device discovery is not ready. Tap Discover devices first.');
    }
    return this.deviceManager;
  }

  addDeviceListListener(listener: () => void): void {
    this.deviceListListeners.add(listener);
  }

  removeDeviceListListener(listener: () => void): void {
    this.deviceListListeners.delete(listener);
  }

  private notifyDeviceListChanged(): void {
    this.deviceListListeners.forEach((listener) => listener());
  }

  private setDeviceManagerCallback(): void {
    const manager = this.getDeviceManager();
    manager.on('discoverSuccess', (data) => {
      let dev: distributedDeviceManager.DeviceBasicInfo = data.device;
      if (!this.discoveredDevices.has(dev.deviceId)) {
        Logger.info(TAG, `New device: <${dev.deviceId}: ${dev.deviceName}>`);
      }
      this.discoveredDevices.set(dev.deviceId, dev);
      this.notifyDeviceListChanged();
    });
    manager.on('discoverFailure', (data) => {
      this.discovering = false;
      Logger.error(TAG, `discoverFailure data = ${JSON.stringify(data)}`);
    });
    manager.on('deviceStateChange', (data) => {
      let action: distributedDeviceManager.DeviceStateChange = data.action;
      switch (action) {
        case distributedDeviceManager.DeviceStateChange.UNAVAILABLE:
          Logger.info(TAG, `Device ${data.device.deviceName} offline`);
          this.connectedDevices.delete(data.device.deviceId);
          break;
        case distributedDeviceManager.DeviceStateChange.AVAILABLE:
          Logger.info(TAG, `Device ${data.device.deviceName} online`);
          this.connectedDevices.set(data.device.deviceId, data.device);
          break;
        default:
          this.connectedDevices.delete(data.device.deviceId);
          break;
      };
      this.notifyDeviceListChanged();
    })
    manager.on('serviceDie', (info) => {
      Logger.error(TAG, `serviceDie: ${JSON.stringify(info)}`);
      this.deviceManager = undefined;
      this.discovering = false;
      this.discoveredDevices.clear();
      this.connectedDevices.clear();
      this.notifyDeviceListChanged();
    })
  }

  startDiscover(): boolean {
    const manager = this.getDeviceManager();
    if (this.discovering) {
      Logger.info(TAG, 'Device discovery is already running');
      return false;
    }
    try {
      let discoverParam = {
        'discoverTargetType': 1
      };
      manager.startDiscovering(discoverParam);
      this.discovering = true;
      Logger.info(TAG, 'Device discovery started');
      return true;
    } catch (e) {
      this.discovering = false;
      Logger.error(TAG, `Discover error: ${e}`);
      throw e;
    }
  }

  stopDiscover(): void {
    if (!this.discovering) {
      return;
    }
    try {
      this.getDeviceManager().stopDiscovering();
      this.discovering = false;
      Logger.info(TAG, 'Device discovery stopped');
    } catch (e) {
      Logger.error(TAG, `Stop discover error: ${e}`);
      throw e;
    }
  }

  exportDeviceList(): Array<distributedDeviceManager.DeviceBasicInfo> {
    return Array.from(this.discoveredDevices.values()).filter((device) => !this.connectedDevices.has(device.deviceId));
  }

  private formatBindingFailure(error: DeviceBindingFailure): string {
    const details: Array<string> = [];
    if (error.code !== undefined) {
      // In a native authentication callback, code is the auth status; zero alone is not success.
      details.push(`code=${error.code}`);
    }
    if (error.reason !== undefined) {
      details.push(`reason=${error.reason}`);
    }
    const description = error.errInfo || error.message || 'The system did not provide a binding failure description.';
    return details.length > 0 ? `${description} (${details.join(', ')})` : description;
  }

  async bindDevice(deviceId: string): Promise<void> {
    const manager = this.getDeviceManager();
    if (!this.discoveredDevices.has(deviceId)) {
      throw new Error('The selected device is no longer available. Discover devices again.');
    }
    let bindParam = {
      bindLevel: 3,
      bindType: 1,
      targetPkgName: 'com.demo.audioplayer',
      appName: 'AudioPlayer',
    }
    const bindStartedAt = Date.now();
    Logger.info(TAG, `Trying to bind ${deviceId}, params=${JSON.stringify(bindParam)}`);
    try {
      await new Promise<void>((resolve, reject) => {
        manager.bindTarget(deviceId, bindParam, (err, data) => {
          Logger.info(TAG, `Bind callback: deviceId=${deviceId}, elapsedMs=${Date.now() - bindStartedAt}, ` +
            `error=${JSON.stringify(err) ?? 'null'}, data=${JSON.stringify(data) ?? 'null'}`);
          if (err) {
            reject(err);
            return;
          }
          Logger.info(TAG, `Device bound: ${data.deviceId}`);
          resolve();
        });
      });
    } catch (err) {
      // Normalize both asynchronous authentication failures and synchronous API exceptions.
      const error = err as DeviceBindingFailure;
      const message = this.formatBindingFailure(error);
      Logger.error(TAG, `Bind device failed: deviceId=${deviceId}, elapsedMs=${Date.now() - bindStartedAt}, ` +
        `${message}, rawError=${JSON.stringify(error)}`);
      throw new Error(message);
    }
    try {
      this.refreshBoundList();
    } catch (err) {
      // Binding can finish before the device becomes AVAILABLE; its state callback also refreshes the UI.
      Logger.error(TAG, `Refresh devices after binding failed: ${err}`);
    }
  }

  refreshBoundList(): void {
    const devices = this.getDeviceManager().getAvailableDeviceListSync();
    this.connectedDevices.clear();
    devices.forEach((device) => {
      this.connectedDevices.set(device.deviceId, device);
      Logger.info(TAG, `Available device: ${device.deviceName}, NetworkID: ${device.networkId}`);
    });
    Logger.info(TAG, `Available device count: ${devices.length}`);
    this.notifyDeviceListChanged();
  }

  exportBoundList(): Array<distributedDeviceManager.DeviceBasicInfo> {
    return Array.from(this.connectedDevices.values());
  }

  async startRemoteAbility(context: common.UIAbilityContext, restoreInfo: RemoteRestoreInfo,
    deviceId?: string): Promise<void> {
    this.refreshBoundList();
    const devices = this.exportBoundList();
    if (devices.length === 0) {
      throw new Error('No available device. Bind a device and wait for it to come online.');
    }
    const device = deviceId === undefined ? devices[0] : devices.find((item) => item.deviceId === deviceId);
    if (device === undefined || !device.networkId) {
      throw new Error('The device is not ready for remote startup. Refresh the device list and try again.');
    }
    Logger.info(TAG, `Try to start ${device.deviceName}: ${device.networkId}`);
    await context.startAbility({
      bundleName: 'com.demo.audioplayer',
      abilityName: 'EntryAbility',
      deviceId: device.networkId,
      parameters: {
        restoreInfo: restoreInfo
      }
    });
    Logger.info(TAG, 'startAbility finished');
  }
}
