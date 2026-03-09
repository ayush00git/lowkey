import {
  RTCPeerConnection,
  RTCSessionDescription,
  RTCIceCandidate,
} from 'react-native-webrtc';
import { SignalingService } from './SignalingService';
import { SdpExchange, IceCandidate } from '../proto/signaling_pb';

export class WebRTCManager {
  public peerConnection: RTCPeerConnection;
  private signaling: SignalingService;
  private currentTargetUuid: string | null = null;
  
  public onRemoteStream?: (stream: any) => void;

  constructor(signalingService: SignalingService) {
    this.signaling = signalingService;

    // Initialize RTCPeerConnection with public Google STUN servers
    this.peerConnection = new RTCPeerConnection({
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' },
        { urls: 'stun:stun2.l.google.com:19302' }
      ]
    });

    this.setupListeners();
  }

  private setupListeners() {
    this.peerConnection.addEventListener('icecandidate', (event: any) => {
      // Local ICE candidate generated
      if (event.candidate && this.currentTargetUuid) {
        this.signaling.sendIceCandidate(
          event.candidate.candidate,
          event.candidate.sdpMid,
          event.candidate.sdpMLineIndex,
          event.candidate.usernameFragment,
          this.currentTargetUuid
        );
      }
    });

    this.peerConnection.addEventListener('track', (event: any) => {
      // Incoming remote stream track
      if (this.onRemoteStream && event.streams && event.streams[0]) {
        this.onRemoteStream(event.streams[0]);
      }
    });

    this.peerConnection.addEventListener('connectionstatechange', () => {
      console.log('WebRTC Connection State:', this.peerConnection.connectionState);
    });
  }

  /**
   * Generates a local SDP offer and sends it to the target peer via signaling.
   */
  public async createOffer(targetUuid: string) {
    this.currentTargetUuid = targetUuid;

    try {
      const offer = await this.peerConnection.createOffer({});
      await this.peerConnection.setLocalDescription(offer);

      this.signaling.sendSdp(
        SdpExchange.Type.TYPE_OFFER,
        offer.sdp,
        targetUuid
      );
    } catch (err) {
      console.error('Error creating offer:', err);
    }
  }

  /**
   * Receives a remote SDP offer, sets it, creates a local answer, and sends it back.
   */
  public async createAnswer(offerSdp: string, targetUuid: string) {
    this.currentTargetUuid = targetUuid;

    try {
      // Set remote description from the received offer
      await this.peerConnection.setRemoteDescription(
        new RTCSessionDescription({ type: 'offer', sdp: offerSdp })
      );

      // Create an answer
      const answer = await this.peerConnection.createAnswer();
      await this.peerConnection.setLocalDescription(answer);

      // Send the answer back to the peer
      this.signaling.sendSdp(
        SdpExchange.Type.TYPE_ANSWER,
        answer.sdp,
        targetUuid
      );
    } catch (err) {
      console.error('Error creating answer:', err);
    }
  }

  /**
   * Handles an SDP answer received from the remote peer in response to our offer.
   */
  public async handleAnswer(answerSdp: string) {
    try {
      await this.peerConnection.setRemoteDescription(
        new RTCSessionDescription({ type: 'answer', sdp: answerSdp })
      );
    } catch (err) {
      console.error('Error handling answer:', err);
    }
  }

  /**
   * Handles an incoming ICE candidate received from signaling.
   */
  public async handleIceCandidate(iceProtoMsg: IceCandidate) {
    try {
      const candidate = new RTCIceCandidate({
        candidate: iceProtoMsg.getCandidate(),
        sdpMid: iceProtoMsg.getSdpMid(),
        sdpMLineIndex: iceProtoMsg.getSdpMLineIndex()
      });
      await this.peerConnection.addIceCandidate(candidate);
    } catch (err) {
      console.error('Error adding received ice candidate:', err);
    }
  }

  public close() {
    this.peerConnection.close();
    this.currentTargetUuid = null;
  }
}
