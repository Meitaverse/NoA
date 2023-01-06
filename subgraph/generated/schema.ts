// THIS IS AN AUTOGENERATED FILE. DO NOT EDIT THIS FILE DIRECTLY.

import {
  TypedMap,
  Entity,
  Value,
  ValueKind,
  store,
  Bytes,
  BigInt,
  BigDecimal
} from "@graphprotocol/graph-ts";

export class Profile extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(id != null, "Cannot save Profile entity without an ID");
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type Profile must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("Profile", id.toString(), this);
    }
  }

  static load(id: string): Profile | null {
    return changetype<Profile | null>(store.get("Profile", id));
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get soulBoundTokenId(): BigInt {
    let value = this.get("soulBoundTokenId");
    return value!.toBigInt();
  }

  set soulBoundTokenId(value: BigInt) {
    this.set("soulBoundTokenId", Value.fromBigInt(value));
  }

  get creator(): Bytes {
    let value = this.get("creator");
    return value!.toBytes();
  }

  set creator(value: Bytes) {
    this.set("creator", Value.fromBytes(value));
  }

  get wallet(): Bytes {
    let value = this.get("wallet");
    return value!.toBytes();
  }

  set wallet(value: Bytes) {
    this.set("wallet", Value.fromBytes(value));
  }

  get nickName(): string {
    let value = this.get("nickName");
    return value!.toString();
  }

  set nickName(value: string) {
    this.set("nickName", Value.fromString(value));
  }

  get imageURI(): string {
    let value = this.get("imageURI");
    return value!.toString();
  }

  set imageURI(value: string) {
    this.set("imageURI", Value.fromString(value));
  }

  get timestamp(): BigInt {
    let value = this.get("timestamp");
    return value!.toBigInt();
  }

  set timestamp(value: BigInt) {
    this.set("timestamp", Value.fromBigInt(value));
  }
}

export class MintNDPValueHistory extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(id != null, "Cannot save MintNDPValueHistory entity without an ID");
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type MintNDPValueHistory must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("MintNDPValueHistory", id.toString(), this);
    }
  }

  static load(id: string): MintNDPValueHistory | null {
    return changetype<MintNDPValueHistory | null>(
      store.get("MintNDPValueHistory", id)
    );
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get soulBoundTokenId(): BigInt {
    let value = this.get("soulBoundTokenId");
    return value!.toBigInt();
  }

  set soulBoundTokenId(value: BigInt) {
    this.set("soulBoundTokenId", Value.fromBigInt(value));
  }

  get value(): BigInt {
    let value = this.get("value");
    return value!.toBigInt();
  }

  set value(value: BigInt) {
    this.set("value", Value.fromBigInt(value));
  }

  get timestamp(): BigInt {
    let value = this.get("timestamp");
    return value!.toBigInt();
  }

  set timestamp(value: BigInt) {
    this.set("timestamp", Value.fromBigInt(value));
  }
}

export class Hub extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(id != null, "Cannot save Hub entity without an ID");
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type Hub must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("Hub", id.toString(), this);
    }
  }

  static load(id: string): Hub | null {
    return changetype<Hub | null>(store.get("Hub", id));
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get soulBoundTokenId(): BigInt {
    let value = this.get("soulBoundTokenId");
    return value!.toBigInt();
  }

  set soulBoundTokenId(value: BigInt) {
    this.set("soulBoundTokenId", Value.fromBigInt(value));
  }

  get creator(): Bytes {
    let value = this.get("creator");
    return value!.toBytes();
  }

  set creator(value: Bytes) {
    this.set("creator", Value.fromBytes(value));
  }

  get hubId(): BigInt {
    let value = this.get("hubId");
    return value!.toBigInt();
  }

  set hubId(value: BigInt) {
    this.set("hubId", Value.fromBigInt(value));
  }

  get name(): string {
    let value = this.get("name");
    return value!.toString();
  }

  set name(value: string) {
    this.set("name", Value.fromString(value));
  }

  get description(): string {
    let value = this.get("description");
    return value!.toString();
  }

  set description(value: string) {
    this.set("description", Value.fromString(value));
  }

  get imageURI(): string {
    let value = this.get("imageURI");
    return value!.toString();
  }

  set imageURI(value: string) {
    this.set("imageURI", Value.fromString(value));
  }

  get timestamp(): BigInt {
    let value = this.get("timestamp");
    return value!.toBigInt();
  }

  set timestamp(value: BigInt) {
    this.set("timestamp", Value.fromBigInt(value));
  }
}

