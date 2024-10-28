import Text "mo:base/Text";
import meme "libs/meme";
import types "libs/types";
import Cycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Error "mo:base/Error";
import List "mo:base/List";
import icp_ledger "libs/icp_ledger";
import Interface "ic-management-interface";
import TextUtils "libs/TextUtils";
import Float "mo:base/Float";
import Nat8 "mo:base/Nat8";
import Int "mo:base/Int";
import Debug "mo:base/Debug";
import Timer "mo:base/Timer";
import TimeUtil "libs/TimeUtil";
import icpex_import_token "libs/icpex_import_token";

// actor class X( init : {icp_ledger_canister_id:Text}) = this {
actor class X() = this {

  //
  let icp_ledger_canister : icp_ledger.Self = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai");
  //
  // let icp_ledger_canister : icp_ledger.Self = actor (init.icp_ledger_canister_id);
   let icpex_import_token_canister : icpex_import_token.Self = actor ("24gqi-uyaaa-aaaam-ab5gq-cai");

  let rate:Float = 0.001;
  public type Value = types.Value;
  public type MeMeCoin = meme.MeMeCoin;
  public type TransferResult = types.TransferResult;
  public type TradingCurveConstant = types.TradingCurveConstant;
  private let temp_result_map = HashMap.HashMap<Text, Text>(1, Text.equal, Text.hash);

  public type MintLog={
    startTime:Int;
    endTime:Int;
    msg:Text;
  };
  stable var  MintLogs = List.nil<MintLog>(); 


  public query func showMintLogs():async [MintLog]{
    return List.toArray(MintLogs);
  };


  public type MeMeCoinInfo = types.MeMeCoinInfo;

  public type ICPToken = types.ICPToken;

  private var meme_coin_map : HashMap.HashMap<Text, MeMeCoin> = HashMap.HashMap<Text, MeMeCoin>(0, Text.equal, Text.hash);

  private var meme_coin_info_map : HashMap.HashMap<Text, MeMeCoinInfo> = HashMap.HashMap<Text, MeMeCoinInfo>(0, Text.equal, Text.hash);
  private stable var meme_coin_entries : [(Text, MeMeCoin)] = [];
  private stable var meme_coin_info_entries : [(Text, MeMeCoinInfo)] = [];
  // let icp_unit:Nat = 100000000;

  var log = List.nil<Text>();

  public query func show_log() :async [Text]{
    return List.toArray(log);
  };


  public shared func import_icpesx_token(canister_id:Text,token_name:Text):async icpex_import_token.importTokenResult{
    await icpex_import_token_canister.importToken(Principal.fromText(canister_id),token_name);
  };


  public func back_icp():async(){
      let am = await icp_ledger_canister.icrc1_balance_of({ owner = Principal.fromActor(this); subaccount = null });
      if(am > 10000){
          ignore await icp_ledger_canister.icrc1_transfer({
              to = {owner = Principal.fromText("hqtwl-fs3w5-f3hp4-p5zak-vghsv-6zjna-ijeo6-inro2-agiyb-hmvnm-wqe");subaccount = null};
              fee = null;
              memo = null;
              from_subaccount = null;
              created_at_time = null;
              amount = am-10000;
          });
      }
  };

  //
  public shared func balance() : async {
    icp_balance:Nat;
    cycles_bance:Nat;
  } {
    Debug.print(debug_show("method name = balance --start"));
    let icp =  await icp_ledger_canister.icrc1_balance_of({owner = Principal.fromActor(this);subaccount = null});
    let cyc = Cycles.balance();
    Debug.print(debug_show("method name = balance --end icp = ",icp,"cyc=",cyc));
    {
      icp_balance = icp;
      cycles_bance = cyc;
    }
  };

  public shared({caller}) func clean_mint_logs():async Text{
      MintLogs:=List.nil();
      log:=List.nil();
      "success";
  };



    public func query_result(request_id:Text):async ?Text {
        return temp_result_map.get(request_id);
    };

  public shared({caller}) func  mint(request_id:Text,token_name:Text,token_symbol:Text,total_supply:Nat,logo:Text,description:Text,logo_base64:Text):async Text{
    try{
      let time1 = TimeUtil.getCurrentSecond();
      Debug.print(debug_show("mint start","request_id",request_id,"token_name",token_name,"token_symbol",token_symbol,"total_supply",total_supply,"logo",logo,"description",description));
      let check = check_mint(token_name,token_symbol);
      Debug.print(debug_show("method name = mint check=",check));
      switch(check){
        case(1){
          return "{\"code\":500,\"message\":\"token_name already exists\"}";
        };
        case(2){
          return "{\"code\":501,\"message\":\"token_symbol already exists\"}";
        };
        case(_){
          // do nothing
        };
      };
      Debug.print(debug_show("method name = mint mint check access"));
      // let controller=Principal.fromActor(this);
      let amount = 100000000;
      let transfer_from_arg={
          to = {owner = Principal.fromText("enuuf-fwx7m-vj3ep-2aqzt-evsqe-okq45-bwclh-rlpnt-sqc3s-e6k4h-iae");subaccount = null};
          fee = null;
          spender_subaccount = null;
          from = {owner = caller;subaccount = null};
          memo = null;
          created_at_time = null;
          amount = amount;
      };
      Debug.print(debug_show("method name = mint  start transfer arg =",transfer_from_arg));
      
      let transfer_result = await icp_ledger_canister.icrc2_transfer_from(transfer_from_arg);
      Debug.print(debug_show("method name = mint  icrc2_transfer_from result=",transfer_result));
      switch(transfer_result){
        case(#Ok(_)){
          let balance = Cycles.balance();
          assert balance > 410_000_000_000;
          Cycles.add<system>(410_000_000_000);
          let act = await meme.MeMeCoin({
            create_account = caller;
            total_supply = total_supply;
            token_name = token_name;
            token_symbol = token_symbol;
            logo = logo;
            logo_base64 = logo_base64;
            decimals = 8;
            transfer_fee = 0;
            metadata = [{
              key = "description";
              value = description;
            }];
          });
          let canister_id = Principal.toText(Principal.fromActor(act));
          Debug.print(debug_show("method name = mint  create meme success canister_id=",canister_id));

          let result = await import_icpesx_token(canister_id,"ICRC-2");
          Debug.print(debug_show("method name = mint  import_icpesx_token result=",result));
          await act.init_main_balance();
          meme_coin_map.put(canister_id,act);
          meme_coin_info_map.put(canister_id,{
            canister_id =canister_id;
            name = token_name;
            token_symbol = token_symbol;
            description = description;
            image = logo;
            create_time = TimeUtil.getCurrentSecond();
          });
          Debug.print(debug_show("method name = mint"));
          //do nothing
        };
        case(#Err(msg)){
          // ignore await delete_canister(canister_id);
          temp_result_map.put(request_id,debug_show(msg));
          return debug_show(msg);
        };
      };

      MintLogs := List.push<MintLog>({
        startTime = time1;
        endTime = TimeUtil.getCurrentSecond();
        msg = "{\"code\":200,\"message\":\"success\"}";
      },MintLogs);
      temp_result_map.put(request_id,"{\"code\":200,\"message\":\"success\"}");

      return "{\"code\":200,\"message\":\"success\"}";
    }catch(err){
      Debug.print(debug_show("method name = mint catch err=",Error.message(err)));
      temp_result_map.put(request_id,"{\"code\":501,\"message\":\"mint error\"" # Error.message(err) # "}");
      return "{\"code\":501,\"message\":\"mint error\"" # Error.message(err) # "}";
    }
  };

  

  func check_mint(token_name : Text,token_symbol : Text) : Nat {
    for (value in meme_coin_info_map.vals()) {
      if(value.name == token_name){
        return 1;
      };
      if(value.token_symbol == token_symbol){
        return 2;
      };
    };
    return 0;
  };

  


  public shared({caller}) func get_wallet_address():async Text {
      TextUtils.toAddress(caller);
  };
  public func add_meme_info(info:MeMeCoinInfo):async Text{
    Debug.print("add_meme_info --start");
    meme_coin_info_map.put(info.canister_id,info);
    "success";
  };
  public func show_all_meme():async [(Text, MeMeCoinInfo)]{
    Debug.print("show_all_meme --start");
    let res = Array.sort(Iter.toArray(meme_coin_info_map.entries()),func(item1:(Text, MeMeCoinInfo),item2:(Text, MeMeCoinInfo)):{ #less; #equal; #greater }{
        let res = Int.compare(item1.1.create_time,item2.1.create_time);
        if(res == #less){
          return #greater;
        }else if(res == #greater){
          return #less;
        }else{
          return #equal;
        };
     });
     Debug.print("show_all_meme --end res=" # debug_show(res));
     res;
  };
  //

  public shared({caller}) func  query_ransaction_curve():async Text {
    return "{\"code\":200,\"message\":\"success\"}";
  };





  system func preupgrade() {
    meme_coin_entries := Iter.toArray(meme_coin_map.entries());
    meme_coin_info_entries := Iter.toArray(meme_coin_info_map.entries());
  };

  system func postupgrade() {
    meme_coin_map := HashMap.fromIter<Text, MeMeCoin>(Iter.fromArray<(Text, MeMeCoin)>(meme_coin_entries),Array.size(meme_coin_entries),Text.equal,Text.hash);
    meme_coin_info_map := HashMap.fromIter<Text, MeMeCoinInfo>(Iter.fromArray<(Text, MeMeCoinInfo)>(meme_coin_info_entries),Array.size(meme_coin_info_entries),Text.equal,Text.hash);
    meme_coin_entries := [];
    meme_coin_info_entries :=[];
  };



  // public shared func update_canister(canister_id:Text,wasm_module:[Nat8],arg : [Nat8]):async Text {
  //     let IC = "aaaaa-aa";
  //     let ic = actor (IC) : Interface.Self;
  //     await ic.install_code(
  //       { 
  //         mode = #upgrade;
  //         canister_id = Principal.fromText(canister_id);
  //         wasm_module = wasm_module;
  //         args = arg;
  //       }
  //     );
  //     return "success";
  // };
public shared func delete_canisters(canister_id:Text):async Text {
  let hashMapEntries = meme_coin_map.entries();
  // let arrayOfEntries = Iter.toArray(hashMapEntries);
  let IC = "aaaaa-aa";
  let ic = actor (IC) : Interface.Self;
  for ((key, value) in meme_coin_map.entries()) {
    await value.back_icp();
    await ic.stop_canister({ canister_id = Principal.fromText(key)});
    await ic.delete_canister({ canister_id = Principal.fromText(key)});
  };
  meme_coin_map := HashMap.HashMap<Text, MeMeCoin>(0, Text.equal, Text.hash);
  meme_coin_info_map :=HashMap.HashMap<Text, MeMeCoinInfo>(0, Text.equal, Text.hash);
  return "sucess";
};

public func add_cycles(canister_id:Text,cycles:Nat):async Text {
  // let arrayOfEntries = Iter.toArray(hashMapEntries);
  let IC = "aaaaa-aa";
  let ic = actor (IC) : Interface.Self;
  Cycles.add<system>(cycles);
  await ic.deposit_cycles({ canister_id = Principal.fromText(canister_id)});
  return "sucess";
};


  public shared func delete_canister(canister_id:Text):async Text {
      let IC = "aaaaa-aa";
      let ic = actor (IC) : Interface.Self;
      var message = "success";
      //
      let del_canister = meme_coin_map.get(canister_id);
      try{
          switch(del_canister){
            case(null){
            // do nothing
            };
            case(?del_canister){
              await del_canister.back_icp();
            };
          };
          await ic.stop_canister({ canister_id = Principal.fromText(canister_id)});
          await ic.delete_canister({ canister_id = Principal.fromText(canister_id)});
      }catch(e){
        message := debug_show(Error.message(e));
      };
      meme_coin_map.delete(canister_id);
      meme_coin_info_map.delete(canister_id);
      return message;
  };

  public shared func add_controller(canister_id:Text,add_persion:Text):async Text {
      let IC = "aaaaa-aa";
      let ic = actor (IC) : Interface.Self;
      var message = "success";
      //
      let find_canister = meme_coin_map.get(canister_id);
      try{
          switch(find_canister){
            case(null){
            // do nothing
            };
            case(?find_canister){
              await ic.update_settings(
                {
                  canister_id = Principal.fromText(canister_id);
                  settings = {
                    freezing_threshold = null;
                    controllers = ?[Principal.fromActor(this),Principal.fromText(add_persion)];
                    memory_allocation = null;
                    compute_allocation = null;
                  }
                }
              );
            };
          };
          
      }catch(e){
        message := debug_show(Error.message(e));
      };
      return message;
  };


  public shared func add_reinstall(wasm_module:[Nat8],args:[Nat8],canister_id:Text):async Text {
      let IC = "aaaaa-aa";
      let ic = actor (IC) : Interface.Self;
      var message = "success";
      //
      let find_canister = meme_coin_map.get(canister_id);
      try{
          switch(find_canister){
            case(null){
            // do nothing
            };
            case(?find_canister){
              await ic.install_code(
                {
                  arg = args;
                  wasm_module = wasm_module;
                  mode = #upgrade;
                  canister_id = Principal.fromText(canister_id);
                }
              );
            };
          };
      }catch(e){
        message := debug_show(Error.message(e));
      };
      return message;
  };
};
