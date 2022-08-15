pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    struct Airline {
        string name;
        address AddrAl;
        bool isRegisted;
        bool isFunded;
    }
    mapping(address => Airline) private airLines;

    struct Passenger{
        address AddrP;
        mapping (bytes32 => uint256) insuredFlights;
        uint256 refund;
    }
    mapping(address => Passenger) private passengers;
    address[] private lookup_passenger;

    address private contractOwner;                                      
    bool private operational = true;                                    

    uint256  registeredAirlineCounter = 0;

    mapping(address => bool) private authorizedAppContracts;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        lookup_passenger = new address[](0);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    function isAirlineRegistered
                            (
                                address airline
                            )
                            external
                            view
                            returns(bool)
    {
        return airLines[airline].AddrAl != address(0);
    }

    function getRegisteredAirline()
                            external
                            view
                            returns(uint256)
    {
        return registeredAirlineCounter;
    }

    function isAirlineFunded
                            (
                                address airline
                            )
                            external
                            view
                            returns(bool) 
    {
        return airLines[airline].isFunded;
    }

    function getPassengerRefund
                            (
                                address insuredPassenger
                            )
                            external
                            view
                            returns(uint256)
    {
        return passengers[insuredPassenger].refund;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (
                                string name,
                                address airlineAddress

                            )
                            public
                            requireIsOperational
    {
        require(airlineAddress != address(0));
        require(!airLines[airlineAddress].isRegisted, "Caller is registed");
        airLines[airlineAddress] = Airline({
            name: name,
            AddrAl: airlineAddress,
            isFunded: false,
            isRegisted: true
        });

        registeredAirlineCounter = registeredAirlineCounter.add(1);
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (      
                                bytes32 flightKey,
                                address passengerAddress,
                                uint256 insuredAmount                        
                            )
                            external
                            payable
                            requireIsOperational
    {
        require(passengerAddress != address(0), "invalid address");
        if (passengers[passengerAddress].AddrP != address(0)) { // Existing  passenger
            require(passengers[passengerAddress].insuredFlights[flightKey] == 0, "This flight is already insured");
            
        }
        else { 
            passengers[passengerAddress] = Passenger({
                AddrP: passengerAddress,
                refund: 0
            });
            lookup_passenger.push(passengerAddress);
        }
        passengers[passengerAddress].insuredFlights[flightKey] = insuredAmount;
    }


    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    bytes32 flightKey
                                )
                                external
                                requireIsOperational
    {
        for (uint256 i = 0; i < lookup_passenger.length; i++) {
            address addp = lookup_passenger[i];
            if(passengers[addp].insuredFlights[flightKey] != 0) { // Insured flights
                uint256 price = passengers[addp].insuredFlights[flightKey];
                passengers[addp].insuredFlights[flightKey] = 0;
                passengers[addp].refund = passengers[addp].refund + price + price.div(2); // 1.5X the amount they paid
            }
        }
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address insuredPassenger
                            )
                            external
                            payable
                            requireIsOperational
    {
        require(insuredPassenger == tx.origin, "Contracts not allowed");
        require(passengers[insuredPassenger].AddrP != address(0), "the passenger error");
        require(passengers[insuredPassenger].refund > 0, "Not refund to pay");
        uint256 refund = passengers[insuredPassenger].refund;
        require(address(this).balance > refund, "not enought to fund");
        insuredPassenger.transfer(refund);
        passengers[insuredPassenger].refund = 0;
    }

    function authorizeCaller
                            (
                                address appContract
                            )
                            public
    {
        authorizedAppContracts[appContract] = true;
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fundAirline
                            (
                                address airlineAddress,
                                uint256 amount
                            )
                            public
                            payable
    {
        require(amount >= 10 ether, "require at least 10 ether");
        airLines[airlineAddress].isFunded = true;
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }



}

