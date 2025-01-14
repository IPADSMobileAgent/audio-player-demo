import Util from '../common/Util'

@Component
export struct ProgressBar {
  @Link current: number;
  @Link total: number;

  build() {
    Row() {
      Text(Util.formatDuration(this.current))
      Slider({
        value: this.current,
        max: this.total
      })
        .enabled(false)
        .layoutWeight(1)
      Text(Util.formatDuration(this.total))
    }
    .width('95%')
  }
}

@Component
struct LatestNewsScreen {
  @State expanded: boolean = false;
  build() {
    Column() {
      // ...
      Button()
        .onClick(() =>
        this.expanded = !this.expanded)
      if (this.expanded) {
        Text('More Details')
      }
      // ...
    }
  }
}