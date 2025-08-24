// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;
// import "../auth/GovernanceAuth.sol";
// import "../auth/OnlyOwnerAuth.sol";

// contract Governance is GovernanceAuth, OnlyOwnerAuth {
//     error Governance__AddressIsZeroAddress();
//     error Governance__NotDAOMember();
//     error Governance__ProposalNameCannotBeEmpty();
//     error Governance__ProposalNotFound();
//     error Governance__ProposalAlreadyExist(string proposalName);

//     event DAOMembersManagement(string message, address memberAddress, address indexed addedBy, uint256 addedAt);
//     event DAOProposalManagement(
//         string message, 
//         string indexed proposalName, 
//         ProposalAction indexed proposalAction, 
//         uint256 tokenSupplyChange, 
//         address indexed addedBy, 
//         uint256 addedAt
//     );
    
//     struct DAOMember {
//         address memberAddress;
//         address addedBy;
//         uint256 addedAt;
//     }

//     DAOMember[] internal governanceDAOMembers;
//     mapping(address => DAOMember) internal DAOMemberAddressToProfile;

//     enum ProposalAction { Mint, Burn }

//     struct Proposal {
//         string proposalName;
//         address addedBy;
//         uint256 addedAt;
//         ProposalAction proposalAction;
//         uint256 tokenSupplyChange;
//     }

//     Proposal[] internal DAOProposalsHistory;
//     mapping(string => Proposal) internal proposalNameToProposal;
//     mapping(address => Proposal[]) internal memberToMemberProposals;

//     enum VoteAction { Approve, Reject }
    
//     struct Vote {
//         string proposalName;
//         VoteAction voteAction;
//         address votedBy;
//         uint256 votedAt;
//     }
//     mapping(address => Vote) internal memberToVote;
//     mapping(address => Vote[]) internal memberToMemberVotes;

//     function addDAOMember(address _memberAddress) external onlyOwner(msg.sender) {
//         if (_memberAddress == address(0)) {
//             revert Governance__AddressIsZeroAddress();
//         }

//         DAOMember memory newMember = DAOMember(_memberAddress, msg.sender, block.timestamp);

//         governanceDAOMembers.push(newMember);

//         // isDAOMember - from GovernanceAuth.sol
//         isDAOMember[_memberAddress] = true;

//         DAOMemberAddressToProfile[_memberAddress] = newMember;

//         emit DAOMembersManagement("DAO member added successfully", _memberAddress, msg.sender, block.timestamp);

//         DAOMemberAddressToProfile[_memberAddress] = DAOMember(_memberAddress, msg.sender, block.timestamp);
//     }

//     function removeDAOMember(address _memberAddress) external onlyOwner(msg.sender) {
//         if (_memberAddress == address(0)) {
//             revert Governance__AddressIsZeroAddress();
//         }

//         // isDAOMember - from GovernanceAuth.sol
//         if(isDAOMember[_memberAddress] != true) {
//             revert Governance__NotDAOMember();
//         }

//         // Remove from DAO members list
//         for (uint256 i = 0; i < governanceDAOMembers.length; i++) {
//             if (governanceDAOMembers[i].memberAddress == _memberAddress) {
//                 governanceDAOMembers[i] = governanceDAOMembers[governanceDAOMembers.length - 1];
//                 governanceDAOMembers.pop();

//                 break;
//             }
//         }

//         // isDAOMember - from GovernanceAuth.sol
//         isDAOMember[_memberAddress] = false;

//         // reset the profile data to solidity defaults
//         delete DAOMemberAddressToProfile[_memberAddress];

//         emit DAOMembersManagement("DAO member removed successfully", _memberAddress, msg.sender, block.timestamp);
//     }

//     function createDAOProposal (
//         string memory _proposalName,
//         ProposalAction _proposalAction,
//         uint256 _tokenSupplyChange
//     ) external onlyDAOMember(msg.sender){
//         if (bytes(_proposalName).length == 0) {
//             revert Governance__ProposalNameCannotBeEmpty();
//         }

