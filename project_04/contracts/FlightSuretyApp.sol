pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;
    uint256 private constant AIRLINE_FUNDING_AMOUNT = 10 ether;
    uint256 private constant INSURANCE_MAX_AMOUNT = 1 ether;

    address private contractOwner;          // Account used to deploy contract
    FlightSuretyData private  flightSuretyData;
    
    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
        string flightname;
    }
    mapping(bytes32 => Flight) private flights;
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
         // Modify to call data contract's status
        require(flightSuretyData.isOperational(), "Contract is currently not operational");  
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
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address dataContractAddress
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContractAddress);
        _registerAirline("Chungnx airline", contractOwner);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() 
                            public 
                            pure 
                            returns(bool) 
    {
        return true;  // Modify to call data contract's status
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline
                            (   
                                string name,
                                address airlineAddress
                            )
                            external
                            requireIsOperational
                            returns(bool)
    {
        require(flightSuretyData.isAirlineRegistered(msg.sender), "Sender is not an registered airline");
        require(flightSuretyData.isAirlineFunded(msg.sender), "It is not possible to register the airline, the sender is not funded");
        require(!flightSuretyData.isAirlineRegistered(airlineAddress), "The airline is already registered");
        if (flightSuretyData.getRegisteredAirline() < 4) {
            _registerAirline(name, airlineAddress);
            return(true);
        }
        return(false);
    }

    function _registerAirline
                            (
                                string airlineName,
                                address airlineAddress
                            )
                            private
    {
        flightSuretyData.registerAirline(airlineName, airlineAddress);
    }

    function isAirlineRegistered
                            (
                                address airlineAddress
                            )
                            view
                            external
                            requireIsOperational
                            returns(bool)
    {
        return flightSuretyData.isAirlineRegistered(airlineAddress);
    }

    function isAirlineFunded
                            (
                                address airlineAddress
                            )
                            view
                            external
                            requireIsOperational
                            returns(bool)
    {
        return flightSuretyData.isAirlineFunded(airlineAddress);
    }

    function getPassengerCredit
                            (
                                address insuredPassenger
                            )
                            view
                            external
                            requireIsOperational
                            returns(uint256)
    {
        return flightSuretyData.getPassengerRefund(insuredPassenger);
    }


    function fundAirline
                                (
                                    address airlineAddress
                                )
                                payable
                                external
                                requireIsOperational
    {
        require(flightSuretyData.isAirlineRegistered(airlineAddress), "The Airline is not registered");
        require(flightSuretyData.isAirlineFunded(airlineAddress) == false, "Airline is already funded");
        require(msg.value >= AIRLINE_FUNDING_AMOUNT , "Ether amount is not enough");
        flightSuretyData.fundAirline.value(msg.value)(airlineAddress, msg.value);
    }

    function buy
                                (
                                    bytes32 flightKey
                                    
                                )
                                external
                                payable
                                requireIsOperational
    {
        require(msg.value <= INSURANCE_MAX_AMOUNT, "Insuranced amount must be 1 ether or less");
        require(flights[flightKey].airline != address(0), "Flight is not registered");
        flightSuretyData.buy.value(msg.value)(flightKey, msg.sender, msg.value);
    }


    function registerFlight
                                (
                                    string flightName,
                                    address airlineAddress,
                                    uint256 timestamp
                                )
                                external
                                requireIsOperational
                                returns(bytes32)
    {
        require(flightSuretyData.isAirlineRegistered(airlineAddress), "Airline is not registered");
        require(flightSuretyData.isAirlineFunded(airlineAddress), "Airline is not funded");
        bytes32 flightKey = getFlightKey(airlineAddress, flightName, timestamp);
        require(flights[flightKey].airline == address(0), "Flight was registered");
        flightKey = getFlightKey(airlineAddress, flightName, timestamp);
        flights[flightKey]=Flight({
                                isRegistered: true,
                                statusCode: 0,
                                updatedTimestamp: timestamp,
                                airline: airlineAddress,
                                flightname: flightName
                            });
        return flightKey;
    }

    function getFlightKeybyName (
                                    string flightName,
                                    address airlineAddress,
                                    uint256 timestamp
                                )
                                view
                                external
                                requireIsOperational
                                returns(bytes32)
    {
        require(flightSuretyData.isAirlineRegistered(airlineAddress), "Airline is not registered");
        require(flightSuretyData.isAirlineFunded(airlineAddress), "Airline is not funded");
        bytes32 lflightKey = getFlightKey(airlineAddress, flightName, timestamp);
        require(flights[lflightKey].airline != address(0), "Flight is not registered");
        return lflightKey;
    }
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
    {
        if(statusCode == STATUS_CODE_LATE_AIRLINE) {
            bytes32 flightKey = getFlightKey(airline, flight, timestamp);
            flightSuretyData.creditInsurees(flightKey);
        }
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                             bytes32 flightKey                           
                        )
                        external
    {
        require(flights[flightKey].airline != address(0), "Flight is not registered cnx");
        uint8 index = getRandomIndex(msg.sender);
        address airline = flights[flightKey].airline;
        uint256 timestamp = flights[flightKey].updatedTimestamp;
        string storage flightname = flights[flightKey].flightname;
        bytes32 key = keccak256(abi.encodePacked(index, airline, flightname, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flightname, timestamp);
    } 

    function withdrawCredit(address pessangerAddress) external{
        require(pessangerAddress != address(0), "Provide valid address");
        flightSuretyData.pay(pessangerAddress);
    }


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    function getRegistrationFee() public pure returns(uint256) {
        return REGISTRATION_FEE;
    }



    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }

    function fetchFlightStatusWithName
                        (
                            address airline,
                            string flight,
                            uint256 timestamp                            
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    } 


    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= 3) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}   

contract FlightSuretyData {

    function isOperational() public view returns(bool);

    function registerAirline(string name, address airlineAddress) external;

    function isAirlineRegistered(address airline) external view returns(bool);

    function isAirlineFunded(address airline) external view returns(bool);

    function getRegisteredAirline() public view returns(uint256);

    function getPassengerRefund(address passangerAddress) external view returns (uint256);

    function fundAirline(address airlineAddress, uint256 amount) external payable;

    function buy(bytes32 flightKey, address passengerAddress, uint256 insuredAmount) external payable;

    function creditInsurees(bytes32 flightKey) external;

    function pay(address passengerAddress) external payable;

}