import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {

            this.owner = accts[0];

            let counter = 1;

            while (this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while (this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner }, callback);
    }

    registerAirline(airlineName, airlineAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .registerAirline(airlineName, airlineAddress)
            .send({ from: self.owner, gas: 6721900 }, callback);
    }

    fundAirline(airlineAddress, callback) {
        let self = this;
        const fee = this.web3.utils.toWei('10', 'ether');
        self.flightSuretyApp.methods
            .fundAirline(airlineAddress)
            .send({ from: airlineAddress, value: fee }, callback);
    }

    isAirlineRegistered(airlineAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isAirlineRegistered(airlineAddress)
            .call({ from: self.owner }, callback);
    }

    registerFlight(flightName, airlineAddress, timestamp, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .registerFlight(flightName, airlineAddress, timestamp)
            .send({ from: self.owner, gas: 6721900 }, callback);
    }
    
    isAirlineFunded(airlineAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isAirlineFunded(airlineAddress)
            .call({ from: self.owner }, callback);
    }

    buy(flightkey, amount, callback) {
        let self = this;
        let insuredAmount = this.web3.utils.toWei(amount, 'ether');
        self.flightSuretyApp.methods
            .buy(flightkey)
            .send({ from: self.owner, gas: 6721900, value: insuredAmount }, callback);
    }

    getFlightKeybyName(flightName, airlineAddress, timestamp, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .getFlightKeybyName(flightName, airlineAddress, timestamp)
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flightKey, callback) {
        let self = this;
        let payload = {
            flightKey: flightKey,
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.flightKey)
            .send({  from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    getPassengerCredit(passangerAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .getPassengerCredit(passangerAddress)
            .call({ from: self.owner }, callback);
    }

    withdrawCredit(pessangerAddress, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .withdrawCredit(pessangerAddress)
            .send({ from: self.owner }, (error, result) => {
                callback(error, result);
            });
    }
}