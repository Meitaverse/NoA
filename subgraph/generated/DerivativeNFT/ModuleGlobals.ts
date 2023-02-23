// THIS IS AN AUTOGENERATED FILE. DO NOT EDIT THIS FILE DIRECTLY.

import {
  ethereum,
  JSONValue,
  TypedMap,
  Entity,
  Bytes,
  Address,
  BigInt
} from "@graphprotocol/graph-ts";

export class ModuleGlobals__getCurrencyInfoResultValue0Struct extends ethereum.Tuple {
  get currencyName(): string {
    return this[0].toString();
  }

  get currencySymbol(): string {
    return this[1].toString();
  }

  get currencyDecimals(): i32 {
    return this[2].toI32();
  }
}

export class ModuleGlobals__getGenesisAndPreviousPublishIdResult {
  value0: BigInt;
  value1: BigInt;

  constructor(value0: BigInt, value1: BigInt) {
    this.value0 = value0;
    this.value1 = value1;
  }

  toMap(): TypedMap<string, ethereum.Value> {
    let map = new TypedMap<string, ethereum.Value>();
    map.set("value0", ethereum.Value.fromUnsignedBigInt(this.value0));
    map.set("value1", ethereum.Value.fromUnsignedBigInt(this.value1));
    return map;
  }

  getGenesisPublishId(): BigInt {
    return this.value0;
  }

  getPreviousPublishId(): BigInt {
    return this.value1;
  }
}

export class ModuleGlobals__getHubInfoResultValue0Struct extends ethereum.Tuple {
  get soulBoundTokenId(): BigInt {
    return this[0].toBigInt();
  }

  get hubOwner(): Address {
    return this[1].toAddress();
  }

  get name(): string {
    return this[2].toString();
  }

  get description(): string {
    return this[3].toString();
  }

  get imageURI(): string {
    return this[4].toString();
  }
}

export class ModuleGlobals__getProjectInfoResultValue0Struct extends ethereum.Tuple {
  get hubId(): BigInt {
    return this[0].toBigInt();
  }

  get soulBoundTokenId(): BigInt {
    return this[1].toBigInt();
  }

  get name(): string {
    return this[2].toString();
  }

  get description(): string {
    return this[3].toString();
  }

  get image(): string {
    return this[4].toString();
  }

  get metadataURI(): string {
    return this[5].toString();
  }

  get descriptor(): Address {
    return this[6].toAddress();
  }

  get defaultRoyaltyPoints(): i32 {
    return this[7].toI32();
  }

  get permitByHubOwner(): boolean {
    return this[8].toBoolean();
  }
}

export class ModuleGlobals__getPublicationResultValue0Struct extends ethereum.Tuple {
  get soulBoundTokenId(): BigInt {
    return this[0].toBigInt();
  }

  get hubId(): BigInt {
    return this[1].toBigInt();
  }

  get projectId(): BigInt {
    return this[2].toBigInt();
  }

  get salePrice(): BigInt {
    return this[3].toBigInt();
  }

  get royaltyBasisPoints(): BigInt {
    return this[4].toBigInt();
  }

  get currency(): Address {
    return this[5].toAddress();
  }

  get amount(): BigInt {
    return this[6].toBigInt();
  }

  get name(): string {
    return this[7].toString();
  }

  get description(): string {
    return this[8].toString();
  }

  get canCollect(): boolean {
    return this[9].toBoolean();
  }

  get materialURIs(): Array<string> {
    return this[10].toStringArray();
  }

  get fromTokenIds(): Array<BigInt> {
    return this[11].toBigIntArray();
  }

  get collectModule(): Address {
    return this[12].toAddress();
  }

  get collectModuleInitData(): Bytes {
    return this[13].toBytes();
  }

  get publishModule(): Address {
    return this[14].toAddress();
  }

  get publishModuleInitData(): Bytes {
    return this[15].toBytes();
  }
}

export class ModuleGlobals__getTreasuryDataResult {
  value0: Address;
  value1: i32;

  constructor(value0: Address, value1: i32) {
    this.value0 = value0;
    this.value1 = value1;
  }

