pragma solidity >=0.4.21 <0.6.0;
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "./ERC721Mintable.sol";
import "./Verifier.sol";

// TODO define a contract call to the zokrates generated solidity contract <Verifier> or <renamedVerifier>

// TODO define another contract named SolnSquareVerifier that inherits from your ERC721Mintable class
contract SolnSquareVerifier is Verifier, CustomERC721Token{


    constructor( address verifierAddress) public {
        // _squareVerifier = SquareVerifier(verifierAddress);
    }

    // TODO define a solutions struct that can hold an tokenId & an address
    struct Solution{
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[2] inputs;
        uint256 tokenId;
        address Address;
    }

    // TODO define an array of the above struct
    Solution[] solutionsArr;

    // TODO define a mapping to store unique solutions submitted
    mapping(bytes32 => Solution) solutions_mapping;


    // TODO Create an event to emit when a solution is added
    event AddedSolutions(uint256 tokenId, address solution_addr, bytes32 key);


    // TODO Create a function to add the solutions to the array and emit the event
    function addSolution( uint256 id, address addr, bytes32 key,
                          uint[2] memory a, uint[2][2] memory b, uint[2] memory c,
                          uint[2] memory inputs) public {
        require(solutions_mapping[key].Address == address(0), "aready exist token");
        Solution memory solution = Solution({
            a: a,
            b: b,
            c: c,
            inputs: inputs,
            tokenId: id, 
            Address: addr} );
        solutionsArr.push(solution);
        solutions_mapping[key] = solution;
        emit AddedSolutions(id, addr, key);
    }


    // TODO Create a function to mint new NFT only after the solution has been verified
    //  - make sure the solution is unique (has not been used before)
    //  - make sure you handle metadata as well as tokenSuplly
    function generateKey(uint[2] memory a,
        uint[2][2] memory b, uint[2] memory c,
        uint[2] memory inputs) pure public returns(bytes32) {
        return keccak256(abi.encodePacked(a, b, c, inputs));
    }

    function mintToken(address addr, uint256 tokenId,
        uint[2] memory a, uint[2][2] memory b,
        uint[2] memory c, uint[2] memory inputs)
    public
    {
        require(verifyTx(a,b,c,inputs), "verify error");
        bytes32 key = generateKey(a, b, c, inputs);
        require(solutions_mapping[key].Address == address(0), "aready exist token");
        addSolution(tokenId, addr, key, a, b, c, inputs);
        mint(addr, tokenId);
    }
}


  


