export class Publication extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(id != null, "Cannot save Publication entity without an ID");
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type Publication must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("Publication", id.toString(), this);
    }
  }

  static load(id: string): Publication | null {
    return changetype<Publication | null>(store.get("Publication", id));
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get soulBoundTokenId(): BigInt {
    let value = this.get("soulBoundTokenId");
    return value!.toBigInt();
  }

  set soulBoundTokenId(value: BigInt) {
    this.set("soulBoundTokenId", Value.fromBigInt(value));
  }

  get hubId(): BigInt {
    let value = this.get("hubId");
    return value!.toBigInt();
  }

  set hubId(value: BigInt) {
    this.set("hubId", Value.fromBigInt(value));
  }

  get projectId(): BigInt {
    let value = this.get("projectId");
    return value!.toBigInt();
  }

  set projectId(value: BigInt) {
    this.set("projectId", Value.fromBigInt(value));
  }

  get salePrice(): BigInt {
    let value = this.get("salePrice");
    return value!.toBigInt();
  }

  set salePrice(value: BigInt) {
    this.set("salePrice", Value.fromBigInt(value));
  }

  get royaltyBasisPoints(): BigInt {
    let value = this.get("royaltyBasisPoints");
    return value!.toBigInt();
  }

  set royaltyBasisPoints(value: BigInt) {
    this.set("royaltyBasisPoints", Value.fromBigInt(value));
  }

  get amount(): BigInt {
    let value = this.get("amount");
    return value!.toBigInt();
  }

  set amount(value: BigInt) {
    this.set("amount", Value.fromBigInt(value));
  }

  get name(): string {
    let value = this.get("name");
    return value!.toString();
  }

  set name(value: string) {
    this.set("name", Value.fromString(value));
  }

  get description(): string {
    let value = this.get("description");
    return value!.toString();
  }

  set description(value: string) {
    this.set("description", Value.fromString(value));
  }

  get materialURIs(): Array<string> | null {
    let value = this.get("materialURIs");
    if (!value || value.kind == ValueKind.NULL) {
      return null;
    } else {
      return value.toStringArray();
    }
  }

  set materialURIs(value: Array<string> | null) {
    if (!value) {
      this.unset("materialURIs");
    } else {
      this.set("materialURIs", Value.fromStringArray(<Array<string>>value));
    }
  }

  get fromTokenIds(): Array<BigInt> | null {
    let value = this.get("fromTokenIds");
    if (!value || value.kind == ValueKind.NULL) {
      return null;
    } else {
      return value.toBigIntArray();
    }
  }

  set fromTokenIds(value: Array<BigInt> | null) {
    if (!value) {
      this.unset("fromTokenIds");
    } else {
      this.set("fromTokenIds", Value.fromBigIntArray(<Array<BigInt>>value));
    }
  }

  get collectModule(): Bytes {
    let value = this.get("collectModule");
    return value!.toBytes();
  }

  set collectModule(value: Bytes) {
    this.set("collectModule", Value.fromBytes(value));
  }

  get collectModuleInitData(): Bytes {
    let value = this.get("collectModuleInitData");
    return value!.toBytes();
  }

  set collectModuleInitData(value: Bytes) {
    this.set("collectModuleInitData", Value.fromBytes(value));
  }

  get publishModule(): Bytes {
    let value = this.get("publishModule");
    return value!.toBytes();
  }

  set publishModule(value: Bytes) {
    this.set("publishModule", Value.fromBytes(value));
  }

  get publishModuleInitData(): Bytes {
    let value = this.get("publishModuleInitData");
    return value!.toBytes();
  }

  set publishModuleInitData(value: Bytes) {
    this.set("publishModuleInitData", Value.fromBytes(value));
  }

  get publishId(): BigInt {
    let value = this.get("publishId");
    return value!.toBigInt();
  }

  set publishId(value: BigInt) {
    this.set("publishId", Value.fromBigInt(value));
  }

  get previousPublishId(): BigInt {
    let value = this.get("previousPublishId");
    return value!.toBigInt();
  }

  set previousPublishId(value: BigInt) {
    this.set("previousPublishId", Value.fromBigInt(value));
  }

  get publishTaxAmount(): BigInt {
    let value = this.get("publishTaxAmount");
    return value!.toBigInt();
  }

  set publishTaxAmount(value: BigInt) {
    this.set("publishTaxAmount", Value.fromBigInt(value));
  }

  get timestamp(): BigInt {
    let value = this.get("timestamp");
    return value!.toBigInt();
  }

  set timestamp(value: BigInt) {
    this.set("timestamp", Value.fromBigInt(value));
  }
}

