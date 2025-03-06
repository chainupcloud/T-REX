pragma solidity 0.8.17;

interface ICompliance {
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
     *  @param _amount The amount of tokens involved in the transfer
     */
    function isCompliant(address _from, address _to, uint256 _amount) external view returns (bool);

    /**
     *  @dev function called whenever tokens are transferred
     *  from one wallet to another
     *  this function can update state variables in the modules bound to the compliance
     *  these state variables being used by the module checks to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the modules
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function transferred(address _from, address _to, uint256 _amount) external;

    /**
     *  @dev function called whenever tokens are created on a wallet
     *  this function can update state variables in the bound to the compliance
     *  these state variables being used by the checks to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the minting
     */
    function created(address _to, uint256 _amount) external;

    /**
     *  @dev function called whenever tokens are destroyed from a wallet
     *  this function can update state variables in the bound to the compliance
     *  these state variables being used by the module checks to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters
     *  @param _from The address on which tokens are burnt
     *  @param _amount The amount of tokens involved in the burn
     */
    function destroyed(address _from, uint256 _amount) external;
}
