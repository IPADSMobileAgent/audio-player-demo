import { distributedDeviceManager } from "@kit.DistributedServiceKit";

import Logger from '../common/Logger';

const TAG: string = '[RemoteDeviceManager]';

export class RemoteDeviceManager {

  private deviceManager: distributedDeviceManager.DeviceManager;
  private discoveredDevices: Map<string, distributedDeviceManager.DeviceBasicInfo>;
  private connectedDevices: Map<string, distributedDeviceManager.DeviceBasicInfo>;

  constructor() {
    try {
      this.deviceManager = distributedDeviceManager.createDeviceManager('com.demo.audioplayer');
      Logger.info(TAG, 'deviceManager created');
      this.discoveredDevices = new Map<string, distributedDeviceManager.DeviceBasicInfo>();
      this.setDeviceManagerCallback();
      this.startDiscover();
    } catch (err) {
      Logger.error(TAG, `Create device manager failed: ${err}`);
    }
  }

  setDeviceManagerCallback() {
    this.deviceManager.on('discoverSuccess', (data) => {
      let dev: distributedDeviceManager.DeviceBasicInfo = data.device;
      if (!this.discoveredDevices.has(dev.deviceId)) {
        Logger.info(TAG, `New device: <${dev.deviceId}: ${dev.deviceName}>`);
        this.discoveredDevices.set(dev.deviceId, dev);
      }
    });
    this.deviceManager.on('discoverFailure', (data) => {
      Logger.error(TAG, `discoverFailure data = ${JSON.stringify(data)}`);
    });
    this.deviceManager.on('deviceStateChange', (data) => {
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
      };
    })
    this.deviceManager.on('serviceDie', (info) => {
      Logger.error(TAG, `serviceDie: ${JSON.stringify(info)}`);
    })
  }

  startDiscover() {
    try {
      Logger.info(TAG, `Device Device`)
      let discoverParam = {
        'discoverTargetType': 1
      };
      this.deviceManager.startDiscovering(discoverParam);
    } catch (e) {
      Logger.error(TAG, `Discover error: ${e}`);
    }
  }

  stopDiscover() {
    try {
      this.deviceManager.stopDiscovering();
    } catch (e) {
      Logger.error(TAG, `Stop discover error: ${e}`);
    }
  }

  exportDeviceList(): Array<distributedDeviceManager.DeviceBasicInfo> {
    return Array.from(this.discoveredDevices.values());
  }

  bindDevice(deviceId: string) {
    if (!this.discoveredDevices.has(deviceId)) {
      Logger.error(TAG, `Device ${deviceId} not found`);
    }
    let bindParam = {
      bindLevel: 3,
      bindType: 1,
      targetPkgName: 'com.demo.audioplayer',
      appName: 'AudioPlayer',
    }
    try {
      Logger.info(TAG, `Trying to bind ${deviceId}`);
      this.deviceManager.bindTarget(deviceId, bindParam, (err, data) => {
        if (err) {
          Logger.error(TAG, `Bind device failed: ${err.message}`);
          return;
        }
      })
    } catch (err) {
      Logger.error(TAG, `Bind device failed: ${err}`);
    }
  }

  exportBoundList(): Array<distributedDeviceManager.DeviceBasicInfo> {
    let arr = this.deviceManager.getAvailableDeviceListSync()
    arr.forEach((info) => {Logger.info(TAG, `NetworkID: ${info.networkId}`)});
    return arr;
  }
}