export class PublishCreatedHistory extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(
      id != null,
      "Cannot save PublishCreatedHistory entity without an ID"
    );
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type PublishCreatedHistory must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("PublishCreatedHistory", id.toString(), this);
    }
  }

  static load(id: string): PublishCreatedHistory | null {
    return changetype<PublishCreatedHistory | null>(
      store.get("PublishCreatedHistory", id)
    );
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get publishId(): BigInt {
    let value = this.get("publishId");
    return value!.toBigInt();
  }

  set publishId(value: BigInt) {
    this.set("publishId", Value.fromBigInt(value));
  }

  get soulBoundTokenId(): BigInt {
    let value = this.get("soulBoundTokenId");
    return value!.toBigInt();
  }

  set soulBoundTokenId(value: BigInt) {
    this.set("soulBoundTokenId", Value.fromBigInt(value));
  }

  get hubId(): BigInt {
    let value = this.get("hubId");
    return value!.toBigInt();
  }

  set hubId(value: BigInt) {
    this.set("hubId", Value.fromBigInt(value));
  }

  get projectId(): BigInt {
    let value = this.get("projectId");
    return value!.toBigInt();
  }

  set projectId(value: BigInt) {
    this.set("projectId", Value.fromBigInt(value));
  }

  get newTokenId(): BigInt {
    let value = this.get("newTokenId");
    return value!.toBigInt();
  }

  set newTokenId(value: BigInt) {
    this.set("newTokenId", Value.fromBigInt(value));
  }

  get amount(): BigInt {
    let value = this.get("amount");
    return value!.toBigInt();
  }

  set amount(value: BigInt) {
    this.set("amount", Value.fromBigInt(value));
  }

  get collectModuleInitData(): Bytes {
    let value = this.get("collectModuleInitData");
    return value!.toBytes();
  }

  set collectModuleInitData(value: Bytes) {
    this.set("collectModuleInitData", Value.fromBytes(value));
  }

  get timestamp(): BigInt {
    let value = this.get("timestamp");
    return value!.toBigInt();
  }

  set timestamp(value: BigInt) {
    this.set("timestamp", Value.fromBigInt(value));
  }
}

