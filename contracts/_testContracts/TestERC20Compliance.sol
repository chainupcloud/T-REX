// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "contracts/compliance/ERC20/ICompliance.sol";

contract TestERC20Compliance is ICompliance {
    event TransferCompliance(address _from, address _to, uint256 _amount);
    event MintCompliance(address _from, address _to, uint256 _amount);
    event BurnCompliance(address _from, address _to, uint256 _amount);

    address public token;

    constructor(address _token) {
        token = _token;
    }

    function getTokenBound() external view returns (address) {
        return token;
    }

    function isCompliant(address _from, address _to, uint256 _amount) external view returns (bool) {
        if (_amount > 1e21) {
            return false;
        }

        return true;
    }

    function transferred(address _from, address _to, uint256 _amount) external {
        emit TransferCompliance(_from, _to, _amount);
    }

    function created(address _to, uint256 _amount) external {
        emit MintCompliance(_to, address(0), _amount);
    }

    function destroyed(address _from, uint256 _amount) external {
        emit BurnCompliance(address(0), _from, _amount);
    }
}
