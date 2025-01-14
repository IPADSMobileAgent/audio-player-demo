import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit'

import Logger from '../common/Logger';
import { Song, PlayerState, PlayMode, IPlayer, RemoteRestoreInfo } from '../common/Types';
import Constants from '../common/Constants';
import Background from '../common/Background';
import { common } from '@kit.AbilityKit';
import Global from '../common/Global';
import { avSession } from '@kit.AVSessionKit';
import { Content } from '@kit.ArkUI';
import Network, { NetworkResponse } from '@system.network';

const TAG: string = '[PlayerModel]'

enum AVPlayerState {
  IDLE = 'idle',
  INITIALIZED = 'initialized',
  PREPARED = 'prepared',
  PLAYING = 'playing',
  PAUSED = 'paused',
  COMPLETED = 'completed'
}

export class PlayerManager {
  state: PlayerState = PlayerState.NOT_INITIALIZED;
  player: media.AVPlayer;
  playList: Array<Song> = [];

  parent: IPlayer;
  context: common.Context;

  currentTime: number = 0; // current playback time
  timerId: number = Constants.DEFAULT_TIMER_ID; // current timer to update progress bar

  constructor(context: common.Context) {
    this.context = context;
    Logger.info(TAG, 'create AVPlayer');
    media.createAVPlayer((error: BusinessError, player: media.AVPlayer) => {
      if (player != null) {
        this.player = player;
        this.setPlayerCallback();
        this.setState(PlayerState.IDLE);
      } else {
        Logger.error(TAG, 'create AVPlayer error, message = ' + error.message);
      }
    });
  }

  setPlayList(playList: Array<Song>) {
    this.playList = playList;
  }

  setParent(parent: IPlayer) {
    this.parent = parent;
  }

  setPlayerCallback() {
    this.player.on('stateChange', async (state) => {
      switch (state) {
        case AVPlayerState.IDLE:
          Logger.info(TAG, 'Player goes to IDLE');
          this.setState(PlayerState.IDLE)
          Global.SessionManager.setState(avSession.PlaybackState.PLAYBACK_STATE_IDLE);
          break;
        case AVPlayerState.INITIALIZED: // after the playback source is set
          this.setState(PlayerState.INITIALIZED);
          this.player.prepare();
          break;
        case AVPlayerState.PREPARED:
          Logger.info(TAG, 'Music is prepared, duration = ' + this.player.duration);
          this.setState(PlayerState.PREPARED);
          Global.SessionManager.setState(avSession.PlaybackState.PLAYBACK_STATE_PREPARE);
          this.player.play();
          break;
        case AVPlayerState.PLAYING:
          Logger.info(TAG, 'Music is playing now, current = ' + this.currentTime);
          this.setState(PlayerState.PLAYING);
          Global.SessionManager.setState(avSession.PlaybackState.PLAYBACK_STATE_PLAY);
          if (this.currentTime > 0) {
            this.player.seek(this.currentTime);
          }
          Background.startBackgroundRunning(this.context);
          this.startProgressChange();
          break;
        case AVPlayerState.PAUSED:
          Logger.info(TAG, 'Player is paused at ' + this.player.currentTime);
          this.setState(PlayerState.PAUSED);
          Global.SessionManager.setState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE);
          this.currentTime = this.player.currentTime;
          Background.stopBackgroundRunning(this.context);
          break;
        case AVPlayerState.COMPLETED:
          Logger.info(TAG, 'Music is completed');
          this.setState(PlayerState.COMPLETED)
          Global.SessionManager.setState(avSession.PlaybackState.PLAYBACK_STATE_COMPLETED);
          this.playNext();
          break;
        default:
          Logger.error(TAG, 'Unhandled state: ' + state);
          break;
      }
    });
    this.player.on('error', (error: BusinessError) => {
      Logger.error(TAG, 'Error occurred: ' + error.message);
    });
  }

  async playIndex(index: number, seekTo: number = 0) {
    if (index >= this.playList.length) {
      Logger.error(TAG, `play index ${index} out of range`);
      return;
    }
    this.play(this.playList[index].avFd, seekTo);
  }

  async play(avFd: media.AVFileDescriptor, seekTo: number = 0) {
    Logger.info(TAG, 'Start to play ');
    this.clearTimer();
    if (this.state !== PlayerState.IDLE) {
      Logger.info(TAG, `Current state: ${this.state}, reset to IDLE`);
      await this.player.reset();
    }
    this.currentTime = Math.max(0, seekTo);
    this.player.fdSrc = avFd;
  }

  async seek(seekTo: number) {
    Logger.info(TAG, 'Seek to ' + seekTo);
    this.player.seek(seekTo);
  }

  async pause() {
    Logger.info(TAG, 'Pause');
    this.clearTimer();
    await this.player.pause();
  }

  async resume() {
    Logger.info(TAG, 'Try to resume');
    if (this.state !== PlayerState.PAUSED)
      return
    await this.player.play();
  }

  async release() {
    Logger.info(TAG, 'Release the player');
    if (this.state !== PlayerState.NOT_INITIALIZED) {
      this.clearTimer();
      await this.player.release();
      this.player = undefined;
      Global.SessionManager.setState(avSession.PlaybackState.PLAYBACK_STATE_RELEASED);
      this.setState(PlayerState.NOT_INITIALIZED);
    }
  }

  startProgressChange() {
    this.parent.current = this.currentTime;
    this.parent.total = this.player.duration;
    /* update progress bar every second */
    this.timerId = setInterval(() => {
      this.parent.current = this.player.currentTime;
    }, 1000);
  }

  clearTimer() {
    if (this.timerId !== Constants.DEFAULT_TIMER_ID) {
      clearInterval(this.timerId);
      this.timerId = Constants.DEFAULT_TIMER_ID;
    }
  }

  setState(newState: PlayerState) {
    if (this.state !== newState) {
      this.state = newState;
      this.parent.playerState = newState;
    }
  }

  exportRestoreInfo(): RemoteRestoreInfo {
    return {
      shouldContinue: true,
      playIndex: this.parent.songIndex,
      currentTime: this.currentTime
    };
  }

  playNext() {
    let mode = this.parent.playMode;
    switch (mode) {
      case PlayMode.SINGLE_LOOP:
        break;
      case PlayMode.RANDOM:
        break;
      case PlayMode.SEQUENTIAL:
        break;
      default:
        Logger.error(TAG, "Unhandled playMode: " + mode);
    }
  }
}




