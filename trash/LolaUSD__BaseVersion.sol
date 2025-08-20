// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LolaUSD {
    error LolaUSD__InsufficientBalance();
    error LolaUSD__OperatorAddressIsZeroAddress();
    error LolaUSD__OwnerAddressIsZeroAddress();
    error LolaUSD__ReceiverAddressIsZeroAddress();
    error LolaUSD__TransferOperationWasUnsuccessful();
    error LolaUSD__ExcessSpendRequestOrUnauthorized();
    error LolaUSD__UnsuccessfulTransferFromOperation();

    event Transfer(address indexed _owner, address indexed _receiver, uint256 _value);
    event Approval(address indexed _owner, address indexed _operator, uint256 _value);

    string private tokenName;
    string private tokenSymbol;
    uint8 private tokenDecimals;
    address private owner;
    uint256 private supply;

    mapping(address => uint256) private balance;
    mapping(address => mapping(address => uint256)) private allowedSpend;

    constructor(string memory _tokenName, string memory _tokenSymbol, uint8 _decimals, uint256 _supply) {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        tokenDecimals = _decimals;
        // owner = _owner;
        supply = _supply * 10 ** 18;

        balance[msg.sender] = supply;
        emit Transfer(address(0), msg.sender, supply);
    }
    
    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256){
        return balance[_owner];
    }    

    function approve(address _operator, uint256 _value) public returns (bool) {
        allowedSpend[msg.sender][_operator] = _value; // user(msg.sender) allows platform/operator, e.g. a DEX, to currently be able to spend '_value' amount from their balance

        emit Approval(msg.sender, _operator, _value);
        return true;
    }

    function allowance(address _owner, address _operator) public view returns (uint256) {
        return allowedSpend[_owner][_operator]; // check how much a user has allowed an operator to spend
    }
    
    function transfer(address _receiver, uint256 _value) public returns (bool) {
        if(_receiver == address(0)) {
            revert LolaUSD__ReceiverAddressIsZeroAddress();
        }

        if(_value > balanceOf(msg.sender)) {
            revert LolaUSD__InsufficientBalance();
        }

        balance[msg.sender] -= _value;
        balance[_receiver] += _value;

        emit Transfer(msg.sender, _receiver, _value);

        return true;
    }

    function transferFrom(address _owner, address _receiver, uint256 _value) public returns (bool) {
        if (_receiver == address(0)) {
            revert LolaUSD__ReceiverAddressIsZeroAddress();
        }

        if (_owner == address(0)) {
            revert LolaUSD__OwnerAddressIsZeroAddress();
        }

        uint256 currentAllowance = allowedSpend[_owner][msg.sender];

        if (currentAllowance < _value) {
            revert LolaUSD__ExcessSpendRequestOrUnauthorized();
        }

        if (balance[_owner] < _value) {
            revert LolaUSD__InsufficientBalance();
        }

        balance[_owner] -= _value;
        balance[_receiver] += _value;

        // standard “infinite approval” behavior: an added if block
        // if (currentAllowance != type(uint256).max) {
        //     allowedSpend[_owner][msg.sender] = currentAllowance - _value;
        //     emit Approval(_owner, msg.sender, allowedSpend[_owner][msg.sender]); // optional but good practice
        // }
        
        allowedSpend[_owner][msg.sender] = currentAllowance - _value;
        emit Approval(_owner, msg.sender, allowedSpend[_owner][msg.sender]); // optional but good practice
        // allowedSpend[_owner][msg.sender] =  0;

        emit Transfer(_owner, _receiver, _value);

        return true;
    }
}