export class DerivativeNFTCollectedHistory extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(
      id != null,
      "Cannot save DerivativeNFTCollectedHistory entity without an ID"
    );
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type DerivativeNFTCollectedHistory must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("DerivativeNFTCollectedHistory", id.toString(), this);
    }
  }

  static load(id: string): DerivativeNFTCollectedHistory | null {
    return changetype<DerivativeNFTCollectedHistory | null>(
      store.get("DerivativeNFTCollectedHistory", id)
    );
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get projectId(): BigInt {
    let value = this.get("projectId");
    return value!.toBigInt();
  }

  set projectId(value: BigInt) {
    this.set("projectId", Value.fromBigInt(value));
  }

  get derivativeNFT(): Bytes {
    let value = this.get("derivativeNFT");
    return value!.toBytes();
  }

  set derivativeNFT(value: Bytes) {
    this.set("derivativeNFT", Value.fromBytes(value));
  }

  get fromSoulBoundTokenId(): BigInt {
    let value = this.get("fromSoulBoundTokenId");
    return value!.toBigInt();
  }

  set fromSoulBoundTokenId(value: BigInt) {
    this.set("fromSoulBoundTokenId", Value.fromBigInt(value));
  }

  get toSoulBoundTokenId(): BigInt {
    let value = this.get("toSoulBoundTokenId");
    return value!.toBigInt();
  }

  set toSoulBoundTokenId(value: BigInt) {
    this.set("toSoulBoundTokenId", Value.fromBigInt(value));
  }

  get tokenId(): BigInt {
    let value = this.get("tokenId");
    return value!.toBigInt();
  }

  set tokenId(value: BigInt) {
    this.set("tokenId", Value.fromBigInt(value));
  }

  get value(): BigInt {
    let value = this.get("value");
    return value!.toBigInt();
  }

  set value(value: BigInt) {
    this.set("value", Value.fromBigInt(value));
  }

  get newTokenId(): BigInt {
    let value = this.get("newTokenId");
    return value!.toBigInt();
  }

  set newTokenId(value: BigInt) {
    this.set("newTokenId", Value.fromBigInt(value));
  }

  get timestamp(): BigInt {
    let value = this.get("timestamp");
    return value!.toBigInt();
  }

  set timestamp(value: BigInt) {
    this.set("timestamp", Value.fromBigInt(value));
  }
}

export class DerivativeNFTTransferHistory extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(
      id != null,
      "Cannot save DerivativeNFTTransferHistory entity without an ID"
    );
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type DerivativeNFTTransferHistory must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("DerivativeNFTTransferHistory", id.toString(), this);
    }
  }

  static load(id: string): DerivativeNFTTransferHistory | null {
    return changetype<DerivativeNFTTransferHistory | null>(
      store.get("DerivativeNFTTransferHistory", id)
    );
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get fromSoulBoundTokenId(): BigInt {
    let value = this.get("fromSoulBoundTokenId");
    return value!.toBigInt();
  }

  set fromSoulBoundTokenId(value: BigInt) {
    this.set("fromSoulBoundTokenId", Value.fromBigInt(value));
  }

  get toSoulBoundTokenId(): BigInt {
    let value = this.get("toSoulBoundTokenId");
    return value!.toBigInt();
  }

  set toSoulBoundTokenId(value: BigInt) {
    this.set("toSoulBoundTokenId", Value.fromBigInt(value));
  }

  get projectId(): BigInt {
    let value = this.get("projectId");
    return value!.toBigInt();
  }

  set projectId(value: BigInt) {
    this.set("projectId", Value.fromBigInt(value));
  }

  get tokenId(): BigInt {
    let value = this.get("tokenId");
    return value!.toBigInt();
  }

  set tokenId(value: BigInt) {
    this.set("tokenId", Value.fromBigInt(value));
  }

  get timestamp(): BigInt {
    let value = this.get("timestamp");
    return value!.toBigInt();
  }

  set timestamp(value: BigInt) {
    this.set("timestamp", Value.fromBigInt(value));
  }
}

