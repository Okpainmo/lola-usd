// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GovernanceAuth {
    error GovernanceAuth__NotDAOMember();

    mapping(address => bool) internal isDAOMember;

    modifier onlyDAOMember(address _address) {
        if(!isDAOMember[_address]) {
            revert GovernanceAuth__NotDAOMember();
        }

        _;
    }
}