// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IMintableERC20} from "./IMintableERC20.sol";
import "contracts/compliance/ERC20/ICompliance.sol";

contract MintableERC20 is IMintableERC20, ERC20, AccessControl, Pausable {
    error AccountIsBlacklisted(address account);
    error NotCompliance();

    event SetCompliance(address indexed _compliance);

    // 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // 0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848
    bytes32 internal constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Blacklist mapping
    mapping(address => bool) private _blacklist;

    uint8 private _decimals;

    address public compliance;

    // Initialize the contract
    constructor(string memory name, string memory symbol, uint8 decimals_, address admin, address mintBurner)
        ERC20(name, symbol)
    {
        if (decimals_ > 0) _decimals = decimals_;
        else _decimals = 18;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        if (mintBurner != address(0)) {
            _grantRole(MINTER_ROLE, mintBurner);
            _grantRole(BURNER_ROLE, mintBurner);
        }
    }

    // decimals 8, The native precision of BTC is 8
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // Add address to blacklist
    function addBlackList(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _blacklist[account] = true;
    }

    // Remove address from blacklist
    function removeFromBlacklist(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _blacklist[account] = false;
    }

    // Check if an address is blacklisted
    function isBlackListed(address account) public view returns (bool) {
        return _blacklist[account];
    }

    // Pause the contract (can be done by PAUSER_ROLE)
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    // Unpause the contract (can only be done by the admin role)
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // Internal function to check paused and blacklist status
    function _checkPausedAndBlacklist(address account) internal view whenNotPaused {
        if (_blacklist[account]) {
            revert AccountIsBlacklisted(account);
        }
    }

    function burnerRole() external pure returns (bytes32) {
        return BURNER_ROLE;
    }

    function minterRole() external pure returns (bytes32) {
        return MINTER_ROLE;
    }

    function pauserRole() external pure returns (bytes32) {
        return PAUSER_ROLE;
    }

    function setCompliance(address _compliance) external onlyRole(DEFAULT_ADMIN_ROLE) {
        compliance = _compliance;
        emit SetCompliance(_compliance);
    }

    // Override ERC20's `_transfer` function to include blacklist check and paused status
    function _transfer(address from, address to, uint256 amount) internal override {
        _checkPausedAndBlacklist(from);
        _checkPausedAndBlacklist(to);
        if (compliance != address(0) && !ICompliance(compliance).isCompliant(from, to, amount)) {
            revert NotCompliance();
        }
        super._transfer(from, to, amount);
        if (compliance != address(0)) {
            ICompliance(compliance).transferred(from, to, amount);
        }
    }

    // Public burn function to include blacklist check and paused status
    function burn(address account, uint256 amount) external onlyRole(BURNER_ROLE) {
        _checkPausedAndBlacklist(account);
        _burn(account, amount);
        if (compliance != address(0)) {
            ICompliance(compliance).destroyed(account, amount);
        }
    }

    // Public mint function to include blacklist check and paused status
    function mint(address account, uint256 amount) external onlyRole(MINTER_ROLE) {
        _checkPausedAndBlacklist(account);
        if (compliance != address(0) && !ICompliance(compliance).isCompliant(address(0), account, amount)) {
            revert NotCompliance();
        }
        _mint(account, amount);
        if (compliance != address(0)) {
            ICompliance(compliance).created(account, amount);
        }
    }
}
