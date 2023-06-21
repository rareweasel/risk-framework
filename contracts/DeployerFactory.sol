// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract DeployerFactory is AccessControlEnumerable {

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    constructor(address initialConfigurator) {
        require(initialConfigurator != address(0), "!initial_configurator");
        _setRoleAdmin(CONFIGURATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(CONFIGURATOR_ROLE, initialConfigurator);
    }

    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    )
        external returns (address createdContract)
    {
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "!access_role");
        createdContract = Create2.deploy(amount, salt, bytecode);
    }

    /** View Functions */

    function getCodeAt(address target)
        external view returns (bytes memory code, bytes32 codeHash)
    {
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "!access_role");
        code = type(target).code;
        codeHash = type(target).codehash;
    }

    function computeAddress(uint256 salt, bytes32 bytecodeHash)
        external view returns (address computedAddress)
    {
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "!access_role");
        computedAddress = Create2.computeAddress(salt, bytecodeHash);
    }

    /** Internal Functions */

}

