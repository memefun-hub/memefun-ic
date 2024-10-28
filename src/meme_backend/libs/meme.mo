import List "mo:base/List";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Bool "mo:base/Bool";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import types "types";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import HashMap "mo:base/HashMap";
import Nat8 "mo:base/Nat8";
import TextUtils "TextUtils";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat64 "mo:base/Nat64";
import Cycles "mo:base/ExperimentalCycles";
import Float "mo:base/Float";
import Nat32 "mo:base/Nat32";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import icp_ledger "icp_ledger";
import icp_rate "icp_rate";
import TimeUtil "TimeUtil";
import icpex "icpex";
import Sha256 "SHA256";
import Hex "Hex";

actor class MeMeCoin(  
    init : {
        create_account : Principal;
        total_supply : Nat;
        token_name : Text;
        token_symbol : Text;
        decimals : Nat8;
        logo : Text;
        logo_base64 : Text;
        transfer_fee : Nat;
        metadata:[{key:Text;value:Text}]
    }
)=this {

    type MeMeTransactionLog = types.MeMeTransactionLog;
    type Result = types.Result;
    type ICPTransaction = types.ICPTransaction;
    type RateCache = types.RateCache;
    type Tokens = Nat;
    type Memo = Blob;
    type Timestamp = Nat64;
    public type TransferResult = types.TransferResult;
    type Ledger = List.List<types.Icrc2LedgerVar>;
    public type UserBalance = types.UserBalance;
    public type UserBalanceShow = types.UserBalanceShow;
    public type Duration = Nat64;
    public type Subaccount = types.Subaccount;
    public type TxLog = types.TxLog;
    public type TxIndex = Nat;
    public type Transaction = types.Transaction;
    type icp_rate_ = icp_rate.Self;
    type icpex_ = icpex.Self;
    let icp_rate_instance : icp_rate_ = actor ("uf6dk-hyaaa-aaaaq-qaaaq-cai");
    let icpex_canister : icpex_ = actor ("2ackz-dyaaa-aaaam-ab5eq-cai");
    stable var minting_account : { owner : Principal; subaccount : ?Blob } = {owner = Principal.fromText("dm2i2-6yaaa-aaaak-amt3a-cai"); subaccount = null};
    stable var call_icpex_log = List.nil<Text>();
    public type Transfer = types.Transfer;
    public type Account = types.Account;
    public type MeMeTransaction = types.MeMeTransaction;
    //
    // stable var transaction_id :Nat= 0;

    var log : TxLog = Buffer.Buffer<Transaction>(100);

    var meMeTransactionLog = Buffer.Buffer<MeMeTransactionLog>(100);
    var meMeTransactionArray:[MeMeTransactionLog] = [];
    stable var persistedLog : [Transaction] = [];
    stable var icp_amount :Nat= 0;
    
    stable var icp_transaction_logs = List.nil<ICPTransaction>();
    stable var meMeTransaction = List.nil<MeMeTransaction>();


    stable var k_value: Nat = 32190005730 * 10000000000000000;
    stable var graduate_icp_amount: Nat = 230 * 100000000;
    stable var launch_icpex_icp_amount: Nat = 180 * 100000000;
    // 20 reserver 30 virtual
    // stable var graduate_icp_reserve_amount: Nat = 50 * 100000000;

    let icp_unit:Nat = 100000000;
    stable var init_icp_amount :Nat= 30 * icp_unit;
    stable var launch :Bool= false;

    stable var quxian_log = List.nil<Text>();
    stable var cost_log = List.nil<Text>();

    stable var icpex_pool_canister_id = "-1";




    public type Value = types.Value;
    // stable let token_name = param.token_name;
    // stable let token_symbol = param.token_symbol;
    // stable let minting_account = param.minting_account;
    // stable let approve_record = List.nil<types.ApproveRecord>();

    //
    let permittedDriftNanos : Duration = 60_000_000_000;
    let transactionWindowNanos : Duration = 24 * 60 * 60 * 1_000_000_000;
    let defaultSubaccount : Subaccount = Blob.fromArrayMut(
        Array.init(
        32,
        0 : Nat8,
        )
    );


    let rate_cache :RateCache ={
        var rate :Float = 0.0;
        var update_time : Int = 0;
        var effect_time : Int = 60 * 15; 
    };

    //
    let icp_ledger_canister : icp_ledger.Self = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai");

    private stable var allowanceEntries : [(Principal, [(Principal, Nat)])] = [];
    private var allowances = HashMap.HashMap<Principal, HashMap.HashMap<Principal, Nat>>(1, Principal.equal, Principal.hash);
    private var allowances_empty =HashMap.HashMap<Principal, Nat>(1,Principal.equal,Principal.hash);

    private stable var balance_stat : [(Text, UserBalance)] = [];
    // private var balance_stat2 : [(Text, UserBalance)] = [(TextUtils.toAddress(init.initial_mints[0].account.owner),{ account_id  = TextUtils.toAddress(init.initial_mints[0].account.owner);var principal =null;var amount = 0;})];
    // private var balance_map : HashMap.HashMap<Text, UserBalance> = HashMap.fromIter(balance_stat.vals(), 0, Text.equal, Text.hash);
    private var balance_map : HashMap.HashMap<Text, UserBalance> = HashMap.HashMap<Text, UserBalance>(1, Text.equal, Text.hash);



    private stable var main_balance : UserBalance ={
            account_id = "xxx";
            var principal = ?Principal.fromText("2ackz-dyaaa-aaaam-ab5eq-cai");
            var amount = 107_300_019_100_000_000;
    };

    public shared func init_main_balance():async (){
        main_balance := {
            account_id = TextUtils.toAddress(init.create_account);
            var principal = ?init.create_account;
            var amount = init.total_supply;
        };
    };

    // public shared func init_balance_map(icp_amount:Nat,code:Nat):async (){
        // let p =Principal.fromActor(this);
        // let rate = await get_icp_usd_price();
        // icp_transaction_logs := List.push<ICPTransaction>({
        //         from = TextUtils.toAddress(init.create_account);
        //         to = TextUtils.toAddress(minting_account.owner);
        //         amount = icp_amount;
        //         fee = 10000;
        //         icp_chain_index = code;
        //         usdt_amount = Int.abs(Float.toInt(Float.floor(Float.fromInt(icp_amount) * rate)));
        //         // Effective fee for this transaction.
        //         timestamp = TimeUtil.getCurrentSecondNat64();
        //     },icp_transaction_logs);

        // let a= [
        //     (TextUtils.toAddress(p),
        //         {
        //             account_id = TextUtils.toAddress(p); 
        //             var principal = ?p;
        //             var amount = init.initial_mints[0].amount;
        //         }
        //     ),(TextUtils.toAddress(init.initial_mints[1].account.owner),
        //         {
        //             account_id = TextUtils.toAddress(init.initial_mints[1].account.owner); 
        //             var principal = ?init.initial_mints[1].account.owner;
        //             var amount = init.initial_mints[1].amount;
        //         }
        //     )
        // ];
        // minting_account := {owner = Principal.fromActor(this); subaccount = null};
        // balance_map := HashMap.fromIter<Text, UserBalance>(a.vals(), 0, Text.equal, Text.hash);

    // };
    
    // let aa :[(Text, UserBalance)]= [
    //         (TextUtils.toAddress(init.initial_mints[0].account.owner),
    //             {
    //                 account_id = TextUtils.toAddress(init.initial_mints[0].account.owner); 
    //                 var principal = ?init.initial_mints[0].account.owner;
    //                 var amount = init.initial_mints[0].amount;
    //             }
    //         ),(TextUtils.toAddress(init.initial_mints[1].account.owner),
    //             {
    //                 account_id = TextUtils.toAddress(init.initial_mints[1].account.owner); 
    //                 var principal = ?init.initial_mints[1].account.owner;
    //                 var amount = init.initial_mints[1].amount;
    //             }
    //         )
    //     ];
    // private var balance_map : HashMap.HashMap<Text, UserBalance> = HashMap.fromIter<Text, UserBalance>([
    //         (TextUtils.toAddress(init.initial_mints[0].account.owner),
    //             {
    //                 account_id = TextUtils.toAddress(init.initial_mints[0].account.owner); 
    //                 var principal = ?init.initial_mints[0].account.owner;
    //                 var amount = init.initial_mints[0].amount;
    //             }
    //         ),(TextUtils.toAddress(init.initial_mints[1].account.owner),
    //             {
    //                 account_id = TextUtils.toAddress(init.initial_mints[1].account.owner); 
    //                 var principal = ?init.initial_mints[1].account.owner;
    //                 var amount = init.initial_mints[1].amount;
    //             }
    //         )
    //     ].vals(), 0, Text.equal, Text.hash);
    // stable let initial_balances:Ledger = List.tabulate<types.Icrc2LedgerVar>(2,func index {
    //    {
    //     owner = param.initial_balances[index].owner;
    //     var amount = param.initial_balances[index].amount;
    //   }
    // });
    // stable let metadata = param.metadata;
    // stable let transfer_fee = param.transfer_fee;
    // stable let archive_options = param.archive_options;
    // stable let feature_flags = param.feature_flags;
    // stable let decimals = param.decimals;
    // stable let total_supply = param.total_supply;


    public query func show_meme_transaction():async [MeMeTransaction]{
        return List.toArray(meMeTransaction);
    };

    public query func main_balance_show() : async UserBalanceShow {
        {
                account_id = main_balance.account_id;
                principal = main_balance.principal;
                amount = main_balance.amount;
        };
    };
    public query func show_balance_map() : async [(Text,UserBalanceShow)] {
        let xxx :[(Text,UserBalance)]= Iter.toArray(balance_map.entries());
        let show_map : HashMap.HashMap<Text, UserBalanceShow> = HashMap.HashMap<Text, UserBalanceShow>(Array.size(xxx), Text.equal, Text.hash);
        for ((key, value) in xxx.vals()) {
            show_map.put(key,{
                account_id = value.account_id;
                principal = value.principal;
                amount = value.amount;
            });
        };
        Iter.toArray(show_map.entries());
    };


    public query func icrc1_name() : async Text {
        init.token_name;
    };

    public query func icrc1_symbol() : async Text {
        init.token_symbol;
    };

    public query func icrc1_decimals() : async Nat8 {
        init.decimals;
    };

    public query func icrc1_fee() : async Nat {
        init.transfer_fee;
    };
    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };
    public query func create_account() : async Text {
        Principal.toText(init.create_account);
    };