//         // prevent duplicate Proposal names
//         if (bytes(proposalNameToProposal[_proposalName].proposalName).length != 0) {
//             revert Governance__ProposalAlreadyExist(_proposalName);
//         }

//         Proposal memory newProposal = Proposal({
//             proposalName: _proposalName,
//             addedBy: msg.sender,
//             addedAt: block.timestamp,
//             proposalAction: _proposalAction,
//             tokenSupplyChange: _tokenSupplyChange
//         });

//         DAOProposalsHistory.push(newProposal);
//         proposalNameToProposal[_proposalName] = newProposal;

//         emit DAOProposalManagement(
//             "DAO Proposal added successfully", 
//             _proposalName,
//             _proposalAction,
//             _tokenSupplyChange,
//             msg.sender,
//             block.timestamp
//         );
//     }

//     function removeDAOProposal(string memory _proposalName) external onlyDAOMember(msg.sender) {
//         if (bytes(_proposalName).length == 0) {
//             revert Governance__ProposalNameCannotBeEmpty();
//         }

//         if (bytes(proposalNameToProposal[_proposalName].proposalName).length == 0) {
//             revert Governance__ProposalNotFound();
//         }

//         // Remove from DAOProposalsHistory array
//         for (uint256 i = 0; i < DAOProposalsHistory.length; i++) {
//             if (keccak256(bytes(DAOProposalsHistory[i].proposalName)) == keccak256(bytes(_proposalName))) {
//                 DAOProposalsHistory[i] = DAOProposalsHistory[DAOProposalsHistory.length - 1];
//                 DAOProposalsHistory.pop();

//                 break;
//             }
//         }

//         delete proposalNameToProposal[_proposalName];

//         Proposal storage existingProposal = proposalNameToProposal[_proposalName];

//         emit DAOProposalManagement(
//             "DAO Proposal removed successfully", 
//             existingProposal.proposalName,
//             existingProposal.proposalAction,
//             existingProposal.tokenSupplyChange,
//             msg.sender,
//             block.timestamp
//         );
//     }

//     function ProposalDAOProposal(
//         string memory _proposalName,
//         ProposalAction _newProposalAction,
//         uint256 _newTokenSupplyChange
//     ) external onlyDAOMember(msg.sender) {
//         if (!isDAOMember[msg.sender]) {
//             revert Governance__NotDAOMember();
//         }

//         if (bytes(_proposalName).length == 0) {
//             revert Governance__ProposalNameCannotBeEmpty();
//         }

//         if (bytes(proposalNameToProposal[_proposalName].proposalName).length == 0) {
//             revert Governance__ProposalNotFound();
//         }

//         // Proposal the mapping entry - only an Proposal you added
//         Proposal storage existingProposal = proposalNameToProposal[_proposalName];

//         if(existingProposal.addedBy != msg.sender ) {
//             revert ("Unauthorized: you can only make changes to DAO Proposals created by you");
//         }

//         existingProposal.proposalAction = _newProposalAction;
//         existingProposal.tokenSupplyChange = _newTokenSupplyChange;
//         existingProposal.addedAt = block.timestamp;

//         // also Proposal the DAOProposalsHistory array
//         for (uint256 i = 0; i < DAOProposalsHistory.length; i++) {
//             if (keccak256(bytes(DAOProposalsHistory[i].proposalName)) == keccak256(bytes(_proposalName))) {
//                 DAOProposalsHistory[i] = existingProposal;

//                 break;
//             }
//         }

//          emit DAOProposalManagement(
//             "DAO Proposal Proposald successfully", 
//             existingProposal.proposalName,
//             existingProposal.proposalAction,
//             existingProposal.tokenSupplyChange,
//             msg.sender,
//             block.timestamp
//         );
//     }

// }