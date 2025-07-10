pragma solidity 0.8.17;

interface IERC721Compliance {
    /**
     *  @dev getter for the address of the token bound
     *  returns the address of the token
     */
    function getTokenBound() external view returns (address);

    /**
     *  @dev checks that the transfer is compliant.
     *  default compliance always returns true
     *  READ ONLY FUNCTION, this function cannot be used to increment
     *  counters, emit events, ...
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _tokenId The tokenId of tokens involved in the transfer
     */
    function isCompliant(address _from, address _to, uint256 _tokenId) external view returns (bool);

    /**
     *  @dev function called whenever tokens are transferred
     *  from one wallet to another
     *  this function can update state variables in the modules bound to the compliance
     *  these state variables being used by the module checks to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the modules
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _tokenId The tokenId of tokens involved in the transfer
     */
    function transferred(address _from, address _to, uint256 _tokenId) external;

    /**
     *  @dev function called whenever tokens are created on a wallet
     *  this function can update state variables in the bound to the compliance
     *  these state variables being used by the checks to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters
     *  @param _to The address of the receiver
     *  @param _quantity The number of mint
     */
    function created(address _to, uint256 _quantity) external;

    /**
     *  @dev function called whenever tokens are destroyed from a wallet
     *  this function can update state variables in the bound to the compliance
     *  these state variables being used by the module checks to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters
     */
    function destroyed(uint256 _tokenId) external;
}
