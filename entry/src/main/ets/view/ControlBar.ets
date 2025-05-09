import Global from '../common/Global'
import { PlayerState } from '../common/Types'

const TAG: string = "[ControlBar]"

@Component
export struct ControlBar {
  @Link playerState: PlayerState;
  @Link selectedIndex: number;

  @Builder
  switchStateButton(resource: Resource) {
    Image(resource)
      .width('15%')
      .onClick(() => this.switchPlayState())
  }

  build() {
    Row() {
      Image($r('app.media.ic_back'))
        .width('15%')
        .onClick(() => Global.PlayerManager.seek(0))
      if (this.playerState === PlayerState.PLAYING) {
        this.switchStateButton($r('app.media.ic_play'))
      } else {
        this.switchStateButton($r('app.media.ic_pause'))
      }
      Image($r('app.media.ic_next'))
        .width('15%')
        .onClick(() => this.playNextSong())
    }
    .width('70%')
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(VerticalAlign.Center)
  }

  switchPlayState() {
    let currentState = Global.PlayerManager.state;
    if (currentState === PlayerState.PLAYING) {
      Global.PlayerManager.pause();
    } else if (currentState === PlayerState.PAUSED) {
      Global.PlayerManager.resume();
    } else if (currentState === PlayerState.IDLE) {
      Global.PlayerManager.playIndex(this.selectedIndex);
    }
  }
  playNextSong() {
    const totalSongs = Global.PlayerManager.playList.length
    if (totalSongs === 0) {
      return
    }

    let nextIndex = this.selectedIndex + 1

    if (nextIndex >= totalSongs) {
      nextIndex = 0
    }

    Global.PlayerManager.playIndex(nextIndex)

    this.selectedIndex = nextIndex
  }

}