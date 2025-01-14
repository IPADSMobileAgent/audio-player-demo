import { media } from '@kit.MediaKit';

export class SongProps {
  name: string;
  artist: string;
  coverPath: string;
  filePath: string;
}

export class Song {
  public name: string;
  public artist: string;
  public coverPath: string;
  public filePath: string;

  /* file descriptor of opened media file */
  public avFd: media.AVFileDescriptor;

  constructor(props: SongProps, avFd: media.AVFileDescriptor) {
    this.name = props.name;
    this.artist = props.artist;
    this.coverPath = props.coverPath;
    this.filePath = props.filePath;
    this.avFd = avFd;
  }
}

export enum PlayerState {
  NOT_INITIALIZED = -1,
  IDLE,
  INITIALIZED,
  PREPARED,
  PLAYING,
  PAUSED,
  COMPLETED
}

export enum PlayMode {
  SINGLE_LOOP,
  RANDOM,
  SEQUENTIAL,
}

export interface IPlayer {
  current: number;
  total: number;
  songIndex: number;

  playerState: PlayerState;
  playMode: PlayMode;
}

export class RemoteRestoreInfo {
  shouldContinue: boolean = false; // should not continue by default
  playIndex: number;
  currentTime: number;
}