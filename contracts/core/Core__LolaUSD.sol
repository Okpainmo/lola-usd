// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Base__LolaUSD.sol";

contract Core__LolaUSD is Base__LolaUSD {
    error LolaUSDCore__ZeroAddressError();
    error LolaUSDCore__AccessDenied_AdminOnly();
    error LolaUSDCore__LogoNameCannotBeEmpty();
    error LolaUSDCore__SpendApprovalFailedForAirdropContract();

    event Logs(string message, uint256 timestamp, string indexed contractName);

    string private constant CONTRACT_NAME = "Core__LolaUSD"; // set in one place to avoid mispelling elsewhere
    address private i_owner;
    string private s_tokenImageCID;
    string private s_tokenMetadataCID;
    address internal s_airdropCoreContractAddress;

    // IBase__Airdrop internal airdropContract__Base = IBase__Airdrop(s_airdropCoreContractAddress);
    uint256 internal s_airdropLimit;
    uint256 internal s_airdropAmount;

    constructor(
        string memory _s_tokenName,
        string memory _tokenLogoCID,
        string memory _s_tokenMetadataCID,
        string memory _tokenSymbol,
        uint8 _decimals,
        uint256 _supply,
        address _adminManagementCoreContractAddress,
        address _proposalManagementCoreContractAddress,
        address _airdropCoreContractAddress
    ) {
        s_tokenName = _s_tokenName;
        s_tokenSymbol = _tokenSymbol;
        s_tokenDecimals = _decimals;
        i_owner = msg.sender;
        s_supply = _supply * 10 ** s_tokenDecimals;

        s_tokenMetadataCID = _s_tokenMetadataCID;
        s_tokenImageCID = _tokenLogoCID;

        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress; // needed to check admin rights and likely more
        s_proposalManagementCoreContractAddress = _proposalManagementCoreContractAddress;
        // s_airdropCoreContractAddress = _airdropCoreContractAddress;

        balance[msg.sender] = s_supply;
        emit Transfer(address(0), msg.sender, s_supply);

        // approve externally deployed airdrop contract to spend airdrop allocation
        bool success = approve(
            _airdropCoreContractAddress,
            s_airdropLimit * s_airdropAmount
        );

        if (!success) {
            revert LolaUSDCore__SpendApprovalFailedForAirdropContract();
        }

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

    function getAdminManagementCoreContractAddress()
        public
        view
        returns (address)
    {
        return s_adminManagementCoreContractAddress;
    }

    function getProposalManagementCoreContractAddress()
        public
        view
        returns (address)
    {
        return s_proposalManagementCoreContractAddress;
    }

    function updateAdminManagementCoreContractAddress(
        address _newAddress
    ) public {
        if (!s_adminMangementContract.checkIsAdmin(msg.sender)) {
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
        if (!s_adminMangementContract.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        if (_newAddress == address(0)) {
            revert LolaUSDCore__ZeroAddressError();
        }

        s_proposalManagementCoreContractAddress = _newAddress;
    }

    function getTokenLogo() public view returns (string memory) {
        return s_tokenImageCID;
    }

    function getTokenMetadata() public view returns (string memory) {
        return s_tokenMetadataCID;
    }

    function updateTokenLogo(string memory _newLogoCID) public {
        if (!s_adminMangementContract.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        if (bytes(_newLogoCID).length < 1)
            revert LolaUSDCore__LogoNameCannotBeEmpty();

        s_tokenImageCID = _newLogoCID;
    }

    function updateTokenMetaData(string memory _newMetaDataCID) public {
        if (!s_adminMangementContract.checkIsAdmin(msg.sender)) {
            revert LolaUSDCore__AccessDenied_AdminOnly();
        }

        if (bytes(_newMetaDataCID).length < 1)
            revert LolaUSDCore__LogoNameCannotBeEmpty();

        s_tokenMetadataCID = _newMetaDataCID;
    }

    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }
}
