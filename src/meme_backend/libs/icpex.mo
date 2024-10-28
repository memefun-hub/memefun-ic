import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Bool "mo:base/Bool";
import Text "mo:base/Text";
module {

    public type CreateCommonPoolArgs = {
        base_token : Principal;
        quote_token : Principal;
        base_in_amount : Nat;
        quote_in_amount : Nat;
        fee_rate : Nat;
        i : Nat;
        k : Nat;
        deadline : Nat64;
        relinquish_on : ?Bool;
    };
    public type CreateCommonPoolResonse = (Principal, Nat);
    public type CreateCommonPoolResult = {
        #Ok : CreateCommonPoolResonse;
        #Err : Text;
    };
    public type Self = actor {
        createCommonPool : shared (Principal, Principal, Nat, Nat, Nat, Nat, Nat, Nat64, ?Bool) -> async CreateCommonPoolResult;
    };
};
