import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";
import Nat64 "mo:base/Nat64";
import Float "mo:base/Float";
import Prelude "mo:base/Prelude";
import Hash "mo:base/Hash";

module{




// dfx deploy token_a --argument '
  // (variant {
  //   Init = record {
  //     token_name = "Token A";
  //     token_symbol = "A";
  //     minting_account = record {
  //       owner = principal "'${OWNER}'";
  //     };
  //     initial_balances = vec {
  //       record {
  //         record {
  //           owner = principal "'${ALICE}'";
  //         };
  //         100_000_000_000;
  //       };
  //     };
  //     metadata = vec {};
  //     transfer_fee = 10_000;
  //     archive_options = record {
  //       trigger_threshold = 2000;
  //       num_blocks_to_archive = 1000;
  //       controller_id = principal "'${OWNER}'";
  //     };
  //     feature_flags = opt record {
  //       icrc2 = true;
  //     };
  //   }
  // })


    public type Subaccount = Blob;
    public type BlockIndex = Nat;
    public type Tokens = Nat;
    public type Memo = Blob;
    public type TxLog = Buffer.Buffer<Transaction>;
    public type Account = { owner : Principal; subaccount : ?Subaccount; };
    // public type Tokens = {var e8s:Nat};
    public type Timestamp = Nat64;
    public type Value = { #Nat : Nat; #Int : Int; #Blob : Blob; #Text : Text };
    public type Metadatas=[Metadata];
    public type TxKind = {#Mint; #Transfer;#Destroy};
    public type MeMeTransactionStatus = {#Complete; #Error};
    public type MeMeTransactionType = {#Mint; #Burn;#Transfer;#Approve};
    public type TransferArg = {
        from_subaccount : ?Subaccount;
        to : Account;
        amount : Nat;
        fee : ?Nat;
        memo : ?Blob;
        created_at_time : ?Timestamp;
    };
    
    public type MeMeTransaction = {
        t_hash : Text;
        t_type : MeMeTransactionType;
        t_status : MeMeTransactionStatus;
        t_index : Nat;
        t_timestamp : Nat;
        from : Principal;
        to : ?Principal;
        amount : Nat;
        fee : ?Nat;
        memo : ?Blob;
        spender_account : ?Principal
    };


    public type ICPTransaction = {
        from : Text;
        to : Text;
        amount : Nat;
        fee : Nat;
        usdt_amount : Nat;
        icp_chain_index : Nat;
        // Effective fee for this transaction.
        timestamp : Timestamp;
    };
    public type Transaction = {
        index : Nat;
        args : Transfer;
        kind : TxKind;
        // Effective fee for this transaction.
        timestamp : Timestamp;
    };


    public type MeMeTransactionLog = {
        index : Nat;
        from : Principal;
        to : Principal;
        t_type : MeMeTransactionType;
        icp_amount : Nat;
        meme_amount : Nat;
        usdt : Float;
        // Effective fee for this transaction.
        timestamp : Timestamp;
    };

    public type RateCache = {
        var rate : Float;
        var update_time : Int;
        var effect_time : Int;
    };

    public type TransferResult = {
        #Ok : BlockIndex;
        #Err : TransferError;
    };

    public type ICPToken = {e8s:Nat64};

    public type ApproveResult = {
        #Ok : Tokens;
        #Err : ApproveError;
    };

    public type TradingCurveConstant = {
        var param1:Nat;
        var param2:Nat;
        var param3:Nat;
    };
    public type MeMeCoinInfo = {
        canister_id :Text;
        name : Text;
        token_symbol : Text;
        description :Text;
        image :Text;
        create_time : Int;
    };

    public type Result = {
        #Ok : Nat;
        #Err : Text;
    };


    public type Transfer = {
        to : Account;
        from : Account;
        memo : ?Memo;
        amount : Tokens;
        fee : ?Tokens;
        created_at_time : ?Timestamp;
    };


    public type TransferFromResult = {
        #Ok : Nat;
        #Err : TransferFromError;
    };


    public type AllowanceArgs = {
        account : Account;
        spender : Account;
    };

    public type Allowance = {
        allowance : Nat;
        expires_at : Nat;
    };

  public type TransferError = {
    #BadFee : { expected_fee : Nat };
    #BadBurn : { min_burn_amount : Nat };
    #InsufficientFunds : { balance : Nat };
    #TooOld;
    #CreatedInFuture : { ledger_time : Nat64 };
    #TemporarilyUnavailable;
    #Duplicate : { duplicate_of : BlockIndex };
    #GenericError : { error_code : Nat; message : Text };
  };


    public type Metadata = {
        key : Text;
        value : Text;
    };
    public type Icrc2LedgerVar = {
        owner : Account;
        var amount : Nat;
    };
    public type Icrc2Ledger = {
        owner : Account;
        amount : Nat;
    };

    public type UserBalance = {
        account_id : Text; //accountId
        var principal : ?Principal;
        var amount : Nat;
    };
    public type UserBalanceShow = {
        account_id : Text; //accountId
        principal : ?Principal;
        amount : Nat;
    };

    public type ApproveArgs = {
        from_subaccount : Blob;
        //
        spender : Account;

        amount : Nat;
        //
        expected_allowance : ?Nat;
        //
        expires_at : ?Nat;
        //
        fee : Nat;
        //
        memo : Blob;
        //
        created_at_time : Nat;
    };

    public type TransferFromArgs = {
        spender_subaccount : Blob;
        from : Account;
        to : Account;
        amount : Nat;
        fee : Nat;
        memo : Nat;
        created_at_time : Nat;
    };


    public type TransferFromError = {
        #BadFee : { expected_fee : Nat };
        #BadBurn : { min_burn_amount : Nat };
        // The [from] account does not hold enough funds for the transfer.
        #InsufficientFunds : { balance : Nat };
        // The caller exceeded its allowance.
        #InsufficientAllowance :  { allowance : Nat };
        #TooOld;
        #CreatedInFuture: { ledger_time : Nat };
        #Duplicate : { duplicate_of : Nat };
        #TemporarilyUnavailable;
        #GenericError : { error_code : Nat; message : Text };
    };

    public type ApproveRecord = {
        from_subaccount : Blob;
        spender : Account;
        var amount : Nat;
        expected_allowance : ?Nat;
        expires_at : ?Nat;
        fee : Nat;
        memo : Blob;
        created_at_time : Nat;
    };

    public type ApproveError = {
        #BadFee : { expected_fee : Nat };
        // The caller does not have enough funds to pay the approval fee.
        #InsufficientFunds : { balance : Nat };
        // The caller specified the [expected_allowance] field, and the current
        // allowance did not match the given value.
        #AllowanceChanged : { current_allowance : Nat };
        // The approval request expired before the ledger had a chance to apply it.
        #Expired : { ledger_time : Nat; };
        // TooOld;
        #CreatedInFuture: { ledger_time : Nat };
        #Duplicate : { duplicate_of : Nat };
        // TemporarilyUnavailable;
        #GenericError : { error_code : Nat; message : Text };
    };

    public type MemeMintParam={
        token_name : Text;
        token_symbol : Text;
        decimals : Nat8;
        total_supply: Nat;
        minting_account : Account;
        //
        initial_balances : [Icrc2Ledger];
        metadata : [Metadata];
        transfer_fee : Nat;
        archive_options : {
            trigger_threshold : Nat;
            num_blocks_to_archive : Nat;
            controller_id : Text;
        };
        feature_flags : {
            icrc2 : Bool;
        };
    };


    public func build_mint_param(owner:Principal,user_rate:Nat
                                ,total_supply:Nat
                                ,token_name:Text,token_symbol:Text
                                ,transfer_fee:Nat
                                , logo : Text
                                ,decimals :Nat8
                                ,trigger_threshold:Nat
                                ,num_blocks_to_archive:Nat

                    ): MemeMintParam {
        return {
            token_name = token_name;
            //
            token_symbol = token_symbol;
            //
            decimals = decimals;
            minting_account = {
                owner = owner;
                subaccount = null;
            };
            initial_balances = [
                {
                    owner = {owner=owner;subaccount=null};
                    // amount = {var e8s=minting_account_amount};
                    amount = total_supply* ( 1-user_rate );              },
                {
                    owner = {owner=owner;subaccount=null};
                    amount = total_supply * user_rate;
                }
            ];
            metadata = [{key="logo";value=logo}];
            transfer_fee = transfer_fee;
            archive_options = {
                trigger_threshold = trigger_threshold;
                num_blocks_to_archive = num_blocks_to_archive;
                controller_id = Principal.toText(owner);
            };
            feature_flags = {
                icrc2 = true;
            };
            total_supply = total_supply;
        }
    }



}