// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../LolaUSD.sol";

contract Core__LolaUSD is LolaUSD {
    error LolaUSDCore__ZeroAddressError();
    error LolaUSDCore__WalletAlreadyReceivedAirdrop();
    error LolaUSDCore__AirdropCampaignEnded();
    error LolaUSDCore__AirdropLimitCannotBeZero();
    error LolaUSDCore__AccessDenied_AdminOnly();
    error LolaUSDCore__AirdropFailed();

    event Logs(string message, uint256 timestamp, string indexed contractName);

    string private constant CONTRACT_NAME = "Core__LolaUSD"; // set in one place to avoid mispelling elsewhere
    address private i_owner;
    string private tokenImageCID;
    string private tokenMetaDataCID;

    /*---------------- airdrop functionality -----------------*/
    /*---------------- airdrop functionality -----------------*/

    uint256 private s_airdropAmount = 10 * 10 ** 18; // 10 USDL
    uint256 private s_airdropLimit = 100;
    mapping(address => bool) private s_hasReceivedAirdrop;

    struct Airdrop {
        address recipient;
        uint256 deliveredAt;
    }

    Airdrop[] private s_airdrops;

    /*---------------- airdrop functionality -----------------*/
    /*---------------- airdrop functionality -----------------*/

    constructor(
        string memory _tokenName,
        string memory _tokenLogoCID,
        string memory _tokenMetaDataCID,
        string memory _tokenSymbol,
        uint8 _decimals,
        uint256 _supply,
        address _adminManagementCoreContractAddress,
        address _proposalManagementCoreContractAddress
    ) {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        tokenDecimals = _decimals;
        i_owner = msg.sender;
        supply = _supply * 10 ** 18;

        tokenMetaDataCID = _tokenMetaDataCID;
        tokenImageCID = _tokenLogoCID;

        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress; // needed to check admin rights and likely more
        s_proposalManagementCoreContractAddress = _proposalManagementCoreContractAddress;

        balance[msg.sender] = supply;
        emit Transfer(address(0), msg.sender, supply);

        emit Logs(
            "contract deployed successfully with constructor chores completed",
            block.timestamp,
            CONTRACT_NAME
        );
    }

    function getContractName() public pure returns (string memory) {
        return CONTRACT_NAME;
    }

    function getContractOwner() public view returns (address) {
        return i_owner;
    }

    function updateAdminManagementCoreContractAddress(
        address _newAddress
    ) public {
        if (_newAddress == address(0)) {
            revert LolaUSDCore__ZeroAddressError();
        }

        s_adminManagementCoreContractAddress = _newAddress;
    }

    function updateProposalManagementCoreContractAddress(
        address _newAddress
    ) public {
        if (_newAddress == address(0)) {
            revert LolaUSDCore__ZeroAddressError();
        }

        s_proposalManagementCoreContractAddress = _newAddress;
    }

    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }

    /*---------------- airdrop functionality -----------------*/
    /*---------------- airdrop functionality -----------------*/

    // potential todo: consider keeping aridrop funds in a separate wallet, and processing from that wallet - for added safety.
    function airdrop() public {
        if (s_hasReceivedAirdrop[msg.sender]) {
            revert LolaUSDCore__WalletAlreadyReceivedAirdrop();
        }

        if (s_airdrops.length >= s_airdropLimit) {
            revert LolaUSDCore__AirdropCampaignEnded();
        }

        if (msg.sender == address(0)) {
            revert LolaUSD__OperatorAddressIsZeroAddress();
        }

        // approve the deduction from token holder(owner) wallet
        allowedSpend[i_owner][msg.sender] = s_airdropAmount; // user(i_owner) allows platform/operator, e.g. a DEX, to currently be able to spend '_value' amount from their balance

        emit Approval(i_owner, msg.sender, s_airdropAmount);

        // now process with "transferFrom"
        bool success = transferFrom(i_owner, msg.sender, s_airdropAmount);
        if (!success) {
            revert LolaUSDCore__AirdropFailed();
        }

        s_hasReceivedAirdrop[msg.sender] = true;

        Airdrop memory newAirdrop = Airdrop({
            recipient: msg.sender,
            deliveredAt: block.timestamp
        });

        s_airdrops.push(newAirdrop);
    }

    function getAirdropCount() public view returns (uint256) {
        return s_airdrops.length;
    }

    function getAirdrops() public view returns (Airdrop[] memory) {
        return s_airdrops;
    }

    function getAirdropLimit() public view returns (uint256) {
        return s_airdropLimit;
    }

    function updateAirdropLimit(uint256 _newAirdropLimit) public {
        if (!adminMangementContract.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        if (_newAirdropLimit == 0) {
            revert LolaUSDCore__AirdropLimitCannotBeZero();
        }

        s_airdropLimit = _newAirdropLimit;
    }

    /*---------------- airdrop functionality -----------------*/
    /*---------------- airdrop functionality -----------------*/
}
