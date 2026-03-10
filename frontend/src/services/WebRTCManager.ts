import {
  RTCPeerConnection,
  RTCSessionDescription,
  RTCIceCandidate,
  RTCDataChannel,
  RTCMessageEvent,
} from 'react-native-webrtc';
import { SignalingService } from './SignalingService';
import { SdpExchange, IceCandidate } from '../proto/signaling_pb';
import { Database } from '@nozbe/watermelondb';
import 'react-native-get-random-values';
import { v4 as uuidv4 } from 'uuid';

export class WebRTCManager {
  public peerConnection: RTCPeerConnection;
  private signaling: SignalingService;
  private database: Database;
  public dataChannel: RTCDataChannel | null = null;
  private currentTargetUuid: string | null = null;
  
  public onRemoteStream?: (stream: any) => void;

  constructor(signalingService: SignalingService, database: Database) {
    this.signaling = signalingService;
    this.database = database;

    // Initialize RTCPeerConnection with STUN + TURN servers
    this.peerConnection = new RTCPeerConnection({
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' },
        // TURN server for NAT traversal (update host for production)
        // TODO: Replace YOUR_SERVER_IP with your deployed server's public IP
        {
          urls: 'turn:YOUR_SERVER_IP:3478',
          username: 'lowkey',
          credential: 'lowkey-turn-secret',
        },
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

    this.peerConnection.ondatachannel = (event: any) => {
      console.log('Received remote data channel');
      this.dataChannel = event.channel;
      this.setupDataChannel(this.dataChannel!);
    };
  }

  private setupDataChannel(channel: RTCDataChannel) {
    channel.onopen = () => {
      console.log('Data channel is open and ready');
    };

    channel.onmessage = (event: RTCMessageEvent) => {
      console.log('Received message:', event.data);
      if (typeof event.data === 'string') {
        this.saveMessageToDB(event.data);
      }
    };

    channel.onerror = (error: Error) => {
      console.error('Data channel error:', error);
    };

    channel.onclose = () => {
      console.log('Data channel closed');
    };
  }

  private async saveMessageToDB(text: string) {
    try {
      await this.database.write(async () => {
        const messagesCollection: any = this.database.get('messages');
        await messagesCollection.create((message: any) => {
          message.message_id = uuidv4();
          message.sender_id = this.currentTargetUuid || 'unknown';
          message.ciphertext = text;
          message.expires_at = Date.now() + 86400000; // 24 hours from now
        });
      });
      console.log('Message saved to WatermelonDB successfully.');
    } catch (err) {
      console.error('Error saving message to DB:', err);
    }
  }

  /**
   * Generates a local SDP offer and sends it to the target peer via signaling.
   */
  public async createOffer(targetUuid: string) {
    this.currentTargetUuid = targetUuid;

    try {
      // Proactively create the data channel since we are the caller
      this.dataChannel = this.peerConnection.createDataChannel('chat');
      this.setupDataChannel(this.dataChannel);

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
    if (this.dataChannel) {
      this.dataChannel.close();
      this.dataChannel = null;
    }
    this.peerConnection.close();
    this.currentTargetUuid = null;
  }
}
