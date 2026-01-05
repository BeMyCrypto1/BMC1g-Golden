// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * ============================================================
 * Company: BMC1 BeMyCrypto1 LLC
 * Product: BMC1g – Golden Utility Token
 * Contract: BMC1Golden
 * Version: 1.0.0
 *
 * Creator / CEO: Ben Macedo
 * Contact Email: bmc1.ceo.macedo@bemycrypto1.online // line corrected inside github for reference but original deployed had mistake in it
 *
 * ============================================================
 *
 * Characteristics:
 * - Fixed supply (minted once at deployment)
 * - No admin roles
 * - No proxy / upgrade logic
 * - No blacklist / freeze
 * - No pausing
 * - No ETH handling
 * - No external calls
 * - Flat 0.02% fee on ALL transfers
 * - Treasury address is immutable and hardcoded
 * - Transparent, predictable, honeypot-resistant design
 *
 * Fee Model:
 * - 0.02% (2 basis points) on every transfer
 * - Fee is sent directly to company treasury
 * - Fee rate and treasury cannot be changed
 *
 * Governance & Trust:
 * - No minting after deployment
 * - No burning
 * - No owner privileges
 * - If a transfer is possible, selling is always possible
 *
 * ============================================================
 */

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract BMC1Golden is IERC20 {

    /* ------------------------------------------------------------
       Token Metadata
    ------------------------------------------------------------ */

    string public constant name     = "BMC1Golden";
    string public constant symbol   = "BMC1g";
    uint8  public constant decimals = 18;

    /* ------------------------------------------------------------
       Treasury (Company Wallet)
    ------------------------------------------------------------ */

    address public constant treasury =
        0x0A0A4D16a496A45FEd4f4a8d107e10368a8209cc;

    /* ------------------------------------------------------------
       Supply
    ------------------------------------------------------------ */

    uint256 private immutable _totalSupply;

    /* ------------------------------------------------------------
       Fee Configuration (Immutable)
    ------------------------------------------------------------ */

    // 0.02% = 2 basis points
    uint256 private constant FEE_BPS = 2;
    uint256 private constant BPS_DENOMINATOR = 10_000;

    /* ------------------------------------------------------------
       Storage
    ------------------------------------------------------------ */

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /* ------------------------------------------------------------
       Constructor
    ------------------------------------------------------------ */

    constructor(uint256 totalSupply_) {
        _totalSupply = totalSupply_;

        // Entire supply minted to company treasury
        _balances[treasury] = totalSupply_;
        emit Transfer(address(0), treasury, totalSupply_);
    }

    /* ------------------------------------------------------------
       ERC20 Views
    ------------------------------------------------------------ */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /* ------------------------------------------------------------
       ERC20 Core Logic
    ------------------------------------------------------------ */

    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        require(spender != address(0), "Approve to zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        external
        override
        returns (bool)
    {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "Allowance exceeded");

        unchecked {
            _allowances[from][msg.sender] = currentAllowance - amount;
        }

        _transfer(from, to, amount);
        return true;
    }

    /* ------------------------------------------------------------
       Internal Transfer With Flat Fee
    ------------------------------------------------------------ */

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(amount > 0, "Amount must be greater than zero");

        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "Insufficient balance");

        uint256 fee = (amount * FEE_BPS) / BPS_DENOMINATOR;
        uint256 netAmount = amount - fee;

        unchecked {
            _balances[from] = senderBalance - amount;
            _balances[to] += netAmount;
        }

        emit Transfer(from, to, netAmount);

        if (fee > 0) {
            _balances[treasury] += fee;
            emit Transfer(from, treasury, fee);
        }
    }
}
