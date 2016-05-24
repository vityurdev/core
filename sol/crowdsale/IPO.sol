import 'lib/AddressArray.sol';
import 'token/Token.sol';
import './CashFlow.sol';

contract IPO is Mortal {
    /* The IPO public token */
    Token public credits;

    /* The IPO shares token */
    Token public shares;

    /* The IPO cash flow */
    CashFlow public cashflow;

    /* The funders storage */
    address[] public funders;
    mapping(address => uint) public valueOf;
    
    /* Use libs */
    using AddressArray for address[];

    /* This field has `true` when IPO is closed */
    bool public closed = false;

    /* This event called when IPO closed */
    event Closed(bool indexed success);

    function IPO(Token _credits, uint _shares) {
        credits = _credits;
        shares  = new Token("IPO shares", "S");
        shares.emission(_shares);
    }

    /**
     * @dev Available shares getter
     * @return available shares value
     */
    function getFreeShares() constant returns (uint)
    { return shares.getBalance(); }

    /**
     * @dev Founded credits getter
     * @return founded credits value
     */
    function getFoundedCredits() constant returns (uint)
    { return credits.getBalance(); }

    /**
     * @dev This method is called when user accept the IPO
     * @notice Some credits should be approved for IPO before call 
     */
    function sign();

    /**
     * @dev This internal method should be called when IPO closed success
     */
    function done() internal {
        // Create the cashflow
        cashflow = new CashFlow(credits, shares);

        // Burn unused shares
        shares.burn(shares.getBalance());

        // Delegate shares to cashflow
        shares.delegate(cashflow);

        // Transfer funded credits to cashflow
        credits.transfer(cashflow, credits.getBalance());

        // Close the IPO
        closed = true;
        Closed(true);
    }

    /**
     * @dev This internal method should be called when IPO closed fail
     */
    function fail() internal {
        // Refund credits
        for (uint i = 0; i < funders.length; i += 1)
            credits.transfer(funders[i], valueOf[funders[i]]);

        // Close the IPO
        closed = true;
        Closed(false);
    }

    function append(address _funder, uint _value) internal {
        if (funders.indexOf(_funder) == funders.length)
            funders.push(_funder);
        valueOf[_funder] += _value;
    }
}
