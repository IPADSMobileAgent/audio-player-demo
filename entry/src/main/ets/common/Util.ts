export default class Util {

  public static formatDuration(duration: number): string {
    if (duration < 0)
      duration = 0;

    const seconds = Math.floor((duration / 1000) % 60);
    const minutes = Math.floor((duration / (1000 * 60)) % 60);
    const hours = Math.floor(duration / (1000 * 60 * 60));

    const minutesStr = (hours > 0 ? minutes.toString().padStart(2, '0') : minutes.toString());
    const secondsStr = seconds.toString().padStart(2, '0');

    return (hours > 0 ? hours.toString() + ":" : "") + minutesStr + ":" + secondsStr;
  }
}