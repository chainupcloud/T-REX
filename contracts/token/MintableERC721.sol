// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "contracts/token/IMintableERC721.sol";
import "contracts/compliance/ERC721/IERC721Compliance.sol";

contract MintableERC721 is IMintableERC721, ERC721AQueryable, AccessControl, Pausable {
    // 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // 0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848
    bytes32 internal constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Blacklist mapping
    mapping(address => bool) private _blacklist;

    string private _baseTokenURI;

    address public compliance;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_,
        address admin,
        address mintBurner
    ) ERC721A(name, symbol) {
        _baseTokenURI = baseTokenURI_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        if (mintBurner != address(0)) {
            _grantRole(MINTER_ROLE, mintBurner);
            _grantRole(BURNER_ROLE, mintBurner);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, AccessControl)
        returns (bool)
    {
        return interfaceId == type(IMintableERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    /// Add address to blacklist
    function addBlackList(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _blacklist[account] = true;
    }

    /// Remove address from blacklist
    function removeFromBlacklist(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _blacklist[account] = false;
    }

    /// Check if an address is blacklisted
    function isBlackListed(address account) public view returns (bool) {
        return _blacklist[account];
    }

    /// Pause the contract (can be done by PAUSER_ROLE)
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// Unpause the contract (can only be done by the admin role)
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function minterRole() external pure returns (bytes32) {
        return MINTER_ROLE;
    }

    function burnerRole() external pure returns (bytes32) {
        return BURNER_ROLE;
    }

    function pauserRole() external pure returns (bytes32) {
        return PAUSER_ROLE;
    }

    function setCompliance(address _compliance) external onlyRole(DEFAULT_ADMIN_ROLE) {
        compliance = _compliance;
        emit SetCompliance(_compliance);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        // Exit early if the baseURI is empty.
        if (bytes(baseURI).length == 0) {
            return "";
        }

        // Check if the last character in baseURI is a slash.
        if (bytes(baseURI)[bytes(baseURI).length - 1] != bytes("/")[0]) {
            return baseURI;
        }

        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    /// @notice Mint specifies the number of tokens
    function mint(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        _safeMint(to, quantity);
        if (compliance != address(0)) {
            IERC721Compliance(compliance).created(to, quantity);
        }
    }

    /// @notice Mint the specified token
    function mintSpot(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        if (compliance != address(0) && !IERC721Compliance(compliance).isCompliant(address(0), to, tokenId)) {
            revert NotCompliance();
        }
        _safeMintSpot(to, tokenId);
        if (compliance != address(0)) {
            IERC721Compliance(compliance).transferred(address(0), to, tokenId);
        }
    }

    /// @notice Destroy the specified token
    function burn(uint256 tokenId) external onlyRole(BURNER_ROLE) {
        if (compliance != address(0) && !IERC721Compliance(compliance).isCompliant(address(0), address(0), tokenId)) {
            revert NotCompliance();
        }
        _burn(tokenId);
        if (compliance != address(0)) {
            IERC721Compliance(compliance).destroyed(tokenId);
        }
    }

    /// @notice Transfer the specified token
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(IERC721A, ERC721A)
    {
        if (compliance != address(0) && !IERC721Compliance(compliance).isCompliant(from, to, tokenId)) {
            revert NotCompliance();
        }
        super.transferFrom(from, to, tokenId);
        if (compliance != address(0)) {
            IERC721Compliance(compliance).transferred(from, to, tokenId);
        }
    }

    /// @dev mint, burn, and transfer will all call this function, and you need to check whether it is paused and blacklisted
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        override
    {
        _checkPausedAndBlacklist(from);
        _checkPausedAndBlacklist(to);
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (bytes(_baseTokenURI).length == 0) {
            return "";
        }

        return _baseTokenURI;
    }

    function _checkPausedAndBlacklist(address account) internal view whenNotPaused {
        if (_blacklist[account]) {
            revert AccountIsBlacklisted(account);
        }
    }
}