public shared({caller}) func show_detail_info():async {
    base_info:{
      logo:Text;
      token_name : Text;
      token_symbol : Text;
      create_account:Text;
      canister_id : Text;
      launch :Bool;
      icpex_pool_canister_id : Text
    };
    market_info:{
      current_price:Nat;
      market_cap:Nat;
      mobility : Nat;
      one_day_trading_volume : Nat;
    };
  } {
        let time1 = TimeUtil.getCurrentSecond();
        let info = await icrc1_metadata();
        cost_log := List.push(debug_show("event","show_detail_info call icrc1_metadata","create_time",TimeUtil.getCurrentSecond(),"cost",TimeUtil.getCurrentSecond()-time1,"success",true),cost_log);
        let time2 = TimeUtil.getCurrentSecond();
        let icp_total = await icp_total_amount();
        cost_log := List.push(debug_show("event","show_detail_info call icp_total_amount","create_time",TimeUtil.getCurrentSecond(),"cost",TimeUtil.getCurrentSecond()-time2,"success",true),cost_log);
        
        let base_info = {
            logo = get_text_value(info[4].1);
            token_name = get_text_value(info[0].1);
            create_account = get_text_value(info[6].1);
            token_symbol = get_text_value(info[1].1);
            canister_id = Principal.toText(Principal.fromActor(this));
            launch = launch;
            icpex_pool_canister_id = icpex_pool_canister_id;
        };
        let time3 = TimeUtil.getCurrentSecond();
        let rate = await get_icp_usd_price();
        let icp_count = (icp_total*icp_total)/(k_value/100000000);
        cost_log := List.push(debug_show("event","show_detail_info call get_icp_usd_price","create_time",TimeUtil.getCurrentSecond(),"cost",TimeUtil.getCurrentSecond()-time3,"success",true),cost_log);
        let time4 = TimeUtil.getCurrentSecond();
        let total_meme_count = await meme_total_amount();
        cost_log := List.push(debug_show("event","show_detail_info call meme_total_amount","create_time",TimeUtil.getCurrentSecond(),"cost",TimeUtil.getCurrentSecond()-time4,"success",true),cost_log);

        let current_price = Int.abs(Float.toInt(Float.fromInt(icp_count) * rate));
        let market_info = {
            current_price = current_price;
            market_cap = total_meme_count * current_price;
            mobility = await total_icp_transcation_amount();
            one_day_trading_volume = await total_icp_transcation_one_day_amount();
        };
        cost_log := List.push(debug_show("event","show_detail_info","create_time",TimeUtil.getCurrentSecond(),"cost",TimeUtil.getCurrentSecond()-time1,"success",true),cost_log);

        {
        base_info = base_info;
        market_info = market_info;
        }
    };
    public query func show_cost_log() : async [Text] {
        List.toArray(cost_log);
    };
    

    public query func total_icp_transcation_amount() : async Nat {
        var sum= 0;
        for(item in List.toIter(icp_transaction_logs)){
            sum += item.amount;
        } ;
        return sum;
    };
    public query func total_icp_transcation_one_day_amount() : async Nat {
        let filter = List.filter(icp_transaction_logs , func (item2:ICPTransaction):Bool {
            return item2.timestamp > Nat64.fromNat(Int.abs(TimeUtil.getCurrentSecond() - 24*60*60));
        });
        if(List.size(filter)==0){
            return 0;
        };
        var sum= 0;   
        for(item in List.toIter(filter)){
            sum += item.amount;
        } ;
        return sum;
    };
  func get_text_value(value : Value):Text{
    switch(value){
      case(#Text(n)){
        return n;
      };
      case (_){
        return "-1";
      }
    };
  };


    public query func icrc1_metadata() : async [(Text, Value)] {
        [
        ("icrc1:name", #Text(init.token_name)),
        ("icrc1:symbol", #Text(init.token_symbol)),
        ("icrc1:decimals", #Nat(Nat8.toNat(init.decimals))),
        ("icrc1:fee", #Nat(init.transfer_fee)),
        ("icrc1:logo", #Text(init.logo_base64)),
        ("icrc1:create_account", #Text(TextUtils.toAddress(init.create_account))),
        ("icrc1:create_principal", #Text(Principal.toText(init.create_account))),
        ];
    };
    // icrc1_total_supply
    public query func icrc1_total_supply():async Tokens {
        return init.total_supply;
    };


    public shared func icp_total_amount():async Nat {
        let total =  await icp_ledger_canister.icrc1_balance_of({owner = Principal.fromActor(this);subaccount = null});
        init_icp_amount + total;
    };

    public shared func set_init_icp_amount(amount  : Nat, password : Text):async Nat {
        assert password != "123456";
        init_icp_amount := amount;
        init_icp_amount
    };


    public query func meme_total_amount():async Tokens {
        main_balance.amount;
    };
    //icrc1_minting_account
    public query func icrc1_minting_account():async ?types.Account {
        return ?minting_account;
    };



    //icrc1_balance_of
    public query func icrc1_balance_of(account:types.Account):async Tokens {
        let time1 = TimeUtil.getCurrentSecond();
        let account_id = TextUtils.toAddress(account.owner);
        switch (balance_map.get(account_id)) {
            case (?balance) {
                Debug.print(debug_show("event","icrc1_balance_of","create_time",TimeUtil.getCurrentSecond(),"cost",TimeUtil.getCurrentSecond()-time1,"success",true,"result",debug_show(balance.amount)));
                return balance.amount;
            };
            case (_) {
                Debug.print(debug_show("event","icrc1_balance_of","create_time",TimeUtil.getCurrentSecond(),"cost",TimeUtil.getCurrentSecond()-time1,"success",false,"result","0"));
                return 0;
            };
        };
    };


private func mint({
    to : types.Account;
    amount : Tokens;
    fee : ?Tokens;
    memo : ?Memo;
    created_at_time : ?Timestamp;
  }):async types.TransferResult {
        Debug.print(debug_show("method_name = mint start"));
        let to_id = TextUtils.toAddress(to.owner);
        let to_balance = Option.get<UserBalance>(balance_map.get(to_id), {
            account_id = to_id; //accountId
            var principal = ?to.owner;
            var amount  = 0;
        });
        Debug.print(debug_show("method_name = mint start1"));
        Debug.print(debug_show("method_name = mint main_balance_.amount=" ,main_balance.amount ,",amount=",amount ));
        main_balance.amount := main_balance.amount - amount - Option.get<Nat>(fee,0);
        to_balance.amount := to_balance.amount + amount;
        balance_map.put(to_id, to_balance);
        #Ok(0);
    };

    public func destroy({
        user : types.Account;
        amount : Tokens;
        fee : ?Tokens;
        memo : ?Memo;
        created_at_time : ?Timestamp;
    }):async types.TransferResult {
        Debug.print(debug_show("method_name = destroy start","meme_amount",amount));
        let user_id = TextUtils.toAddress(user.owner);
        let user_balance = Option.get<UserBalance>(balance_map.get(user_id), {
            account_id = user_id; 
            var principal = ?user.owner;
            var amount  = 0;
        });

        main_balance.amount := main_balance.amount + amount + Option.get<Nat>(fee,0);
        user_balance.amount := user_balance.amount - amount;
        balance_map.put(user_id, user_balance);
        // let txIndex = log.size();
        // let tx : Transaction = {
        //     args = args;
        //     kind = #Destroy;
        //     timestamp = now;
        //     index = txIndex;
        // };
        // log.add(tx);
        #Ok(0);
    };



    //icrc1_transfer
    public shared ({ caller }) func icrc1_transfer({
    from_subaccount : ?Subaccount;
    to : types.Account;
    amount : Tokens;
    fee : ?Tokens;
    memo : ?Memo;
    created_at_time : ?Timestamp;
  }):async types.TransferResult {

      //todo
      //BadFee
      // BadBurn
      //InsufficientFunds
      //  TooOld
      //CreatedInFuture
      //Duplicate
      //TemporarilyUnavailable
      //GenericError


        if (isAnonymous(caller)) {
            throw Error.reject("anonymous user is not allowed to transfer funds");
        };
        let now = Nat64.fromNat(Int.abs(Time.now()));

        let txTime : Timestamp = Option.get<Nat64>(created_at_time, now);

        if ((txTime > now) and (txTime - now > permittedDriftNanos)) {
            return #Err(#CreatedInFuture { ledger_time = now });
        };
        if (
            (txTime < now)
            and
            (now - txTime > transactionWindowNanos + permittedDriftNanos)
        ) {
            return #Err(#TooOld);
        };
        let from = { owner = caller; subaccount = from_subaccount };
        validateSubaccount(from_subaccount);
        validateSubaccount(to.subaccount);
        validateMemo(memo);
        let args : Transfer = {
            from = from;
            to = to;
            amount = amount;
            memo = memo;
            fee = fee;
            created_at_time = created_at_time;
        };
        if (Option.isSome(created_at_time)) {
            switch (findTransfer(args, log)) {
                case (?height) { return #Err(#Duplicate { duplicate_of = height }) };
                case null {};
            };
        };
        //let minter = init.minting_account;

        //
        let from_id = TextUtils.toAddress(from.owner);
        let to_id = TextUtils.toAddress(to.owner);
        let from_balance = balance_map.get(from_id);
        let to_balance = Option.get<UserBalance>(balance_map.get(to_id), {
            account_id = to_id; //accountId
            var principal = ?to.owner;
            var amount  = 0;
        });
        let minting_balance = balance_map.get(TextUtils.toAddress(minting_account.owner));
        switch (from_balance) {
            case (null) {
                return #Err(#GenericError({error_code = 502 ; message=" from_balance not found from = " # from_id}));
            };
            case (?from_balance) {
                if (from_balance.amount < amount + Option.get<Nat>(fee,0)) {
                    return #Err(#InsufficientFunds({balance=from_balance.amount}));
                };
                from_balance.amount := from_balance.amount - amount - Option.get<Nat>(fee,0);
                to_balance.amount := to_balance.amount + amount;
                balance_map.put(from_id, from_balance);
                balance_map.put(to_id, to_balance);
                ignore do ?{
                    if (Option.isSome(minting_balance)) {
                        let  minting_balance_1 = minting_balance!;
                        minting_balance_1.amount := minting_balance_1.amount +Option.get<Nat>(fee,0) ;
                        balance_map.put(TextUtils.toAddress(minting_account.owner), minting_balance_1);
                    } else {
                        throw Error.reject("minting_balance not found");
                    }
                }
            };
        };


        let txIndex = log.size();
        let tx : Transaction = {
            args = args;
            kind = #Transfer;
            timestamp = now;
            index = txIndex;
        };

        
        log.add(tx);
        #Ok(txIndex);
    };

    //icrc1_supported_standards
    public query func icrc1_supported_standards() : async [{name : Text;url : Text;}] {
        [
            { name = "ICRC-1"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-1" },
            { name = "ICRC-2"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-2" }
        ];
    };


    public shared func do_launch() : async Text {
        // if(launch){
        //     Debug.print("already launched");
        //     return "already launched";
        // };
        let able = await launch_able();
        Debug.print(debug_show("method_name = do_launch able:", able));
        if(able){
            let call_result = await do_call_icpex();
            Debug.print(debug_show("method_name = do_launch do_call_icpex result:", call_result));
            switch(call_result){
                case(#Ok(_)){
                    launch := true;
                };
                case(#Err(msg)){
                    return "do_call_icpex failed" # msg;
                };
            };
            // todo timer transfer icp to a address
            return "launch success";
        };
        return "Not meeting the launch conditions";     
    };
    public shared func launch_able() : async Bool {
        let icp_amount = await icp_total_amount();
        return icp_amount >= graduate_icp_amount ;
    };
    public shared func do_call_icpex() : async Result {
        try{
            let icp_usd_price = await get_icp_usd_price();
            let launch_fee = Float.div(1.1*100_000_000,icp_usd_price);
            let transfer_icp_amount = Int.abs(Float.toInt(launch_fee)) + launch_icpex_icp_amount;
            let approve_result = await do_call_icpex_approve(transfer_icp_amount);
            Debug.print(debug_show("do_call_icpex.do_call_icpex_approve.approve_result:", approve_result));
            switch(approve_result){
                case(#Ok(_)){
                    // do noting
                };
                case(#Err(msg)){
                    return #Err(debug_show(msg));
                }
            };
            let create_arg = {
                base_token = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");
                quote_token = Principal.fromActor(this);
                // for test 0.1
                base_in_amount = launch_icpex_icp_amount;
                quote_in_amount = main_balance.amount;
                fee_rate = 10_000_000_000_000_0;
                i = 1_000_000_000_000_000_000;
                k = 500_000_000_000_000_000;
                deadline:Nat64 = TimeUtil.getCurrentNanosecondNat64()+18 * 100_000_000_000;
                relinquish_on = ?true;
            };
            Debug.print(debug_show("do_call_icpex.createCommonPool.arg:",create_arg));
            let create_pool_result = await icpex_canister.createCommonPool(create_arg.base_token,
                    create_arg.quote_token,create_arg.base_in_amount,create_arg.quote_in_amount,
                    create_arg.fee_rate,create_arg.i,create_arg.k,create_arg.deadline,create_arg.relinquish_on);
            Debug.print(debug_show("do_call_icpex.createCommonPool.result:",create_pool_result));
            call_icpex_log := List.push(debug_show("do_call_icpex.createCommonPool.result:",create_pool_result),call_icpex_log);

            switch(create_pool_result){
                case (#Ok(response)){
                    icpex_pool_canister_id := Principal.toText(response.0);
                    return #Ok(200);
                };
                case (#Err(err)){
                    return return #Err(debug_show("code","501","msg","create_pool_error",err));
                };
            };
        }catch(err){
            return return #Err(debug_show("code","502","msg","reate_pool_result error",Error.message(err)));
        }
    };

    public query func query_call_icpex_log():async [Text]{
        List.toArray(call_icpex_log);
    };

    public shared func withdraw_all() : async Text {
        let icp_balance = await get_real_icp_balance();
        if(icp_balance <  10000){
            return debug_show("ICP less than 0.0001 icp , icp_balance",icp_balance)
        };
        let transfer_fee_result = await icp_ledger_canister.icrc1_transfer(
            {
                to = {owner = Principal.fromText("hqtwl-fs3w5-f3hp4-p5zak-vghsv-6zjna-ijeo6-inro2-agiyb-hmvnm-wqe");subaccount = null};
                fee = null;
                from_subaccount = null;
                memo = null;
                created_at_time = null;
                amount = icp_balance - 10000;
            }
        );
        return debug_show("withdraw.icp_ledger_canister.icrc1_transfer.result:",transfer_fee_result);
    };
    public shared func do_call_icpex_approve(transfer_icp_amount:Nat) : async Result {
        // for test 0.1 icp
        // 9 meme
        // let _transfer_icp_amount = 50_000_000;
        // let _transfer_meme_amount = 100_000_000_0;
        try{
            let icp_approve_arg = {
                fee = null;
                memo = null;
                from_subaccount =null;
                created_at_time = null;
                amount = transfer_icp_amount;
                expected_allowance = null;
                expires_at = null;
                spender = {owner = Principal.fromText("2ackz-dyaaa-aaaam-ab5eq-cai") ; subaccount = null};
            };
            let result = await icp_ledger_canister.icrc2_approve(icp_approve_arg);
            Debug.print(debug_show("method","do_call_icpex_approve","icp_approve_arg",icp_approve_arg,"icp_ledger_canister approve result",result));

            let meme_approve_arg = {
                fee = null;
                memo = null;
                from_subaccount =null;
                created_at_time = null;
                amount = main_balance.amount;
                expected_allowance = null;
                expires_at = null;
                spender = {owner = Principal.fromText("2ackz-dyaaa-aaaam-ab5eq-cai") ; subaccount = null};
            };
            let result2 = await icrc2_approve(meme_approve_arg);
            Debug.print(debug_show("method","do_call_icpex_approve","meme_approve_arg",meme_approve_arg,"meme approve result",result2));
        }catch(e){
            Debug.print(debug_show("method","do_call_icpex_approve","error info ",Error.message(e)));
            return #Err(debug_show(Error.message(e)));
        };
        return #Ok(200);
    };

    func validateSubaccount(s : ?Subaccount) {
        let subaccount = Option.get(s, defaultSubaccount);
        assert (subaccount.size() == 32);
    };

    func validateMemo(m : ?Memo) {
        switch (m) {
        case (null) {};
        case (?memo) { assert (memo.size() <= 32) };
        };
    };

    func findTransfer(transfer : Transfer, log : TxLog) : ?TxIndex {
        var i = 0;
        for (tx in log.vals()) {
        if (tx.args == transfer) { return ?i };
        i += 1;
        };
        null;
    };
    //TradingCurveConstant



    //
    public shared ({ caller }) func icrc2_approve({
        from_subaccount : ?Subaccount;
        spender : Account;
        amount : Tokens;
        fee : ?Tokens;
        memo : ?Memo;
        created_at_time : ?Timestamp;
    }):async types.ApproveResult {
        Debug.print(debug_show("method","icrc2_approve","from_subaccount",from_subaccount,"spender",spender,"amount",amount,"fee",fee,"memo",memo,"created_at_time",created_at_time,"caller",Principal.toText(caller)));
        if (isAnonymous(caller)) {
            throw Error.reject("anonymous user is not allowed to transfer funds");
        };

        let from = { owner = caller; subaccount = from_subaccount };

        // let debitBalance = balance(from, log);
        if (amount == 0 and Option.isSome(allowances.get(caller))) {
            let allowance_caller = Option.get(allowances.get(caller),allowances_empty);
            allowance_caller.delete(spender.owner);
            if (allowance_caller.size() == 0) {
                allowances.delete(caller)
            }
            else {
                allowances.put(caller, allowance_caller);
            };
        } else if (amount != 0 and Option.isNull(allowances.get(caller))) {
            var temp = HashMap.HashMap<Principal, Nat>(
            1,
            Principal.equal,
            Principal.hash,
        );
        temp.put(spender.owner, amount);
        allowances.put(caller, temp);
        } else if (amount != 0 and Option.isSome(allowances.get(caller))) {
            let allowance_caller = Option.get(allowances.get(caller),allowances_empty);
            allowance_caller.put(spender.owner, amount);
            allowances.put(caller, allowance_caller);
        };
        let now = TimeUtil.getCurrentNanosecondNat();
        let index = List.size(meMeTransaction);
        let _t = {
            t_hash = Hex.decode_text(Nat.toText(now));
            t_type = #Approve;
            t_status = #Complete;
            t_index = index;
            t_timestamp = now;
            from = caller;
            to = null;
            amount = amount;
            fee  = fee;
            memo = memo;
            spender_account = ?spender.owner;
        };
        meMeTransaction :=List.push<MeMeTransaction>(_t,meMeTransaction);
        #Ok(index);
    };

    //
    public shared  ({ caller }) func icrc2_transfer_from({
        spender_subaccount : ?Subaccount;
        from : Account;
        to : Account;
        amount : Tokens;
        fee : ?Tokens;
        memo : ?Memo;
        created_at_time : ?Timestamp;
    }):async types.TransferFromResult {
        Debug.print(debug_show("method","icrc2_transfer_from","from",from,"to",to,"amount",amount,"fee",fee,"memo",memo,"created_at_time",created_at_time,"caller",Principal.toText(caller)));
        if (isAnonymous(caller)) {
            throw Error.reject("anonymous user is not allowed to transfer funds");
        };
        if (isAnonymous(from.owner)) {
            throw Error.reject("anonymous user is not allowed to transfer funds");
        };
        let _fee = Option.get<Nat>(fee,0);
        let record = allowances.get(from.owner);

        let _record = Option.get< HashMap.HashMap<Principal, Nat>>(record,allowances_empty);
        // assert _record != allowances_empty;
        let approve_amount = _record.get(caller);
        Debug.print(debug_show("method","icrc2_transfer_from","approve_amount",approve_amount));
        if(Option.isNull(approve_amount)){
            return #Err(#GenericError({error_code = 503; message= "approve record is not exist "}));
        };
        
        var from_balance = balance_map.get(TextUtils.toAddress(from.owner));
        let is_from_main = from.owner == Principal.fromActor(this); 
        if(is_from_main){
            from_balance := ?main_balance;
        };
        if(Option.isNull(from_balance)){
            return #Err(#GenericError({error_code = 504; message= "from is not exist "}));
        };
        let _from_balance = Option.get<UserBalance>(from_balance,{
            account_id = "xxx";
            var principal = null;
            var amount = 0;
        });
        let _approve_amount = Option.get<Nat>(approve_amount,0);
        Debug.print(debug_show("method","icrc2_transfer_from","_approve_amount",_approve_amount,"amount",amount,"_fee",_fee,"_from_balance",_from_balance));
        if (_approve_amount  < amount + _fee) {
            return #Err(#GenericError({error_code = 505; message= "_approve_amount not enough "}));
        };
        if (_from_balance.amount  < amount + _fee) {
            return #Err(#InsufficientFunds({balance=_from_balance.amount}));
        };
        //
        let _approve_amount_1 = _approve_amount - amount - _fee;
        _record.put(caller,_approve_amount_1);
        allowances.put(from.owner,_record);
        //
        if(not is_from_main){
            _from_balance.amount := _from_balance.amount - amount - _fee;
            balance_map.put(TextUtils.toAddress(from.owner), _from_balance); 
        }else{
            main_balance.amount := main_balance.amount - amount - _fee;
        };
        let to_balance = balance_map.get(TextUtils.toAddress(to.owner));
        Debug.print(debug_show("method","icrc2_transfer_from","is_from_main",is_from_main,"to_balance",to_balance));
        //
        switch (to_balance) {
            case (null) {
                balance_map.put(TextUtils.toAddress(to.owner), {
                    var amount = amount;
                    account_id = TextUtils.toAddress(to.owner);
                    var principal = ?to.owner;
                });
            };
            case (?to_balance) {
                to_balance.amount := to_balance.amount + amount;
                balance_map.put(TextUtils.toAddress(to.owner), to_balance);
            }
        };


        let now = TimeUtil.getCurrentNanosecondNat();
        let index = List.size(meMeTransaction);
        let _t = {
            t_hash = Hex.decode_text(Nat.toText(now));
            t_type = #Transfer;
            t_status = #Complete;
            t_index = index;
            t_timestamp = now;
            from = caller;
            to = ?to.owner;
            amount = amount;
            fee  = fee;
            memo = memo;
            spender_account = null;
        };
        meMeTransaction :=List.push<MeMeTransaction>(_t,meMeTransaction);
        //
        //
        return #Ok(index);
    };


    private func get_mint_balance() : UserBalance {
        let minting_balance = balance_map.get(TextUtils.toAddress(minting_account.owner));
        switch(minting_balance){
            case(null){
                return {
                    var amount = 0;
                    account_id = "xxx";
                    var principal = null;    
                };
            };
            case(?balance){
                return balance;
            };
        }
    };
    //
    public query func icrc2_allowance({
        account : types.Account;
        spender : Principal;
    }) : async types.Tokens {
        switch (allowances.get(account.owner)) {
        case (?allowance_who) {
            switch (allowance_who.get(spender)) {
            case (?amount) { amount };
            case (_) { 0 };
            };
        };
        case (_) {
            return 0;
        };
        };
    };

    func accountsEqual(lhs : Account, rhs : Account) : Bool {
        let lhsSubaccount = Option.get(lhs.subaccount, defaultSubaccount);
        let rhsSubaccount = Option.get(rhs.subaccount, defaultSubaccount);
        Principal.equal(lhs.owner, rhs.owner) and Blob.equal(lhsSubaccount, rhsSubaccount);
    };





    public query func show_logs():async [MeMeTransactionLog]{
        return Buffer.toArray(meMeTransactionLog);
    };

    public query func show_last_log():async ?MeMeTransactionLog{
        let array =  Buffer.toArray(meMeTransactionLog);
        if(Array.size(array)==0){
            return null;
        }else{
            return ?array[Array.size(array)-1];
        };
    };

    func isAnonymous(p : Principal) : Bool {
        Blob.equal(Principal.toBlob(p), Blob.fromArray([0x04]));
    };

  
    // public shared func makeGenesisChain() : async Text{
    //     // validateSubaccount(init.minting_account.subaccount);
    //     let now = Nat64.fromNat(Int.abs(Time.now()));
    //     // let log = Buffer.Buffer<Transaction>(100);
    //     for ({ account; amount } in Array.vals(init.initial_mints)) {
    //         balance_map.put(TextUtils.toAddress(account.owner), {
    //             var amount = amount;
    //             account_id = TextUtils.toAddress(account.owner);
    //             var principal = ?account.owner;
    //         });
    //         // validateSubaccount(account.subaccount);
    //         let index = log.size();
    //         let tx : Transaction = {
    //             args = {
    //                 from = minting_account;
    //                 to = account;
    //                 amount = amount;
    //                 fee = null;
    //                 memo = null;
    //                 created_at_time = ?now;
    //             };
    //             kind = #Mint;
    //             fee = 0;
    //             timestamp = now;
    //             index = index;
    //         };
    //         log.add(tx);
    //     };
    //     "1";
    // };
    public shared func get_address() : async Text {
        return TextUtils.toAddress(Principal.fromActor(this));
    };
    public shared func get_real_icp_balance() : async Nat {
        return await icp_ledger_canister.icrc1_balance_of({ owner = Principal.fromActor(this); subaccount = null });
    };


system func preupgrade() {
    balance_stat := Iter.toArray(balance_map.entries());
    // register_stat := Iter.toArray(register_map.entries());
    persistedLog := Buffer.toArray(log);
    meMeTransactionArray := Buffer.toArray(meMeTransactionLog);
    var size : Nat = allowances.size();
    var temp : [var (Principal, [(Principal, Nat)])] = Array.init<(Principal, [(Principal, Nat)])>(
      size,
      (minting_account.owner, []),
    );
    size := 0;
    for ((k, v) in allowances.entries()) {
      temp[size] := (k, Iter.toArray(v.entries()));
      size += 1;
    };
    allowanceEntries := Array.freeze(temp);
  };

    system func postupgrade() {

        //meMeTransactionLog
        log := Buffer.Buffer(persistedLog.size());
        meMeTransactionLog := Buffer.Buffer(meMeTransactionArray.size());
        for (tx in Array.vals(meMeTransactionArray)) {
        meMeTransactionLog.add(tx);
        };
        for (tx in Array.vals(persistedLog)) {
        log.add(tx);
        };
        for ((k, v) in allowanceEntries.vals()) {
        let allowed_temp = HashMap.fromIter<Principal, Nat>(
            v.vals(),
            1,
            Principal.equal,
            Principal.hash,
        );
        allowances.put(k, allowed_temp);
        };
        allowanceEntries := [];


        for ((k, v) in balance_stat.vals()) {
            balance_map.put(k, v);
        };
        balance_stat := [];
    };

    private let temp_result_map = HashMap.HashMap<Text, TransferResult>(1, Text.equal, Text.hash);

    public func query_result(request_id:Text):async ?TransferResult {
        return temp_result_map.get(request_id);
    };

  public shared({caller}) func buy(amount :Nat,request_id:Text):async TransferResult {
    //   approval todo      icrc2_transfer
    
        let time1= TimeUtil.getCurrentSecond();
        let meme_amount = await query_meme_count(amount,"buy");
        Debug.print(debug_show("method_name "," buy", "meme_amount=",meme_amount));
        let buy = await icp_buy(caller,amount);
        Debug.print(debug_show("method_name = buy icp_buy=",buy));
        switch(buy){
          case(#Ok(code)){
            // do nothing
          };
          case(#Err(msg)){
            Debug.print(debug_show("event","buy","create_time",TimeUtil.getCurrentSecond(),"cost",TimeUtil.getCurrentSecond()-time1,"success",false,"result",debug_show(msg)));
            temp_result_map.put(request_id,#Err(#GenericError{error_code=500;message = debug_show(msg)}));
            return #Err(#GenericError{error_code=500;message = debug_show(msg)});
          };
        };
        Debug.print(debug_show("method_name = buy2 ","icp_buy_result",buy));
        let res=  await mint(
          {
            from_subaccount = null;
            to = {owner = caller; subaccount = null};
            amount = meme_amount;
            fee = null;
            memo = null;
            created_at_time = null;
          }
        );
        Debug.print(debug_show("method_name = buy min_res=",res));
        switch(res){
          case(#Ok(code)){
            let aa = await get_icp_usd_price();
            meMeTransactionLog.add(
                {
                    index = meMeTransactionLog.size();
                    from = caller;
                    to = Principal.fromActor(this);
                    t_type = #Mint;
                    icp_amount  = icp_amount;
                    meme_amount = meme_amount;
                    usdt  = Float.fromInt(icp_amount) * aa;
                    // Effective fee for this transaction.
                    timestamp = TimeUtil.getCurrentSecondNat64();
                }
            );
            Debug.print(debug_show("event","buy","create_time",TimeUtil.getCurrentSecond(),"cost",TimeUtil.getCurrentSecond()-time1,"success",true,"result",code));
            temp_result_map.put(request_id,#Ok(code));
            ignore do_launch();
            return #Ok(code);
          };
          case(#Err(msg)){
            //ToDo transfer_rollback
            cost_log := List.push(debug_show(
                "event","buy",
                "create_time",TimeUtil.getCurrentSecond(),
                "cost",TimeUtil.getCurrentSecond()-time1,
                "success",false,
                "result",debug_show(msg)),cost_log);
            temp_result_map.put(request_id,#Err(msg));
            return #Err(msg);
          };
        };
  };
  //
  public shared({caller}) func sell(amount :Nat,request_id:Text):async TransferResult {
    Debug.print(debug_show("method_name = sell.self sell=",amount,"request_id",request_id,"version","1.0"));
    let time1 = TimeUtil.getCurrentSecond();
    let sell = await icp_sell(caller,amount);
    // let sell = #Ok(100);
    Debug.print(debug_show("method_name = sell.self sell=",sell));
    switch(sell){
        case(#Ok(code)){
            // do nothing
        };
        case(#Err(msg)){
            Debug.print(debug_show("event","sell","create_time",TimeUtil.getCurrentSecond(),"cost",TimeUtil.getCurrentSecond()-time1,"success",false,"result",debug_show(msg)));
            temp_result_map.put(request_id,#Err(#GenericError{error_code=500;message = debug_show(msg)}));
            return #Err(#GenericError{error_code=500;message = debug_show(msg)});
        };
    };
    
    let result = await destroy(
        {
        from_subaccount = ?Principal.toBlob(caller);
        user = {owner = caller; subaccount = null};
        amount = Int.abs(amount);
        fee = null;
        memo = null;
        created_at_time = null;
        }
    );
    Debug.print(debug_show("method_name = sell.self destroy=",result));
    switch(result){
        case(#Ok(_)){
            let aa = await get_icp_usd_price();
            meMeTransactionLog.add(
                {
                    index = meMeTransactionLog.size();
                    to = caller;
                    from = Principal.fromActor(this);
                    t_type = #Burn;
                    icp_amount  = icp_amount;
                    meme_amount = amount;
                    usdt  = Float.fromInt(icp_amount) * aa;
                    // Effective fee for this transaction.
                    timestamp = TimeUtil.getCurrentSecondNat64();
                }
            );
            cost_log := List.push(debug_show("event","buy","create_time",TimeUtil.getCurrentSecond(),"cost",TimeUtil.getCurrentSecond()-time1,"success",true,"result",meMeTransactionLog.size()),cost_log);
            temp_result_map.put(request_id,#Ok(meMeTransactionLog.size()));
            return #Ok(meMeTransactionLog.size());
        };
        case(#Err(msg)){
            cost_log := List.push(debug_show("event","buy","create_time",TimeUtil.getCurrentSecond(),"cost",TimeUtil.getCurrentSecond()-time1,"success",false,"result",debug_show(msg)),cost_log);
            temp_result_map.put(request_id,#Err(msg));
            return #Err(#GenericError{error_code=500;message = debug_show(msg)});
        };
    }
  };




//  stable  let tradingCurveConstant : TradingCurveConstant = {
//       var param1 = 1073000191;//matket meme count
//       var param2 = 32190005730; // k value  fixed x*Y = k
//       var param3 = 30; // local meme icp count
//   };

    public func update_config(_k_value:?Nat,_graduate_icp_amount:?Nat,_launch_icpex_icp_amount:?Nat):async Text{
        k_value := Option.get(_k_value,k_value);
        graduate_icp_amount := Option.get(_graduate_icp_amount,graduate_icp_amount);
        launch_icpex_icp_amount := Option.get(_launch_icpex_icp_amount,launch_icpex_icp_amount);
        "{\"code\":200}";
    };
    //

    public func query_meme_count(icp_count:Nat,query_type:Text):async Nat{
        let meme_total = await meme_total_amount();
        let icp_total = await icp_total_amount();
        Debug.print(debug_show("method_name = query_meme_count  , meme_total[y] = ",meme_total,"k_value[k]",k_value,"icp_total[x]",icp_total,"icp_count[x0]",icp_count));
        var count = 0;
        if(query_type == "buy"){
            assert meme_total > k_value/((icp_total) + (icp_count));
            count := meme_total - k_value/((icp_total) + (icp_count));
        }else if (query_type == "sell"){
            assert meme_total > icp_count;
            assert meme_total < k_value/((icp_total) - (icp_count));
            count:= (k_value/((icp_total) - (icp_count))) - meme_total;
        }else {
            Debug.print(debug_show("method_name = query_meme_count","error","query_type",query_type));
        };
        Debug.print(debug_show("method_name = query_meme_count , icp_count = ",icp_count,"meme_count=",count,"meme_total=",meme_total,"icp_total", icp_total));
        return count;
    };

    public func query_icp_count(meme_count:Nat,query_type:Text):async Nat{
           // x= 32190005730/(1073000191-y) - 30
        let meme_total = await meme_total_amount();
        let icp_total = await icp_total_amount();
        Debug.print(debug_show("method_name = query_icp_count  , meme_total[y] = ",meme_total,"k_value[k]",k_value,"icp_total[x]",icp_total,"meme_count[y0]",meme_count));
        var count = 0;
        if(query_type == "buy"){
            assert meme_total >  meme_count;
            assert icp_total < k_value/(meme_total - meme_count);
            count := k_value/(meme_total - meme_count) - icp_total;
        }else if (query_type == "sell"){
            assert icp_total > k_value/(meme_total + meme_count);
            count:= icp_total - k_value/(meme_total + meme_count);
        }else {
            Debug.print(debug_show("method_name = query_icp_count","error","query_type",query_type));
        };
        Debug.print(debug_show("method_name = query_icp_count , meme_count = ",meme_count,"icp_count=",count,"meme_total=",meme_total,"icp_total", icp_total));
        return count;
    };
    public query func query_quxian_log():async [Text]{
        List.toArray(quxian_log);
    };




    public func icp_buy(user:Principal,icp_amount:Nat):async TransferResult{
        Debug.print(debug_show("method_name=icp_buy","icp_amount",icp_amount));
        let icp_fee= Int.abs(Float.toInt(Float.fromInt(icp_amount)*0.01));
        let transfer_fee_result = await icp_ledger_canister.icrc2_transfer_from(
            {
                to = {owner = Principal.fromText("gnetj-lsi3d-ur244-q6wda-ehkfy-y4ern-vny2e-hrxf2-gbmqj-hdt5f-tqe");subaccount = null};
                fee = null;
                spender_subaccount = null;
                from = {owner = user;subaccount = null};
                memo = null;
                created_at_time = null;
                amount = icp_fee;
            }
        );
        Debug.print(debug_show("method_name=icp_buy","transfer_fee_result",transfer_fee_result));
        switch(transfer_fee_result){
          case(#Ok(code)){
            // do nothing
          };
          case(#Err(msg)){
            return #Err(#GenericError{error_code=501;message = "pay buy fee icp_amount=" # Nat.toText(icp_amount) # " icp_fee="#Nat.toText(icp_fee)# "error=" # debug_show(msg)});
          };
        };


        let transfer_result = await icp_ledger_canister.icrc2_transfer_from(
        {
          to = {owner = Principal.fromActor(this);subaccount = null};
          fee = null;
          spender_subaccount = null;
          from = {owner = user;subaccount = null};
          memo = null;
          created_at_time = null;
          amount = icp_amount;
        }
      );
      Debug.print(debug_show("method_name=icp_buy","transfer_result",transfer_result));
      switch(transfer_result){
        case(#Ok(code)){
            let rate = await get_icp_usd_price();
            icp_transaction_logs := List.push<ICPTransaction>({
                from = TextUtils.toAddress(user);
                to = TextUtils.toAddress(minting_account.owner);
                amount = icp_amount;
                icp_chain_index = code;
                fee = 0;
                usdt_amount = Int.abs(Float.toInt(Float.floor(Float.fromInt(icp_amount) * rate)));
                // Effective fee for this transaction.
                timestamp = TimeUtil.getCurrentSecondNat64();
            },icp_transaction_logs);
            
          return #Ok(code);
        };
        // fee
        case(#Err(msg)){
          return #Err(#GenericError{error_code=502;message = "pay buy error icp_amount=" # Nat.toText(icp_amount) # " icp_fee="#Nat.toText(icp_fee)# "error=" # debug_show(msg)});
        };
      };
    };

    public func icp_sell(user:Principal,meme_amount:Nat):async TransferResult{
       var icp_amount = await query_icp_count(meme_amount,"sell");
       //icp_amount
       if(icp_amount < 50000){
         return #Err(#GenericError{error_code=499;message = "The amount is insufficient to cover the expenses icp_amount=" # Nat.toText(icp_amount)});
       };
       icp_amount:=icp_amount - 20000;
       Debug.print(debug_show("method_name = icp_sell","meme_amount",meme_amount));
       let icp_fee = Int.abs(Float.toInt(Float.fromInt(icp_amount)*0.01));
       let icp_sell_amount = Int.abs(Float.toInt(Float.fromInt(icp_amount)*0.99));
        //for_test
       let transfer_fee = 10000;
    //    let icp_sell_amount = 10000;
       Debug.print(debug_show("method_name = icp_sell.icp_sell2 icp_fee=",icp_fee,"icp_sell_amount",icp_sell_amount));
        let transfer_fee_result = await icp_ledger_canister.icrc1_transfer(
            {
                to = {owner = Principal.fromText("gnetj-lsi3d-ur244-q6wda-ehkfy-y4ern-vny2e-hrxf2-gbmqj-hdt5f-tqe");subaccount = null};
                fee = null;
                from_subaccount = null;
                memo = null;
                created_at_time = null;
                amount = icp_fee - transfer_fee;
            }
        );
        Debug.print(debug_show("method_name = icp_sell transfer_fee_result=",transfer_fee_result));
        switch(transfer_fee_result){
          case(#Ok(code)){
            // do nothing
          };
          case(#Err(msg)){
            return #Err(#GenericError{error_code=501;message = "pay sell fee error icp_amount=" # Nat.toText(icp_amount) # " icp_fee="#Nat.toText(icp_fee)# "error=" # debug_show(msg)});
          };
        };
        Debug.print(debug_show("method_name = sell.icp_sell3"));

        // ToDo   icrc1 transfer
        let transfer_result = await icp_ledger_canister.icrc1_transfer(
            {
                to = {owner = user;subaccount = null};
                fee = null;
                memo = null;
                from_subaccount = null;
                created_at_time = null;
                amount = icp_sell_amount - transfer_fee;
            }
        );
        Debug.print(debug_show("method_name = icp_sell transfer_result=",transfer_result));
        switch(transfer_result){
            case(#Ok(code)){
                return #Ok(code);
            };
            case(#Err(msg)){
                return #Err(#GenericError{error_code=502;message = "pay sell error icp_amount=" # Nat.toText(icp_amount) # " icp_fee="#Nat.toText(icp_fee)# "error=" # debug_show(msg)});
            };
        };
    };


    public func back_icp():async(){
        let am = await icp_ledger_canister.icrc1_balance_of({ owner = Principal.fromActor(this); subaccount = null });
        if(am > 10000){
            ignore await icp_ledger_canister.icrc1_transfer({
                to = {owner = init.create_account;subaccount = null};
                fee = null;
                memo = null;
                from_subaccount = null;
                created_at_time = null;
                amount = am-10000;
            });
        }
    };
    public func show_all_icp_transaction_logs():async [ICPTransaction]{
        List.toArray(icp_transaction_logs);
    };


    public func get_icp_usd_price():async Float{

        if (rate_cache.update_time + rate_cache.effect_time < TimeUtil.getCurrentSecond() and rate_cache.rate > 0){
            return rate_cache.rate;
        };

        let request : icp_rate.GetExchangeRateRequest = {
            quote_asset ={
                symbol = "USD";
                class_ = #FiatCurrency;
            };
            base_asset = {
                symbol = "ICP";
                class_ = #Cryptocurrency;
            };
            timestamp = null;
        };
        // Every XRC call needs 1B cycles.
        Cycles.add<system>(1_000_000_000);
        let response = await icp_rate_instance.get_exchange_rate(request);
        switch(response){
            case(#Ok(rate_response)){
                let float_rate = Float.fromInt(Nat64.toNat(rate_response.rate));
                let float_divisor = Float.fromInt(Nat32.toNat(10 ** rate_response.metadata.decimals));
                let rate = float_rate / float_divisor;
                rate_cache.update_time := TimeUtil.getCurrentSecond();
                rate_cache.rate := rate;
                return rate;
            };
            case(#Err(msg)){
                return 0;
            };
        };
    };

    


    

    




};