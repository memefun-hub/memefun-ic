import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Bool "mo:base/Bool";
import Text "mo:base/Text";
module {

    public type importTokenResult = {
        #Ok : ();
        #Err : Text;
    };
    public type Self = actor {
        importToken : shared (Principal, Text) -> async importTokenResult;
    };
};