export class DerivativeNFTTransferValueHistory extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(
      id != null,
      "Cannot save DerivativeNFTTransferValueHistory entity without an ID"
    );
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type DerivativeNFTTransferValueHistory must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("DerivativeNFTTransferValueHistory", id.toString(), this);
    }
  }

  static load(id: string): DerivativeNFTTransferValueHistory | null {
    return changetype<DerivativeNFTTransferValueHistory | null>(
      store.get("DerivativeNFTTransferValueHistory", id)
    );
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get fromSoulBoundTokenId(): BigInt {
    let value = this.get("fromSoulBoundTokenId");
    return value!.toBigInt();
  }

  set fromSoulBoundTokenId(value: BigInt) {
    this.set("fromSoulBoundTokenId", Value.fromBigInt(value));
  }

  get toSoulBoundTokenId(): BigInt {
    let value = this.get("toSoulBoundTokenId");
    return value!.toBigInt();
  }

  set toSoulBoundTokenId(value: BigInt) {
    this.set("toSoulBoundTokenId", Value.fromBigInt(value));
  }

  get projectId(): BigInt {
    let value = this.get("projectId");
    return value!.toBigInt();
  }

  set projectId(value: BigInt) {
    this.set("projectId", Value.fromBigInt(value));
  }

  get tokenId(): BigInt {
    let value = this.get("tokenId");
    return value!.toBigInt();
  }

  set tokenId(value: BigInt) {
    this.set("tokenId", Value.fromBigInt(value));
  }

  get value(): BigInt {
    let value = this.get("value");
    return value!.toBigInt();
  }

  set value(value: BigInt) {
    this.set("value", Value.fromBigInt(value));
  }

  get newTokenId(): BigInt {
    let value = this.get("newTokenId");
    return value!.toBigInt();
  }

  set newTokenId(value: BigInt) {
    this.set("newTokenId", Value.fromBigInt(value));
  }

  get timestamp(): BigInt {
    let value = this.get("timestamp");
    return value!.toBigInt();
  }

  set timestamp(value: BigInt) {
    this.set("timestamp", Value.fromBigInt(value));
  }
}

export class WithdrawERC3525History extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(
      id != null,
      "Cannot save WithdrawERC3525History entity without an ID"
    );
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type WithdrawERC3525History must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("WithdrawERC3525History", id.toString(), this);
    }
  }

  static load(id: string): WithdrawERC3525History | null {
    return changetype<WithdrawERC3525History | null>(
      store.get("WithdrawERC3525History", id)
    );
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get fromTokenId(): BigInt {
    let value = this.get("fromTokenId");
    return value!.toBigInt();
  }

  set fromTokenId(value: BigInt) {
    this.set("fromTokenId", Value.fromBigInt(value));
  }

  get toTokenId(): BigInt {
    let value = this.get("toTokenId");
    return value!.toBigInt();
  }

  set toTokenId(value: BigInt) {
    this.set("toTokenId", Value.fromBigInt(value));
  }

  get value(): BigInt {
    let value = this.get("value");
    return value!.toBigInt();
  }

  set value(value: BigInt) {
    this.set("value", Value.fromBigInt(value));
  }

  get timestamp(): BigInt {
    let value = this.get("timestamp");
    return value!.toBigInt();
  }

  set timestamp(value: BigInt) {
    this.set("timestamp", Value.fromBigInt(value));
  }
}

export class NFTVoucherHistory extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(id != null, "Cannot save NFTVoucherHistory entity without an ID");
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type NFTVoucherHistory must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("NFTVoucherHistory", id.toString(), this);
    }
  }

  static load(id: string): NFTVoucherHistory | null {
    return changetype<NFTVoucherHistory | null>(
      store.get("NFTVoucherHistory", id)
    );
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get soulBoundTokenId(): BigInt {
    let value = this.get("soulBoundTokenId");
    return value!.toBigInt();
  }

  set soulBoundTokenId(value: BigInt) {
    this.set("soulBoundTokenId", Value.fromBigInt(value));
  }

  get account(): Bytes {
    let value = this.get("account");
    return value!.toBytes();
  }

  set account(value: Bytes) {
    this.set("account", Value.fromBytes(value));
  }

  get vouchType(): i32 {
    let value = this.get("vouchType");
    return value!.toI32();
  }

  set vouchType(value: i32) {
    this.set("vouchType", Value.fromI32(value));
  }

  get tokenId(): BigInt {
    let value = this.get("tokenId");
    return value!.toBigInt();
  }

  set tokenId(value: BigInt) {
    this.set("tokenId", Value.fromBigInt(value));
  }

  get ndptValue(): BigInt {
    let value = this.get("ndptValue");
    return value!.toBigInt();
  }

  set ndptValue(value: BigInt) {
    this.set("ndptValue", Value.fromBigInt(value));
  }

  get generateTimestamp(): BigInt {
    let value = this.get("generateTimestamp");
    return value!.toBigInt();
  }

  set generateTimestamp(value: BigInt) {
    this.set("generateTimestamp", Value.fromBigInt(value));
  }
}

