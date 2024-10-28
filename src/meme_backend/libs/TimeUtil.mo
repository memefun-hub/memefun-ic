import Time "mo:base/Time";
import Bool "mo:base/Bool";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
module {
    public func getCurrentSecond() : Int {
        return (Time.now() / 1_000_000_000);
    };

    public func getCurrentSecondNat64() : Nat64 {
        // let now : Nat64 = Nat64.fromNat(Time.now());
        return Nat64.fromNat(Int.abs((Time.now() / 1_000_000_000)));
    };
    public func getCurrentNanosecondNat64() : Nat64 {
        // let now : Nat64 = Nat64.fromNat(Time.now());
        return Nat64.fromNat(Int.abs((Time.now())));
    };
    public func getCurrentNanosecondNat() : Nat {
        // let now : Nat64 = Nat64.fromNat(Time.now());
        return Int.abs((Time.now()));
    };

    public func checkTimeout(time : Nat) : Bool {
        return getCurrentSecond() -time < 6000;
    };
};
