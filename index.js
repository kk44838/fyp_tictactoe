
//HTML page environement variables
var game = document.getElementById('game');
var boxes = document.querySelectorAll('li');
var turnDisplay = document.getElementById('whos-turn');
var statusDisplay = document.getElementById('game-status');
var gameMessages = document.getElementById('game-messages');
var newGame = document.getElementById('new-game');
var joinGame = document.getElementById('join-game');
// var startGame;
var player;
var gameOver = false;
var accounts;


if (typeof web3 !== 'undefined') {
    web3 = new Web3(web3.currentProvider);
} else {
    //this Dapp requires the use of metamask
    alert('please install metamask')
}
const eth = new Eth(web3.currentProvider);

var TicTacToeContract;
var TicTacToe;

//Play functions
var init = async function() {
    let response = await fetch('/artifacts/contracts/TicTacToe.sol/TicTacToe.json');
    const data = await response.json()
    const abi = data.abi
    const byteCode = data.bytecode

    accounts = await ethereum.request({ method: 'eth_requestAccounts' });

    TicTacToeContract = eth.contract(abi, byteCode, { from: accounts[0], gas: '3000000' });

    ethereum.on('accountsChanged', async function (accounts) {
        accounts = await ethereum.request({ method: 'eth_requestAccounts' });
        TicTacToeContract = eth.contract(abi, byteCode, { from: accounts[0], gas: '3000000' });
    });
    
    //the user can first create or join a game
    newGame.addEventListener('click',newGameHandler,false);
    joinGame.addEventListener('click',joinGameHandler, false);
    
    //events listeners for user to click on the board
    for(var i = 0; i < 9; i++) {
        boxes[i].addEventListener('click', clickHandler, false);
    }
    renderInterval = setInterval(render, 1000);
    render();
}

var checkWin = function(){

    //checks the contract on the blockchain to verify if there is a winner or not
    if (typeof TicTacToe != 'undefined'){
        var win;
        TicTacToe.status().then(function(res){
            win = res[0].words[0];
            console.log(win)
            var displayResult;
            statusDisplay.innerHTML = "Status: " + win
            if (win>0 && win<4){
                if (win==3){
                    displayResult = "Draw ! game is over";
                } else if (win == 2){
                    displayResult = "Player 2 wins ! game is over";
                } else if (win == 1) {
                    displayResult = "Player 1 wins ! game is over";
                }
                gameOver = true;
                document.querySelector('#game-messages').innerHTML = displayResult;
                for (var i = 0; i < 9; i++){
                    boxes[i].removeEventListener('click', clickHandler);
                }
            } else if (win == 4){
                document.querySelector('#game-messages').innerHTML = "Waiting for players...";
            }
        });
        if (win>0 && win<4){
            return true;
        } else {
            return false;
        }
    } else { 
        return false;
    }
}

var render = function(){

    //renders the board byt fetching the state of the board from the blockchain
    if (typeof TicTacToe != 'undefined'){
        TicTacToe.showBoard().then(function(res){
            for (var i = 0; i < 3; i++){
                for (var j = 0; j < 3; j++){
                    var state = res[0][i][j].words[0];
                    if (state>0){
                        var box_i = 3*i + j;
                        if (state==1){
                            boxes[box_i].className = 'x';
                            boxes[box_i].innerHTML = 'x';
                        } else{
                            boxes[box_i].className = 'o';
                            boxes[box_i].innerHTML = 'o';
                        }
                    }
                }   
            }
        });
        checkWin();
        if (!gameOver){
            turnMessageHandler();
        } else {
            TicTacToe.paidWinner().then(function(res){
                document.querySelector('#winner-paid').innerHTML = "Winner paid: " + res[0].words[0];
            });
        }
    }
}

var turnMessageHandler = function(){
    TicTacToe.turn().then(function(res){
        turnDisplay.innerHTML = "Player Turn: " + res[0].words[0]
        if (res[0].words[0] == player){
            document.querySelector('#game-messages').innerHTML = "Your turn !";
        } else {
            document.querySelector('#game-messages').innerHTML = "Not your turn !";
        }
    });
}

