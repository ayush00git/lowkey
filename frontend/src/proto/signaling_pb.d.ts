import * as jspb from 'google-protobuf'



export class SignalRequest extends jspb.Message {
  getRegistration(): Identity | undefined;
  setRegistration(value?: Identity): SignalRequest;
  hasRegistration(): boolean;
  clearRegistration(): SignalRequest;

  getSdp(): SdpExchange | undefined;
  setSdp(value?: SdpExchange): SignalRequest;
  hasSdp(): boolean;
  clearSdp(): SignalRequest;

  getIce(): IceCandidate | undefined;
  setIce(value?: IceCandidate): SignalRequest;
  hasIce(): boolean;
  clearIce(): SignalRequest;

  getPayloadCase(): SignalRequest.PayloadCase;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): SignalRequest.AsObject;
  static toObject(includeInstance: boolean, msg: SignalRequest): SignalRequest.AsObject;
  static serializeBinaryToWriter(message: SignalRequest, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): SignalRequest;
  static deserializeBinaryFromReader(message: SignalRequest, reader: jspb.BinaryReader): SignalRequest;
}

export namespace SignalRequest {
  export type AsObject = {
    registration?: Identity.AsObject,
    sdp?: SdpExchange.AsObject,
    ice?: IceCandidate.AsObject,
  }

  export enum PayloadCase { 
    PAYLOAD_NOT_SET = 0,
    REGISTRATION = 1,
    SDP = 2,
    ICE = 3,
  }
}

export class SignalResponse extends jspb.Message {
  getIdentity(): Identity | undefined;
  setIdentity(value?: Identity): SignalResponse;
  hasIdentity(): boolean;
  clearIdentity(): SignalResponse;

  getSdp(): SdpExchange | undefined;
  setSdp(value?: SdpExchange): SignalResponse;
  hasSdp(): boolean;
  clearSdp(): SignalResponse;

  getIce(): IceCandidate | undefined;
  setIce(value?: IceCandidate): SignalResponse;
  hasIce(): boolean;
  clearIce(): SignalResponse;

  getError(): Error | undefined;
  setError(value?: Error): SignalResponse;
  hasError(): boolean;
  clearError(): SignalResponse;

  getPayloadCase(): SignalResponse.PayloadCase;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): SignalResponse.AsObject;
  static toObject(includeInstance: boolean, msg: SignalResponse): SignalResponse.AsObject;
  static serializeBinaryToWriter(message: SignalResponse, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): SignalResponse;
  static deserializeBinaryFromReader(message: SignalResponse, reader: jspb.BinaryReader): SignalResponse;
}

export namespace SignalResponse {
  export type AsObject = {
    identity?: Identity.AsObject,
    sdp?: SdpExchange.AsObject,
    ice?: IceCandidate.AsObject,
    error?: Error.AsObject,
  }

  export enum PayloadCase { 
    PAYLOAD_NOT_SET = 0,
    IDENTITY = 1,
    SDP = 2,
    ICE = 3,
    ERROR = 4,
  }
}

export class Identity extends jspb.Message {
  getUuid(): string;
  setUuid(value: string): Identity;

  getPublicKey(): Uint8Array | string;
  getPublicKey_asU8(): Uint8Array;
  getPublicKey_asB64(): string;
  setPublicKey(value: Uint8Array | string): Identity;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): Identity.AsObject;
  static toObject(includeInstance: boolean, msg: Identity): Identity.AsObject;
  static serializeBinaryToWriter(message: Identity, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): Identity;
  static deserializeBinaryFromReader(message: Identity, reader: jspb.BinaryReader): Identity;
}

export namespace Identity {
  export type AsObject = {
    uuid: string,
    publicKey: Uint8Array | string,
  }
}

export class SdpExchange extends jspb.Message {
  getType(): SdpExchange.Type;
  setType(value: SdpExchange.Type): SdpExchange;

  getSdp(): string;
  setSdp(value: string): SdpExchange;

  getTargetUuid(): string;
  setTargetUuid(value: string): SdpExchange;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): SdpExchange.AsObject;
  static toObject(includeInstance: boolean, msg: SdpExchange): SdpExchange.AsObject;
  static serializeBinaryToWriter(message: SdpExchange, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): SdpExchange;
  static deserializeBinaryFromReader(message: SdpExchange, reader: jspb.BinaryReader): SdpExchange;
}

export namespace SdpExchange {
  export type AsObject = {
    type: SdpExchange.Type,
    sdp: string,
    targetUuid: string,
  }

  export enum Type { 
    TYPE_UNSPECIFIED = 0,
    TYPE_OFFER = 1,
    TYPE_ANSWER = 2,
    TYPE_PRANSWER = 3,
    TYPE_ROLLBACK = 4,
  }
}

export class IceCandidate extends jspb.Message {
  getCandidate(): string;
  setCandidate(value: string): IceCandidate;

  getSdpMid(): string;
  setSdpMid(value: string): IceCandidate;

  getSdpMLineIndex(): number;
  setSdpMLineIndex(value: number): IceCandidate;

  getUsernameFragment(): string;
  setUsernameFragment(value: string): IceCandidate;

  getTargetUuid(): string;
  setTargetUuid(value: string): IceCandidate;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): IceCandidate.AsObject;
  static toObject(includeInstance: boolean, msg: IceCandidate): IceCandidate.AsObject;
  static serializeBinaryToWriter(message: IceCandidate, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): IceCandidate;
  static deserializeBinaryFromReader(message: IceCandidate, reader: jspb.BinaryReader): IceCandidate;
}

export namespace IceCandidate {
  export type AsObject = {
    candidate: string,
    sdpMid: string,
    sdpMLineIndex: number,
    usernameFragment: string,
    targetUuid: string,
  }
}

export class Error extends jspb.Message {
  getCode(): number;
  setCode(value: number): Error;

  getMessage(): string;
  setMessage(value: string): Error;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): Error.AsObject;
  static toObject(includeInstance: boolean, msg: Error): Error.AsObject;
  static serializeBinaryToWriter(message: Error, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): Error;
  static deserializeBinaryFromReader(message: Error, reader: jspb.BinaryReader): Error;
}

export namespace Error {
  export type AsObject = {
    code: number,
    message: string,
  }
}

