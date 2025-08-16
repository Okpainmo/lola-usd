// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ERC20 - NatSpec documented implementation (OpenZeppelin style)
 * @author Andrew Okpainmo (adapted for audit readiness)
 * @notice A complete, audited-friendly ERC-20 token implementation with standard extensions:
 *         - minting and burning (owner-only)
 *         - increaseAllowance / decreaseAllowance helpers
 *         - internal hooks (_beforeTokenTransfer / _afterTokenTransfer)
 * @dev Designed to be self-contained for review. This intentionally follows OpenZeppelin design patterns
 *      but avoids external imports so auditors can review a single file. It uses Solidity 0.8.x built-in
 *      overflow checks and a clear storage layout.
 */
contract ERC20 {
    /* ==============================================================
     *                          EVENTS
     * ==============================================================
     */

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`). Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /* ==============================================================
     *                          STORAGE
     * ==============================================================
     */

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private _owner;

    /* ==============================================================
     *                          MODIFIERS
     * ==============================================================
     */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "ERC20: caller is not the owner");
        _;
    }

    /* ==============================================================
     *                          CONSTRUCTOR
     * ==============================================================
     */

    /**
     * @notice Construct a new ERC20 token
     * @param name_ The ERC20 token name (human-readable)
     * @param symbol_ The ERC20 token symbol (short ticker)
     * @param decimals_ The number of decimals used for display (commonly 18)
     * @dev The deployer is set as the contract owner. No tokens are minted by
     *      default; call `mint` after deployment if you want an initial supply.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /* ==============================================================
     *                          OWNERSHIP LOGIC
     * ==============================================================
     */

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Return the address of the current owner.
     * @return The owner address.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Transfer ownership to `newOwner`.
     * @param newOwner The address to transfer ownership to. Cannot be the zero-address.
     * @dev Emits an {OwnershipTransferred} event.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "ERC20: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /* ==============================================================
     *                          ERC20 INTERFACE
     * ==============================================================
     */

    /**
     * @notice Returns the name of the token.
     * @return The token name.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the token, usually a shorter version of the name.
     * @return The token symbol.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * @return The number of decimals.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Returns the total token supply in base units.
     * @return The total supply.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns the balance of `account` in base units.
     * @param account The address to query.
     * @return The account balance.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Transfer `amount` tokens to `to`.
     * @param to The recipient address.
     * @param amount The number of base units to transfer.
     * @return True if the operation succeeded.
     * @dev Reverts when `to` is the zero address or the caller has insufficient balance.
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice Returns the remaining number of tokens that `spender` will be
     *         allowed to spend on behalf of `owner` through {transferFrom}.
     * @param owner_ The token owner address.
     * @param spender The spender address.
     * @return The remaining allowance for the spender.
     */
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    /**
     * @notice Approve `spender` to spend `amount` on behalf of the caller.
     * @param spender The address which will spend the funds.
     * @param amount The number of base units to approve.
     * @return True if the operation succeeded.
     * @dev Emits an {Approval} event. NOTE: changing an existing non-zero allowance
     *      to another non-zero value is discouraged due to potential race conditions.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `from` to `to` using the allowance mechanism.
     * @param from The address which you want to send tokens from.
     * @param to The recipient address.
     * @param amount The number of base units to transfer.
     * @return True if the operation succeeded.
     * @dev Emits a {Transfer} event and reduces the caller's allowance.
     */
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(from, msg.sender, currentAllowance - amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     * @param spender The spender address.
     * @param addedValue The amount of base units to add to the allowance.
     * @return True if the operation succeeded.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     * @param spender The spender address.
     * @param subtractedValue The amount of base units to subtract from the allowance.
     * @return True if the operation succeeded.
     * @dev Reverts if the subtraction would underflow.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    /* ==============================================================
     *                     MINT / BURN (OWNER) 
     * ==============================================================
     */

    /**
     * @notice Creates `amount` new tokens and assigns them to `account`, increasing the total supply.
     * @param account The address that will receive the minted tokens.
     * @param amount The number of base units to mint.
     * @dev Only callable by the owner. Emits a {Transfer} event with `from` set to the zero address.
     */
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @notice Destroys `amount` tokens from `account`, reducing the total supply.
     * @param account The address whose tokens will be burned.
     * @param amount The number of base units to burn.
     * @dev Only callable by the owner. Emits a {Transfer} event with `to` set to the zero address.
     */
    function burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    /* ==============================================================
     *                          INTERNALS
     * ==============================================================
     */

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     * @param from The sender address.
     * @param to The recipient address.
     * @param amount The number of base units to transfer.
     * @dev Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner_` s tokens.
     * @param owner_ The token owner address.
     * @param spender The spender address.
     * @param amount The new allowance in base units.
     * @dev Emits an {Approval} event.
     */
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

}
