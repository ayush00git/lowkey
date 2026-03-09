declare module 'react-native-webrtc' {
  export class RTCPeerConnection {
    constructor(configuration: any);
    connectionState: string;
    addIceCandidate(candidate: RTCIceCandidate): Promise<void>;
    createOffer(options?: any): Promise<RTCSessionDescription>;
    createAnswer(options?: any): Promise<RTCSessionDescription>;
    setLocalDescription(description: RTCSessionDescription): Promise<void>;
    setRemoteDescription(description: RTCSessionDescription): Promise<void>;
    addEventListener(type: string, listener: (event: any) => void): void;
    removeEventListener(type: string, listener: (event: any) => void): void;
    createDataChannel(label: string, options?: any): RTCDataChannel;
    ondatachannel: ((event: { channel: RTCDataChannel }) => void) | null;
    close(): void;
  }

  export class RTCSessionDescription {
    constructor(info: { type: string; sdp: string });
    type: string;
    sdp: string;
    toJSON(): any;
  }

  export class RTCIceCandidate {
    constructor(info: { candidate: string; sdpMid: string; sdpMLineIndex: number });
    candidate: string;
    sdpMid: string;
    sdpMLineIndex: number;
    toJSON(): any;
  }

  export interface RTCMessageEvent {
    data: any;
  }

  export class RTCDataChannel {
    label: string;
    send(data: string | ArrayBuffer | ArrayBufferView): void;
    close(): void;
    onopen: (() => void) | null;
    onmessage: ((event: RTCMessageEvent) => void) | null;
    onerror: ((error: Error) => void) | null;
    onclose: (() => void) | null;
  }
}
