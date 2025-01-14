import Global from '../common/Global';
import Logger from '../common/Logger';
import { Song } from '../common/Types';
import { borderRadiuses } from '@kit.ArkUI';

const TAG: string = '[SongList]'

@Component
export struct SongList {
  @StorageLink("playList") playList: Array<Song> = [];
  @Link selectedIndex: number;

  build() {
    Column() {
      Column({ space: 5 }) {
        ForEach(this.playList, (item: Song, index: number) => {
          Column() {
            Flex({
              direction: FlexDirection.Row,
              justifyContent: FlexAlign.SpaceBetween,
              alignItems: ItemAlign.Center
            }) {
              Image($r('app.media.fake_cover'))
                .width(50)
              Column() {
                Text(item.name)
                  .fontSize(20)
                Text(item.artist)
                  .fontSize(20)
              }
              .alignItems(HorizontalAlign.Start)
              Radio({ value: '', group: 'radioGroup' })
                .radioStyle({
                  checkedBackgroundColor: '#ff0d64fb'
                })
                .enabled(false)
                .width('7%')
                .checked(index === this.selectedIndex)
            }
            .borderRadius(borderRadiuses(4))
            .width('90%')
          }
          .onClick(() => this.onSelectedChange(index))
        }, (item: Song) => JSON.stringify(item))
      }
      .alignItems(HorizontalAlign.Start)
    }
  }

  onSelectedChange(newIndex: number) {
    if (this.selectedIndex != newIndex) {
      this.selectedIndex = newIndex;
      Logger.info(TAG, `Selected index changed to ${newIndex}`);
      Global.PlayerManager.playIndex(newIndex);
    }
  }
}