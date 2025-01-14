import { distributedDeviceManager } from "@kit.DistributedServiceKit";
import Global from "../common/Global";
import Logger from "../common/Logger";
import { common } from "@kit.AbilityKit";
import { BusinessError } from "@kit.BasicServicesKit";

const TAG: string = 'DeviceDialog';

@CustomDialog
export struct DeviceDialog {
  controller: CustomDialogController;
  deviceList: Array<distributedDeviceManager.DeviceBasicInfo> = [];

  boundList: Array<distributedDeviceManager.DeviceBasicInfo> = [];

  @State selectedIndex: number = -1;

  selectedIndexChanged(newIndex: number) {
    Logger.info("selectedIndex = " + newIndex);
    this.selectedIndex = newIndex;
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
        ForEach(this.deviceList, (item: distributedDeviceManager.DeviceBasicInfo, index: number) => {
          ListItem() {
            Flex({
              direction: FlexDirection.Row,
              justifyContent: FlexAlign.SpaceBetween,
              alignItems: ItemAlign.Center
            }) {
              Text(item.deviceName).fontSize(16)
              Radio({ value: '', group: 'radioGroup' })
                .radioStyle({
                  checkedBackgroundColor: '#ff0d64fb'
                })
                .width('7%')
                .checked(index === this.selectedIndex ? true : false)
            }
            .onClick(() => {
              Logger.info(TAG, `Select device index = ${index}`);
              if (index === this.selectedIndex)
                return;
              this.selectedIndexChanged(index);
            })
          }
        })
      }
      .margin({ top: 12 })
      .width('434px')
      .height('18%')
      Row({ space: 30 }) {
        Button('Cancel')
          .onClick(() => {
            this.controller.close();
          })
        Button('Bind')
          .onClick(() => {
            Logger.info(TAG, `Bind index ${this.selectedIndex}`);
            if (this.selectedIndex != -1)
              Global.RemoteDeviceManager.bindDevice(this.deviceList[this.selectedIndex].deviceId);
          })
      }
      Text('Bound Devices')
        .fontSize('32px')
        .width('434px')
        .fontColor(Color.Black)
        .textAlign(TextAlign.Start)
        .fontWeight(600)
      List() {
        ForEach(this.boundList, (item: distributedDeviceManager.DeviceBasicInfo, index: number) => {
          ListItem() {
            Flex({
              direction: FlexDirection.Row,
              justifyContent: FlexAlign.SpaceBetween,
              alignItems: ItemAlign.Center
            }) {
              Text(item.deviceName).fontSize(16)
              Radio({ value: '', group: 'radioGroup' })
                .radioStyle({
                  checkedBackgroundColor: '#ff0d64fb'
                })
                .width('7%')
                .checked(index === this.selectedIndex ? true : false)
            }
            .height('10%')
            .onClick(() => {
              Logger.info(TAG, `Try to start ${item.deviceName}: ${item.networkId}`);
              (getContext(this) as common.UIAbilityContext).startAbility({
                bundleName: 'com.demo.audioplayer',
                abilityName: 'EntryAbility',
                deviceId: item.networkId,
                parameters: {
                  restoreInfo: Global.PlayerManager.exportRestoreInfo()
                }
              }).then(() => {
                Logger.info(TAG, `startAbility finished`);
              }).catch((err: BusinessError) => {
                Logger.error(TAG, `Error starting, error: [${err.code}] ${err.message}`);
              })
            })
          }
        })
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