  toMap(): TypedMap<string, ethereum.Value> {
    let map = new TypedMap<string, ethereum.Value>();
    map.set("value0", ethereum.Value.fromAddress(this.value0));
    map.set(
      "value1",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(this.value1))
    );
    return map;
  }

  getValue0(): Address {
    return this.value0;
  }

  getValue1(): i32 {
    return this.value1;
  }
}

export class ModuleGlobals extends ethereum.SmartContract {
  static bind(address: Address): ModuleGlobals {
    return new ModuleGlobals("ModuleGlobals", address);
  }

  getCurrencyInfo(
    currency: Address
  ): ModuleGlobals__getCurrencyInfoResultValue0Struct {
    let result = super.call(
      "getCurrencyInfo",
      "getCurrencyInfo(address):((string,string,uint8))",
      [ethereum.Value.fromAddress(currency)]
    );

    return changetype<ModuleGlobals__getCurrencyInfoResultValue0Struct>(
      result[0].toTuple()
    );
  }

  try_getCurrencyInfo(
    currency: Address
  ): ethereum.CallResult<ModuleGlobals__getCurrencyInfoResultValue0Struct> {
    let result = super.tryCall(
      "getCurrencyInfo",
      "getCurrencyInfo(address):((string,string,uint8))",
      [ethereum.Value.fromAddress(currency)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(
      changetype<ModuleGlobals__getCurrencyInfoResultValue0Struct>(
        value[0].toTuple()
      )
    );
  }

  getGenesisAndPreviousPublishId(
    publishId: BigInt
  ): ModuleGlobals__getGenesisAndPreviousPublishIdResult {
    let result = super.call(
      "getGenesisAndPreviousPublishId",
      "getGenesisAndPreviousPublishId(uint256):(uint256,uint256)",
      [ethereum.Value.fromUnsignedBigInt(publishId)]
    );

    return new ModuleGlobals__getGenesisAndPreviousPublishIdResult(
      result[0].toBigInt(),
      result[1].toBigInt()
    );
  }

  try_getGenesisAndPreviousPublishId(
    publishId: BigInt
  ): ethereum.CallResult<ModuleGlobals__getGenesisAndPreviousPublishIdResult> {
    let result = super.tryCall(
      "getGenesisAndPreviousPublishId",
      "getGenesisAndPreviousPublishId(uint256):(uint256,uint256)",
      [ethereum.Value.fromUnsignedBigInt(publishId)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(
      new ModuleGlobals__getGenesisAndPreviousPublishIdResult(
        value[0].toBigInt(),
        value[1].toBigInt()
      )
    );
  }

  getGovernance(): Address {
    let result = super.call("getGovernance", "getGovernance():(address)", []);

    return result[0].toAddress();
  }

  try_getGovernance(): ethereum.CallResult<Address> {
    let result = super.tryCall(
      "getGovernance",
      "getGovernance():(address)",
      []
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toAddress());
  }

  getHubInfo(hubId: BigInt): ModuleGlobals__getHubInfoResultValue0Struct {
    let result = super.call(
      "getHubInfo",
      "getHubInfo(uint256):((uint256,address,string,string,string))",
      [ethereum.Value.fromUnsignedBigInt(hubId)]
    );

    return changetype<ModuleGlobals__getHubInfoResultValue0Struct>(
      result[0].toTuple()
    );
  }

  try_getHubInfo(
    hubId: BigInt
  ): ethereum.CallResult<ModuleGlobals__getHubInfoResultValue0Struct> {
    let result = super.tryCall(
      "getHubInfo",
      "getHubInfo(uint256):((uint256,address,string,string,string))",
      [ethereum.Value.fromUnsignedBigInt(hubId)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(
      changetype<ModuleGlobals__getHubInfoResultValue0Struct>(
        value[0].toTuple()
      )
    );
  }

  getManager(): Address {
    let result = super.call("getManager", "getManager():(address)", []);

    return result[0].toAddress();
  }

  try_getManager(): ethereum.CallResult<Address> {
    let result = super.tryCall("getManager", "getManager():(address)", []);
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toAddress());
  }

  getMarketPlace(): Address {
    let result = super.call("getMarketPlace", "getMarketPlace():(address)", []);

    return result[0].toAddress();
  }

  try_getMarketPlace(): ethereum.CallResult<Address> {
    let result = super.tryCall(
      "getMarketPlace",
      "getMarketPlace():(address)",
      []
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toAddress());
  }

  getProjectInfo(
    projectId_: BigInt
  ): ModuleGlobals__getProjectInfoResultValue0Struct {
    let result = super.call(
      "getProjectInfo",
      "getProjectInfo(uint256):((uint256,uint256,string,string,string,string,address,uint16,bool))",
      [ethereum.Value.fromUnsignedBigInt(projectId_)]
    );

    return changetype<ModuleGlobals__getProjectInfoResultValue0Struct>(
      result[0].toTuple()
    );
  }

  try_getProjectInfo(
    projectId_: BigInt
  ): ethereum.CallResult<ModuleGlobals__getProjectInfoResultValue0Struct> {
    let result = super.tryCall(
      "getProjectInfo",
      "getProjectInfo(uint256):((uint256,uint256,string,string,string,string,address,uint16,bool))",
      [ethereum.Value.fromUnsignedBigInt(projectId_)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(
      changetype<ModuleGlobals__getProjectInfoResultValue0Struct>(
        value[0].toTuple()
      )
    );
  }

  getPublication(
    publishId_: BigInt
  ): ModuleGlobals__getPublicationResultValue0Struct {
    let result = super.call(
      "getPublication",
      "getPublication(uint256):((uint256,uint256,uint256,uint256,uint256,address,uint256,string,string,bool,string[],uint256[],address,bytes,address,bytes))",
      [ethereum.Value.fromUnsignedBigInt(publishId_)]
    );

    return changetype<ModuleGlobals__getPublicationResultValue0Struct>(
      result[0].toTuple()
    );
  }

  try_getPublication(
    publishId_: BigInt
  ): ethereum.CallResult<ModuleGlobals__getPublicationResultValue0Struct> {
    let result = super.tryCall(
      "getPublication",
      "getPublication(uint256):((uint256,uint256,uint256,uint256,uint256,address,uint256,string,string,bool,string[],uint256[],address,bytes,address,bytes))",
      [ethereum.Value.fromUnsignedBigInt(publishId_)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(
      changetype<ModuleGlobals__getPublicationResultValue0Struct>(
        value[0].toTuple()
      )
    );
  }

  getPublishCurrencyTax(): BigInt {
    let result = super.call(
      "getPublishCurrencyTax",
      "getPublishCurrencyTax():(uint256)",
      []
    );

    return result[0].toBigInt();
  }

  try_getPublishCurrencyTax(): ethereum.CallResult<BigInt> {
    let result = super.tryCall(
      "getPublishCurrencyTax",
      "getPublishCurrencyTax():(uint256)",
      []
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBigInt());
  }

  getSBT(): Address {
    let result = super.call("getSBT", "getSBT():(address)", []);

    return result[0].toAddress();
  }

  try_getSBT(): ethereum.CallResult<Address> {
    let result = super.tryCall("getSBT", "getSBT():(address)", []);
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toAddress());
  }

  getTreasury(): Address {
    let result = super.call("getTreasury", "getTreasury():(address)", []);

    return result[0].toAddress();
  }

  try_getTreasury(): ethereum.CallResult<Address> {
    let result = super.tryCall("getTreasury", "getTreasury():(address)", []);
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toAddress());
  }

  getTreasuryData(): ModuleGlobals__getTreasuryDataResult {
    let result = super.call(
      "getTreasuryData",
      "getTreasuryData():(address,uint16)",
      []
    );

    return new ModuleGlobals__getTreasuryDataResult(
      result[0].toAddress(),
      result[1].toI32()
    );
  }

  try_getTreasuryData(): ethereum.CallResult<
    ModuleGlobals__getTreasuryDataResult
  > {
    let result = super.tryCall(
      "getTreasuryData",
      "getTreasuryData():(address,uint16)",
      []
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(
      new ModuleGlobals__getTreasuryDataResult(
        value[0].toAddress(),
        value[1].toI32()
      )
    );
  }

  getTreasuryFee(): i32 {
    let result = super.call("getTreasuryFee", "getTreasuryFee():(uint16)", []);

    return result[0].toI32();
  }

  try_getTreasuryFee(): ethereum.CallResult<i32> {
    let result = super.tryCall(
      "getTreasuryFee",
      "getTreasuryFee():(uint16)",
      []
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toI32());
  }

  getVoucher(): Address {
    let result = super.call("getVoucher", "getVoucher():(address)", []);

    return result[0].toAddress();
  }

  try_getVoucher(): ethereum.CallResult<Address> {
    let result = super.tryCall("getVoucher", "getVoucher():(address)", []);
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toAddress());
  }

  getWallet(soulBoundTokenId: BigInt): Address {
    let result = super.call("getWallet", "getWallet(uint256):(address)", [
      ethereum.Value.fromUnsignedBigInt(soulBoundTokenId)
    ]);

    return result[0].toAddress();
  }

  try_getWallet(soulBoundTokenId: BigInt): ethereum.CallResult<Address> {
    let result = super.tryCall("getWallet", "getWallet(uint256):(address)", [
      ethereum.Value.fromUnsignedBigInt(soulBoundTokenId)
    ]);
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toAddress());
  }

  isCurrencyWhitelisted(currency: Address): boolean {
    let result = super.call(
      "isCurrencyWhitelisted",
      "isCurrencyWhitelisted(address):(bool)",
      [ethereum.Value.fromAddress(currency)]
    );

    return result[0].toBoolean();
  }

  try_isCurrencyWhitelisted(currency: Address): ethereum.CallResult<boolean> {
    let result = super.tryCall(
      "isCurrencyWhitelisted",
      "isCurrencyWhitelisted(address):(bool)",
      [ethereum.Value.fromAddress(currency)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBoolean());
  }

  isWhitelistCollectModule(collectModule: Address): boolean {
    let result = super.call(
      "isWhitelistCollectModule",
      "isWhitelistCollectModule(address):(bool)",
      [ethereum.Value.fromAddress(collectModule)]
    );

    return result[0].toBoolean();
  }

  try_isWhitelistCollectModule(
    collectModule: Address
  ): ethereum.CallResult<boolean> {
    let result = super.tryCall(
      "isWhitelistCollectModule",
      "isWhitelistCollectModule(address):(bool)",
      [ethereum.Value.fromAddress(collectModule)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBoolean());
  }

  isWhitelistHubCreator(soulBoundTokenId: BigInt): boolean {
    let result = super.call(
      "isWhitelistHubCreator",
      "isWhitelistHubCreator(uint256):(bool)",
      [ethereum.Value.fromUnsignedBigInt(soulBoundTokenId)]
    );

    return result[0].toBoolean();
  }

  try_isWhitelistHubCreator(
    soulBoundTokenId: BigInt
  ): ethereum.CallResult<boolean> {
    let result = super.tryCall(
      "isWhitelistHubCreator",
      "isWhitelistHubCreator(uint256):(bool)",
      [ethereum.Value.fromUnsignedBigInt(soulBoundTokenId)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBoolean());
  }

  isWhitelistProfileCreator(profileCreator: Address): boolean {
    let result = super.call(
      "isWhitelistProfileCreator",
      "isWhitelistProfileCreator(address):(bool)",
      [ethereum.Value.fromAddress(profileCreator)]
    );

    return result[0].toBoolean();
  }

  try_isWhitelistProfileCreator(
    profileCreator: Address
  ): ethereum.CallResult<boolean> {
    let result = super.tryCall(
      "isWhitelistProfileCreator",
      "isWhitelistProfileCreator(address):(bool)",
      [ethereum.Value.fromAddress(profileCreator)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBoolean());
  }

  isWhitelistPublishModule(publishModule: Address): boolean {
    let result = super.call(
      "isWhitelistPublishModule",
      "isWhitelistPublishModule(address):(bool)",
      [ethereum.Value.fromAddress(publishModule)]
    );

    return result[0].toBoolean();
  }

  try_isWhitelistPublishModule(
    publishModule: Address
  ): ethereum.CallResult<boolean> {
    let result = super.tryCall(
      "isWhitelistPublishModule",
      "isWhitelistPublishModule(address):(bool)",
      [ethereum.Value.fromAddress(publishModule)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBoolean());
  }

  isWhitelistTemplate(template: Address): boolean {
    let result = super.call(
      "isWhitelistTemplate",
      "isWhitelistTemplate(address):(bool)",
      [ethereum.Value.fromAddress(template)]
    );

    return result[0].toBoolean();
  }

  try_isWhitelistTemplate(template: Address): ethereum.CallResult<boolean> {
    let result = super.tryCall(
      "isWhitelistTemplate",
      "isWhitelistTemplate(address):(bool)",
      [ethereum.Value.fromAddress(template)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBoolean());
  }
}

export class ConstructorCall extends ethereum.Call {
  get inputs(): ConstructorCall__Inputs {
    return new ConstructorCall__Inputs(this);
  }

  get outputs(): ConstructorCall__Outputs {
    return new ConstructorCall__Outputs(this);
  }
}

export class ConstructorCall__Inputs {
  _call: ConstructorCall;

  constructor(call: ConstructorCall) {
    this._call = call;
  }

  get manager(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get sbt(): Address {
    return this._call.inputValues[1].value.toAddress();
  }

  get governance(): Address {
    return this._call.inputValues[2].value.toAddress();
  }

  get treasury(): Address {
    return this._call.inputValues[3].value.toAddress();
  }

  get marketPlace(): Address {
    return this._call.inputValues[4].value.toAddress();
  }

  get voucher(): Address {
    return this._call.inputValues[5].value.toAddress();
  }

  get treasuryFee(): i32 {
    return this._call.inputValues[6].value.toI32();
  }

  get publishRoyalty(): BigInt {
    return this._call.inputValues[7].value.toBigInt();
  }
}

export class ConstructorCall__Outputs {
  _call: ConstructorCall;

  constructor(call: ConstructorCall) {
    this._call = call;
  }
}

export class SetGovernanceCall extends ethereum.Call {
  get inputs(): SetGovernanceCall__Inputs {
    return new SetGovernanceCall__Inputs(this);
  }

  get outputs(): SetGovernanceCall__Outputs {
    return new SetGovernanceCall__Outputs(this);
  }
}

export class SetGovernanceCall__Inputs {
  _call: SetGovernanceCall;

  constructor(call: SetGovernanceCall) {
    this._call = call;
  }

  get newGovernance(): Address {
    return this._call.inputValues[0].value.toAddress();
  }
}

export class SetGovernanceCall__Outputs {
  _call: SetGovernanceCall;

  constructor(call: SetGovernanceCall) {
    this._call = call;
  }
}

export class SetManagerCall extends ethereum.Call {
  get inputs(): SetManagerCall__Inputs {
    return new SetManagerCall__Inputs(this);
  }

  get outputs(): SetManagerCall__Outputs {
    return new SetManagerCall__Outputs(this);
  }
}

export class SetManagerCall__Inputs {
  _call: SetManagerCall;

  constructor(call: SetManagerCall) {
    this._call = call;
  }

  get newManager(): Address {
    return this._call.inputValues[0].value.toAddress();
  }
}

export class SetManagerCall__Outputs {
  _call: SetManagerCall;

  constructor(call: SetManagerCall) {
    this._call = call;
  }
}

export class SetMarketPlaceCall extends ethereum.Call {
  get inputs(): SetMarketPlaceCall__Inputs {
    return new SetMarketPlaceCall__Inputs(this);
  }

  get outputs(): SetMarketPlaceCall__Outputs {
    return new SetMarketPlaceCall__Outputs(this);
  }
}

export class SetMarketPlaceCall__Inputs {
  _call: SetMarketPlaceCall;

  constructor(call: SetMarketPlaceCall) {
    this._call = call;
  }

  get newMarketPlace(): Address {
    return this._call.inputValues[0].value.toAddress();
  }
}

export class SetMarketPlaceCall__Outputs {
  _call: SetMarketPlaceCall;

  constructor(call: SetMarketPlaceCall) {
    this._call = call;
  }
}

export class SetPublishRoyaltyCall extends ethereum.Call {
  get inputs(): SetPublishRoyaltyCall__Inputs {
    return new SetPublishRoyaltyCall__Inputs(this);
  }

  get outputs(): SetPublishRoyaltyCall__Outputs {
    return new SetPublishRoyaltyCall__Outputs(this);
  }
}

export class SetPublishRoyaltyCall__Inputs {
  _call: SetPublishRoyaltyCall;

  constructor(call: SetPublishRoyaltyCall) {
    this._call = call;
  }

  get publishRoyalty(): BigInt {
    return this._call.inputValues[0].value.toBigInt();
  }
}

export class SetPublishRoyaltyCall__Outputs {
  _call: SetPublishRoyaltyCall;

  constructor(call: SetPublishRoyaltyCall) {
    this._call = call;
  }
}

export class SetSBTCall extends ethereum.Call {
  get inputs(): SetSBTCall__Inputs {
    return new SetSBTCall__Inputs(this);
  }

  get outputs(): SetSBTCall__Outputs {
    return new SetSBTCall__Outputs(this);
  }
}

export class SetSBTCall__Inputs {
  _call: SetSBTCall;

  constructor(call: SetSBTCall) {
    this._call = call;
  }

  get newSBT(): Address {
    return this._call.inputValues[0].value.toAddress();
  }
}

export class SetSBTCall__Outputs {
  _call: SetSBTCall;

  constructor(call: SetSBTCall) {
    this._call = call;
  }
}

export class SetTreasuryCall extends ethereum.Call {
  get inputs(): SetTreasuryCall__Inputs {
    return new SetTreasuryCall__Inputs(this);
  }

  get outputs(): SetTreasuryCall__Outputs {
    return new SetTreasuryCall__Outputs(this);
  }
}

export class SetTreasuryCall__Inputs {
  _call: SetTreasuryCall;

  constructor(call: SetTreasuryCall) {
    this._call = call;
  }

  get newTreasury(): Address {
    return this._call.inputValues[0].value.toAddress();
  }
}

export class SetTreasuryCall__Outputs {
  _call: SetTreasuryCall;

  constructor(call: SetTreasuryCall) {
    this._call = call;
  }
}

export class SetTreasuryFeeCall extends ethereum.Call {
  get inputs(): SetTreasuryFeeCall__Inputs {
    return new SetTreasuryFeeCall__Inputs(this);
  }

  get outputs(): SetTreasuryFeeCall__Outputs {
    return new SetTreasuryFeeCall__Outputs(this);
  }
}

export class SetTreasuryFeeCall__Inputs {
  _call: SetTreasuryFeeCall;

  constructor(call: SetTreasuryFeeCall) {
    this._call = call;
  }

  get newTreasuryFee(): i32 {
    return this._call.inputValues[0].value.toI32();
  }
}

export class SetTreasuryFeeCall__Outputs {
  _call: SetTreasuryFeeCall;

  constructor(call: SetTreasuryFeeCall) {
    this._call = call;
  }
}

export class SetVoucherCall extends ethereum.Call {
  get inputs(): SetVoucherCall__Inputs {
    return new SetVoucherCall__Inputs(this);
  }

  get outputs(): SetVoucherCall__Outputs {
    return new SetVoucherCall__Outputs(this);
  }
}

export class SetVoucherCall__Inputs {
  _call: SetVoucherCall;

  constructor(call: SetVoucherCall) {
    this._call = call;
  }

  get newVoucher(): Address {
    return this._call.inputValues[0].value.toAddress();
  }
}

export class SetVoucherCall__Outputs {
  _call: SetVoucherCall;

  constructor(call: SetVoucherCall) {
    this._call = call;
  }
}

export class WhitelistCollectModuleCall extends ethereum.Call {
  get inputs(): WhitelistCollectModuleCall__Inputs {
    return new WhitelistCollectModuleCall__Inputs(this);
  }

  get outputs(): WhitelistCollectModuleCall__Outputs {
    return new WhitelistCollectModuleCall__Outputs(this);
  }
}

export class WhitelistCollectModuleCall__Inputs {
  _call: WhitelistCollectModuleCall;

  constructor(call: WhitelistCollectModuleCall) {
    this._call = call;
  }

  get collectModule(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get whitelist(): boolean {
    return this._call.inputValues[1].value.toBoolean();
  }
}

export class WhitelistCollectModuleCall__Outputs {
  _call: WhitelistCollectModuleCall;

  constructor(call: WhitelistCollectModuleCall) {
    this._call = call;
  }
}

export class WhitelistCurrencyCall extends ethereum.Call {
  get inputs(): WhitelistCurrencyCall__Inputs {
    return new WhitelistCurrencyCall__Inputs(this);
  }

  get outputs(): WhitelistCurrencyCall__Outputs {
    return new WhitelistCurrencyCall__Outputs(this);
  }
}

export class WhitelistCurrencyCall__Inputs {
  _call: WhitelistCurrencyCall;

  constructor(call: WhitelistCurrencyCall) {
    this._call = call;
  }

  get currency(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get toWhitelist(): boolean {
    return this._call.inputValues[1].value.toBoolean();
  }
}

export class WhitelistCurrencyCall__Outputs {
  _call: WhitelistCurrencyCall;

  constructor(call: WhitelistCurrencyCall) {
    this._call = call;
  }
}

export class WhitelistHubCreatorCall extends ethereum.Call {
  get inputs(): WhitelistHubCreatorCall__Inputs {
    return new WhitelistHubCreatorCall__Inputs(this);
  }

  get outputs(): WhitelistHubCreatorCall__Outputs {
    return new WhitelistHubCreatorCall__Outputs(this);
  }
}

export class WhitelistHubCreatorCall__Inputs {
  _call: WhitelistHubCreatorCall;

  constructor(call: WhitelistHubCreatorCall) {
    this._call = call;
  }

  get soulBoundTokenId(): BigInt {
    return this._call.inputValues[0].value.toBigInt();
  }

  get whitelist(): boolean {
    return this._call.inputValues[1].value.toBoolean();
  }
}

export class WhitelistHubCreatorCall__Outputs {
  _call: WhitelistHubCreatorCall;

  constructor(call: WhitelistHubCreatorCall) {
    this._call = call;
  }
}

export class WhitelistProfileCreatorCall extends ethereum.Call {
  get inputs(): WhitelistProfileCreatorCall__Inputs {
    return new WhitelistProfileCreatorCall__Inputs(this);
  }

  get outputs(): WhitelistProfileCreatorCall__Outputs {
    return new WhitelistProfileCreatorCall__Outputs(this);
  }
}

export class WhitelistProfileCreatorCall__Inputs {
  _call: WhitelistProfileCreatorCall;

  constructor(call: WhitelistProfileCreatorCall) {
    this._call = call;
  }

  get profileCreator(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get whitelist(): boolean {
    return this._call.inputValues[1].value.toBoolean();
  }
}

export class WhitelistProfileCreatorCall__Outputs {
  _call: WhitelistProfileCreatorCall;

  constructor(call: WhitelistProfileCreatorCall) {
    this._call = call;
  }
}

export class WhitelistPublishModuleCall extends ethereum.Call {
  get inputs(): WhitelistPublishModuleCall__Inputs {
    return new WhitelistPublishModuleCall__Inputs(this);
  }

  get outputs(): WhitelistPublishModuleCall__Outputs {
    return new WhitelistPublishModuleCall__Outputs(this);
  }
}

export class WhitelistPublishModuleCall__Inputs {
  _call: WhitelistPublishModuleCall;

  constructor(call: WhitelistPublishModuleCall) {
    this._call = call;
  }

  get publishModule(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get whitelist(): boolean {
    return this._call.inputValues[1].value.toBoolean();
  }
}

export class WhitelistPublishModuleCall__Outputs {
  _call: WhitelistPublishModuleCall;

  constructor(call: WhitelistPublishModuleCall) {
    this._call = call;
  }
}

export class WhitelistTemplateCall extends ethereum.Call {
  get inputs(): WhitelistTemplateCall__Inputs {
    return new WhitelistTemplateCall__Inputs(this);
  }

  get outputs(): WhitelistTemplateCall__Outputs {
    return new WhitelistTemplateCall__Outputs(this);
  }
}

export class WhitelistTemplateCall__Inputs {
  _call: WhitelistTemplateCall;

  constructor(call: WhitelistTemplateCall) {
    this._call = call;
  }

  get template(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get whitelist(): boolean {
    return this._call.inputValues[1].value.toBoolean();
  }
}

export class WhitelistTemplateCall__Outputs {
  _call: WhitelistTemplateCall;

  constructor(call: WhitelistTemplateCall) {
    this._call = call;
  }
}