export class ProfileCreatorWhitelistedHistory extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(
      id != null,
      "Cannot save ProfileCreatorWhitelistedHistory entity without an ID"
    );
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type ProfileCreatorWhitelistedHistory must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("ProfileCreatorWhitelistedHistory", id.toString(), this);
    }
  }

  static load(id: string): ProfileCreatorWhitelistedHistory | null {
    return changetype<ProfileCreatorWhitelistedHistory | null>(
      store.get("ProfileCreatorWhitelistedHistory", id)
    );
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get profileCreator(): Bytes {
    let value = this.get("profileCreator");
    return value!.toBytes();
  }

  set profileCreator(value: Bytes) {
    this.set("profileCreator", Value.fromBytes(value));
  }

  get whitelisted(): boolean {
    let value = this.get("whitelisted");
    return value!.toBoolean();
  }

  set whitelisted(value: boolean) {
    this.set("whitelisted", Value.fromBoolean(value));
  }

  get timestamp(): BigInt {
    let value = this.get("timestamp");
    return value!.toBigInt();
  }

  set timestamp(value: BigInt) {
    this.set("timestamp", Value.fromBigInt(value));
  }
}

export class FeesForCollectHistory extends Entity {
  constructor(id: string) {
    super();
    this.set("id", Value.fromString(id));
  }

  save(): void {
    let id = this.get("id");
    assert(
      id != null,
      "Cannot save FeesForCollectHistory entity without an ID"
    );
    if (id) {
      assert(
        id.kind == ValueKind.STRING,
        `Entities of type FeesForCollectHistory must have an ID of type String but the id '${id.displayData()}' is of type ${id.displayKind()}`
      );
      store.set("FeesForCollectHistory", id.toString(), this);
    }
  }

  static load(id: string): FeesForCollectHistory | null {
    return changetype<FeesForCollectHistory | null>(
      store.get("FeesForCollectHistory", id)
    );
  }

  get id(): string {
    let value = this.get("id");
    return value!.toString();
  }

  set id(value: string) {
    this.set("id", Value.fromString(value));
  }

  get collectorSoulBoundTokenId(): BigInt {
    let value = this.get("collectorSoulBoundTokenId");
    return value!.toBigInt();
  }

  set collectorSoulBoundTokenId(value: BigInt) {
    this.set("collectorSoulBoundTokenId", Value.fromBigInt(value));
  }

  get publishId(): BigInt {
    let value = this.get("publishId");
    return value!.toBigInt();
  }

  set publishId(value: BigInt) {
    this.set("publishId", Value.fromBigInt(value));
  }

  get treasuryAmount(): BigInt {
    let value = this.get("treasuryAmount");
    return value!.toBigInt();
  }

  set treasuryAmount(value: BigInt) {
    this.set("treasuryAmount", Value.fromBigInt(value));
  }

  get genesisAmount(): BigInt {
    let value = this.get("genesisAmount");
    return value!.toBigInt();
  }

  set genesisAmount(value: BigInt) {
    this.set("genesisAmount", Value.fromBigInt(value));
  }

  get adjustedAmount(): BigInt {
    let value = this.get("adjustedAmount");
    return value!.toBigInt();
  }

  set adjustedAmount(value: BigInt) {
    this.set("adjustedAmount", Value.fromBigInt(value));
  }

  get timestamp(): BigInt {
    let value = this.get("timestamp");
    return value!.toBigInt();
  }

  set timestamp(value: BigInt) {
    this.set("timestamp", Value.fromBigInt(value));
  }
}
