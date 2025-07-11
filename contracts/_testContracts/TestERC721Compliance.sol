// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "contracts/compliance/ERC721/IERC721Compliance.sol";

contract TestERC20Compliance is IERC721Compliance {
    event TransferCompliance(address _from, address _to, uint256 _tokenId);
    event MintCompliance(address _from, address _to, uint256 _quantity);
    event BurnCompliance(uint256 _tokenId);

    address public token;

    constructor(address _token) {
        token = _token;
    }

    function getTokenBound() external view returns (address) {
        return token;
    }

    function isCompliant(address _from, address _to, uint256 _tokenId) external view returns (bool) {
        return true;
    }

    function transferred(address _from, address _to, uint256 _tokenId) external {
        emit TransferCompliance(_from, _to, _tokenId);
    }

    function created(address _to, uint256 _quantity) external {
        emit MintCompliance(address(0), _to, _quantity);
    }

    function destroyed(uint256 _tokenId) external {
        emit BurnCompliance(_tokenId);
    }
}
