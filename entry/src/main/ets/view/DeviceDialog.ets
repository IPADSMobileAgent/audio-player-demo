import { distributedDeviceManager } from "@kit.DistributedServiceKit";
import Global from "../common/Global";
import Logger from "../common/Logger";
import { common } from "@kit.AbilityKit";
import { BusinessError } from "@kit.BasicServicesKit";

const TAG: string = 'DeviceDialog';

@CustomDialog
export struct DeviceDialog {
  controller: CustomDialogController;
  @State deviceList: Array<distributedDeviceManager.DeviceBasicInfo> = [];
  @State boundList: Array<distributedDeviceManager.DeviceBasicInfo> = [];
  @State selectedDeviceId: string = '';
  @State binding: boolean = false;
  @State starting: boolean = false;

  private active: boolean = false;
  private deviceListListener: () => void = () => this.updateDeviceLists();

  aboutToAppear(): void {
    this.active = true;
    Global.RemoteDeviceManager.addDeviceListListener(this.deviceListListener);
    this.updateDeviceLists();
    try {
      Global.RemoteDeviceManager.refreshBoundList();
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(TAG, `Refresh devices failed: [${error.code}] ${error.message}`);
      this.showMessage(`Could not refresh devices: ${error.message}`);
    }
  }

  aboutToDisappear(): void {
    this.active = false;
    Global.RemoteDeviceManager.removeDeviceListListener(this.deviceListListener);
  }

  private updateDeviceLists(): void {
    this.deviceList = Global.RemoteDeviceManager.exportDeviceList();
    this.boundList = Global.RemoteDeviceManager.exportBoundList();
    if (!this.deviceList.some((device) => device.deviceId === this.selectedDeviceId)) {
      this.selectedDeviceId = '';
    }
  }

  private selectDevice(deviceId: string): void {
    if (!this.binding) {
      this.selectedDeviceId = deviceId;
      Logger.info(TAG, `Selected device: ${deviceId}`);
    }
  }

  private showMessage(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  private async bindSelectedDevice(): Promise<void> {
    if (this.binding) {
      return;
    }
    if (this.selectedDeviceId.length === 0) {
      this.showMessage('Select a device to bind first.');
      return;
    }
    this.binding = true;
    try {
      await Global.RemoteDeviceManager.bindDevice(this.selectedDeviceId);
      if (this.active) {
        this.showMessage('Binding succeeded. The device will appear below when it is available.');
      }
    } catch (err) {
      const error = err as Error;
      const message = error.message || 'The system did not provide a binding failure description.';
      Logger.error(TAG, `Bind device failed: ${message}`);
      if (this.active) {
        this.showMessage(`Binding failed: ${message}`);
      }
    } finally {
      if (this.active) {
        this.binding = false;
      }
    }
  }

  private async startRemoteAbility(deviceId: string): Promise<void> {
    if (this.starting) {
      return;
    }
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
    if (context === undefined) {
      this.showMessage('The application is not ready. Try again.');
      return;
    }
    this.starting = true;
    try {
      await Global.RemoteDeviceManager.startRemoteAbility(context, Global.PlayerManager.exportRestoreInfo(), deviceId);
      if (this.active) {
        this.showMessage('App started on the remote device.');
      }
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(TAG, `Remote startup failed: [${error.code}] ${error.message}`);
      if (this.active) {
        this.showMessage(`Could not start the remote app: ${error.message}`);
      }
    } finally {
      if (this.active) {
        this.starting = false;
      }
    }
  }

  build() {
    Column() {
      Text('Unauthorized Devices')
        .fontSize('32px')
        .width('434px')
        .fontColor(Color.Black)
        .textAlign(TextAlign.Start)
        .fontWeight(600)
      List() {
        ForEach(this.deviceList, (item: distributedDeviceManager.DeviceBasicInfo) => {
          ListItem() {
            Flex({
              direction: FlexDirection.Row,
              justifyContent: FlexAlign.SpaceBetween,
              alignItems: ItemAlign.Center
            }) {
              Text(item.deviceName).fontSize(16)
              Radio({ value: item.deviceId, group: 'deviceBindingGroup' })
                .radioStyle({
                  checkedBackgroundColor: '#ff0d64fb'
                })
                .width('7%')
                .checked(item.deviceId === this.selectedDeviceId)
                .onChange((checked: boolean) => {
                  if (checked) {
                    this.selectDevice(item.deviceId);
                  }
                })
            }
            .onClick(() => {
              this.selectDevice(item.deviceId);
            })
          }
        }, (item: distributedDeviceManager.DeviceBasicInfo) => item.deviceId)
      }
      .enabled(!this.binding)
      .margin({ top: 12 })
      .width('434px')
      .height('18%')
      Row({ space: 30 }) {
        Button('Cancel')
          .onClick(() => {
            this.controller.close();
          })
        Button(this.binding ? 'Binding...' : 'Bind')
          .enabled(!this.binding)
          .onClick(() => {
            this.bindSelectedDevice();
          })
      }
      Text('Bound Devices')
        .fontSize('32px')
        .width('434px')
        .fontColor(Color.Black)
        .textAlign(TextAlign.Start)
        .fontWeight(600)
      List() {
        ForEach(this.boundList, (item: distributedDeviceManager.DeviceBasicInfo) => {
          ListItem() {
            Flex({
              direction: FlexDirection.Row,
              justifyContent: FlexAlign.SpaceBetween,
              alignItems: ItemAlign.Center
            }) {
              Text(item.deviceName).fontSize(16)
              Button('Start')
                .enabled(!this.starting)
                .onClick(() => {
                  this.startRemoteAbility(item.deviceId);
                })
            }
            .padding({ top: 8, bottom: 8 })
          }
        }, (item: distributedDeviceManager.DeviceBasicInfo) => item.deviceId)
      }
      .margin({ top: 12 })
      .width('434px')
      .height('18%')
    }
    .margin({ bottom: 36 })
    .width('500px')
    .padding(10)
    .backgroundColor(Color.White)
    .border({ color: Color.White, radius: 20 })
  }
}
