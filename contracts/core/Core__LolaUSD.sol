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
    error LolaUSDCore__LogoNameCannotBeEmpty();

    event Logs(string message, uint256 timestamp, string indexed contractName);

    string private constant CONTRACT_NAME = "Core__LolaUSD"; // set in one place to avoid mispelling elsewhere
    address private i_owner;
    string private tokenImageCID;
    string private tokenMetadataCID;

    /*---------------- airdrop functionality -----------------*/
    /*---------------- airdrop functionality -----------------*/

    uint256 private s_airdropAmount; // 10 USDL
    uint256 private s_airdropLimit;
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
        string memory _tokenMetadataCID,
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
        supply = _supply * 10 ** tokenDecimals;

        tokenMetadataCID = _tokenMetadataCID;
        tokenImageCID = _tokenLogoCID;

        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress; // needed to check admin rights and likely more
        s_proposalManagementCoreContractAddress = _proposalManagementCoreContractAddress;

        s_airdropAmount = 10 * 10 ** tokenDecimals;
        s_airdropLimit = 100;

        balance[msg.sender] = supply;
        emit Transfer(address(0), msg.sender, supply);

        // approve externally deployed airdrop contract to spend airdrop allocation 
        // approve(s_airdropContractAddress, s_airdropLimit * s_airdropAmount);
        
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

    function getAdminManagementCoreContractAddress() public view returns(address) {
        return s_adminManagementCoreContractAddress;
    }

    function getProposalManagementCoreContractAddress() public view returns(address) {
        return s_proposalManagementCoreContractAddress;
    }

    function updateAdminManagementCoreContractAddress(
        address _newAddress
    ) public {
        if (!adminMangementContract.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        if (_newAddress == address(0)) {
            revert LolaUSDCore__ZeroAddressError();
        }

        s_adminManagementCoreContractAddress = _newAddress;
    }

    function updateProposalManagementCoreContractAddress(
        address _newAddress
    ) public {
        if (!adminMangementContract.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        if (_newAddress == address(0)) {
            revert LolaUSDCore__ZeroAddressError();
        }

        s_proposalManagementCoreContractAddress = _newAddress;
    }

    function getTokenLogo() public view returns(string memory){
        return tokenImageCID;
    }

    function getTokenMetadata() public view returns(string memory){
        return tokenMetadataCID;
    }

    function updateTokenLogo(string memory _newLogoCID) public {
        if (!adminMangementContract.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        if (bytes(_newLogoCID).length < 1) revert LolaUSDCore__LogoNameCannotBeEmpty();

        tokenImageCID = _newLogoCID;
    }

    function updateTokenMetaData(string memory _newMetaDataCID) public {
        if (!adminMangementContract.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        if (bytes(_newMetaDataCID).length < 1) revert LolaUSDCore__LogoNameCannotBeEmpty();
        
        tokenMetadataCID = _newMetaDataCID;
    }

    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }

    /*---------------- airdrop functionality -----------------*/
    /*---------------- airdrop functionality -----------------*/

    /* todo: consider creating an airdrop contract, and using 'allowance' to give the airdrop contract permission to be
    able to send up to the total airdrop allocation amount - see commented implementation inside constructor block above. */
    function airdrop() public {
        if (s_hasReceivedAirdrop[msg.sender]) {
            revert LolaUSDCore__WalletAlreadyReceivedAirdrop();
        }

        if (s_airdrops.length >= s_airdropLimit) {
            revert LolaUSDCore__AirdropCampaignEnded();
        }

        if(s_airdropAmount > balance[i_owner]) {
            revert LolaUSDCore__AirdropCampaignEnded();
        }

        s_hasReceivedAirdrop[msg.sender] = true;

        balance[i_owner] -= s_airdropAmount;
        balance[msg.sender] += s_airdropAmount;

        emit Transfer(i_owner, msg.sender, s_airdropAmount);

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

    function updateAirdropCampaign(uint256 _newAirdropLimit, uint256 _newAirdropAmount) public {
        _newAirdropAmount = _newAirdropAmount * 10 ** tokenDecimals;

        if (!adminMangementContract.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        if (_newAirdropLimit == 0) {
            revert LolaUSDCore__AirdropLimitCannotBeZero();
        }

        s_airdropLimit = _newAirdropLimit;
        s_airdropAmount = _newAirdropAmount;
    }

    /*---------------- airdrop functionality -----------------*/
    /*---------------- airdrop functionality -----------------*/
}