var newGameHandler = function(){

    //creates a new contract based on the user input of their opponent's address
    if (typeof TicTacToe != 'undefined'){
        console.log("There seems to be an existing game going on already");
    } else{
        var opponentAddress = document.getElementById('opponentAdress').value
        console.log(opponentAddress)
        TicTacToeContract.new(opponentAddress)
        .then(function(txHash) {
            var waitForTransaction = setInterval(function(){
                eth.getTransactionReceipt(txHash, function(err, receipt){
                    if (receipt) {
                        clearInterval(waitForTransaction);
                        TicTacToe = TicTacToeContract.at(receipt.contractAddress);
                        //display the contract address to share with the opponent

                        document.querySelector('#betAmountField').innerHTML = 
                    "<input type=\"text\" id=\"betAmount\" placeholder=\"Place Your Bet\"></input><button id=\"start-game\" onclick=\"startGameHandler()\">Place Bet</button> <br><br>";
                    }
                })
            }, 300);
        
        })
        
    }
}

var startGameHandler = async function(){

    if (typeof TicTacToe != 'undefined'){
        var betAmount = document.getElementById('betAmount');
        if (!betAmount) {
            betAmount = 1;
        } else {
            betAmount = betAmount.value;
        }
        console.log(betAmount);

        // await ethereum.request({ method: 'eth_requestAccounts' });
        // const signer = provider.getSigner();
        // await signer;
        // await contract.connect(signer).deposit(/*arguments*/, {value: ethdeposit});
        // { from: accounts[0], gas: '3000000',  value: web3.utils.toWei(1, "ether")}


        /* I need to make the bet amount the value of the join function call it is not working right now*/
        TicTacToe.join().then(function(txHash) {
            var waitForTransaction = setInterval(function(){
                eth.getTransactionReceipt(txHash, function(err, receipt){
                    if (receipt) {
                        clearInterval(waitForTransaction);
                        //display the contract address to share with the opponent

                        document.querySelector('#betAmountField').innerHTML +=  
                            "BET AMOUNT OF " + betAmount + " PLACED <br><br>" 
                            + "Share the contract address with your opponnent: " + String(TicTacToe.address) + "<br><br>";
                        document.querySelector('#player').innerHTML ="Player1"
                        player = 1;
                    }
                })
            }, 300);
        
        })

        // TicTacToe.join({ from: ethereum.selectedAddress, gas: '3000000',  value: web3.utils.toWei(1, "ether")}, function(err, res){ });
        


        // await ethereum.request({ method: 'eth_accounts' }).then(function (accounts) {
        //     TicTacToe.join({ from: accounts[0], gas: '3000000',  value: web3.utils.toWei(1, "ether")}, function(err, res){ });
        // }).then(function() {
        //     document.querySelector('#betAmountField').innerHTML = 
        //     "<input type=\"text\" id=\"betAmount\" placeholder=\"BET PLACED\"></input><button id=\"start-game\" onclick=\"() => startGameHandler()\">BET PLACED</button> <br><br>";
        //     }
        // )
        
        // .then(res => 
        //     console.log('Success', res))
        // .catch(err => console.log(err)) 
        // .then(function(txHash){   
        //     // var contractAddress;
        //     var waitForTransaction = setInterval(function(){
        //         eth.getTransactionReceipt(txHash, function(err, receipt){
        //             if (receipt) {
        //                 clearInterval(waitForTransaction);
        //                 //display the contract address to share with the opponent
        //                 document.querySelector('#newGameAddress').innerHTML = 
        //                     "Share the contract address with your opponnent: " + String(receipt.contractAddress) + "<br><br>";
        //                 document.querySelector('#player').innerHTML ="Player1"
        //                 player = 1;
        //             }
        //         })
        //     }, 300);
        // })
    } else {
        console.log("There doesn't seem to be an existing game going on already");
    }
    
}

var joinGameHandler = function(){
    //idem for joining a game
    var contractAddress = document.getElementById('contract-ID-tojoin').value.trim();
    TicTacToe = TicTacToeContract.at(contractAddress);
    TicTacToe.join();
    document.querySelector('#player').innerHTML = "Player2";
    player = 2;
}

var clickHandler = function() {

    //called when the user clicks a cell on the board

    if (typeof TicTacToe != 'undefined'){
        if (checkWin()){
            return;
        }
        var target_x = this.getAttribute('data-pos-x');
        var target_y = this.getAttribute('data-pos-y');
        TicTacToe.validMove(target_x, target_y).then(function(res){
            if (res[0]) {
                TicTacToe.turn().then(function(res) {
                    if (res[0].words[0] == player) {
                        TicTacToe.move(target_x, target_y).catch(function(err){
                            console.log('something went wrong ' + String(err));
                        }).then(function(res){
                            this.removeEventListener('click', clickHandler);
                            render();
                        });
                    }
                });
            }
        });
    }
}

init();
