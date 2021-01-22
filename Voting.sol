pragma solidity >= 0.7.0 <0.9.0;

contract Ballot {
    
    // represents a single voter
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted; // if true, person already voted
        address delegate; // person delegated to
        uint vote; // index of the voted proposal
    }
    
    // represents a single proposal 
    struct Proposal {
        bytes32 name; // short name
        uint voteCount; // number of accumulated votes
    }
    
    address public chairPerson;
    
    // stores a Voter struct for each address
    mapping(address => Voter) public voters;
    
    // dynamically-sized array of Proposals
    Proposal[] public proposals;
    
    // create a new Ballot with several proposalNames
    constructor(bytes32[] memory proposalNames) {
        chairPerson = msg.sender;
        voters[chairPerson].weight = 1;
        
        // for each provided proposalName, create a new Proposal
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
    // give voter the right to vote on this ballot
    function giveRightToVote(address voter) public {
        require(msg.sender == chairPerson, "Only chairPerson can give voting rights.");
        require(!voters[voter].voted, "Voter has already voted.");
        require(voters[voter].weight == 0); // checks if already had voting rights
        voters[voter].weight = 1; // actually assigns the voting right by setting weight
    }
    
    // give a list of voters the right to vote
    function giveRightToVote(address[] memory voters) public {
        for (uint i = 0; i < voters.length; i++) {
            giveRightToVote(voters[i]);
        }
    }
    
    // function that allows everyone to vote
    function giveEveryoneRightToVote() public {
        // TO-DO
    }

    
    // delegate your vote to "to"
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You've already voted.");
        require(msg.sender != to, "Self-delegation is not allowed.");
        
        // forward the delegation
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate; // changes "to" the person "to" delegated to
            
            // if found loop in delegation, disallow
            require(to != msg.sender, "Found loop in delegation.");
        }
        
        sender.voted = true;
        sender.delegate = to;
        
        Voter storage _delegate = voters[to];
        // if delegate voted, increment it's voteCount
        if (_delegate.voted) {
            proposals[_delegate.vote].voteCount += sender.weight;
        } else { // else, add to it's weight
            _delegate.weight += sender.weight;
        }
    }
    
    // give your vote + votes delegated to you to proposal
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no right to vote.");
        require(!sender.voted, "You've already voted.");
        sender.voted = true;
        sender.vote = proposal;
        
        // if proposal doesn't actually exist, changes will be reverted
        proposals[proposal].voteCount += sender.weight;
    }
    
    // compute winning proposal taking all votes into account
    function winningProposal() public view returns (uint _winningProposal) {
        uint winningVoteCount = 0;
        
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                _winningProposal = p;
            }
        }
    }
    
    // returns the name of the winning proposal
    function winnerName() public view returns (bytes32 _winnerName) {
        _winnerName = proposals[winningProposal()].name;
    }
}
