import hilog from '@ohos.hilog';
import { missionManager } from '@kit.AbilityKit';

class Logger {
  private domain: number
  private prefix: string
  private format: string = '%{public}s, %{public}s'

  constructor(prefix: string) {
    this.prefix = prefix
    this.domain = 0xFF00
  }

  debug(...args: any[]) {
    hilog.debug(this.domain, this.prefix, this.format, args)
  }

  info(...args: any[]) {
    hilog.info(this.domain, this.prefix, this.format, args)
  }

  warn(...args: any[]) {
    hilog.warn(this.domain, this.prefix, this.format, args)
  }

  error(...args: any[]) {
    hilog.error(this.domain, this.prefix, this.format, args)
  }
}

let a: missionManager.MissionInfo;


export default new Logger('[OH AudioPlayer]')