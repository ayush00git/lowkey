import { SignalingClient } from '../proto/SignalingServiceClientPb';
import {
  SignalRequest,
  SignalResponse,
  Identity,
  SdpExchange,
  IceCandidate,
} from '../proto/signaling_pb';
import 'react-native-get-random-values';
import { v4 as uuidv4 } from 'uuid';

export class SignalingService {
  private client: SignalingClient;
  private stream: any;
  public myUuid: string;

  private onSdpReceived?: (sdp: SdpExchange) => void;
  private onIceCandidateReceived?: (ice: IceCandidate) => void;
  private onIdentityRegistered?: (identity: Identity) => void;
  private onErrorReceived?: (error: any) => void;

  constructor(backendUrl: string) {
    this.client = new SignalingClient(backendUrl, null, null);
    this.myUuid = uuidv4();
    this.stream = null;
  }

  public setCallbacks(callbacks: {
    onSdp: (sdp: SdpExchange) => void;
    onIce: (ice: IceCandidate) => void;
    onIdentity?: (identity: Identity) => void;
    onError?: (error: any) => void;
  }) {
    this.onSdpReceived = callbacks.onSdp;
    this.onIceCandidateReceived = callbacks.onIce;
    this.onIdentityRegistered = callbacks.onIdentity;
    this.onErrorReceived = callbacks.onError;
  }

  public connect() {
    // Open the bidirectional stream (grpc-web supports server-streaming, and we assume connect() is generated if it's a server stream)
    // Note: Since `connect` in grpc-web might be generated differently based on unary/server-streaming,
    // we use the generated method. If it's a bidirectional stream, standard grpc-web has limited support.
    
    // We instantiate the stream. According to grpc-web, for server-streaming it's `client.connect(request, metadata)`
    // But since the proto defines `rpc Connect(stream SignalRequest) returns (stream SignalResponse);`, 
    // it's a bidirectional stream. Standard grpc-web does not fully support bidi streams natively without
    // a websocket proxy or specific transport. Assuming the stub generates a `connect` method that returns a stream:
    
    // Create an initial empty request just to open the stream if required by the stub API
    const initialRequest = new SignalRequest();
    
    // @ts-ignore - The generated stub omits bidirectional methods by standard grpc-web configs.
    // Assuming backend Envoy or websocket proxy supports it, we cast to any.
    this.stream = (this.client as any).connect(initialRequest, {});

    // Register identity immediately upon connection
    this.registerIdentity();

    // Listen for incoming messages
    this.stream.on('data', (response: SignalResponse) => {
      this.handleIncomingMessage(response);
    });

    this.stream.on('status', (status: any) => {
      console.log('Signaling stream status:', status);
    });

    this.stream.on('error', (err: any) => {
      console.error('Signaling stream error:', err);
      if (this.onErrorReceived) {
        this.onErrorReceived(err);
      }
    });

    this.stream.on('end', () => {
      console.log('Signaling stream ended');
    });
  }

  private registerIdentity() {
    const identityMsg = new Identity();
    identityMsg.setUuid(this.myUuid);
    
    // For now, setting an empty or dummy public key until encryption is integrated
    const dummyKey = new Uint8Array([0]);
    identityMsg.setPublicKey(dummyKey);

    const request = new SignalRequest();
    request.setRegistration(identityMsg);

    this.stream.write(request);
  }

  public sendSdp(type: SdpExchange.Type, sdp: string, targetUuid: string) {
    if (!this.stream) return;

    const sdpMsg = new SdpExchange();
    sdpMsg.setType(type);
    sdpMsg.setSdp(sdp);
    sdpMsg.setTargetUuid(targetUuid);

    const request = new SignalRequest();
    request.setSdp(sdpMsg);

    this.stream.write(request);
  }

  public sendIceCandidate(candidate: string, sdpMid: string, sdpMLineIndex: number, usernameFragment: string, targetUuid: string) {
    if (!this.stream) return;

    const iceMsg = new IceCandidate();
    iceMsg.setCandidate(candidate);
    iceMsg.setSdpMid(sdpMid);
    iceMsg.setSdpMLineIndex(sdpMLineIndex);
    iceMsg.setUsernameFragment(usernameFragment);
    iceMsg.setTargetUuid(targetUuid);

    const request = new SignalRequest();
    request.setIce(iceMsg);

    this.stream.write(request);
  }

  private handleIncomingMessage(response: SignalResponse) {
    if (response.hasIdentity()) {
      const identity = response.getIdentity();
      if (identity && this.onIdentityRegistered) {
        this.onIdentityRegistered(identity);
      }
    } else if (response.hasSdp()) {
      const sdp = response.getSdp();
      if (sdp && this.onSdpReceived) {
        this.onSdpReceived(sdp);
      }
    } else if (response.hasIce()) {
      const ice = response.getIce();
      if (ice && this.onIceCandidateReceived) {
        this.onIceCandidateReceived(ice);
      }
    } else if (response.hasError()) {
      const error = response.getError();
      if (error && this.onErrorReceived) {
        this.onErrorReceived(error);
      }
    }
  }

  public disconnect() {
    if (this.stream) {
      this.stream.cancel();
      this.stream = null;
    }
  }
}
