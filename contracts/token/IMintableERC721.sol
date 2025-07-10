// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IMintableERC721 {
    error AccountIsBlacklisted(address account);
    error NotCompliance();

    event SetCompliance(address indexed _compliance);

    function mint(address to, uint256 quantity) external;

    function minterRole() external pure returns (bytes32);

    function burnerRole() external pure returns (bytes32);
}
